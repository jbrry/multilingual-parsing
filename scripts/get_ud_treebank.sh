#!/bin/sh

# move to the directory you want to save the treebanks ('ud-parsing')
cd && cd ud-parsing

# get the UD 2.2 treebanks/tools
curl --remote-name-all https://lindat.mff.cuni.cz/repository/xmlui/bitstream/handle/11234/1-2837{/ud-treebanks-v2.2.tgz}

# handle unpacking 
gunzip ud-treebanks-v2.2.tgz
tar -xvf ud-treebanks-v2.2.tar

# clean up directory
rm ud-treebanks-v2.2.tar
