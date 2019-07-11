#!/bin/bash

TB_DIR='/home/jbarry/ud-treebanks-v2.3'

v=`echo $((1 + RANDOM % 1000))`

for tbid in en_lines ; do
  for filepath in $TB_DIR/*/$tbid-ud-train.conllu; do 
  
  dir=`dirname $filepath`        # e.g. /home/james/ud_folder/ud-treebanks-v2.2/UD_Afrikaans-AfriBooms
  tb_name=`basename $dir`        # e.g. UD_Afrikaans-AfriBooms

  # ud v2.3
  export TRAIN_PATHNAME=${TB_DIR}/${tb_name}/${tbid}-ud-train.conllu
  export DEV_PATHNAME=${TB_DIR}/${tb_name}/${tbid}-ud-dev.conllu
  #export TEST_PATHNAME=/home/jbarry/ud-treebanks-v2.3/${tb_name}/${tbid}-ud-test.conllu
  
  allennlp train ../configs/monolingual/dependency_parser_char.jsonnet -s ../output/monolingual/${tbid}-$v --include-package library
  done
done
