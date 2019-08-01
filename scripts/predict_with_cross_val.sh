#!/bin/bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

GLD_DIR='data/ud-treebanks-v2.2'
TMP_DIR='data/tmp'
TB_DIR='data/ud-treebanks-v2.2-crossfold-tags'

TIMESTAMP=`date "+%Y%m%d-%H%M%S"` 

SUFFIX='-20190730-184750' # easier to just find the run you want rather than rename everything

PREDICTOR='conllu-predictor'

if [ ${model_type} == 'monolingual' ]
  then echo "processing monolingual model(s)..."

  #for tbid in da_ddt sv_talbanken no_nynorsk no_bokmaal; do
  for tbid in da_ddt; do
      for split in 0 1 2 3 4 5 6 7 8 9; do
          for filepath in ${GLD_DIR}/*/${tbid}-ud-train.conllu; do
              dir=`dirname $filepath`
              tb_name=`basename $dir`

              mkdir -p ${TB_DIR}/${tb_name}

			  PRED_FILE=${TMP_DIR}/${tb_name}/${tbid}-ud-dev.conllu.split-${split}
			  OUT_FILE=${TMP_DIR}/${tb_name}/${tbid}-ud-dev.conllu.split-${split}-predicted

			  src=${tbid}-split-${split}${SUFFIX}

			  #=== Predict ===
			  allennlp predict output/${model_type}/cross_val/${src}/model.tar.gz ${PRED_FILE} \
   				--output-file ${OUT_FILE} \
   				--predictor ${PREDICTOR} \
   				--include-package library \
   				--use-dataset-reader

              # append the predictions of the splits to the training file 
              cat ${TMP_DIR}/${tb_name}/${tbid}-ud-dev.conllu.split-${split}-predicted  >> ${TMP_DIR}/${tb_name}/${tbid}-ud-train.conllu
    done
  done

  cp ${TMP_DIR}/${tb_name}/${tbid}-ud-train.conllu ${TB_DIR}/${tb_name}/${tbid}-ud-train.conllu
done

elif [ ${model_type} == 'multilingual' ]
  then echo "training multilingual model..."

  # need to find a way to work with unusual filepaths...

#  allennlp train configs/multilingual/pos_source_tbemb.jsonnet -s output/multilingual/cross_val/da_sv_no-$TIMESTAMP \
#    --include-package library
fi
