#!/bin/bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

TIMESTAMP=`date "+%Y%m%d-%H%M%S"` 

TB_DIR='/home/jbarry/DeepLo2019/multilingual-parsing/output/'${model_type}'/validated'

echo "training on  multiple target treebanks"
# need to copy names inf TB_DIR to be ${tbid}-allennlp.projected.conllu
export TRAIN_DATA_PATH=${TB_DIR}/*-allennlp.projected.conllu
    
allennlp train configs/multilingual/source_tbemb_no_dev.jsonnet -s output/${model_type}/target_models/multi-target-$TIMESTAMP --include-package library


