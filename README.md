# multilingual-parsing

Repository for cross-lingual parsing for low-resource languages by means of annotation projection. Code for Parsing a Low-Resource Language... submitted to the DeepLo Workshop 2019.

## Table of Contents

- [Installation](#installation)
- [Obtain data](#obtain-data)
- [Train models](#train-models)
- [Projection steps](#projection-steps)
- [Predict](#predict)

## Installation

This project is developed in Python 3.6 using a [Conda](https://conda.io/) environment.

1.  [Download and install Conda](https://conda.io/projects/conda/en/latest/user-guide/install/linux.html).

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

## Train models
1.  Train monolingual parsing models for the source languages.
    ```bash
    ./train_monolingual_parser.sh
    ```
2.  Train multilingual parsing model for the source languages.
    ```bash
    ./train_tbemb_parser.sh
    ```
    
## Projection steps
1.  Project from source languges to the target language.
    ```bash
    ./scripts/project_all.sh
    ```
2.  Take only the valid sentences.
    ```
    python utils/validate_treebank.py
    ```
    
3.  Combine sentences where we have 3/4 valid projected sentences.
    ```
    python utils/treebanks_union.py
    ```
    
4.  Perform MST voting over the matching, calidated sentences.
    ```
    python utils/conllu_graphs.py
    ```
    
5.  Validate the voted sentences.
    ```bash
    python utils/validate_treebank.py
    ```
    
5.  Check for double-headed sentences.
    ```bash
    python utils/check_double_headed.py
    ```    

## Predict
1.  Use a source model to predict annotations for files translated into source languages.
    ```bash
    ./predict_source_models.sh
    ```
2.  Use a multilingual source model to predict annotations for files translated into source languages.
    ```bash
    ./predict_multilingual_parser.sh
    ```
