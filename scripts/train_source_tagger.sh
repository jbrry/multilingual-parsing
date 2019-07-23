#!/bin/bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

TB_DIR='data/ud-treebanks-v2.2'
TIMESTAMP=`date "+%Y%m%d-%H%M%S"` 

if [ ${model_type} == 'monolingual' ]
   then echo "training monolingual model(s)..."

   for tbid in da_ddt sv_talbanken no_nynorsk no_bokmaal; do
      for filepath in ${TB_DIR}/*/${tbid}-ud-train.conllu; do 
  
      dir=`dirname $filepath`        # e.g. /home/james/ud_folder/ud-treebanks-v2.2/UD_Afrikaans-AfriBooms
      tb_name=`basename $dir`        # e.g. UD_Afrikaans-AfriBooms

      # ud v2.2
      export TRAIN_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-train.conllu
      export DEV_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-dev.conllu
      export TEST_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-test.conllu
      
      echo "training tagger model..."
      allennlp train configs/monolingual/pos_tagger_char.jsonnet -s output/monolingual/source_models/${tbid}-pos-${TIMESTAMP} --include-package library
    done
  done

elif [ ${model_type} == 'multilingual' ]
  then echo "training multilingual model... Not Implemented"

fi
