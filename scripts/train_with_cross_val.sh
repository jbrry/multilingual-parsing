#!/bin/bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

GLD_DIR='data/ud-treebanks-v2.2'
TMP_DIR='data/tmp'
TB_DIR='data/ud-treebanks-v2.2-crossfold-tags'

TIMESTAMP=`date "+%Y%m%d-%H%M%S"` 

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

              allennlp train configs/monolingual/pos_tagger_char.jsonnet -s output/monolingual/cross_val/${tbid}-split-${split}-${TIMESTAMP} --include-package library

    done
  done
done

elif [ ${model_type} == 'multilingual' ]
  then echo "training multilingual model..."

  # need to find a way to work with unusual filepaths...

#  allennlp train configs/multilingual/pos_source_tbemb.jsonnet -s output/multilingual/cross_val/da_sv_no-$TIMESTAMP \
#    --include-package library
