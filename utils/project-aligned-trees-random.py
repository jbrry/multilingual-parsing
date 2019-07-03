import sys
import numpy as np

"""
This script takes 3 inputs <source conllu output> <alignments> <parallel text>
The source annotations are projected to the target translation via word alignments.
Usage:
    python utils/project-aligned-trees2.py data/faroese/fao_wiki.apertium.fao-dan.udpipe.parsed.conllu data/faroese/fao_wiki.apertium.fao-dan.align.txt data/faroese/fao_wiki.apertium.fao-dan.input.txt
"""

if len(sys.argv) < 3:
    print('Usage: python3 project-aligned-trees.py <conllu output> <alignments> <parallel text>')
    sys.exit(-1)

ud = open(sys.argv[1], 'r', encoding="utf-8").readlines()
align = open(sys.argv[2], 'r', encoding="utf-8").readlines()
corpora = open(sys.argv[3], 'r', encoding="utf-8").readlines()

num_dummy_heads = 0
num_dummy_labels = 0


# list of conllu rels excluding root
rels = ['nsubj', 'obj', 'iobj', 'csubj', 'ccomp', 'xcomp', 'obl', 'vocative', 'expl', 
        'dislocated', 'advcl', 'advmod', 'discourse', 'nmod', 'appos', 'nummod', 'acl', 
        'amod', 'conj', 'fixed', 'flat', 'compound', 'list', 'parataxis', 'orphan', 'goeswith', 
        'reparandum', 'dep', 'aux', 'cop', 'mark', 'det', 'clf', 'case', 'cc']

def ud_parse(ud):
    """
    CoNLL-U reader which returns a list containing conllu sentences.
    Each conllu sentence is itself a list-of-lists where each sub-list contains the conllu features at a specific index.
    Also returns sentence and token counts.
    """
    print("Reading sentences from {}".format(sys.argv[1]))

    sent_count = 0
    token_counts = 0

    doc = []
    current_sentence = []
    current_tokens = []


    for line in ud:
        if line.startswith('#'):
            continue
        elif line.isspace():
            # append the current sentence to the doc
            doc.append(current_sentence)
            # update token/sentence counts
            tokens_per_sent = len(current_tokens)
            token_counts += tokens_per_sent
            sent_count += 1
            # clear the lists for the next conllu sentence
            current_sentence = []
            current_tokens = []
        else:
            # add text and conllu items
            current_sentence.append(line.replace('\n', '').split('\t'))
            # normal conllu line
            if line.count('\t') == 9:
                rows = line.split('\t')
                word = rows[1] # TODO only count real arc heads not MWT
                current_tokens.append(word)

    assert len(doc) == sent_count
    print("Found {} sentences and {} tokens".format(sent_count, token_counts))
    return doc, token_counts, sent_count


def align_arr(align):
    """Takes in word-alignments and creates a dictionary `arr` 
    which maps target words to source words."""

    arr = []
    for line in align:
        d = {}
        for word in line.replace('\n','').split():
            pattern = word.split('-')
            p0 = int(pattern[0])
            p1 = int(pattern[1])
            d[p0] = p1
        arr.append(d)        
    return arr


def corpora_arr(corpora):
    """Takes in parallel text where source and target sentences
    are separated by '|||'."""

    arr = []
    for line in corpora:
        src_trg = [l.split() for l in line.replace('\n', '').split('|||')]
        arr.append(src_trg)
    return arr


