#!/bin/bash

stage=7
njobs=$(($(nproc)-1))
training_set=train
mono_ali_set=mono_ali

# end configuration section
. ./path.sh
. utils/parse_options.sh

n_speakers_test=$(cat data/test/spk2utt | wc -l)



if [ $stage == 7 ]; then
  echo ============================================================================
  echo " tri1 : TriPhone with delta delta-delta features Training & Decoding      "
  echo ============================================================================

  #Train Deltas + Delta-Deltas model based on mono_ali
  steps/train_deltas.sh 3000 40000 data/${training_set} data/lang exp/${mono_ali_set} exp/tri1_${training_set}

  #Decoder
  for lm in SRILM; do
    utils/mkgraph.sh data/lang_test_$lm exp/tri1_${training_set} exp/tri1_${training_set}/graph_$lm
    steps/decode.sh --config conf/decode.config --nj $n_speakers_test exp/tri1_${training_set}/graph_$lm data/test exp/tri1_${training_set}/decode_test_$lm
  done
  for x in exp/tri1_${training_set}/decode_*; do
    [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh
  done
  #Align the train data using tri1 model
  steps/align_si.sh --nj $njobs data/${training_set} data/lang exp/tri1_${training_set} exp/tri1_${training_set}_ali
fi