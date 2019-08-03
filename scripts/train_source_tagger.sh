#!/bin/bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

TB_DIR='data/ud-treebanks-v2.2'
EMB_DIR=${HOME}/embeddings

TIMESTAMP=`date "+%Y%m%d-%H%M%S"` 

if [ ${model_type} == 'monolingual' ]
   then echo "training monolingual model(s)..."

   for tbid in da_ddt sv_talbanken no_nynorsk no_bokmaal ; do
   #for tbid in da_ddt ; do
     for filepath in ${TB_DIR}/*/${tbid}-ud-train.conllu; do 
  
      dir=`dirname $filepath`        # e.g. /home/james/ud_folder/ud-treebanks-v2.2/UD_Afrikaans-AfriBooms
      tb_name=`basename $dir`        # e.g. UD_Afrikaans-AfriBooms

      # ud v2.2
      export TRAIN_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-train.conllu
      export DEV_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-dev.conllu
      export TEST_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-test.conllu
      
      lang=$(echo ${tb_name} | awk -F "_" '{print $2}')

      echo "processing language: ${lang}"

      VECS_DIR=${EMB_DIR}/${lang}
      VECS_FILE=$(ls ${VECS_DIR}/*.vectors)
      echo $VECS_FILE
      export VECS_PATH=${VECS_FILE}

      allennlp train configs/monolingual/pos_tagger_char.jsonnet -s output/monolingual/source_models/${tbid}-pos-${TIMESTAMP} --include-package library
    done
  done

elif [ ${model_type} == 'multilingual' ]
  then echo "training multilingual model..."
  for tbid in da_ddt sv_talbanken no_nynorsk no_bokmaal ; do 
    for filepath in ${TB_DIR}/*/${tbid}-ud-train.conllu; do 
    dir=`dirname $filepath`
    tb_name=`basename $dir`


    # files are found using the config file.
    allennlp train configs/multilingual/pos_source_tbemb_embeds.jsonnet -s output/multilingual/source_models/da_sv_no-pos-$TIMESTAMP \
  --include-package library

  done
done
fi
