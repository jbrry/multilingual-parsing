#!/usr/bin/env bash

# if using files wihout annotations use: --overrides '{"dataset_reader": {"disable_dependencies": true}}'

test -z $1 && echo "Missing model type: 'monolingual' or 'multilingual'"
test -z $1 && exit 1
model_type=$1

test -z $2 && echo "Missing source type: 'single' or 'multiple'"
test -z $2 && exit 1
src_type=$2

TEST_FILE=/home/jbarry/ud-parsing/ud-treebanks-v2.2/UD_Faroese-OFT/fo_oft-ud-test.conllu

if [ ${src_type} == 'single' ]
	then echo "predicting using single source, i.e. not combining inputs..."
	for lang in dan swe nno nob; do
		OUTFILE=output/${model_type}/target_predicted/${lang}-fao.conllu
		
		# UDPipe predicted file (silver UPOS)
		PRED_FILE=/home/jbarry/DeepLo2019/github_issue/cross-lingual-parsing/predicted/${lang}.udpipe.conllu 
		head -5 ${PRED_FILE}

		allennlp predict output/${model_type}/target_models/${lang}/model.tar.gz ${PRED_FILE} \
			--output-file ${OUTFILE} \
			--predictor biaffine-dependency-parser-monolingual \
			--include-package library \
			--use-dataset-reader

        echo "running evaluation script with gold file ${TEST_FILE} and output file ${OUTFILE}"
        python utils/conll18_ud_eval.py --verbose ${TEST_FILE} ${OUTFILE} > output/${model_type}/results/${lang}-fao.result
        echo "wrote results to output/${model_type}/results/${lang}-fao.result"
	done

elif [ ${src_type} == 'multiple' ]
	then echo "predicting using multiple sources, e.g. MST voting..."
	OUTFILE=output/${model_type}/target_predicted/combined.conllu

	# UDPipe predicted file (silver UPOS)
	PRED_FILE=/home/jbarry/DeepLo2019/github_issue/cross-lingual-parsing/predicted/combined.udpipe.conllu
	head -5 ${PRED_FILE}

	allennlp predict output/${model_type}/target_models/combined/model.tar.gz ${PRED_FILE} \
		--output-file ${OUTFILE} \
        --predictor biaffine-dependency-parser-monolingual \
		--include-package library \
		--use-dataset-reader

    echo "running evaluation script with gold file ${TEST_FILE} and output file ${OUTFILE}"
    python utils/conll18_ud_eval.py --verbose ${TEST_FILE} ${OUTFILE} > output/${model_type}/results/combined-fao.result
    echo "wrote results to output/${model_type}/results/combined-fao.result"
fi

