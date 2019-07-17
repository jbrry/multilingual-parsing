import sys
from conllu_parser import Sentence

model_type = str(sys.argv[1])
print('model type: {}'.format(model_type))

with open(f'output/{model_type}/validated/combined_four.conllu') as f:
    t = f.read()
sents = [Sentence(s) for s in t.split('\n\n')]


def find_root(sent):
    root_tokens = []
    for tok in sent.tokens:
        if tok[6] == '0':
            root_tokens.append(tok)
    return root_tokens


doubleheaded = []
good = []
# i = 0
for sent in sents:
    r = find_root(sent)
    if len(r) == 1:
        good.append(sent)
        # print(r)
        # i += 1
        # if i == 20:
        #     quit()
    else:
        doubleheaded.append(sent)
print('# good: ' + str(len(good)))
print('# doubleheaded: ' + str(len(doubleheaded)))

with open(f'output/{model_type}/validated/comb.conllu', 'w') as f:
    f.write('\n\n'.join(str(s) for s in good))
