#!/usr/bin/env bash
# (c) 2019 voicea <sylvainlg@voicea.ai>

ngram_order=4

ami_dir=$KALDI_ASR/egs/ami/s5b
# f_v / eval 
#rnnlm_dir=exp/rnnlm_lstm_tdnn_a
#rnnlm_dir=exp/rnnlm_lstm_tdnn_f_v_r_w
# rnnlm_dir=exp/rnnlm_fvrwtl_averaged
#rnnlm_dir=exp/rnnlm_fvrwtl
rnnlm_dir=$ami_dir/exp/rnnlm_ami

# aspire f_v_r_w setup
# lang_dir=$BABEL/graphs/fisher_vca_rev_webex/mixpocolm_folded_3g/lang/
# data_dir=$DATA/kaldi_sets/rdi/test_100_8k
# source_dir=$ASPIRE/exp/tdnn_7b_chain_online/decode_test_100_8k_3g_f_v_r_w

# RDI f_v_r_w setup
# lang_dir=$BABEL/graphs/fisher_vca_rev_webex/mixpocolm_folded_3g/lang/
# data_dir=$DATA/kaldi_sets/rdi/test_10_16k
# source_dir=$RDI/exp/model/decode_test_10_16k_f_v

# eval setup aspire
#lang_dir=$BABEL/graphs/eval/mixpocolm_folded_3g/lang/
#lang_dir=$BABEL/graphs/fisher_vca_rev_webex/mixpocolm_folded_3g/from_s3/lang
#lang_dir=$BABEL/graphs/f_v_r_w/mixpocolm_folded_3g/lang
lang_dir=$ami_dir/data/lang_ami_fsh.o3g.kn.pr1-7
#lang_dir=$BABEL/graphs/051019_fvrw/lang
#data_dir=$DATA/kaldi_sets/rdi/test_1000_16k
data_dir=$ami_dir/ihm/eval
# data_dir=$DATA/webex/webex_10_16k
#source_dir=$RDI/exp/model/decode_webex_10_8k_f_v_r_w_latest
#source_dir=$RDI/exp/model/decode_test_100_16k_f_v_r_w_latest
#source_dir=$RDI/exp/nut-webex-epoch10/decode_test_1000_16k_f_v_r_w_latest_vox2
#source_dir=$RDI/exp/nut-1120-big-conv-epoch10-rnn/model/decode_test_1000_16k_f_v_w_r_latest
source_dir=$ami_dir/exp/ihm/chain_cleaned/tdnn1i_sp_bi/decode_eval
#source_dir=$RDI/exp/nut-1120-big-conv-epoch10-rnn/model/decode_test_1000_16k_nut_1120_vox2

#lang_dir=$RDI/exp/nut-1120-big-conv-epoch10-rnn/lang
# source_dir=$ASPIRE/exp/tdnn_7b_chain_online/decode_test_10_8k_3g-eval
#source_dir=$ASPIRE/exp/tdnn_7b_chain_online/decode_test_1000_8k_f_v_r_w_latest
# source_dir=$RDI/exp/model/decode_test_10_16k_f_v

. ./utils/parse_options.sh

suffix=$(basename $rnnlm_dir)
output_dir=${source_dir}_$suffix

./rnnlm/lmrescore_pruned.sh \
  --cmd "run.pl --mem 4G" \
  --weight 0.5 --max-ngram-order $ngram_order \
  $lang_dir $rnnlm_dir \
  $data_dir $source_dir \
  $output_dir


for i in ${source_dir}*; do
  $ASPIRE/score.sh $i
done
