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

echo "user specified ${model_type} model"

TB_DIR='data/ud-treebanks-v2.2'
TIMESTAMP=`date "+%Y%m%d-%H%M%S"`

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

    #=== UD treebank ===
    if [ "${file_type}" == 'ud' ]; then
      echo "parsing UD treebank"

      # find the appropriate UD treebank
      for filepath in ${TB_DIR}/*/${tbid}-ud-train.conllu; do
        dir=`dirname $filepath`
        tb_name=`basename $dir`

        PRED_FILE=${TB_DIR}/${tb_name}/${tbid}-ud-${data_type}.conllu
        OUT_FILE=output/${model_type}/predicted/${tbid}-ud-${data_type}.conllu
      done

    elif [ "${file_type}" = "user" ]; then
      echo "parsing custom file"

      # allennlp tagged file
      PRED_FILE=data/faroese/fao_wiki.apertium.fao-${lang}-${RANDOM_SEED}.allennlp.tagged.conllu      
    fi
  
    if [ "${model_type}" == 'monolingual' ]; then
      echo "using monolingual model"
      SUFFIX='20190807-142254'
      src=${tbid}-silver-${RANDOM_SEED}

    elif [ "${model_type}" == 'multilingual' ]; then
      echo "using multilignual model"
      SUFFIX='20190806-180232'
      src=da_sv_no-silver-${RANDOM_SEED}
    
      # change name to format expected by dataset reader
      cp ${PRED_FILE} data/faroese/${tbid}-allennlp.tagged.conllu
      PRED_FILE=data/faroese/${tbid}-allennlp.tagged.conllu
    fi

    echo "predicting parse"
      
    # file to write
    OUT_FILE=output/${model_type}/predicted/fao_wiki.apertium.fao-${tbid}-${RANDOM_SEED}.allennlp.parsed.conllu

    #=== Predict ===
    allennlp predict output/${model_type}/source_models/${src}/model.tar.gz ${PRED_FILE} \
       --output-file ${OUT_FILE} \
       --predictor conllu-predictor \
       --include-package library \
       --use-dataset-reader

  done
done

