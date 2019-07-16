local word_embedding_dim = 100;
local char_embedding_dim = 32;
local pos_embedding_dim = 50;
local tb_embedding_dim = 12;
local embedding_dim = word_embedding_dim + pos_embedding_dim + tb_embedding_dim + char_embedding_dim + char_embedding_dim;
local hidden_dim = 400;
local num_epochs = 50;
local patience = 10;
local batch_size = 32;
local learning_rate = 0.1;

{
  "dataset_reader":{
    "type":"universal_dependencies_tbemb",
    "languages": ["da_ddt", "sv_talbanken", "no_nynorsk", "no_bokmaal"],
	"alternate": true,
	"instances_per_file": 32,
	"is_first_pass_for_vocab": true,
	"lazy": true,
      "token_indexers": {
        "tokens": { 
        "type": "single_id" 
        },
        "token_characters": { 
        "type": "characters",
        "min_padding_length": 3
        }
   },
   "use_language_specific_pos": false,
   "use_treebank_embedding": true
   },
   "iterator": {
     "type": "same_language",
     "batch_size": 32,
     "sorting_keys": [["words", "num_tokens"]],
     "instances_per_epoch": 32000
   },
    "train_data_path": "/home/jbarry/ud-parsing/ud-treebanks-v2.2/**/*-ud-train.conllu",
    "validation_data_path": "/home/jbarry/ud-parsing/ud-treebanks-v2.2/**/*-ud-dev.conllu",
    "model": {
      "type": "biaffine_parser_tbemb",
      "text_field_embedder": {
        "token_embedders": {
          "tokens": {
            "type": "embedding",
            "embedding_dim": word_embedding_dim
           },
           "token_characters": {
             "type": "character_encoding",
             "embedding": {
               "embedding_dim": char_embedding_dim,
             },
             "encoder": {
               "type": "lstm",
               "input_size": char_embedding_dim,
               "hidden_size": char_embedding_dim,
               "num_layers": 2,
               "bidirectional": true
             }
           }
        },
      },
      "pos_tag_embedding":{
        "embedding_dim": pos_embedding_dim,
        "vocab_namespace": "pos",
        "sparse": true
      },
      "treebank_embedding":{
        "embedding_dim": 12,
        "vocab_namespace": "tbids"
      },
      "encoder": {
        "type": "stacked_bidirectional_lstm",
        "input_size": embedding_dim,
        "hidden_size": hidden_dim,
        "num_layers": 3,
        "recurrent_dropout_probability": 0.33,
        "use_highway": true
      },
      "langs_for_early_stop": [
      "da_ddt",
      "sv_talbanken",
      "no_nynorsk",
      "no_bokmaal"
      ],
      "use_mst_decoding_for_validation": true,
      "use_treebank_embedding": true,
	  "arc_representation_dim": 500,
      "tag_representation_dim": 100,
      "dropout": 0.33,
      "input_dropout": 0.33,
      "initializer": [
        [".*projection.*weight", {"type": "xavier_uniform"}],
        [".*projection.*bias", {"type": "zero"}],
        [".*tag_bilinear.*weight", {"type": "xavier_uniform"}],
        [".*tag_bilinear.*bias", {"type": "zero"}],
        [".*weight_ih.*", {"type": "xavier_uniform"}],
        [".*weight_hh.*", {"type": "orthogonal"}],
        [".*bias_ih.*", {"type": "zero"}],
        [".*bias_hh.*", {"type": "lstm_hidden_bias"}]]
    },
    "evaluate_on_test": false,
    "trainer": {
      "num_epochs": num_epochs,
      "grad_norm": 5.0,
      "patience": 10,
      "cuda_device": 0,
      "validation_metric": "+LAS_AVG",
      "optimizer": {
        "type": "dense_sparse_adam",
        "betas": [0.9, 0.9]
      }
    },
   "validation_dataset_reader": {
     "type": "universal_dependencies_tbemb",
     "languages": ["da_ddt", "sv_talbanken", "no_nynorsk", "no_bokmaal"],
     "alternate": false,
      "lazy": true,
      "token_indexers": {
        "tokens": {
          "type": "single_id"
      },
      "token_characters": {
        "type": "characters",
        "min_padding_length": 3
      }
   },
   "use_language_specific_pos": false,
   "use_treebank_embedding": true
   },
   "validation_iterator": {
     "type": "same_language",
     "sorting_keys": [["words","num_tokens"]],
     "batch_size": 32
   }
}
