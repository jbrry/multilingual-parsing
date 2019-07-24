#!/bin/bash

TB_DIR='data/ud-treebanks-v2.2'
TIMESTAMP=`date "+%Y%m%d-%H%M%S"` 

for tbid in da_ddt sv_talbanken no_nynorsk no_bokmaal; do
  for split in 0 1 2 3 4 5 6 7 8 9; do
    for filepath in ${TB_DIR}/*/${tbid}-ud-train.conllu; do
      dir=`dirname $filepath`        # e.g. /home/james/ud_folder/ud-treebanks-v2.2/UD_Afrikaans-AfriBooms
      tb_name=`basename $dir`        # e.g. UD_Afrikaans-AfriBooms

      # v2.x
      export TRAIN_PATHNAME=${TB_DIR}/${tb_name}/${tbid}-ud-train.conllu.split-${split}
      export DEV_PATHNAME=${TB_DIR}/${tb_name}/${tbid}-ud-dev.conllu.split-${split}

      allennlp train configs/monolingual/pos_tagger_char.jsonnet -s output/monolingual/cross_val/${tbid}-split-${split}
    
    done
  done
done
