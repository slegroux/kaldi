#!/usr/bin/env bash
# (c) 2019 voicea <sylvainlg@voicea.ai>

. ./cmd.sh
. ./path.sh

#set -x

nj=10 # number of jobs
ndecode_jobs=10 # number of decoding jobs
num_gpu=1 # num of gpus to use in xvector extract
stage=1
score=false

#data_dir=$DATA/kaldi_sets/rdi/test_10_16k
model_dir=exp/nut-1120-big-conv-epoch10-rnn/model
#decode_dir=/tmp

#model_dir=exp/nut-webex-epoch10
#model_dir=exp/model
#graph_dir=$model_dir/graph
#graph_dir=$BABEL/graphs/fisher_vca_rev_webex/mixpocolm_folded_3g/graph_rdi_2nd
#graph_dir=$BABEL/graphs/f_v_r_w/mixpocolm_folded_3g/nut_webex_epoch10_graph
#graph_dir=$BABEL/graphs/f_v_r_w/mixpocolm_folded_3g/nut_1120_big_conv_epoch_10_graph
graph_dir=/tmp/test/extvocab_combined
#lang_tag=f_v_r_w
tag=ext

. utils/parse_options.sh

data_dir=$1

decodeDir=${model_dir}/decode_$(basename $data_dir)_${tag}

# fix data dir
if [ $stage -eq 1 ]; then
	utils/copy_data_dir.sh $data_dir ${data_dir}_hires
fi
utils/fix_data_dir.sh $data_dir
utils/fix_data_dir.sh ${data_dir}_hires

# ivector
#ivector_model=$DATA/kaldi_models/0007_voxceleb_v1_1a
iVectorExtractor=exp/nut-webex-epoch10/extractors/rdi.2019.03.26.ivector_extractor
#ivector_model=.
#iVectorExtractor=$ivector_model/exp/extractor
#iVectorExtractor=exp/ivector_extractor
iVectorDir=${data_dir}_hires/ivectors
#hires_conf=conf/mfcc_hires.conf
#ivector_mfcc_conf=$ivector_model/conf/mfcc.conf
ivector_mfcc_conf=conf/mfcc_hires.conf

# xvectors
xvector_model=$DATA/kaldi_models/0007_voxceleb_v2_1a
#xvector_model=$DATA/kaldi_models/0008_sitw_v2_1a
xVectorExtractor=$xvector_model/exp/xvector_nnet_1a
xVectorDir=$data_dir/xvectors

xvector_vad_conf=conf/vad.conf
xvector_mfcc_conf=conf/mfcc.conf

# directory to save ivectors and xvectors after being merged
newIVectorDir=$data_dir/new_ivectors

# extract features (mfcc_hires)
if [ $stage -eq 1 ]; then
	echo "[INFO] extract MFCC"
	steps/make_mfcc.sh --mfcc-config $ivector_mfcc_conf --nj $nj --cmd "run.pl" ${data_dir}_hires
	steps/compute_cmvn_stats.sh ${data_dir}_hires
	utils/fix_data_dir.sh ${data_dir}_hires 
	utils/validate_data_dir.sh ${data_dir}_hires
fi

# extract ivectors
if [ $stage -eq 2 ]; then
	echo "[INFO] extract ivectors"
	steps/online/nnet2/extract_ivectors_online.sh --cmd "run.pl" --nj $nj ${data_dir}_hires $iVectorExtractor $iVectorDir || exit 1;
fi

# extract features xvector
if [ $stage -eq 3 ]; then
	echo "[INFO] extract mfcc"
	steps/make_mfcc.sh --mfcc-config $xvector_mfcc_conf --nj $nj --cmd "run.pl" $data_dir
	utils/fix_data_dir.sh $data_dir
	utils/validate_data_dir.sh $data_dir
	steps/compute_cmvn_stats.sh $data_dir
fi

# extract xvectors
if [ $stage -eq 4 ]; then
	sid/compute_vad_decision.sh --vad_config $xvector_vad_conf --nj $nj --cmd "run.pl" $data_dir
	sid/nnet3/xvector/extract_xvectors.sh --use-gpu true --cmd "run.pl" --nj $num_gpu $xVectorExtractor $data_dir $xVectorDir
fi

# combine them by repeating the xvector for all frames then concat it with the corresponding ivector per frame
if [ $stage -eq 5 ]; then
	mkdir -p $newIVectorDir
	append-vector-to-feats scp:$iVectorDir/ivector_online.scp \
						   scp:$xVectorDir/xvector.scp \
						   ark,scp:$newIVectorDir/ivectors.ark,$newIVectorDir/ivector_online.scp
	echo 10 > $newIVectorDir/ivector_period
fi

# decode
if [ $stage -eq 6 ]; then
	frames_per_chunk=140
	steps/nnet3/decode.sh \
        --acwt 1.0 --post-decode-acwt 10.0 \
        --frames-per-chunk $frames_per_chunk \
        --nj $nj --cmd "run.pl" \
		--skip-scoring true \
        --max-active 10000 --beam 18.0 \
        --lattice-beam 8.0 \
        --online-ivector-dir $newIVectorDir \
        --scoring-opts "--word_ins_penalty -1 --min_lmwt 13 --max_lmwt 13" \
        $graph_dir ${data_dir}_hires $decodeDir
fi

if [ "$score" = true ]; then
	echo "[INFO] score using sclite"
	$ASPIRE/score.sh $decodeDir
fi


# cleanup
# echo "[INFO] cleanup"
# rm -rf $data_dir/data
# rm -rf $data_dir/new_ivectors
# rm -rf $data_dir/xvectors
# rm -rf $data_dir/log
# rm -rf $data_dir/split*
# rm cmvn.scp
