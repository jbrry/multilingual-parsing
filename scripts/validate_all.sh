#!/bin/bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

test -z $2 && echo "Missing file type: 'single' or 'combined'"
test -z $2 && exit 1
file_type=$2

for lang in dan swe nno nob; do 
  echo "validating ${lang}"

  for RANDOM_SEED in 54360 44184 20423 80520 27916; do

    if [ ${file_type} == 'single' ]; then
      echo "validating single treebanks"

      python utils/validate_treebank.py output/${model_type}/projected/fao_wiki.apertium.${lang}-fao-${RANDOM_SEED}.allennlp.projected.conllu ${model_type}

    elif [ ${file_type} == 'combined' ]; then
      echo "validating combined treebank"

      python utils/validate_treebank.py output/${model_type}/tmp/combined_four_${RANDOM_SEED}.conllu ${model_type}

    fi
  done
done

