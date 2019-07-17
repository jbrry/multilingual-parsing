#!/bin/bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

test -z $2 && echo "Missing source type: 'single' or 'multiple'"
test -z $2 && exit 1
src_type=$2

TIMESTAMP=`date "+%Y%m%d-%H%M%S"` 

TB_DIR='/home/jbarry/DeepLo2019/multilingual-parsing/output/'${model_type}'/validated'

if [ ${src_type} == 'single' ]
    then echo "training using single source, i.e. not combining inputs..."

    for lang in dan swe nno nob; do
        export TRAIN_DATA_PATH=${TB_DIR}/fao_wiki.apertium.${lang}-fao.allennlp.projected.conllu
        allennlp train configs/monolingual/dependency_parser_char_no_dev.jsonnet -s output/${model_type}/target_models/${lang}-$TIMESTAMP --include-package library
    done

elif [ ${src_type} == 'multiple' ]
    then echo "training using multiple sources, e.g. MST voting..."
    export TRAIN_DATA_PATH=${TB_DIR}/comb.conllu
    echo "using combined file at ${TB_DIR}/comb.conllu"
    
    allennlp train configs/monolingual/dependency_parser_char_no_dev.jsonnet -s output/${model_type}/target_models/combined-$TIMESTAMP --include-package library
fi

