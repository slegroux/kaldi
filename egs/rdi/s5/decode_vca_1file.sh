#!/usr/bin/env bash

#model_dir=exp/nut-1120-big-conv-epoch10-rnn2/model
#graph_dir=/tmp/test/extvocab_combined/
model_dir=/Users/syl20/Data/models/en/nut-1120-big-conv-epoch10-rnn2/model
graph_dir=/Users/syl20/Data/models/en/nut-1120-big-conv-epoch10-rnn2-pruned1M/graph
#tag=ext
tag='pruned'


. utils/parse_options.sh

set -x
audio_file=$1

data_path=$(./audiofile2specifiers.sh $audio_file)

./decode_vca.sh --nj 1 --model_dir $model_dir --graph_dir $graph_dir --tag $tag $data_path
decode_dir=${model_dir}/decode_$(basename $data_path)_${tag}
utt=$(basename $audio_file .wav)
cat $decode_dir/log/decode.1.log |grep ^$utt
