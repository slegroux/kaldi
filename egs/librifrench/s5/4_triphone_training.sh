#!/bin/bash

stage=7
njobs=$(($(nproc)-1))

# end configuration section
. ./path.sh
. utils/parse_options.sh

n_speakers_test=$(cat data/test/spk2utt | wc -l)



if [ $stage == 7 ]; then
  echo ============================================================================
  echo " tri1 : TriPhone with delta delta-delta features Training & Decoding      "
  echo ============================================================================

  #Train Deltas + Delta-Deltas model based on mono_ali
  steps/train_deltas.sh 3000 40000 data/train data/lang exp/mono_ali exp/tri1

  #Decoder
  for lm in SRILM; do
    utils/mkgraph.sh data/lang_test_$lm exp/tri1 exp/tri1/graph_$lm
    steps/decode.sh --config conf/decode.config --nj $n_speakers_test exp/tri1/graph_$lm data/test exp/tri1/decode_test_$lm
  done
  for x in exp/tri1/decode_*; do
    [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh
  done
  #Align the train data using tri1 model
  steps/align_si.sh --nj $njobs data/train data/lang exp/tri1 exp/tri1_ali
fi