def extract_source_feats(source_index, token_index, align_sent, ud_sent, target_token, num_target_tokens, have_seen_root):
    global num_dummy_heads
    global num_dummy_labels
    
    """
    Takes in a specific row of a source-parsed sentence.
    Extracts upos, head and label information.
    Looks up target equivalent of the source's head, if
    this token is not available, appends a dummy head ID.
    
    Inputs:    
        i: sentence index in corpora.
        source_index: index of source token.
        ud_sent: source-parsed UD sentence.
        align_sent: word alignments
        corpora_sent: parrallel sentences.

    Returns a conllu row (list of conllu feats)
    """

    # target row we are writing.
    conllu_row = []

    source_data = ud_sent[source_index]
    # separate into items.
    source_data = " ".join(source_data).split()

    # a very small number of sentences will have encoding issues and it gets parsed incorrectly, e.g. sentence 19992
    # add dummy labels/head and decode later.
    if len(source_data) != 10:
        source_upos = '_'
        target_head = -1
        num_dummy_heads += 1
        random_label = np.random.choice(rels)
        num_dummy_labels += 1
        source_label = random_label
        # TODO upos will be token in upos list, head will be int, label will be token in labels.
    else:
        # extract annotations.
        source_upos = source_data[3]
        source_head = source_data[6]
        source_label = source_data[7]
        #print(source_upos, source_head, source_label)

        # we don't want to naively take the head value of the source word as the head of the target word as the word order might be different.
        # invert the dictionary and query using the source key to find the target token.
        source_targ_dict = {v: k for (k, v) in align_sent.items()}

        # source head is 1-indexed (conllu item) but the alignment dict is 0-indexed.
        source_key = int(source_head) - 1
        #print("source head {}: source key: {}".format(source_head, source_key))

        # a source key of -1 would be the ROOT token which has index 0.
        # if we know the source's head is ROOT we just take that as the target HEAD.
        if source_key != -1:
            try:
                target_value = source_targ_dict[source_key]
                #print(target_value)                
                target_head = int(target_value) + 1 # 0 - 1-index.
                #print(target_head)
                # don't allow target head to be outside the range of the sentence.
                if target_head > num_target_tokens:
                    target_head = -1
                    num_dummy_heads += 1

            # sometimes the source sentence has a head that we don't have the target sentence.
            except KeyError:
                # append the upos and label information, but we will append a dummy head ID.
                target_head = -1
                num_dummy_heads += 1
        else:
            # ROOT token
            target_head = 0
            have_seen_root = True

    # append conllu items
    conllu_fields = ("\t".join([str(token_index), target_token, "_", source_upos, "_", "_", str(target_head), source_label, "_", "_"]))
    print(conllu_fields)

    conllu_row.append(conllu_fields)
    return conllu_row, have_seen_root


