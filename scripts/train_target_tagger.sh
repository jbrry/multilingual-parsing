#!/bin/bash

# train a POS tagger on output of projected files so that we can produces silver POS tags for the gold UD treebank

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

TB_DIR='/home/jbarry/DeepLo2019/multilingual-parsing/output/'${model_type}'/validated'

for RANDOM_SEED in 54360 44184 20423 80520 27916; do
  for lang in dan swe nno nob comb; do
    # normal case
    export TRAIN_DATA_PATH=${TB_DIR}/fao_wiki.apertium.${lang}-fao-${RANDOM_SEED}.allennlp.projected.conllu
        
    if [ ${lang} == 'comb' ]; then
      echo " using file created from MST voting..."
      export TRAIN_DATA_PATH=${TB_DIR}/comb_${RANDOM_SEED}.conllu
    fi

    # sampled case (reduced data scenario)
    #export TRAIN_DATA_PATH=output/${model_type}/tmp/fao_wiki.apertium.${lang}-sampled.conllu
        
    allennlp train configs/monolingual/pos_tagger_char_no_dev.jsonnet -s output/${model_type}/target_models/${lang}-pos-${RANDOM_SEED} --include-package library
  
  done
done

