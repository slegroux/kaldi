#!/bin/bash

njobs=$(($(nproc)-1))
stage=5
train_set=train
test_set=test

# end configuration section
. ./path.sh
. utils/parse_options.sh


if [ $stage == 5 ]; then
  echo ============================================================================
  echo " MFCC extraction "
  echo ============================================================================

  mfccdir=mfcc
  for x in ${train_set} ${test_set}; do
    steps/make_mfcc.sh --nj $njobs data/$x exp/make_mfcc/$x $mfccdir || exit 1;
    steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir || exit 1;
    utils/fix_data_dir.sh data/$x
    utils/validate_data_dir.sh data/$x
  done
  
  utils/subset_data_dir.sh data/${train_set} 4000 data/${train_set}_4k
fi

if [ $stage == 51 ]; then
  echo ============================================================================
  echo " PLP extraction "
  echo ============================================================================

  plpdir=plp
  for x in ${train_set} ${test_set}; do
    steps/make_plp.sh --nj $njobs data/$x exp/make_plp/$x $plpdir || exit 1;
    steps/compute_cmvn_stats.sh data/$x exp/make_plp/$x $plpdir || exit 1;
  done
  utils/subset_data_dir.sh data/${train_set} 4000 data/${train_set}4k
fi