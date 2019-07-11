from typing import Dict, Any, List, Tuple
from overrides import overrides
from allennlp.common.util import JsonDict, sanitize
from allennlp.data import DatasetReader, Instance
from allennlp.models import Model
from allennlp.predictors.predictor import Predictor
from allennlp.data.tokenizers.word_splitter import SpacyWordSplitter

sentence_index = 0

@Predictor.register("biaffine-dependency-parser-monolingual")
class BiaffineDependencyParserPredictorMonolingual(Predictor):
    """
    Predictor that takes in a sentence and returns
    a set of heads and tags for it.
    Predictor for the :class:`~allennlp.models.BiaffineDependencyParser` model
    but extended to write conllu lines.
    """
    def __init__(self, model: Model, dataset_reader: DatasetReader) -> None:
        super().__init__(model, dataset_reader)

        
    def predict(self, sentence: str) -> JsonDict: 
        return self.predict_json({"sentence": sentence})

    @overrides
    def _json_to_instance(self, json_dict: JsonDict) -> Instance:
        """
        Expects JSON that looks like ``{"sentence": "..."}``.
        Runs the underlying model, and adds the ``"words"`` to the output, also tags and parse??.
        """
        spacy_tokens = self._tokenizer.split_words(json_dict["sentence"])
        sentence_text = [token.text for token in spacy_tokens]

        #labels = json_dict["head_tags"]
        #for i, label in enumerate(labels):
        #    if label not in self._model.vocab._token_to_index["head_tags"]:
        #        label = None
        #        labels[i] = label

        if self._dataset_reader.use_language_specific_pos: # type: ignore
            # fine-grained part of speech
            pos_tags = [token.tag_ for token in spacy_tokens]
        else:
            pos_tags = None

        pos_tags = [token.pos_ for token in spacy_tokens]
        
        return self._dataset_reader.text_to_instance(sentence_text, pos_tags)

    @overrides
    def predict_instance(self, instance: Instance) -> JsonDict:
        if "@@UNKNOWN@@" not in self._model.vocab._token_to_index["head_tags"]:
            # Handle cases where the labels are present in the test set but not training set
            # https://github.com/Hyperparticle/udify/blob/b6a1173e7e5fc1e4c63f4a7cf1563b469268a3b8/udify/predictors/predictor.py
            self._predict_unknown(instance)

        outputs = self._model.forward_on_instance(instance)
        return sanitize(outputs)

    def _predict_unknown(self, instance: Instance):
        """
        Maps each unknown label in each namespace to a default token
        :param instance: the instance containing a list of labels for each namespace
        from: https://github.com/Hyperparticle/udify/blob/b6a1173e7e5fc1e4c63f4a7cf1563b469268a3b8/udify/predictors/predictor.py
        """
        def replace_tokens(instance: Instance, namespace: str, token: str):
            if namespace not in instance.fields:
                return

            instance.fields[namespace].labels = [label
                                                 if label in self._model.vocab._token_to_index[namespace]
                                                 else token
                                                 for label in instance.fields[namespace].labels]

        replace_tokens(instance, "upos", "NOUN")
        replace_tokens(instance, "head_tags", "case")


    def dump_line(self, outputs: JsonDict) -> str:
        global sentence_index
        
        sentence_index += 1
        sent_id = ('# sent_id = ' + str(sentence_index))
        text = ('# text = ' + ' '.join(w for w in outputs["words"]))
        
        lines = zip(*[outputs[k] for k in ["words", "pos", "predicted_heads", "predicted_dependencies"]])
        # a rather messy way of writing out tab-separated ConLLU fields TODO tidy this up
        conllu_fields = "\n".join([str(i + 1) + "\t" + word + "\t" + "_" + "\t" + \
                                   upos_tag + "\t" + "_" + "\t" + "_" + "\t" + \
                                   str(head) + "\t" + dep + "\t" + "_" + "\t" + "_" \
                                   for i, (word, upos_tag, head, dep) in enumerate(lines)]) + "\n\n"
        return "\n".join([sent_id, text, conllu_fields])
