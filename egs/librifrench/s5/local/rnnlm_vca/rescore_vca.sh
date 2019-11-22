#!/usr/bin/env bash
# (c) 2019 voicea <sylvainlg@voicea.ai>

ngram_order=4

rnnlm_dir=exp/rnnlm
lang_dir=data/lang_test_SRILM
data_dir=data/test
source_dir=exp/chain/cnn_tdnn1a76b_sp/decode_tgsmall_test

. ./utils/parse_options.sh

output_dir=${source_dir}_$(basename $rnnlm_dir)

./rnnlm/lmrescore_pruned.sh \
  --cmd "run.pl --mem 4G" \
  --weight 0.5 --max-ngram-order $ngram_order \
  $lang_dir $rnnlm_dir \
  $data_dir $source_dir \
  $output_dir


for x in ${source_dir}*; do
  #local/score.sh --decode_mbr true $data_dir $lang_dir $x
  [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh;
done

exit 0