#!/usr/bin/env bash

# Set -e here so that we catch if any executable fails immediately
set -euo pipefail
#set -x

stage=15

data=test
lang=lang_chain
decode_dir=

echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh


nspeakers=$(cat data/test/spk2utt| wc -l)

decode_dir_mbr=$decode_dir.mbr

if [ $stage -eq 15 ]; then
  cp -r $decode_dir{,.mbr}
  local/score_mbr.sh data/$data data/$lang $decode_dir_mbr
  for x in $decode_dir_mbr; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
fi