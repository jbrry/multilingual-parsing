import random
from conllu_parser import *

"""
Join projected treebanks?
"""

treebanks = []


# need path to projected files
# i) monolingual projected and ii) multilingual projected
projected_treebank_dir = "" # TODO pass as arg.

for projected_treebank in os.listdir(projected_treebank_dir):
	print(projected_treebank)
	treebanks.append(projected_treebank)

def treebanks_dict():
	whole = {}
	for fname in treebanks:
		with open('validated/' + fname) as f:
			sents = f.read().split('\n\n')
			# at this point, treebank has n sub-lists for each file,
			# where n is a number of treebank versions

			whole = one_treebank_dict(sents, whole)
	print('union: ' + str(len(whole)))
	return whole


def one_treebank_dict(sents, whole):
	for sent in sents:
		s = Sentence(sent)
		for comment_line in s.comments:
			if comment_line.startswith('# sent_id = '):
				num = int(comline.split('=')[1].strip())
				# set sentence id as key and sentence as value
				if num not in whole:
					whole[num] = [s]
				# append sentence to existing keys
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


def fast_write(whole):
	four_sents = [[], [], [], []]
	for num in whole:
		sents = whole[num]

        for i in range(0, len(treebanks)):
            list_%s % i = []

		if len(sents) == 4:
			four_sents[0].append(str(sents[0]))
			four_sents[1].append(str(sents[1]))
			four_sents[2].append(str(sents[2]))
			four_sents[3].append(str(sents[3]))
	print('four_sents: ' + str(len(four_sents[0])))
	with open('tmp/four_1st.conllu', 'w') as f:
		f.write('\n\n'.join(four_sents[0]))
	with open('tmp/four_2nd.conllu', 'w') as f:
		f.write('\n\n'.join(four_sents[1]))
	with open('tmp/four_3rd.conllu', 'w') as f:
		f.write('\n\n'.join(four_sents[2]))
	with open('tmp/four_4th.conllu', 'w') as f:
		f.write('\n\n'.join(four_sents[3]))


if __name__ == '__main__':
	union = treebanks_dict()
	fast_write(union)

	# tbs = treebanks_dict()
	# res = random_union(tbs)
	# with open('random_union.conllu', 'w') as f:
	# 	f.write('\n\n'.join(res))
