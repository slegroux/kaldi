#!/bin/bash

stage=9
njobs=$(($(nproc)-1))

# end configuration section
. ./path.sh
. utils/parse_options.sh

n_speakers_test=$(cat data/test/spk2utt | wc -l)

if [ $stage == 9 ]; then
  echo ============================================================================
  echo " tri3b : LDA+MLLT+SAT Training & Decoding "
  echo ============================================================================
  
  #Train GMM SAT model based on Tri2b_ali
  steps/train_sat.sh 4000 60000 data/train data/lang exp/tri2b_ali exp/tri3b

  #Decoder
  for lm in SRILM; do
    utils/mkgraph.sh data/lang_test_$lm exp/tri3b exp/tri3b/graph_$lm
    steps/decode_fmllr.sh --config conf/decode.config --nj $n_speakers_test exp/tri3b/graph_$lm data/test exp/tri3b/decode_test_$lm
  done
  for x in exp/tri3b/decode_*; do
    [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh
  done

  #Align the train data using tri3b model
  steps/align_fmllr.sh --nj $njobs data/train data/lang exp/tri3b exp/tri3b_ali
  steps/align_fmllr.sh --nj $n_speakers_test data/test data/lang exp/tri3b exp/tri3b_ali_test
fi