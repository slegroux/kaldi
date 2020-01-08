#!/usr/bin/env bash

njobs=$(($(nproc)-1))
stage=6
training_set=train

. ./path.sh
. utils/parse_options.sh

n_speakers_test=$(cat data/test/spk2utt | wc -l)

if [ $stage == 6 ]; then
  echo ============================================================================
  echo " MonoPhone Training & Decoding "
  echo ============================================================================
  
  utils/subset_data_dir.sh data/${training_set} 4000 data/${training_set}_4k
  #Train monophone model
  time steps/train_mono.sh \
    --nj $njobs \
    --config conf/monophone.conf \
    data/${training_set}_4k data/lang exp/mono_${training_set}

  #Decoder
  for lm in SRILM; do
    time utils/mkgraph.sh --mono data/lang_test_$lm exp/mono_${training_set} exp/mono_${training_set}/graph_$lm
    
    time steps/decode.sh \
      --config conf/decode.config \
      --nj $n_speakers_test \
      exp/mono_${training_set}/graph_$lm data/test exp/mono_${training_set}/decode_test_$lm
  done
  echo "Monophone training" | tee -a WER.txt
  cat conf/monophone.conf | tee -a WER.txt
  for x in exp/mono_${training_set}/decode_*; do
    [ -d $x ] && [[ $x =~ "$1" ]] && grep WER $x/wer_* | utils/best_wer.sh |tee -a WER.txt
  done

  #Align the train data using mono-phone model
  steps/align_si.sh --nj $njobs data/${training_set} data/lang exp/mono_${training_set} exp/mono_${training_set}_ali
fi