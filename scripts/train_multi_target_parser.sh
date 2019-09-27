#!/bin/bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

# extra experiment to include original source treebanks with target ones
test -z $2 && echo "Missing data type: 'target' or 'sourcetarget'"
test -z $2 && exit 1
data_type=$2


TIMESTAMP=`date "+%Y%m%d-%H%M%S"` 

TB_DIR='/home/jbarry/DeepLo2019/multilingual-parsing/output/'${model_type}'/validated'

echo "training on  multiple target treebanks"

if [ "${data_type}" == 'target' ]; then
  echo "training on only target files"

  # need to copy names in TB_DIR to be ${tbid}-allennlp.projected.conllu
  export TRAIN_DATA_PATH=${TB_DIR}/*-allennlp.projected.conllu
    
  allennlp train configs/multilingual/source_tbemb_no_dev.jsonnet -s output/${model_type}/target_models/multi-target-${data_type} --include-package library

elif [ "${data_type}" == 'sourcetarget' ]; then
  echo "training on both source and target files"

  export TRAIN_DATA_PATH=${TB_DIR}/*-allennlp.projected.conllu
  allennlp train configs/multilingual/source_targ_tbemb_no_dev.jsonnet -s output/${model_type}/target_models/multi-target-${data_type}-run2 --include-package library

fi

