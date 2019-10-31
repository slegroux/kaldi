#!/usr/bin/env bash

njobs=$(($(nproc)-1))
stage=6

. ./path.sh
. utils/parse_options.sh

n_speakers_test=$(cat data/test/spk2utt | wc -l)

if [ $stage == 6 ]; then
  echo ============================================================================
  echo " MonoPhone Training & Decoding "
  echo ============================================================================
  
  utils/subset_data_dir.sh data/train 4000 data/train_4k
  #Train monophone model
  time steps/train_mono.sh \
    --nj $njobs \
    --config conf/monophone.conf \
    data/train_4k data/lang exp/mono

  #Decoder
  for lm in SRILM; do
    time utils/mkgraph.sh --mono data/lang_test_$lm exp/mono exp/mono/graph_$lm
    
    time steps/decode.sh \
      --config conf/decode.config \
      --nj $n_speakers_test \
      exp/mono/graph_$lm data/test exp/mono/decode_test_$lm
  done
  echo "Monophone training" | tee -a WER.txt
  cat conf/monophone.conf | tee -a WER.txt
  for x in exp/mono/decode_*; do
    [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh |tee -a WER.txt
  done

  #Align the train data using mono-phone model
  steps/align_si.sh --nj $njobs data/train data/lang exp/mono exp/mono_ali
fi