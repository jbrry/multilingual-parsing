#!/bin/sh

# runs project_aligned_trees.py with source parsed files, alignments and parrallel sentences.


for lang in dan swe nno nob; do
  # assign tbid to language
  if [ "${lang}" = "dan" ]; then
    tbid=da_ddt
    echo "projecting source files from $tbid"
  elif [ "${lang}" = "swe" ]; then
    tbid=sv_talbanken
    echo "projecting source files from $tbid"
  elif [ "${lang}" = "nno" ]; then
    tbid=no_nynorsk
    echo "projecting source files from $tbid"
  elif [ "${lang}" = "nob" ]; then
    tbid=no_bokmaal
    echo "projecting source files from $tbid"
  fi

  python utils/project_aligned_trees.py output/monolingual/predicted/fao_wiki.apertium.fao-${tbid}.allennlp.parsed.conllu data/faroese/fao_wiki.apertium.fao-${lang}.align.txt data/faroese/fao_wiki.apertium.${lang}-fao.input.txt > output/monolingual/projected/fao_wiki.apertium.${lang}-fao.allennlp.projected.conllu

done

