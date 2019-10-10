local word_embedding_dim = 100;
local char_embedding_dim = 64;
local embedding_dim = word_embedding_dim + char_embedding_dim + char_embedding_dim;
local hidden_dim = 400;
local num_epochs = 50;
local patience = 10;
local batch_size = 32;
local learning_rate = 0.001;
local cuda_device = 0;

{
  "dataset_reader":{
    "type":"universal_dependencies_monolingual",
      "token_indexers": {
        "tokens": { 
        "type": "single_id" 
        },
        "token_characters": { 
        "type": "characters",
        "min_padding_length": 3
        }
      }
    },
    "train_data_path": std.extVar("TRAIN_DATA_PATH"),
    "model": {
      "type": "pos_tagger_monolingual",
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
      "encoder": {
        "type": "stacked_bidirectional_lstm",
        "input_size": embedding_dim,
        "hidden_size": hidden_dim,
        "num_layers": 2,
        "recurrent_dropout_probability": 0.33,
        "use_highway": true
      },
      "dropout": 0.33,
      "input_dropout": 0.33
    },
    "iterator": {
      "type": "bucket",
      "sorting_keys": [["words", "num_tokens"]],
      "batch_size" : batch_size
    },
    "trainer": {
      "num_epochs": num_epochs,
      "grad_norm": 5.0,
      "patience": 10,
      "cuda_device": cuda_device,
      "validation_metric": "+accuracy",
      "optimizer": {
        "type": "dense_sparse_adam",
        "betas": [0.9, 0.999]
      }
    }
  }
