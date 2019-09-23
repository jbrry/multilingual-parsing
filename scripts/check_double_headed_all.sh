#!/bin/bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

for RANDOM_SEED in 54360 44184 20423 80520 27916; do
  python utils/check_double_headed.py ${model_type} ${RANDOM_SEED}

done

