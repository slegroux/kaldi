#!/usr/bin/env bash
# (c) 2019 sylvainlg@voicea.ai

export KALDI_SLG=/home/workfit/Sylvain/kaldi-slg
export KALDI_SLG_ASPIRE=${KALDI_SLG}/egs/aspire/s5

src_dict=${KALDI_SLG_ASPIRE}/data/local/dict
lm=$KALDI_SLG_ASPIRE/data/local/lm/3gram-mincount/lm_unpruned.gz
model=exp/nut-1120-big-conv-epoch10-rnn/model

./local/grammar/make_generic_graph.sh $src_dict $lm $model /tmp/speech_hints