#!/usr/bin/env bash

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
  
  echo "projecting source files from $tbid"
  
  # path to source udpipe tagged/tokenized file to predict
  PRED_FILE=data/faroese/fao_wiki.apertium.fao-${lang}.udpipe.parsed.conllu  
  
  # file to write
  OUT_FILE=output/monolingual/predicted/fao_wiki.apertium.fao-${tbid}.allennlp.parsed.conllu
  
  allennlp predict output/monolingual/source_models/${tbid}/model.tar.gz ${PRED_FILE} \
      --output-file ${OUT_FILE} \
      --predictor biaffine-dependency-parser-monolingual \
      --include-package library \
      --use-dataset-reader
done
