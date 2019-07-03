## multilingual-parsing
Repository for paper submission to the DeepLo Workshop 2019. 

## Set up environment
Follow the download instructions for AllenNLP to create an environment with AllenNLP installed: https://github.com/allenai/allennlp.

## Obtain data
To obtain the original Faroese data for these experiments please clone the original repository to somewhere in your file system, e.g. in your home directory:

`cd $HOME && git clone https://github.com/ftyers/cross-lingual-parsing.git`

Then from the main project directory e.g. `multilingual-parsing`, create a symbolic link to the original data:

`ln -s /home/user/cross-lingual-parsing/data/ .`

This should create a directory structure `multilingual-parsing/data/`.

