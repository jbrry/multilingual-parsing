#!/bin/sh

# runs utils/project_aligned_trees.py with source parsed files, alignments and parrallel sentences.
# run from main directory, requires 'output/model_type/projected' to write files.

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1


for lang in dan swe nno nob; do
  # assign tbid to language
  if [ "${lang}" = "dan" ]; then
    tbid=da_ddt
  elif [ "${lang}" = "swe" ]; then
    tbid=sv_talbanken
  elif [ "${lang}" = "nno" ]; then
    tbid=no_nynorsk
  elif [ "${lang}" = "nob" ]; then
    tbid=no_bokmaal
  fi

  echo "projecting source files from $tbid"

  for RANDOM_SEED in 54360 44184 20423 80520 27916; do

  python utils/project_aligned_trees.py output/${model_type}/predicted/fao_wiki.apertium.fao-${tbid}-${RANDOM_SEED}.allennlp.parsed.conllu data/faroese/fao_wiki.apertium.fao-${lang}.align.txt data/faroese/fao_wiki.apertium.${lang}-fao.input.txt > output/${model_type}/projected/fao_wiki.apertium.${lang}-fao-${RANDOM_SEED}.allennlp.projected.conllu

  done
done

