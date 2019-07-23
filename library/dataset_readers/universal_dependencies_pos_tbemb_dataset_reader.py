from typing import Dict, Tuple, List, Iterator, Any
import logging
import itertools
import glob
import os
import numpy as np

from overrides import overrides

from allennlp.common.checks import ConfigurationError
from allennlp.data.dataset_readers.dataset_reader import DatasetReader
from allennlp.data.fields import Field, TextField, SequenceLabelField, MetadataField
from allennlp.data.instance import Instance
from allennlp.data.token_indexers import SingleIdTokenIndexer, TokenIndexer
from allennlp.data.tokenizers import Token
from allennlp.data.dataset_readers.universal_dependencies import lazy_parse

logger = logging.getLogger(__name__)  # pylint: disable=invalid-name


def get_file_paths(pathname: str, languages: List[str]):
    """
    Gets a list of all files by the pathname with the given language ids.
    Filenames are assumed to have the language identifier followed by a dash
    as a prefix (e.g. en-universal.conll).

    Parameters
    ----------
    pathname :  ``str``, required.
        An absolute or relative pathname (can contain shell-style wildcards)
    languages : ``List[str]``, required
        The language identifiers to use.

    Returns
    -------
    A list of tuples (language id, file path).
    """
    paths = []
    for file_path in glob.glob(pathname):
        base = os.path.splitext(os.path.basename(file_path))[0]
        lang_id = base.split('-')[0]
        if lang_id in languages:
            paths.append((lang_id, file_path))

    if not paths:
        raise ConfigurationError("No dataset files to read")

    return paths


@DatasetReader.register("universal_dependencies_pos_tbemb")
class UniversalDependenciesPosTbembDatasetReader(DatasetReader):
    """
    Reads multiple files in the conllu Universal Dependencies format.
    All files should be in the same directory and the filenames should have
    the language identifier followed by a dash as a prefix (e.g. en-universal.conll)
    This Dataset Reader can also work with regular UD folder structure.
    When using the alternate option, the reader alternates randomly between
    the files every instances_per_file. The is_first_pass_for_vocab disables
    this behaviour for the first pass (could be useful for a single full path
    over the dataset in order to generate a vocabulary).

    Notice: when using the alternate option, one should also use the ``instances_per_epoch``
    option for the iterator. Otherwise, each epoch will loop infinitely.

    Parameters
    ----------
    languages : ``List[str]``, required
        The language identifiers to use.
    token_indexers : ``Dict[str, TokenIndexer]``, optional (default=``{"tokens": SingleIdTokenIndexer()}``)
        The token indexers to be applied to the words TextField.
    use_language_specific_pos : ``bool``, optional (default = False)
        Whether to use UD POS tags, or to use the language specific POS tags
        provided in the conllu format.
    alternate : ``bool``, optional (default = True)
        Whether to alternate between input files.
    is_first_pass_for_vocab : ``bool``, optional (default = True)
        Whether the first pass will be for generating the vocab. If true,
        the first pass will run over the entire dataset of each file (even if alternate is on).
    instances_per_file : ``int``, optional (default = 32)
        The amount of consecutive cases to sample from each input file when alternating.
    use_treebank_embedding : ``bool``, optional (default = True)
        Whether to use a treebank embedding, a feature encodes what treebank each sentence belongs to.
    """
    def __init__(self,
                 languages: List[str],
                 token_indexers: Dict[str, TokenIndexer] = None,
                 use_language_specific_pos: bool = False,
                 lazy: bool = False,
                 label_namespace: str = "labels"
                 alternate: bool = True,
                 is_first_pass_for_vocab: bool = True,
                 use_treebank_embedding: bool = False,
                 instances_per_file: int = 32) -> None:
        super().__init__(lazy)
        self._languages = languages
        self._token_indexers = token_indexers or {'tokens': SingleIdTokenIndexer()}
        self._use_language_specific_pos = use_language_specific_pos
        self._use_treebank_embedding = use_treebank_embedding
        self.label_namespace = label_namespace


        self._is_first_pass_for_vocab = is_first_pass_for_vocab
        self._alternate = alternate
        self._instances_per_file = instances_per_file

        self._is_first_pass = True
        self._iterators: List[Tuple[str, Iterator[Any]]] = None


    def _read_one_file(self, lang: str, file_path: str):
        with open(file_path, 'r') as conllu_file:
            logger.info("Reading UD instances for %s language from conllu dataset at: %s", lang, file_path)

            for annotation in lazy_parse(conllu_file.read()):
                # CoNLLU annotations sometimes add back in words that have been elided
                # in the original sentence; we remove these, as we're just predicting
                # dependencies for the original sentence.
                # We filter by None here as elided words have a non-integer word id,
                # and are replaced with None by the conllu python library.
                annotation = [x for x in annotation if x["id"] is not None]

                tokens = [x["form"] for x in annotation]
                               
                if self._use_language_specific_pos:
                    tags = [x["xpostag"] for x in annotation]
                else:
                    tags = [x["upostag"] for x in annotation]
                
                # append the lang/treebank tag as a sequence label field
                if self._use_treebank_embedding:
                    treebank_ids = [lang for x in words]
                    yield self.text_to_instance(lang, tokens, tags, treebank_ids)
                else:
                    yield self.text_to_instance(lang, tokens, tags)

    @overrides
    def _read(self, file_path: str):
        file_paths = get_file_paths(file_path, self._languages)
        if (self._is_first_pass and self._is_first_pass_for_vocab) or (not self._alternate):
            iterators = [iter(self._read_one_file(lang, file_path))
                         for (lang, file_path) in file_paths]
            self._is_first_pass = False
            for inst in itertools.chain(*iterators):
                yield inst

        else:
            if self._iterators is None:
                self._iterators = [(lang, iter(self._read_one_file(lang, file_path)))
                                   for (lang, file_path) in file_paths]
            num_files = len(file_paths)
            while True:
                ind = np.random.randint(num_files)
                lang, lang_iter = self._iterators[ind]
                for _ in range(self._instances_per_file):
                    try:
                        yield lang_iter.__next__()
                    except StopIteration:
                        lang, file_path = file_paths[ind]
                        lang_iter = iter(self._read_one_file(lang, file_path))
                        self._iterators[ind] = (lang, lang_iter)
                        yield lang_iter.__next__()

    @overrides
    def text_to_instance(self,  # type: ignore
                         lang: str,
                         tokens: List[str],
                         tags: List[str],
                         treebank_ids: List[str]) -> Instance:
        # pylint: disable=arguments-differ
        """
        Parameters
        ----------
        lang : ``str``, required.
            The language identifier.
        tokens : ``List[str]``, required.
            The words in the sentence to be encoded.
        tags : ``List[str]``, required.
            The universal dependencies POS tags for each word.
        treebank_ids: ``List[str]``, optional (default = None)
            The treebank id for the words in the sentence.

        Returns
        -------
        An instance containing words, upos tags and treebank ids.
        The language identifier is stored in the metadata.
        """
        fields: Dict[str, Field] = {}

        tokens = TextField([Token(t) for t in words], self._token_indexers)
        fields["tokens"] = tokens
        fields["tags"] = SequenceLabelField(tags, tokens, label_namespace=self.label_namespace)
        
        if self._use_treebank_embedding:
            fields["treebank_ids"] = SequenceLabelField(treebank_ids, tokens, label_namespace="tbids")
        

        fields["metadata"] = MetadataField({"words": tokens, "pos": tags, "lang": lang})
        return Instance(fields)
