#!/usr/bin/env bash
# (c) 2019 sylvainlg@voicea.ai

. path.sh

export KALDI_SLG=/home/workfit/Sylvain/kaldi-slg
export KALDI_SLG_ASPIRE=${KALDI_SLG}/egs/aspire/s5

# create dict
src_dict=${KALDI_SLG_ASPIRE}/data/local/dict #will be copied to output_dir/local

# create LM
lm=$KALDI_SLG_ASPIRE/data/local/lm/3gram-mincount/lm_unpruned.gz

# create Acoustic Model
model_dir=exp/nut-1120-big-conv-epoch10-rnn/model

# read speech hints and add to lexicon
speech_hints_list=local/speech_hints/speech_hints.txt
g2p_model_dir=$KALDI_SLG/tools/g2p/en_us/models
output_dir=/tmp/test

./local/speech_hints/generate_oov_lexicon.sh $speech_hints_list $g2p_model_dir $output_dir

# creates:
# - output_dir/local/{dict_basevocab, lang_tmp}: dict
# - output_dir/lang_{basevocab, extvocab}: L
# - output_dir/extvocab_top: HCLG

./local/speech_hints/make_generic_graph.sh $src_dict $lm $model_dir $output_dir

lang_base=$output_dir/lang_basevocab
lexicon=$model_dir/extvocab_lexicon/lexiconp.txt
lang_ext=$output_dir/lang_extvocab

# generates:
# - output_dir/lang_extvocab: L
# - outputdir/extvocab_part: HCLG
./local/speech_hints/make_extended_graph.sh $lang_base $model_dir $lexicon $output_dir

generic_graph=$output_dir/extvocab_top
extended_graph=$output_dir/extvocab_part
lang_ext=$output_dir/lang_extvocab
combined_graph=$output_dir/extvocab_combined

./local/speech_hints/combine_graphs.sh $generic_graph $extended_graph $lang_ext $combined_graph