#!/bin/bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

test -z $2 && echo "Missing data type: 'gold' or 'silver'"
test -z $2 && exit 1
data_type=$2

GOLD_DIR='data/ud-treebanks-v2.2'
SILVER_DIR='data/ud-2.2-conll18-crossfold-morphology'

if [ ${data_type} == 'gold' ]; then
  echo "training on gold data"
  TB_DIR=${GOLD_DIR}
elif [ ${data_type} == 'silver' ]; then
  echo "training on silver data"
  TB_DIR=${SILVER_DIR}
fi

echo "treebank dir: ${TB_DIR}"

EMB_DIR=${HOME}/embeddings

TIMESTAMP=`date "+%Y%m%d-%H%M%S"` 



# repeat experiments with different random_seed, numpy_seed and pytorch_seed

for RANDOM_SEED in 54360 44184 20423 80520 27916; do
  NUMPY_SEED=`echo $RANDOM_SEED | cut -c1-4`
  PYTORCH_SEED=`echo $RANDOM_SEED | cut -c1-3`

  # Monolingual
  if [ ${model_type} == 'monolingual' ]
    then echo "training monolingual model(s)..."
 
     for tbid in da_ddt sv_talbanken no_nynorsk no_bokmaal; do
       for filepath in $TB_DIR/*/$tbid-ud-train.conllu; do 
  
        dir=`dirname $filepath`
        tb_name=`basename $dir`

        export TRAIN_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-train.conllu
        export DEV_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-dev.conllu
        #export TEST_DATA_PATH=${TB_DIR}/${tb_name}/${tbid}-ud-test.conllu

        export RANDOM_SEED=${RANDOM_SEED}
        export NUMPY_SEED=${NUMPY_SEED}
        export PYTORCH_SEED=${PYTORCH_SEED}

        lang=$(echo ${tb_name} | awk -F "_" '{print $2}')
        echo "processing language: ${lang}"
        VECS_DIR=${EMB_DIR}/${lang}
        VECS_FILE=$(ls ${VECS_DIR}/*.vectors)
      
        echo "using ${VECS_FILE}"
        export VECS_PATH=${VECS_FILE}

      allennlp train configs/monolingual/dependency_parser_char.jsonnet -s output/monolingual/source_models/${tbid}-${data_type}-${RANDOM_SEED}
    
    done
  done

  elif [ ${model_type} == 'multilingual' ]
    then echo "training multilingual model..."

    export RANDOM_SEED=${RANDOM_SEED}
    export NUMPY_SEED=${NUMPY_SEED}
    export PYTORCH_SEED=${PYTORCH_SEED}

    export TRAIN_DATA_PATH=${TB_DIR}/**/*-ud-train.conllu
    export DEV_DATA_PATH=${TB_DIR}/**/*-ud-dev.conllu
    #export TEST_DATA_PATH=${TB_DIR}/**/*-ud-test.conllu

    allennlp train configs/multilingual/source_tbemb.jsonnet -s output/multilingual/source_models/da_sv_no-${data_type}-${RANDOM_SEED} \
    --include-package library
fi
done
