#!/usr/bin/env bash

#for lang in dan swe nno nob; do
for lang in nno; do
  OUTFILE=output/monolingual/target_predicted/${lang}-fao.conllu
  TEST_FILE=/home/jbarry/ud-parsing/ud-treebanks-v2.2/UD_Faroese-OFT/fo_oft-ud-test.conllu
  
  # UDPipe predicted file (silver UPOS)
  #PRED_FILE=/home/jbarry/DeepLo2019/multilingual-parsing/output/udpipe/predicted/${lang}.udpipe.conllu
  PRED_FILE=/home/jbarry/DeepLo2019/github_issue/cross-lingual-parsing/predicted/${lang}.udpipe.conllu
  head -5 ${PRED_FILE}

  allennlp predict output/monolingual/target_models/${lang}/model.tar.gz ${PRED_FILE} \
    --output-file ${OUTFILE} \
    --predictor biaffine-dependency-parser-monolingual \
    --include-package library \
    --use-dataset-reader
 
  echo "running evaluation script with gold file ${TEST_FILE} and pred file ${OUTFILE}"
  python utils/conll18_ud_eval.py --verbose /home/jbarry/ud-parsing/ud-treebanks-v2.2/UD_Faroese-OFT/fo_oft-ud-test.conllu output/monolingual/target_predicted/${lang}-fao.conllu > output/monolingual/results/${lang}-fao.result
done
