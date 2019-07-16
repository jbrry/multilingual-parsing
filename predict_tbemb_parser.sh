#!/usr/bin/env bash

TB_DIR='/home/jbarry/ud-parsing/ud-treebanks-v2.2'

for tbid in da_ddt sv_talbanken no_nynorsk no_bokmaal; do
  for filepath in $TB_DIR/*/$tbid-ud-train.conllu; do
  
    dir=`dirname $filepath`        # e.g. /home/james/ud_folder/ud-treebanks-v2.2/UD_Afrikaans-AfriBooms
    tb_name=`basename $dir`        # e.g. UD_Afrikaans-AfriBooms

    TEST_FILE=${TB_DIR}/${tb_name}/${tbid}-ud-test.conllu

    allennlp predict output/multilingual/source_models/da_sv_no/model.tar.gz ${TEST_FILE} \
        --output-file output/multilingual/results/${tbid}.conllu \
        --predictor biaffine-dependency-parser-monolingual \
        --include-package library \
        --use-dataset-reader

    echo "running evaluation script"
    python utils/conll18_ud_eval.py --verbose ${TEST_FILE} output/multilingual/results/${tbid}.conllu > output/multilingual/results/${tbid}-multilingual.result

  done
done
