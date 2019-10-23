#!/bin/bash

# Copyright 2014 Vassil Panayotov
# Apache 2.0

# Trains Sequitur G2P models on lexicon

# can be used to skip some of the initial steps
stage=2

. utils/parse_options.sh || exit 1
. path.sh || exit 1

if [ $# -ne "2" ]; then
  echo "Usage: $0 <lexicon-dir> <g2p-dir>"
  echo "e.g.: $0 lexicon data/local/g2p_model"
  exit 1
fi

lexicon_dir=$1
g2p_dir=$2

mkdir -p $g2p_dir

lexicon_plain=$g2p_dir/lexicon.plain
lexicon_clean=$g2p_dir/lexicon.clean

if [ $stage -le 2 ]; then
  echo "Removing the pronunciation variant markers ..."
  grep -v ';;;' $lexicon_dir/lexicon | \
    perl -ane 'if(!m:^;;;:){ s:(\S+)\(\d+\) :$1 :; print; }' \
    > $lexicon_plain || exit 1;
  echo "Removing special pronunciations(not helpful for G2P modelling)..."
  egrep -v '^[^a-z]' $lexicon_plain >$lexicon_clean
fi

model_1=$g2p_dir/model-1

if [ $stage -le 3 ]; then
  echo "Training first-order G2P model (log in '$g2p_dir/model-1.log') ..."
  PYTHONPATH=$sequitur_path:$PYTHONPATH $PYTHON $sequitur \
    --train $lexicon_clean --devel 5% --write-model $model_1 >$g2p_dir/model-1.log 2>&1 || exit 1
fi

model_2=$g2p_dir/model-2

if [ $stage -le 4 ]; then
  echo "Training second-order G2P model (log in '$g2p_dir/model-2.log') ..."
  PYTHONPATH=$sequitur_path:$PYTHONPATH $PYTHON $sequitur \
    --model $model_1 --ramp-up --train $lexicon_clean \
    --devel 5% --write-model $model_2 >$g2p_dir/model-2.log \
    >$g2p_dir/model-2.log 2>&1 || exit 1
fi

model_3=$g2p_dir/model-3

if [ $stage -le 5 ]; then
  echo "Training third-order G2P model (log in '$g2p_dir/model-3.log') ..."
  PYTHONPATH=$sequitur_path:$PYTHONPATH $PYTHON $sequitur \
    --model $model_2 --ramp-up --train $lexicon_clean \
    --devel 5% --write-model $model_3 \
    >$g2p_dir/model-3.log 2>&1 || exit 1
fi

model_4=$g2p_dir/model-4

if [ $stage -le 4 ]; then
  echo "Training fourth-order G2P model (log in '$g2p_dir/model-4.log') ..."
  PYTHONPATH=$sequitur_path:$PYTHONPATH $PYTHON $sequitur \
    --model $model_3 --ramp-up --train $lexicon_clean \
    --devel 5% --write-model $model_4 \
    >$g2p_dir/model-4.log 2>&1 || exit 1
fi

model_5=$g2p_dir/model-5

if [ $stage -le 5 ]; then
  echo "Training fifth-order G2P model (log in '$g2p_dir/model-5.log') ..."
  PYTHONPATH=$sequitur_path:$PYTHONPATH $PYTHON $sequitur \
    --model $model_4 --ramp-up --train $lexicon_clean \
    --devel 5% --write-model $model_5 \
    >$g2p_dir/model-5.log 2>&1 || exit 1
fi

echo "G2P training finished OK!"
exit 0
