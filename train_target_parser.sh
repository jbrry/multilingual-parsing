#!/bin/bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

TB_DIR='/home/jbarry/DeepLo2019/multilingual-parsing/output/'${model_type}'/validated/'

TIMESTAMP=`date "+%Y%m%d-%H%M%S"` 


for lang in dan swe nno nob; do
  
  export TRAIN_DATA_PATH=${TB_DIR}/fao_wiki.apertium.${lang}-fao.allennlp.projected.conllu
  #export DEV_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-dev.conllu
  #export TEST_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-test.conllu
  
  if [ ${model_type} == 'monolingual' ]
     then echo "training monolingual target model..."
 
     allennlp train configs/monolingual/dependency_parser_char_no_dev.jsonnet -s output/monolingual/target_models/${lang}-$TIMESTAMP --include-package library
  
  elif [ ${model_type} == 'multilingual' ]
    then echo "training monolingual target model using multilingual source-parsed files..."

    allennlp train configs/monolingual/dependency_parser_char_no_dev.jsonnet -s output/multilingual/target_models/${lang}-$TIMESTAMP --include-package library
  fi
done

