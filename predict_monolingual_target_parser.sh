#!/usr/bin/env bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

for lang in dan swe nno nob; do
  OUTFILE=output/${model_type}/target_predicted/${lang}-fao.conllu
  TEST_FILE=/home/jbarry/ud-parsing/ud-treebanks-v2.2/UD_Faroese-OFT/fo_oft-ud-test.conllu
  
  # UDPipe predicted file (silver UPOS)
  #PRED_FILE=/home/jbarry/DeepLo2019/multilingual-parsing/output/udpipe/predicted/${lang}.udpipe.conllu
  PRED_FILE=/home/jbarry/DeepLo2019/github_issue/cross-lingual-parsing/predicted/${lang}.udpipe.conllu
  head -5 ${PRED_FILE}

  allennlp predict output/${model_type}/target_models/${lang}/model.tar.gz ${PRED_FILE} \
    --output-file ${OUTFILE} \
    --predictor biaffine-dependency-parser-monolingual \
    --include-package library \
    --use-dataset-reader

  # if using files wihout annotations use: --overrides '{"dataset_reader": {"disable_dependencies": true}}'

  echo "running evaluation script with gold file ${TEST_FILE} and output file ${OUTFILE}"
  python utils/conll18_ud_eval.py --verbose ${TEST_FILE} ${OUTFILE} > output/${model_type}/results/${lang}-fao.result
done
