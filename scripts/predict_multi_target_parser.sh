#!/bin/bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

# extra experiment to include original source treebanks with target ones
test -z $2 && echo "Missing data type: 'target' or 'sourcetarget'"
test -z $2 && exit 1
data_type=$2

TEST_FILE=data/ud-treebanks-v2.2/UD_Faroese-OFT/fo_oft-ud-test.conllu

echo "predicting target treebanks"

if [ "${data_type}" == 'target' ]; then
  echo "training on only target files"
  SUFFIX=20190815-164746
elif [ "${data_type}" == 'sourcetarget' ]; then
  echo "predicting model which used both source and target files"
  SUFFIX=source-target 
fi

src=multi-target-${SUFFIX}

for lang in da_ddt sv_talbanken no_nynorsk no_bokmaal co_four; do
  OUTFILE=output/${model_type}/target_predicted/${lang}-fao-${SUFFIX}.conllu 
  PRED_FILE=output/${model_type}/target_predicted/fa_oft-test-${lang}.allennlp-multi.tagged.conllu 

  allennlp predict output/${model_type}/target_models/${lang}-${SUFFIX}/model.tar.gz ${PRED_FILE} \
      --output-file ${OUTFILE} \
      --predictor conllu-predictor \
      --include-package library \
      --use-dataset-reader

      echo "running evaluation script with gold file ${TEST_FILE} and output file ${OUTFILE}"
      python utils/conll18_ud_eval.py --verbose ${TEST_FILE} ${OUTFILE} > output/${model_type}/results/${lang}-fao-${SUFFIX}.result
      echo "wrote results to output/${model_type}/results/${lang}-fao-${SUFFIX}.result"
done

