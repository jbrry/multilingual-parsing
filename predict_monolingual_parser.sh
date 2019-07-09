#!/usr/bin/env bash

# tbid code
test -z $1 && echo "Missing TBID for source model"
test -z $1 && exit 1
TBID=$1

# directory of UD treebanks
#test -z $2 && echo "Missing Treebank DIR"
#test -z $2 && exit 1
#TB_DIR=$2
#TEST_FILE=${TB_DIR}/*/${TBID}-ud-test.conllu \
 
test -z $2 && echo "Missing file to predict"
test -z $2 && exit 1
TEST_FILE=$2

OUTFILE=output/monolingual/predicted/fao_wiki.apertium.fao-${TBID}.allennlp.parsed.conllu

allennlp predict output/monolingual/source_models/${TBID}/model.tar.gz ${TEST_FILE} \
    --output-file ${OUTFILE} \
    --predictor biaffine-dependency-parser-monolingual \
    --include-package library \
    --use-dataset-reader