def transfer_tree(i, source_indices, align_sent, ud_sent, target_sent, file):
    """
    Assigns source annotations to each target token in a sentence.
    Calls 'extract_source_feats' to get conllu row features for tokens
    which are in our alignment dictionary.
    For tokens which are not in our alignment dictionary, appends dummy
    annotations which will be decoded by 'decode_trees' later.

    Inputs
        i: Index of the sentence corresponding to its location in a corpus.
        source_indices: The token IDs of the source sentence.
        align_sent: the raw fast_align alignments (note: not checked by function)
        ud_sent: parsed UD source sentence at index i.
        corpora_sent: parralel text sentence at index i (usually targ:src).
        file: sys.stdout
        
    Returns:
        Cleaned parse tree.
    """
    global num_dummy_heads
    global num_dummy_labels
    
    # new list for each target sentence.
    conllu_sent = []
    # flag to detect whether we've seen the ROOT token.
    have_seen_root = False

    token_index = 0
    targ_index = 0

    num_target_tokens = len(target_sent)
    print("num t tokens", num_target_tokens)
    
    # assign annotations for each token in the target sentence.
    for target_token in target_sent:        
        token_index += 1 # conllu token indices are 1-indexed.
        
        # Case 1) There is an alignment between target and source indices.
        try:
            source_index = align_sent[targ_index]
            # NOTE: assumes we will always have a mapping for root.
            current_row, have_seen_root = extract_source_feats(source_index, token_index, align_sent, ud_sent, target_token, num_target_tokens, have_seen_root)
        
        # Case 2) Target token is not in the dictionary, e.g. there are too many
        # target tokens and we don't have mappings for them in the alignment dictionary.
        except KeyError:
            # append row features here.
            current_row = []
            if targ_index not in align_sent.keys():
                # assign dummy labels to these tokens for now.
                random_label = np.random.choice(rels)
                num_dummy_labels += 1
                num_dummy_heads += 1
                source_upos = "unk" # TODO pick a random one?
                
                conllu_fields = ("\t".join([str(token_index), target_token, "_", source_upos, "_", "_", str(-1), str(random_label), "_", "_"]))
                print(conllu_fields)
                current_row.append(conllu_fields)
            else:
                # break the script for other cases not found yet.
                print("Unknown case triggered.")
                raise SystemExit

        # append token metadata to current sentence.
        conllu_sent.append(current_row)
        targ_index += 1
        
    # Case 3) Root token not in dictionary alignments.
    if not have_seen_root:
        
        print("we haven't found ROOT yet")
        # this is because the source ROOT token was not a dictionary value.
        # look for ROOT index in source sentence.
        #current_row = []
        
        # find root index
        for index, row in enumerate(ud_sent):
            if "root" in " ".join(row).split():
                print("root found at i {}".format(index))
                root_index = index
                
        # assign a 1:1 mapping between source root index and target root index.
        # this assumes that i) ROOT will be found within the same range of the target sentece.
        # Case 3.1)
        try:
            conllu_data = conllu_sent[root_index]
            conllu_data = " ".join(conllu_data).split()
            
            # change annotations to ROOT.
            conllu_data[6] = "0"
            conllu_data[7] = "root"
            
            # need to change the value in conllu sent.        
            conllu_sent[root_index] = conllu_data
        
        # Case 3.2)
        # ROOT token is outside the index of the target sentence. (e.g. ROOT is source token 21 and only 16 tokens in target sentence)    
        except IndexError:
            # NOTE: try something like character n-grams for these cases?
            #print(ud_sent[root_index][1])
            
            # NOTE: for now, let's just go with a random label...
            choices = []
            for i in range(0, len(conllu_sent)):
                choices.append(i)
            
            choice_index = np.random.choice(choices)
            print("choice", choice_index)
            conllu_data = conllu_sent[choice_index]
            print(conllu_data)
            conllu_data = " ".join(conllu_data).split()
            # change annotations to ROOT.
            conllu_data[6] = "0"
            conllu_data[7] = "root"
            
            # need to change the value in conllu sent.        
            conllu_sent[choice_index] = conllu_data
            

    return conllu_sent


