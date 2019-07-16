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

  echo "parsing source files with $tbid"

  OUTFILE=output/multilingual/predicted/fao_wiki.apertium.fao-${tbid}.allennlp.parsed.conllu
  
  # udpipe tagged/tokenized source translations
  # if using files wihout annotations use: --overrides '{"dataset_reader": {"disable_dependencies": true}}'
 
  # NOTE, these names will be changed to the format the dataset_reader uses:
  cp data/faroese/fao_wiki.apertium.fao-${lang}.udpipe.parsed.conllu data/faroese/${tbid}-udpipe.parsed.conllu

  PRED_FILE=data/faroese/${tbid}-udpipe.parsed.conllu
  echo "now parsing ${PRED_FILE}"

  #--overrides '{"dataset_reader":{"languages":'${tbid}'}}' \
  
  allennlp predict output/multilingual/source_models/da_sv_no/model.tar.gz ${PRED_FILE} \
    --output-file ${OUTFILE} \
    --predictor biaffine-dependency-parser-monolingual \
    --include-package library \
    --use-dataset-reader

done
