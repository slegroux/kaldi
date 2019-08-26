#!/usr/bin/env bash
# (c) 2019 sylvainlg@voicea.ai

speech_hints_list=$1
g2p_model_dir=$2
output_dir=$3

lexicon_dir=$output_dir/extvocab_lexicon
mkdir -p $lexicon_dir
cp $speech_hints_list $lexicon_dir/words

steps/dict/apply_g2p.sh $lexicon_dir/words $g2p_model_dir $lexicon_dir
cat $lexicon_dir/lexicon.lex | tr '[:upper:]' '[:lower:]' >$lexicon_dir/lexicon_tmp.lex; mv $lexicon_dir/lexicon_tmp.lex $lexicon_dir/lexicon.lex
cp $lexicon_dir/lexicon.lex $lexicon_dir/lexiconp.txt