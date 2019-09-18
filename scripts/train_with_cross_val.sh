#!/bin/bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

GLD_DIR='data/ud-treebanks-v2.2'
TMP_DIR='data/tmp'
TB_DIR='data/ud-treebanks-v2.2-crossfold-tags'

EMB_DIR=${HOME}/embeddings

# repeat experiments with different random_seed, numpy_seed and pytorch_seed
for RANDOM_SEED in 54360 44184 20423 80520 27916; do
  NUMPY_SEED=`echo $RANDOM_SEED | cut -c1-4`
  PYTORCH_SEED=`echo $RANDOM_SEED | cut -c1-3`

  export RANDOM_SEED=${RANDOM_SEED}
  export NUMPY_SEED=${NUMPY_SEED}
  export PYTORCH_SEED=${PYTORCH_SEED}

  if [ ${model_type} == 'monolingual' ]
    then echo "training monolingual model(s)..."

    for tbid in da_ddt sv_talbanken no_nynorsk no_bokmaal; do
        for split in 0 1 2 3 4 5 6 7 8 9; do
            for filepath in ${GLD_DIR}/*/${tbid}-ud-train.conllu; do
                dir=`dirname $filepath`
                tb_name=`basename $dir`

                # v2.x
                export TRAIN_DATA_PATH=${TMP_DIR}/${tb_name}/${tbid}-ud-train.conllu.split-${split}
                export DEV_DATA_PATH=${TMP_DIR}/${tb_name}/${tbid}-ud-dev.conllu.split-${split}

                # embeddings
                lang=$(echo ${tb_name} | awk -F "_" '{print $2}')
                echo "processing language: ${lang}" 
                VECS_DIR=${EMB_DIR}/${lang}
                VECS_FILE=$(ls ${VECS_DIR}/*.vectors)
                export VECS_PATH=${VECS_FILE}

                allennlp train configs/monolingual/pos_tagger_char.jsonnet -s output/monolingual/cross_val/${tbid}-split-${split}-${RANDOM_SEED} --include-package library

      done
    done
done

elif [ ${model_type} == 'multilingual' ]
  then echo "training multilingual model... not implemented"

  #  allennlp train configs/multilingual/pos_source_tbemb.jsonnet -s output/multilingual/cross_val/da_sv_no-$TIMESTAMP \
  #    --include-package library
fi
done

