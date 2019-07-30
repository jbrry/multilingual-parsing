#!/bin/bash

TB_DIR='data/ud-treebanks-v2.2'
OUT_DIR='data/ud-treebanks-v2.2-crossfold-tags'

mkdir -p ${OUT_DIR}

TIMESTAMP=`date "+%Y%m%d-%H%M%S"` 

for tbid in da_ddt sv_talbanken no_nynorsk no_bokmaal; do
  for filepath in $TB_DIR/*/$tbid-ud-train.conllu; do 
  
    dir=`dirname $filepath`        # e.g. /home/james/ud_folder/ud-treebanks-v2.2/UD_Afrikaans-AfriBooms
    tb_name=`basename $dir`        # e.g. UD_Afrikaans-AfriBooms

    #ln -s ${TB_DIR}/${tb_name}/${tbid}-ud-train.conllu ${OUT_DIR}/${tb_name}/
 
    python utils/create_k_folds.py -t ${TB_DIR}/${tb_name}/${tbid}-ud-train.conllu -o ${OUT_DIR}/${tb_name}/ 
  done
done

