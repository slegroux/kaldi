#!/usr/bin/env bash

# Set -e here so that we catch if any executable fails immediately
set -euo pipefail
set -x

stage=15
affix=1k
nnet3_affix=_online_cmn
data=test
lang=lang_chain

echo "$0 $@"  # Print the command line for logging

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh

if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

nspeakers=$(cat data/test/spk2utt| wc -l)

dir=exp/chain${nnet3_affix}/tdnn${affix}_sp
decode_dir=${dir}/decode_tgsmall_${data}
decode_dir_mbr=$decode_dir.mbr



if [ $stage -eq 15 ]; then
  cp -r $decode_dir{,.mbr}
  local/score_mbr.sh data/$data data/$lang $decode_dir_mbr
  for x in $decode_dir_mbr; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
fi