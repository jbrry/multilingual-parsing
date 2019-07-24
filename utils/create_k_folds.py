from collections import Counter, namedtuple
import argparse
import numpy as np
import random
from random import seed
import sys, os, re, copy
import codecs

parser = argparse.ArgumentParser(description='Cross Validation Arguments')
parser.add_argument('--train', '-t', type=str, help='Training file to split into chunks.')
parser.add_argument('--outdir','-o', type=str, help='Directory to write split files to.')
parser.add_argument('--k', '-k', type=int, default=10, help='Number of folds for cross-validation.')
parser.add_argument('--encoding', '-e', type=str, default='utf-8', help='Type of encoding.')
parser.add_argument('--seed', '-s', type=int, default=1, help='Number for random seed.')
parser.add_argument('--random-sampling', '-r', action='store_true', default=False, help='Randomly sample sentences.')

args = parser.parse_args()

if not os.path.exists(args.outdir):
    os.mkdir(args.outdir)

train_name = os.path.basename(args.train)
tbid = train_name.split('-')[0]


def conllu_reader(trainfile):
    """Simple CoNLL-U reader to return a list of sentences from a file 
       as well as token/sentence counts."""
    
    print("Reading sentences from {}".format(trainfile))

    file = codecs.open(trainfile, 'r', encoding=args.encoding)
    
    sentences = []
    current_sentence = []
    current_tokens=[]
    sent_count=0
    token_counts=0

    while True:
        line = file.readline()
        if not line:
            break
        # new conllu sentence
        if line.isspace():
            # append the current sentence to sentences
            sentences.append(current_sentence)
            # update token/sentence counts
            tokens_per_sent = len(current_tokens)
            token_counts += tokens_per_sent
            sent_count += 1
            # clear the lists for the next conllu sentence
            current_sentence = [] 
            current_tokens = []
        else:
            # add text and conllu items
            current_sentence.append(line)
            # normal conllu line
            if line.count('\t') == 9:
                rows = line.split('\t')
                word=rows[1] # TODO only count real arc heads not MWT
                current_tokens.append(word)
    
    file.close()
    assert len(sentences) == sent_count
    print("Found {} sentences and {} tokens".format(sent_count, token_counts))
    return sentences, token_counts, sent_count


def generate_k_folds(train_sentences, k):
    """Divides training sentences into k folds.
    
    Args:
        train_sentences: list of lists containing conllu sentences.
        k: number of folds to create (default=10).
        
    Returns:
        folds: list of k lists of sentences where each sub-list is a fold."""

    # main list which will contain the folds
    data_folds = []
    # keep a copy of the dataset
    dataset_copy = list(train_sentences)  
    sents_per_fold = int(len(train_sentences) / k)
    remainder = int(len(train_sentences) % k)

    required_sizes = remainder * [sents_per_fold + 1] + (k - remainder) * [sents_per_fold]
    print("Splitting the dataset into {} folds containing {} sentences \n".format(args.k, required_sizes))
    
    for i in range(args.k):
        # create a new data fold to be populated
        fold = []
        # populate the fold until it meets the required size
        while len(fold) < required_sizes[i]:
            # take a random sentence from the dataset
            if args.random_sampling:
                sample_index = np.random.choice(len(dataset_copy))
            else:
                # take first element
                sample_index = 0

            fold.append(dataset_copy.pop(sample_index))
        data_folds.append(fold)
    # make sure there are no sentences left
    assert len(dataset_copy) == 0

    return data_folds


def make_train_dev_splits(cv_fold, folded_dataset):
    """Make training and dev sets from folds."""
    
    # allocate the fold for dev/test data
    dev_split = []

    # make a copy of the dataset which we will modify instead 
    folded_dataset_copy = list(folded_dataset)

    if cv_fold in folded_dataset_copy:
        # remove this fold from the dataset
        folded_dataset_copy.remove(cv_fold)
        # training set is the whole dataset without this fold
        train_split = folded_dataset_copy
        # test set becomes this fold
        dev_split.append(cv_fold)

        return train_split, dev_split


def write_conllu(data, outfile):
    """Write list of sentences to '\n' separated sentences in a file."""

    with codecs.open(outfile, 'w', encoding=args.encoding) as f:
        for block in data:
            for sent in block:
                for entry in sent:
                    #f.write(unicode(entry))
                    f.write(entry)
                f.write('\n')


# create training sentences and token/sentence counts
train_sentences, token_counts, sent_count = conllu_reader(args.train)

# turn training dataset into k folds
folded_dataset = generate_k_folds(train_sentences, args.k)
assert len(folded_dataset) == args.k

# create train/dev splits
for i, fold in enumerate(folded_dataset):
    train_split, dev_split = make_train_dev_splits(fold, folded_dataset)
    print("Creating split %d" % (i))
    assert len(train_split) == args.k - 1
    print()
    
    conllu_train = train_name + '.' + 'split-'+ str(i)
    conllu_dev = tbid + '-ud-dev.conllu' + '.' + 'split-' + str(i)
    
    train_out = os.path.join(args.outdir, conllu_train)  
    dev_out = os.path.join(args.outdir, conllu_dev)

    train_sample = write_conllu(train_split, train_out)
    dev_sample = write_conllu(dev_split, dev_out)

print("Finished. Wrote files to {}".format(args.outdir))
