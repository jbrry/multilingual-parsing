#!/bin/bash

# run from main directory: ./scripts/merge_all.sh <model_type>

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

for RANDOM_SEED in 54360 44184 20423 80520 27916; do
  python utils/conllu_graphs.py output/${model_type}/tmp/four_1st_${RANDOM_SEED}.conllu \
    output/${model_type}/tmp/four_2nd_${RANDOM_SEED}.conllu \
    output/${model_type}/tmp/four_3rd_${RANDOM_SEED}.conllu \
    output/${model_type}/tmp/four_4th_${RANDOM_SEED}.conllu \
    ${RANDOM_SEED} \
    ${model_type}
done

