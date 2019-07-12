# multilingual-parsing

Repository for cross-lingual parsing for low-resource languages by means of annotation projection. Code for Parsing a Low-Resource Language... submitted to the DeepLo Workshop 2019.

## Table of Contents

- [Installation](#installation)
- [Getting Started: sentations](#getting-started-evaluating-representations)
- [References](#references)

## Installation

This project is developed in Python 3.6 using a [Conda](https://conda.io/) environment.

1.  [Download and install Conda](https://conda.io/docs/download.html).

2.  Change directory to your clone of this repo.

    ```bash
    cd multilingual-parsing
    ```

3.  Create a Conda environment with Python 3.6.

    ```bash
    conda create -n multilingual_parsing python=3.6
    ```

4.  Activate the Conda environment.

    ```bash
    source activate multilingual_parsing
    ```

5.  Install the required dependencies. This project uses some new AllenNLP features which are not available in the official PyPI release. As such, we will use the 0.8.5-unreleased version from the `master` branch on GitHub.

    ```bash
    pip install https://github.com/allenai/allennlp/archive/master.zip
    ```

## Obtain data
You will need to obtain the original Faroese data for these experiments please. #TODO add this to a data section.

1.  Clone the original repository to somewhere in your file system, e.g. in your home directory.
    ```bash
    cd $HOME && git clone https://github.com/ftyers/cross-lingual-parsing.git
    ```
    
2.  Change directory to your clone of this repo and create a symbolic link to the original data.
    ```bash
    cd multilingual-parsing
    ln -s /home/user/cross-lingual-parsing/data/ .
    ```

This should create a directory structure `multilingual-parsing/data/`.

3. Download UD v2.2 treebanks.
    ```bash
    ./scripts/get_ud_treebank.sh
    ```

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

## Train target model

