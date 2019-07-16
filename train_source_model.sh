#!/bin/bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

TB_DIR='/home/jbarry/ud-parsing/ud-treebanks-v2.2'
TIMESTAMP=`date "+%Y%m%d-%H%M%S"` 

if [ ${model_type} == 'monolingual' ]
   then echo "training monolingual model..."
 
   # need to specify 
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

elif [ ${model_type} == 'multilingual' ]
  then echo "training multilingual model..."

  # files are found using the config file.
  allennlp train configs/multilingual/source_tbemb.jsonnet -s output/multilingual/source_models/da_sv_no-$TIMESTAMP \
  --include-package library

fi
