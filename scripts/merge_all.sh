#!/bin/bash

# run from main directory; ./scripts/merge_all.sh <model_type>
# TODO make an option to choose 3 or 4 matching sentences (4 is default)

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

python utils/conllu_graphs.py output/${model_type}/tmp/four_1st.conllu \
    output/${model_type}/tmp/four_2nd.conllu \
    output/${model_type}/tmp/four_3rd.conllu \
    output/${model_type}/tmp/four_4th.conllu 
   
