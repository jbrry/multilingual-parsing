#!/bin/bash

# run from main directory; ./scripts/validate_all.sh <parsed_file> <model_type>

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

for lang in dan swe nno nob; do
  
  echo "validating ${lang}"

  python utils/validate_treebank.py output/${model_type}/projected/fao_wiki.apertium.${lang}-fao.allennlp.projected.conllu ${model_type}

done

