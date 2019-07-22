from typing import Dict, Tuple, List
import logging

from overrides import overrides
from conllu.parser import parse_line, DEFAULT_FIELDS

from allennlp.common.file_utils import cached_path
from allennlp.data.dataset_readers.dataset_reader import DatasetReader
from allennlp.data.fields import Field, TextField, SequenceLabelField, MetadataField
from allennlp.data.instance import Instance
from allennlp.data.token_indexers import SingleIdTokenIndexer, TokenIndexer
from allennlp.data.tokenizers import Token
# BERT imports?

logger = logging.getLogger(__name__)  # pylint: disable=invalid-name


def lazy_parse(text: str, fields: Tuple[str, ...]=DEFAULT_FIELDS):
    for sentence in text.split("\n\n"):
        if sentence:
            yield [parse_line(line, fields)
                   for line in sentence.split("\n")
                   if line and not line.strip().startswith("#")]


@DatasetReader.register("universal_dependencies_pos_monolingual")
class UniversalDependenciesDatasetReaderPos(DatasetReader):
    """
    Reads a file in the conllu Universal Dependencies format.
    Parameters
    ----------
    token_indexers : ``Dict[str, TokenIndexer]``, optional (default=``{"tokens": SingleIdTokenIndexer()}``)
        The token indexers to be applied to the words TextField.
    use_language_specific_pos : ``bool``, optional (default = False)
        Whether to use UD POS tags, or to use the language specific POS tags
        provided in the conllu format.
    """
    def __init__(self,
                 token_indexers: Dict[str, TokenIndexer] = None,
                 use_language_specific_pos: bool = False,
                 lazy: bool = False,
                 label_namespace: str = "labels") -> None:
        super().__init__(lazy)
        self._token_indexers = token_indexers or {'tokens': SingleIdTokenIndexer()}
        self.use_language_specific_pos = use_language_specific_pos
        self.label_namespace = label_namespace

    @overrides
    def _read(self, file_path: str):
        # if `file_path` is a URL, redirect to the cache
        file_path = cached_path(file_path)

        with open(file_path, 'r') as conllu_file:
            logger.info("Reading UD instances from conllu dataset at: %s", file_path)

            for annotation in  lazy_parse(conllu_file.read()):
                # CoNLLU annotations sometimes add back in words that have been elided
                # in the original sentence; we remove these, as we're just predicting
                # dependencies for the original sentence.
                # We filter by None here as elided words have a non-integer word id,
                # and are replaced with None by the conllu python library.
                annotation = [x for x in annotation if x["id"] is not None]

                tokens = [x["form"] for x in annotation]
                if self.use_language_specific_pos:
                    tags = [x["xpostag"] for x in annotation]
                else:
                    tags = [x["upostag"] for x in annotation]
                yield self.text_to_instance(tokens, tags)

    @overrides
    def text_to_instance(self,  # type: ignore
                         tokens: List[str],
                         tags: List[str]) -> Instance:
        # pylint: disable=arguments-differ
        """
        Parameters
        ----------
        tokens : ``List[str]``, required.
            The tokens in the sentence to be encoded.
        tags : ``List[str]``, required.
            The universal dependencies POS tags for each word.
        Returns
        -------
        An instance containing tokens and pos tags
        indices as fields.
        """
        fields: Dict[str, Field] = {}

        tokens = TextField([Token(t) for t in tokens], self._token_indexers)
        fields["tokens"] = tokens
        fields["tags"] = SequenceLabelField(tags, tokens, self.label_namespace)
        fields["metadata"] = MetadataField({"words": tokens, "pos": tags})
        return Instance(fields)
