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

  #=== UD treebank ===
  if [ "${file_type}" == 'ud' ]; then
    echo "parsing UD treebank"

    # find the appropriate UD treebank
    for filepath in ${TB_DIR}/*/${tbid}-ud-train.conllu; do
      dir=`dirname $filepath`
      tb_name=`basename $dir`

      PRED_FILE=${TB_DIR}/${tb_name}/${tbid}-ud-${data_type}.conllu
      OUT_FILE=output/${model_type}/predicted/${tbid}-${data_type}-${task_type}.conllu
    done
    fi

  #=== Model type ===
  if [ "${model_type}" == 'monolingual' ]; then
    SUFFIX='20190812-002415'
    src=${tbid}-silver-${SUFFIX}
  elif [ "${model_type}" == 'multilingual' ]; then
    SUFFIX='20190812-002456'
    src=da_sv_no-silver-${SUFFIX}
  fi

  echo "predicting parse"
    
  PRED_FILE=data/faroese/fao_wiki.apertium.fao-${lang}.udpipe.parsed.conllu

  if [ "${model_type}" == 'multilingual' ]; then
      # change name to format expected by dataset reader
      cp ${PRED_FILE} data/faroese/${tbid}-udpipe.parsed.conllu
      PRED_FILE=data/faroese/${tbid}-udpipe.parsed.conllu
    fi
    #PRED_FILE=output/${model_type}/predicted/${tbid}-pos.conllu # AllenNLP tagged file
    
    # file to write
    OUT_FILE=output/${model_type}/predicted/fao_wiki.apertium.fao-${tbid}.allennlp.parsed.conllu

#=== Predict ===
allennlp predict output/${model_type}/source_models/${src}/model.tar.gz ${PRED_FILE} \
   --output-file ${OUT_FILE} \
   --predictor conllu-predictor \
   --include-package library \
   --use-dataset-reader

done

