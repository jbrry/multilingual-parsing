#!/bin/bash

for lang in dan swe nno nob; do
    python utils/project-aligned-trees.py data/faroese/fao_wiki.apertium.fao-${lang}.udpipe.parsed.conllu data/faroese/fao_wiki.apertium.fao-${lang}.align.txt data/faroese/fao_wiki.apertium.${lang}-fao.input.txt > data/faroese/${lang}-fao.projected-attempt.conllu
done
