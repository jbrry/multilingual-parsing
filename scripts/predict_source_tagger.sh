#!/usr/bin/env bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

test -z $2 && echo "Missing file type: 'ud' or 'user'"
test -z $2 && exit 1
file_type=$2

if [ -n "$3" ]; then
    # data type: 'dev' or 'test'
    data_type=$3
    fi

echo "user specified model type: ${model_type}"

TB_DIR='data/ud-treebanks-v2.2'
EMB_DIR=${HOME}/embeddings

TIMESTAMP=`date "+%Y%m%d-%H%M%S"`
SUFFIX='20190804-193214'

for lang in dan swe nno nob; do
  # assign tbid to language
  if [ "${lang}" = "dan" ]; then
    tbid=da_ddt
  elif [ "${lang}" = "swe" ]; then
    tbid=sv_talbanken
  elif [ "${lang}" = "nno" ]; then
    tbid=no_nynorsk
  elif [ "${lang}" = "nob" ]; then
    tbid=no_bokmaal
  fi
  
  echo "processing ${tbid}..."

  for RANDOM_SEED in 54360 44184 20423 80520 27916; do

    for filepath in ${TB_DIR}/*/${tbid}-ud-train.conllu; do
      dir=`dirname $filepath`
      tb_name=`basename $dir`

      # embeddings
      vecs_lang=$(echo ${tb_name} | awk -F "_" '{print $2}')
      echo "processing language: ${vecs_lang}" 
	  VECS_DIR=${EMB_DIR}/${vecs_lang}
      VECS_FILE=$(ls ${VECS_DIR}/*.vectors)
	  echo "using embeddings: ${VECS_FILE}"
      export VECS_PATH=${VECS_FILE}
    done

    #=== Model type ===
    if [ "${model_type}" == 'monolingual' ]; then
      src=${tbid}-pos-${RANDOM_SEED}
    elif [ "${model_type}" == 'multilingual' ]; then
      src="da_sv_no-pos-${RANDOM_SEED}"
    fi 

    #=== UD treebank ===
    if [ "${file_type}" == 'ud' ]; then
      echo "tagging UD treebank"

      # find the appropriate UD treebank
      for filepath in ${TB_DIR}/*/${tbid}-ud-train.conllu; do
        dir=`dirname $filepath`
        tb_name=`basename $dir`

        PRED_FILE=${TB_DIR}/${tb_name}/${tbid}-ud-${data_type}.conllu
        OUT_FILE=output/${model_type}/predicted/${tbid}-${data_type}-allennlp-tagged-${RANDOM_SEED}.conllu
      done

    #=== Custom filepath ===
    elif [ "${file_type}" == 'user' ]
      then echo "tagging user-created file with custom paths/name"
      
      # path to source UDPipe segmented/tokenized file to predict
      PRED_FILE=data/faroese/fao_wiki.apertium.fao-${lang}.udpipe.parsed.conllu
      OUT_FILE=data/faroese/fao_wiki.apertium.fao-${lang}-${RANDOM_SEED}.allennlp.tagged.conllu
    fi   

  #=== Predict ===
  allennlp predict output/${model_type}/source_models/${src}/model.tar.gz ${PRED_FILE} \
     --output-file ${OUT_FILE} \
     --predictor conllu-predictor \
     --include-package library \
     --use-dataset-reader

  done
done
