# multilingual-parsing

Repository for cross-lingual parsing for low-resource languages by means of annotation projection. Code for Parsing a Low-Resource Language... submitted to the DeepLo Workshop 2019.

## Table of Contents

- [Installation](#installation)
- [Obtain data](#obtain-data)
- [Train models](#train-source-models)
- [Predict](#predict-translated-source-files)
- [Projection steps](#projection-steps)


## Installation

This project is developed in Python 3.6 using a [Conda](https://conda.io/) environment.

[Download and install Conda](https://conda.io/projects/conda/en/latest/user-guide/install/linux.html).

Create a Conda environment with Python 3.6:

```bash
conda create -n multilingual_parsing python=3.6
```

Activate the Conda environment:

```bash
source activate multilingual_parsing
```
This project uses some new AllenNLP features which are not available in the official 0.8.4 release. As such, we will build the 0.8.5-unreleased version from the `master` branch on GitHub. If there are any problems try updating pip, setuptools and wheel as mentioned [here](https://packaging.python.org/tutorials/installing-packages/).

```bash
cd
git clone https://github.com/allenai/allennlp.git
cd allennlp
pip install --editable .
```

Make the `library` available in `$PYTHONPATH`. From the `multilingual_parsing` directory:

```bash
cd /path/to/multilingual_parsing

export PYTHONPATH="$PWD/library"

# or permanently;
vim ~/.bashrc
export PYTHONPATH=/path/to/multilingual_parsing/library
```

## Obtain data
You will need to obtain the original Faroese data for these experiments please.

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

## Create silver training/ development sets
We follow the same process to develop datasets with [automatically predicted pos-labels](http://universaldependencies.org/conll18/baseline.html) as the CoNLL 2018 shared task. That is, we perform jack-knifing on ther training set to predict pos-tags. Pos-tags on the development set are predicted with a model trained on the gold-standard training set.

```bash
./scripts/create_k_folds.sh

./scripts/train_with_cross_val.sh

#TODO predict these files.
```

## Train source models
1.  Train a source model on source treebanks. The `model_type` argument supplied can be either `monolingual` or `multilingual` and determines whether to use a monolingual or multilingual model accordingly.

    ```bash
    train_source_model.sh <model_type>
    ```

## Predict translated source files
1.  Use a source model to predict annotations for files translated into source languages. The `model_type` argument supplied can be either `monolingual` or `multilingual` and determines whether to use a monolingual or multilingual model accordingly.

    ```bash
    ./predict_source_treebanks.sh <model_type>
    ```

## Projection steps
1.  Project from source languges to the target language.
    ```bash
    ./scripts/project_all.sh <model_type>
    ```
2.  Take only the valid sentences.
    ```bash
    ./scripts/validate_all.sh <model_type>
    ```
    
3.  Combine sentences where we have 3/4 valid projected sentences.
    ```bash
    python utils/treebanks_union.py <model_type>
    ```
    
4.  Perform MST voting over the matching, calidated sentences.
    ```bash
    ./scripts/merge_all.sh <model_type>
    ```
    
5.  Validate the voted sentences.
    ```bash
    python utils/validate_treebank.py output/<model_type>/tmp/combined_four.conllu <model_type>
    ```
    
5.  Check for double-headed sentences.
    ```bash
    python utils/check_double_headed.py <model_type>
    ```    

## Train target models
Train a tagging and parsing models on the synthetic target treebank. `model_type` can be either `monolingual` or `multilingual`. `src_type` is either `single` or `multiple` for multi-source. We train a tagger here so that we can produce silver tags for the final test set.

```bash
./scripts/train_target_tagger.sh <model_type> <src_type> 
```

```bash
./scripts/train_target_parser.sh <model_type> <src_type> 
```

