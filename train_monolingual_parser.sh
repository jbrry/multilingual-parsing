#!/bin/bash

TB_DIR='/home/jbarry/ud-parsing/ud-treebanks-v2.2'

#v=`echo $((1 + RANDOM % 1000))`

for tbid in da_ddt sv_talbanken no_nynorsk no_bokmaal; do
  for filepath in $TB_DIR/*/$tbid-ud-train.conllu; do 
  
  dir=`dirname $filepath`        # e.g. /home/james/ud_folder/ud-treebanks-v2.2/UD_Afrikaans-AfriBooms
  tb_name=`basename $dir`        # e.g. UD_Afrikaans-AfriBooms

  # ud v2.2
  export TRAIN_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-train.conllu
  export DEV_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-dev.conllu
  #export TEST_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-test.conllu
  
  allennlp train configs/monolingual/dependency_parser_char.jsonnet -s output/monolingual/source_models/${tbid}
  done
done
