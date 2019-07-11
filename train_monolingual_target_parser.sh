#!/bin/bash

TB_DIR='/home/jbarry/DeepLo2019/multilingual-parsing/output/monolingual/validated/'

v=`echo $((1 + RANDOM % 1000))`

for lang in dan swe nno nob; do
  
  export TRAIN_DATA_PATH=${TB_DIR}/fao_wiki.apertium.${lang}-fao.allennlp.projected.conllu
  #export DEV_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-dev.conllu
  #export TEST_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-test.conllu
  
  allennlp train configs/monolingual/dependency_parser_char_no_dev.jsonnet -s output/monolingual/target_models/${lang}-$v

done

