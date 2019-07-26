from typing import Dict, Optional, Any, List
import logging

import numpy
from collections import defaultdict
from overrides import overrides
import torch
from torch.nn.modules.linear import Linear
import torch.nn.functional as F
from torch.nn.modules import Dropout

from allennlp.common.checks import ConfigurationError, check_dimensions_match
from allennlp.data import Vocabulary
from allennlp.modules import Seq2SeqEncoder, TextFieldEmbedder, Embedding, TimeDistributed, InputVariationalDropout
from allennlp.modules import FeedForward
from allennlp.models.model import Model
from allennlp.nn import InitializerApplicator, RegularizerApplicator
from allennlp.nn.util import get_text_field_mask, sequence_cross_entropy_with_logits
from allennlp.training.metrics import CategoricalAccuracy
#from library.models.pos_tagger_monolingual_model import PosTaggerMonolingual
# not sure if we should wrap the monolingual model or just have this as a standalone

logger = logging.getLogger(__name__)  # pylint: disable=invalid-name


@Model.register("pos_tagger_tbemb")
class PosTaggerTbemb(Model):
    """
    The Tbemb extension incorporates the treebank embedding of
    Stymne et al. (2018), which encodes which treebank the tokens 
    in a sentence come from. 
    Also, the universal_dependencies_tbemb dataset reader
    supports loading of multiple sources and storing the language
    identifier in the metadata as well as adding the treebank embedding feature.
    Parameters
    ----------
    vocab : ``Vocabulary``, required
        A Vocabulary, required in order to compute sizes for input/output projections.
    text_field_embedder : ``TextFieldEmbedder``, required
        Used to embed the ``tokens`` ``TextField`` we get as input to the model.
    encoder : ``Seq2SeqEncoder``
        The encoder (with its own internal stacking) that we will use to generate representations
        of tokens.
    label_namespace : ``str``, optional (default=``pos``)
        The labels (pos tags) we are predicting.
    treebank_embedding : ``Embedding``, optional.
        Used to embed the ``treebank_ids`` ``SequenceLabelField`` we get as input to the model.    
    langs_for_early_stop : ``List[str]``, optional, (default = [])
        Which languages to include in the averaged metrics
        (that could be used for early stopping).
    dropout : ``float``, optional, (default = 0.0)
        The variational dropout applied to the output of the encoder and MLP layers.
    input_dropout : ``float``, optional, (default = 0.0)
        The dropout applied to the embedded text input.
    initializer : ``InitializerApplicator``, optional (default=``InitializerApplicator()``)
        Used to initialize the model parameters.
    regularizer : ``RegularizerApplicator``, optional (default=``None``)
        If provided, will be used to calculate the regularization penalty during training.
    """

    def __init__(self,
                 vocab: Vocabulary,
                 text_field_embedder: TextFieldEmbedder,
                 encoder: Seq2SeqEncoder,
                 dropout: float = 0.0,
                 input_dropout: float = 0.0,
                 label_namespace: str = "pos",
                 treebank_embedding: Embedding = None,
                 use_treebank_embedding: bool = True,
                 langs_for_early_stop: List[str] = None,
                 initializer: InitializerApplicator = InitializerApplicator(),                 
                 regularizer: Optional[RegularizerApplicator] = None) -> None:
        super(PosTaggerTbemb, self).__init__(vocab, regularizer)
        
        self.label_namespace = label_namespace
        self.text_field_embedder = text_field_embedder
        self.num_classes = self.vocab.get_vocab_size(label_namespace)
        self.encoder = encoder
        encoder_dim = encoder.get_output_dim()

        self._dropout = InputVariationalDropout(dropout)
        self._input_dropout = Dropout(input_dropout)
        self._langs_for_early_stop = langs_for_early_stop or []
        self._treebank_embedding = treebank_embedding or None
        self._use_treebank_embedding = use_treebank_embedding
        
        self._lang_accuracy_scores: Dict[
                str, CategoricalAccuracy] = defaultdict(CategoricalAccuracy)
        
        self.tag_projection_layer = TimeDistributed(Linear(self.encoder.get_output_dim(),
                                                                           self.num_classes))


        representation_dim = text_field_embedder.get_output_dim()

        if treebank_embedding is not None:
            representation_dim += treebank_embedding.get_output_dim()

        check_dimensions_match(representation_dim, encoder.get_input_dim(),
                                       "text field embedding dim", "encoder input dim")

        if self.use_treebank_embedding:
            tbids = self.vocab.get_token_to_index_vocabulary("tbids")
            tbid_indices = {tb: index for tb, index in tbids.items()}
            self._tbids = set(tbid_indices.values())
            logger.info(f"Found TBIDs corresponding to the following treebanks : {tbid_indices}. "
                        "Embedding these as additional features.")

		self._accuracy_scores = CategoricalAccuracy()

        self.metrics = {
                "accuracy": CategoricalAccuracy(),
                "accuracy3": CategoricalAccuracy(top_k=3)
        }

        initializer(self)

    @overrides
    def forward(self,  # type: ignore
                words: Dict[str, torch.LongTensor],
                pos_tags: torch.LongTensor = None,
                head_tags: torch.LongTensor = None,
                head_indices: torch.LongTensor = None,
                treebank_ids: torch.LongTensor = None,
                metadata: List[Dict[str, Any]] = None) -> Dict[str, torch.Tensor]:
        # pylint: disable=arguments-differ
        """
        Parameters:
            TODO

        Embedding each language by the corresponding parameters for
        ``TextFieldEmbedder``. Batches should contain only samples from a
        single language.
        Metadata should have a ``lang`` key.
        """
        if 'lang' not in metadata[0]:
            raise ConfigurationError(
                    "metadata is missing 'lang' key; "
                    "Use the universal_dependencies_multilang/tbemb dataset_reader.")

        batch_lang = metadata[0]['lang']
        for entry in metadata:
            if entry['lang'] != batch_lang:
                raise ConfigurationError("Two languages in the same batch.")

        embedded_text_input = self.text_field_embedder(words, lang=batch_lang)
        
        if treebank_ids is not None and self._treebank_embedding is not None:
            embedded_treebank_ids = self._treebank_embedding(treebank_ids)
        
        if self.use_treebank_embedding:
            embedded_text_input = torch.cat([embedded_text_input, embedded_treebank_ids], -1)
        
        batch_size, sequence_length, _ = embedded_text_input.size()
        mask = get_text_field_mask(words)
        encoded_text = self.encoder(embedded_text_input, mask)

        #######
        logits = self.tag_projection_layer(encoded_text)
        reshaped_log_probs = logits.view(-1, self.num_classes)
        class_probabilities = F.softmax(reshaped_log_probs, dim=-1).view([batch_size,
                                                                          sequence_length,
                                                                          self.num_classes])
            

        output_dict = {
                "logits": logits, 
                "class_probabilities": class_probabilities
        }

        if pos_tags is not None:
            loss = sequence_cross_entropy_with_logits(logits, pos_tags, mask)
            for metric in self.metrics.values():
                metric(logits, pos_tags, mask.float())
            output_dict["loss"] = loss

            self._lang_accuracy_scores[batch_lang](logits,
                                                   pos_tags,
                                                   mask)
        if metadata is not None:
            output_dict["words"] = [x["words"] for x in metadata]
            
            # include ids, heads and tags in dictionary for next task/evaluation
            output_dict["ids"] = [x["ids"] for x in metadata if "ids" in x]
            output_dict["predicted_dependencies"] = [x["head_tags"] for x in metadata] 
            output_dict["predicted_heads"] = [x["head_indices"] for x in metadata] 

        return output_dict

    @overrides
    def decode(self, output_dict: Dict[str, torch.Tensor]) -> Dict[str, torch.Tensor]:
        """
        Does a simple position-wise argmax over each token, converts indices to string labels, and
        adds a ``"tags"`` key to the dictionary with the result.
        """
        all_predictions = output_dict['class_probabilities']
        all_predictions = all_predictions.cpu().data.numpy()
        if all_predictions.ndim == 3:
            predictions_list = [all_predictions[i] for i in range(all_predictions.shape[0])]
        else:
            predictions_list = [all_predictions]
        all_tags = []
        for predictions in predictions_list:
            argmax_indices = numpy.argmax(predictions, axis=-1)
            pos_tags = [self.vocab.get_token_from_index(x, namespace="pos")
                    for x in argmax_indices]
            all_tags.append(pos_tags)
        output_dict['pos'] = all_tags
        return output_dict

    @overrides
    def get_metrics(self, reset: bool = False) -> Dict[str, float]:
        return {metric_name: metric.get_metric(reset) for metric_name, metric in self.metrics.items()}


#        metrics = {}
#        all_uas = []
#        all_las = []
#        for lang, scores in self._lang_attachment_scores.items():
#            lang_metrics = scores.get_metric(reset)

#            for key in lang_metrics.keys():
                # Store only those metrics.
#                if key in ['UAS', 'LAS', 'loss']:
#                    metrics["{}_{}".format(key, lang)] = lang_metrics[key]

            # Include in the average only languages that should count for early stopping.
#            if lang in self._langs_for_early_stop:
#                all_uas.append(metrics["UAS_{}".format(lang)])
#                all_las.append(metrics["LAS_{}".format(lang)])

#        if self._langs_for_early_stop:
#            metrics.update({
#                    "UAS_AVG": numpy.mean(all_uas),
#                    "LAS_AVG": numpy.mean(all_las)
#            })

#        return metrics
