# original file: https://github.com/ftyers/cross-lingual-parsing/blob/master/utils/validate_treebank.py

import sys
import os
from conllu_parser import Sentence

"""
Takes a treebank as input.
Creates a directory 'validated' and puts there only those sentences of
the treebank which are valid.

Usage:
    script.py <parsed_file> <model_type> 
    <parsed_file> = parsed source file to be validated.
    <model_type> = 'monolingual' or 'multilingual' 
"""

def validate(treebank):
    print('treebank sentences: ' + str(len(treebank)))
    doubled = []
    missing = []
    valid = []
    wrong_order = []
    wrong_start = []
    too_large_head = []
    for s in treebank:
        ids = [int(t[0]) for t in s.tokens]
        heads = [int(t[6]) for t in s.tokens]
        if len(set(ids)) != len(ids):
            doubled.append(s)
            # print('doubled:\n')
            # print(s)
        elif ids[0] != 1:
            wrong_start.append(s)
        elif len(ids) < ids[-1]:
            # print('missing:\n')
            # print(s)
            missing.append(s)
        elif ids != list(sorted(ids)):
            wrong_order.append(s)
        elif max(heads) > max(ids):
            too_large_head.append(s)
        else:
            valid.append(s)
    print('# doubled: ' + str(len(doubled)))
    print('# missing: ' + str(len(missing)))
    print('# wrong_order: ' + str(len(wrong_order)))
    print('# wrong_start: ' + str(len(wrong_start)))
    print('# too_large_head: ' + str(len(too_large_head)))
    # for item in too_large_head:
    #   print(item)
    print('# valid: ' + str(len(valid)))
    return valid


def main():
    with open(sys.argv[1]) as f:
        sents = f.read().split('\n\n')
        treebank = [Sentence(s) for s in sents if s]
    treebank = validate(treebank)
    
    # create relevant 'validated' directory
    model_type = str(sys.argv[2])
    out_path = os.path.join('output', model_type, 'validated')
    if not os.path.exists(out_path):
        print('making outdir {}'.format(out_path))
        os.mkdir(out_path)
        
    with open(out_path + '/' + sys.argv[1].split('/')[-1], 'w', encoding='utf-8') as f:
        f.write('\n\n'.join(str(s) for s in treebank))

if __name__ == '__main__':
    main()
