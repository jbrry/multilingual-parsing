#!/bin/bash

v=`echo $((1 + RANDOM % 1000))`

# files are found using the config file.
allennlp train configs/multilingual/source_tbemb.jsonnet -s output/multilingual/source_models/da_sv_no-$v --include-package library


