import os
import sys
import random
from conllu_parser import *


def treebanks_dict(val_path):
    whole = {}
    for fname in treebanks:
        with open(val_path + '/' + fname) as f:
            sents = f.read().split('\n\n')
            # at this point, treebank has n sub-lists for each file,
            # where n is a number of treebank versions

            whole = one_treebank_dict(sents, whole)
    print('# union: ' + str(len(whole)))
    return whole


def one_treebank_dict(sents, whole):
    for sent in sents:
        s = Sentence(sent)
        for comment_line in s.comments:
            if comment_line.startswith('# sent_id = '):
                num = int(comment_line.split('=')[1].strip())
                if num not in whole:
                    whole[num] = [s]
                else:
                    whole[num].append(s)
                break
    return whole


def random_union(tbs):
    result = []
    for num in tbs:
        sent = random.choice(tbs[num])
        result.append(str(sent))
    return result


def unite_treebanks(tbs):
    pass
    # treebank.append([Sentence(s) for s in sents])


def fast_write_3_4(whole):
    three_sents = [[], [], []]
    four_sents = [[], [], [], []]
    
    for num in whole:
        sents = whole[num]
        if len(sents) == 3:
            three_sents[0].append(str(sents[0]))
            three_sents[1].append(str(sents[1]))
            three_sents[2].append(str(sents[2]))
        elif len(sents) == 4:
            four_sents[0].append(str(sents[0]))
            four_sents[1].append(str(sents[1]))
            four_sents[2].append(str(sents[2]))
            four_sents[3].append(str(sents[3]))
    
    print('# three_sents: ' + str(len(three_sents[0])))
    print('# four_sents: ' + str(len(four_sents[0])))

    with open(f'output/{model_type}/tmp/three_1st.conllu', 'w') as f:
        f.write('\n\n'.join(three_sents[0]))
    with open(f'output/{model_type}/tmp/three_2nd.conllu', 'w') as f:
        f.write('\n\n'.join(three_sents[1]))
    with open(f'output/{model_type}/tmp/three_3rd.conllu', 'w') as f:
        f.write('\n\n'.join(three_sents[2]))
    with open(f'output/{model_type}/tmp/four_1st.conllu', 'w') as f:
        f.write('\n\n'.join(four_sents[0]))
    with open(f'output/{model_type}/tmp/four_2nd.conllu', 'w') as f:
        f.write('\n\n'.join(four_sents[1]))
    with open(f'output/{model_type}/tmp/four_3rd.conllu', 'w') as f:
        f.write('\n\n'.join(four_sents[2]))
    with open(f'output/{model_type}/tmp/four_4th.conllu', 'w') as f:
        f.write('\n\n'.join(four_sents[3]))


if __name__ == '__main__':

    # access relevant 'validated' directory
    model_type = str(sys.argv[1])
    val_path = os.path.join('output', model_type, 'validated')
    if not os.path.exists(val_path):
        print('cannot find validated folder at: {}'.format(val_path))

    # populate treebanks list with files in 'validated' folder
    treebanks = []

    for treebank in os.listdir(val_path):
        if 'comb' not in treebank:
            print(treebank)
            treebanks.append(treebank)
    
    union = treebanks_dict(val_path)
    fast_write_3_4(union)

    # tbs = treebanks_dict()
    # res = random_union(tbs)
    # with open('random_union.conllu', 'w') as f:
    #   f.write('\n\n'.join(res))
