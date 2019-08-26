#!/usr/bin/env bash
# (c) 2019 sylvainlg@voicea.ai

dict_dir=$1
lm_base=$2
model_dir=$3
output_dir=$4


lang_base=$output_dir/lang_basevocab
lang_ext=$output_dir/lang_extvocab
output_dir_local=$output_dir/local
mkdir -p $output_dir_local

cp -r $dict_dir $output_dir_local/dict_basevocab
echo "#nonterm:unk" > $output_dir_local/dict_basevocab/nonterminals.txt

utils/prepare_lang.sh data/local/dict_basevocab \
    "<unk>" $output_dir_local/lang_tmp $lang_base


nonterm_unk=$(grep '#nonterm:unk' $lang_base/words.txt | awk '{print $2}')

gunzip -c $lm_base | \
    sed 's/<unk>/#nonterm:unk/g' | \
    arpa2fst --disambig-symbol=#0 \
             --read-symbol-table=$lang_base/words.txt - | \
    fstrmsymbols --remove-from-output=true "echo $nonterm_unk|" - $lang_base/G.fst

utils/mkgraph.sh --self-loop-scale 1.0 $lang_base $model_dir $output_dir/extvocab_top