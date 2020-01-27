#!/usr/bin/env bash
# (c) 2019 voicea <sylvainlg@voicea.ai>

ngram_order=4

rnnlm_dir=exp/rnnlm_lstm_tdnn_a
#rnnlm_dir=exp/rnnlm_lstm_tdnn_a_averaged


#lang_dir=data/lang_chain
# lang_dir=data/lang_nosp
# data_dir=data/
# source_dir=exp/tri3/decode_test

# vca data
#lang_dir=$BABEL/graphs/eval/mixpocolm_folded_3g/lang/
lang_dir=$BABEL/graphs/fisher_vca_rev_webex/mixpocolm_folded_3g/lang/
data_dir=$DATA/kaldi_sets/rdi/test_100_8k
source_dir=$ASPIRE/exp/tdnn_7b_chain_online/decode_test_100_8k_f_v_r_w

. ./utils/parse_options.sh

suffix=$(basename $rnnlm_dir)
output_dir=${source_dir}_$suffix

rnnlm/lmrescore_pruned.sh \
  --cmd "run.pl --mem 4G" \
  --weight 0.5 --max-ngram-order $ngram_order \
  $lang_dir $rnnlm_dir \
  $data_dir $source_dir \
  $output_dir
