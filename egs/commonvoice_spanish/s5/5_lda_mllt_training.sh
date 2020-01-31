#!/bin/bash

stage=8
njobs=$(($(nproc)-1))
train="train"
tri1_ali="tri1_ali"

. ./path.sh
. utils/parse_options.sh

n_speakers_test=$(cat data/test/spk2utt | wc -l)
tri2b=tri2b_${train}
tri2b_ali=tri2b_${train}_ali

if [ $stage == 8 ]; then
  echo ============================================================================
  echo " tri2b : LDA + MLLT Training & Decoding / Speaker Adaptation"
  echo ============================================================================
  
  #Train LDA + MLLT model based on tri1_ali
  steps/train_lda_mllt.sh --splice-opts "--left-context=3 --right-context=3" 4000 60000 data/${train} data/lang exp/${tri1_ali} exp/${tri2b}

  #Decoder
  for lm in SRILM; do
    utils/mkgraph.sh data/lang_test_$lm exp/${tri2b} exp/${tri2b}/graph_$lm
    steps/decode.sh --config conf/decode.config --nj $n_speakers_test exp/${tri2b}/graph_$lm data/test exp/${tri2b}/decode_test_$lm
  done
  for x in exp/${tri2b}/decode_*; do
    [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh
  done
  steps/align_si.sh --nj $njobs data/${train} data/lang exp/${tri2b} exp/${tri2b_ali}
fi