#!/usr/bin/env bash

./decode_offline.sh \
    --njobs 10 \
    --offline_config $ASPIRE/conf/decode.config \
    --mfcc_conf $ASPIRE/conf/mfcc_hires.conf \
    --ivector_extractor $ASPIRE/exp/nnet3/extractor \
    $ASPIRE/exp/tdnn_7b_chain_online/graph_pp \
    $ASPIRE/exp/chain/tdnn_7b/ \
    $DATA/kaldi_sets/rdi/test_10_8k