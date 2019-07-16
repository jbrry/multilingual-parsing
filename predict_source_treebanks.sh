#!/usr/bin/env bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

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
  
  echo "parsing source files with $tbid"
  
  # path to source udpipe tagged/tokenized file to predict
  PRED_FILE=data/faroese/fao_wiki.apertium.fao-${lang}.udpipe.parsed.conllu  
  
  if [ ${model_type} == 'monolingual' ]
    then src=${tbid}

  elif [ ${model_type} == 'multilingual' ]
    # change name to format expected by dataset reader
    then cp ${PRED_FILE} data/faroese/${tbid}-udpipe.parsed.conllu
	PRED_FILE=data/faroese/${tbid}-udpipe.parsed.conllu
	src='da_sv_no'
  fi

  echo "parsing file: ${PRED_FILE}"

  # file to write
  OUT_FILE=output/${model_type}/predicted/fao_wiki.apertium.fao-${tbid}.allennlp.parsed.conllu
  

  allennlp predict output/${model_type}/source_models/${src}/model.tar.gz ${PRED_FILE} \
      --output-file ${OUT_FILE} \
      --predictor biaffine-dependency-parser-monolingual \
      --include-package library \
      --use-dataset-reader
done

# if using files wihout annotations use: --overrides '{"dataset_reader": {"disable_dependencies": true}}'
#--overrides '{"dataset_reader":{"languages":'${tbid}'}}' \
  