def decode_trees(target_sent):
    """
    Decoding step which assigns heads to unassigned heads
    in the direction of the ROOT token.
    Makes sure tokens don't have heads which point to itself or 
    heads which are outside the range of the sentence.
    
    Args:
        synthetic target sentence with potentially erroneous annotations.
    
    Returns:
        A cleaned conllu parse.    
    """
    global num_dummy_heads
    global num_dummy_labels
    global decode_errors
    
    print("decoding tree")
    print(target_sent)
    num_tokens = len(target_sent)
         
    # make sure we have seen ROOT but not more than once.
    #=============================================================
    root_count = 0
    for index, row in enumerate(target_sent):
        if "root" in " ".join(row).split():
            root_index = index
            root_count += 1
    
    if root_count == 0:
        raise ValueError("No root token found")
    elif root_count > 1:
        true_root = root_index
        # set all other tokens to something else.
        for r in range(num_tokens):
            # leave the true index alone (assumes 1:1 mapping)
            if r == true_root:
                continue
            else:
                conllu_data = target_sent[r]
                conllu_data = " ".join(conllu_data).split()

                token_id = int(conllu_data[0])
                head_id = int(conllu_data[6])
                head_label = conllu_data[7]
                
                # change other ROOT cases.
                if head_id == 0:
                    conllu_data[6] = "-1"
                    random_label = np.random.choice(rels)
                    conllu_data[7] = random_label             
                    target_sent[r] = conllu_data
            
    # make sure there are no cycles and assign heads/labels to dummy annotations.
    #=============================================================
    
    for i in range(num_tokens):
        conllu_data = target_sent[i]
        conllu_data = " ".join(conllu_data).split()

        token_id = int(conllu_data[0])
        head_id = int(conllu_data[6])
        head_label = conllu_data[7]
        
        if token_id == head_id:
            raise ValueError("A token can't be its own head!")
        elif head_id > num_tokens:
            # this is probably a result of taking the source token's head which we would not
            # normally have in our target sentence but was added there because of check_align.
            raise ValueError("Head of token {} is outside the range of the sentence {}!".format(token_id, num_tokens))
            
        # make sure there are labels
        if head_label == "_":
            raise ValueError("Has this not been sorted yet?")
            # random choice
            random_label = np.random.choice(rels)            
            conllu_data[6] = random_label

            # need to change the value in conllu sent.
            target_sent[i] = conllu_data
            

        if head_id == -1:
            print("Unallocated head ID")
            num_dummy_heads += 1

            # Implement a heuristic: head ID should be next valid token in the direction of ROOT.
            # Alternative would be selecting random heads/labels so the parser doesn't overfit to these cases.
            
            distance = int(i) - root_index
            print(distance)

            # go backwards towards ROOT.
            if distance > 0:           
                for j in range(1, distance + 1):
                    #print(j)
                    candidate_token = i - j
                    #print(candidate_token)

                    # check if that token would be a good candidate, e.g. no cycles.
                    candidate_data = target_sent[candidate_token]
                    print("candidate data", candidate_data)

                    candidate_data = " ".join(candidate_data).split() # separate into items
                    candidate_head, head_of_candidate_head = candidate_data[0], candidate_data[6]
                    print("candidate head token {} and its head {}".format(candidate_head, head_of_candidate_head))

                    # a token can't be its own head
                    if int(head_of_candidate_head) == token_id:
                        continue
                    else:
                        # set the target head as the closest candidate head
                        target_head = candidate_head
                        print("target head", target_head)
                        conllu_data[6] = target_head

                        # need to change the value in conllu sent.
                        target_sent[i] = conllu_data
                        # exit the loop once we've chosen the first suitable head.
                        break
            # go forwards towards ROOT.
            elif distance < 0:    
                distance = abs(distance)                
                for j in range(1, distance + 1):
                    #print(j)
                    candidate_token = i + j
                    #print(candidate_token)

                    # check if that token would be a good candidate, e.g. no cycles.
                    candidate_data = target_sent[candidate_token]
                    print("candidate data", candidate_data)

                    candidate_data = " ".join(candidate_data).split() # separate into items
                    candidate_head, head_of_candidate_head = candidate_data[0], candidate_data[6]
                    print("candidate head token {} and its head {}".format(candidate_head, head_of_candidate_head))

                    # a token can't be its own head
                    if int(head_of_candidate_head) == token_id:
                        continue
                    else:
                        # set the target head as the closest candidate head
                        target_head = candidate_head
                        print("target head", target_head)
                        conllu_data[6] = target_head
                        target_sent[i] = conllu_data
                        break
     
    # final step to make sure the above worked for all cases.
    #=============================================================

    for j in range(num_tokens):
        conllu_data = target_sent[j]
        conllu_data = " ".join(conllu_data).split()

        head_id = int(conllu_data[6])
        head_label = conllu_data[7]
        
        if head_id == -1:
            raise ValueError("Unassigned head was not processed.")
        if head_label == "_":
            raise ValueError("Unassigned label was not processed.")
    
    print(target_sent)
    return target_sent


