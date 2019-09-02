#!/bin/bash

TB_DIR='data/ud-treebanks-v2.2'
TMP_DIR='data/tmp'
OUT_DIR='data/ud-treebanks-v2.2-crossfold-tags'

mkdir -p ${TMP_DIR} ${OUT_DIR}

for tbid in da_ddt sv_talbanken no_nynorsk no_bokmaal; do
  for filepath in $TB_DIR/*/$tbid-ud-train.conllu; do 
  
    dir=`dirname $filepath`
    tb_name=`basename $dir`

    # we only do jack-knifing for the training sets, see: http://universaldependencies.org/conll18/baseline.html
    python utils/create_k_folds.py -i ${TB_DIR}/${tb_name}/${tbid}-ud-train.conllu -o ${TMP_DIR}/${tb_name}/

  done
done

