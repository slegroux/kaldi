#!/usr/bin/env bash
# (c) 2019 sylvainlg@voicea.ai

speech_hints_list=local/speech_hints/speech_hints.txt
#g2p_model_dir=$KALDI_SLG/tools/g2p/en_us/models
g2p_model_dir=$DATA/voicea-speechhints-data/g2p
output_dir=/tmp/test

./local/speechhints/generate_oov_lexicon.sh $speech_hints_list $g2p_model_dir $output_dir