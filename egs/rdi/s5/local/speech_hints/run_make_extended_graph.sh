#!/usr/bin/env bash
# (c) 2019 sylvainlg@voicea.ai

export KALDI_SLG=/home/workfit/Sylvain/kaldi-slg
export KALDI_SLG_ASPIRE=${KALDI_SLG}/egs/aspire/s5


model_dir=exp/nut-1120-big-conv-epoch10-rnn/model
lang_base=/tmp/speech_hints/lang_basevocab
lexicon=$model_dir/extvocab_lexicon/lexiconp.txt
lang_ext=/tmp/speech_hints/lang_extvocab
output_dir=/tmp/speech_hints/extvocab_part

./local/grammar/make_extended_graph.sh $lang_base $model_dir $lexicon $lang_ext $output_dir