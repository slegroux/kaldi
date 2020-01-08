#!/usr/bin/env bash

set -e

stage=0

# Augmentation options
aug_list="reverb babble music noise clean" # Original train dir is referred to as `clean`
num_reverb_copies=1
use_ivectors=false
train_set=train
clean_ali=tri3b_ali


# End configuration section.
echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh


# First creates augmented data and then extracts features for it data
# The script also creates alignments for aug data by copying clean alignments
local/nnet3/run_aug_common.sh --stage $stage \
  --aug-list "$aug_list" --num-reverb-copies $num_reverb_copies \
  --use-ivectors "$use_ivectors" \
  --train-set $train_set --clean-ali $clean_ali || exit 1;