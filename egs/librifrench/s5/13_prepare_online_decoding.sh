#!/usr/bin/env bash

mfcc_conf=conf/mfcc_hires.conf
cmvn_conf=conf/online_cmvn.conf
lang=data/lang_test_IRSTLM
extractor=exp/nnet3_online_cmn/extractor
model=exp/chain/cnn_tdnn1a76b_sp
online_model=exp/chain/cnn_tdnn1a76b_sp_online
data_test=test

# steps/online/nnet3/prepare_online_decoding.sh \
#     --mfcc-config $mfcc_conf \
#     --online-cmvn-config $cmvn_conf \
#     $lang $extractor $model $online_model


# utils/mkgraph.sh \
#     --self-loop-scale 1.0 \
#     $lang $online_model $online_model/graph

nspk=$(wc -l <data/${data_test}_hires/spk2utt)
steps/online/nnet3/decode.sh \
    --acwt 1.0 --post-decode-acwt 10.0 \
    --nj $nspk --cmd "run.pl" \
    exp/chain_online_cmn/tree_sp/graph_tgsmall data/${data_test}_hires $online_model/decode_${data_test}_hires || exit 1

for x in $online_model/decode_${data_test}; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done