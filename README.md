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
