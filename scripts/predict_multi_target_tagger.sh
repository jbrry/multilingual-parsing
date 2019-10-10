#!/usr/bin/env bash

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

test -z $2 && echo "Missing source type: 'single' or 'multiple'"
test -z $2 && exit 1
src_type=$2

TEST_FILE=data/ud-treebanks-v2.2/UD_Faroese-OFT/fo_oft-ud-test.conllu

if [ ${src_type} == 'single' ]
	then echo "predicting using single source, i.e. not combining inputs..."

    SUFFIX='20190816-190049'

    for tbid in da_ddt sv_talbanken no_nynorsk no_bokmaal co_four; do
		
        # copied version of test file with tbid in string
        PRED_FILE=output/${model_type}/target_predicted/${tbid}-fotest.allennlp.tagged.conllu
        OUTFILE=output/${model_type}/target_predicted/${tbid}-fotest.allennlp-multi.tagged.conllu
		
        # udpipe files
        #PRED_FILE=predicted/${model_type}-${lang}.conllu

		allennlp predict output/${model_type}/target_models/multi-target-pos-${SUFFIX}/model.tar.gz ${PRED_FILE} \
			--output-file ${OUTFILE} \
			--predictor conllu-predictor \
			--include-package library \
			--use-dataset-reader

        echo "running evaluation script with gold file ${TEST_FILE} and output file ${OUTFILE}"
        python utils/conll18_ud_eval.py --verbose ${TEST_FILE} ${OUTFILE} > output/${model_type}/results/${tbid}-fao-pos.result
        echo "wrote results to output/${model_type}/results/${tbid}-fao.result"
	done

elif [ ${src_type} == 'multiple' ]
	then echo "predicting using multiple sources, e.g. MST voting..."
    SUFFIX='20190814-004700'
	
    OUTFILE=output/${model_type}/target_predicted/combined.conllu

	#PRED_FILE=output/${model_type}/target_predicted/fa_oft-test-combined.allennlp.tagged.conllu

    # udpipe files
    #PRED_FILE=predicted/${model_type}-comb.conllu

	allennlp predict output/${model_type}/target_models/combined-${SUFFIX}/model.tar.gz ${PRED_FILE} \
		--output-file ${OUTFILE} \
        --predictor conllu-predictor \
		--include-package library \
		--use-dataset-reader

    echo "running evaluation script with gold file ${TEST_FILE} and output file ${OUTFILE}"
    python utils/conll18_ud_eval.py --verbose ${TEST_FILE} ${OUTFILE} > output/${model_type}/results/combined-fao.result
    echo "wrote results to output/${model_type}/results/combined-fao.result"
fi

