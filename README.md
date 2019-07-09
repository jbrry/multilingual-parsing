## multilingual-parsing
Repository for paper submission to the DeepLo Workshop 2019. 

## Set up environment

This project uses AllenNLP, which can be installed by: 

`pip install allennlp`

## Obtain data
To obtain the original Faroese data for these experiments please clone the original repository to somewhere in your file system, e.g. in your home directory:

`cd $HOME && git clone https://github.com/ftyers/cross-lingual-parsing.git`

Then, `cd` to main project directory `multilingual-parsing` and create a symbolic link to the original data:

`ln -s /home/user/cross-lingual-parsing/data/ .`

This should create a directory structure `multilingual-parsing/data/`.

To download UD v2.2 treebanks run `./scripts/get_ud_treebank.sh`

## Train source models
To train parsing models for the included source treebanks run `./train_monolingual_parser.sh`
To train a unified model with a treebank embedding run `./train_tbemb_parser.sh` TODO

## Predict using source models
To use a source model to predict annotations for files translated into source languages run `predict_source_models.sh`
To predict annotations for a file translated using a model trained on all source languages run `./predict_tbemb_parser.sh` TODO

## Project from source languages to target
`scripts/project_all.sh`

## Clean treebanks
The projection script may not always produce valid trees in the target language. As such, a number of scripts need to be run:

`validate_treebank.py` - which puts only the validated sentences of a projected treebank into a 'validated' folder.
`treebanks_union.py` - which writes sentences where we have either 3 or 4 matching sentences across the validated files.
`conllu_graphs.py` - on the output of `treebanks_union.py` 
`validate_treebank.py` - on `combined_four.conllu`. this validates the treebank created by MST voting over 4 trees and puts the treebank in the `validated` folder.
`check_double_headed.py` - on `validated/combined_four.conllu` which produces `validated/comb.conllu`
`train_model.py` - TODO