def zum_align(align, ud_indexes):
    """Takes in align result and the source indexes."""

    d = {}
    point = ''
    before_zum = True
    # print("ALIGN ", align)
    for i in ud_indexes:
        if i in point:
            continue

        if '-' in i:
            # print(i)
            before_zum = False
            zum = i.split('-')

            for j in range(int(zum[0]), int(zum[1])+1):
                try:
                    d[j-1] = align[j-1]
                except KeyError:
                    d[j-1] = j-1
                point += str(j) + ' '
            before_zum = 0
            continue

        try:
            if before_zum == 0:
                # print(i)
                d[int(i)-1] = align[int(i)-2]

            if before_zum is True:
                d[int(i)-1] = align[int(i)-1]

        except KeyError:
            d[int(i)-1] = int(i)-2

    print('ALIGN RESULT ZUM', d)
    return d


def check_align(align, source_indices, target_sent):
    """
    Checks that for each source index, there is a target key which can access
    that index. If there isn't one in the alignment dictionary, it creates a
    1:1 mapping to that source index.
    Sets last token of target sentence to last token in source sentence (often PUNCT.)
    NOTE: Doesn't make sure there is a source index for every target index, this is because sometimes there
    can be more target tokens than source tokens (Case 2).
    
    Inputs:
        align: word alignments for sentence i.
        source_indices: Token indices for source sentence i.
        target_sent: tokenized target sentence.
    """
    #print("Align: {}".format(align))
    print("Source indices: {}".format(source_indices))

    # get last element of the source/target lists and -1 to convert to 0-index.
    last_source_value = int(source_indices[-1]) -1
    last_target_key = int(len(target_sent) -1)

    print("last target key {}; last source value {}".format(last_target_key, last_source_value))

    for i in source_indices:
        try:
            align[int(i)-1]
            #print('Align result with key {}: {}'.format(int(i)-1, align[int(i)-1]))
        except KeyError:
            # if there's not a mapping for the number of source tokens in our dictionary
            # create a 1:1 mapping to that particular source index (it may not even be used):
            a = int(i) - 2
            if a >= 0:
                align[int(i)-1] = int(i)-1
            else:
                align[int(i)-1] = int(i)-1

    # set last key = last value
    # TODO we shouldn't allow a token in the target dict to equal the end source token in cases where there's more source tokens..
    align[last_target_key] = last_source_value

    print('check_align RESULT', align)
    return align

# load ud, alignment and parallel files.
ud_res, num_tokens, num_sents = ud_parse(ud)
align_res = align_arr(align)
corpora_res = corpora_arr(corpora)


file = open("z.conllu", "w")
for i in range(0, len(align_res)): # 28861 (the parallel texts have 28862)
#for i in range(0, 10):
    sent_id = '# sent_id = ' + str(i+1) + '\n'
    text = '# text = ' + ' '.join(corpora_res[i][1]) + '\n' # [1] is the target sentence.
    print(sent_id)
    print(text)
    
    # write sent id and text lines to each sentence.
    file.write(sent_id)
    file.write(text)

    source_len = len(ud_res[i])
    # source indices are the token IDs of the source-parsed sentence.
    # Source sentence at index i; j corresponds to the index number and 0 means the first conllu item.
    source_indices = [ud_res[i][j][0] for j in range(0, source_len)]
    
    target_sent = ' '.join(corpora_res[i][1]).strip().split() # [1]: target sentence

    # MWT handling
    if '-' in ''.join(source_indices):
        print(source_indices)
        #transfer_tree(i, source_indices, zum_align(align_res[i], source_indices), ud_res[i], corpora_res[i], file)
    else:

        conllu_sent = transfer_tree(i, source_indices, check_align(align_res[i], source_indices, target_sent), \
                                    ud_res[i], target_sent, file)
        # decode the tree
        cleaned_sent = decode_trees(conllu_sent)
        
        # write sentence features to file.
        for sent in cleaned_sent:
            conllu_items = ("\t".join(sent))
            file.write(conllu_items + '\n')
        file.write('\n')
file.close()

# TODO need target token count:       
print("assigned {} dummy heads".format(num_dummy_heads))
print("assigned {} dummy labels".format(num_dummy_labels))