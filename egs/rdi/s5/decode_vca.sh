#!/usr/bin/env bash
# (c) 2019 sylvainlg@voicea.ai

nj=10
#graph_dir=exp/model/graph
#model_dir=exp/nut-webex-epoch10
#graph_dir=$BABEL/graphs/f_v_r_w/mixpocolm_folded_3g/nut_webex_epoch10_graph
model_dir=exp/nut-1120-big-conv-epoch10-rnn2/model
#decode_dir=/tmp/decode_vca_ext
#graph_dir=$BABEL/graphs/f_v_r_w/mixpocolm_folded_3g/nut_1120_big_conv_epoch_10_graph
# graph_dir=$model_dir/graph
# graph_dir=$BABEL/graphs/051019_fvrw/nut1120
graph_dir=/tmp/test/extvocab_combined/
tag=ext

step=6
i=0
. utils/parse_options.sh

dev_data=$1

for i in $(seq $step); do
  ./runNut.sh --model_dir $model_dir --graph_dir $graph_dir --tag $tag \
    --stage $i --nj $nj --ndecode_jobs $nj $dev_data
done



