#!/usr/bin/env bash
# (c) 2019 sylvainlg@voicea.ai

lang_base=$1
model_dir=$2
lexicon=$3
output_dir=$4

lang_ext=$output_dir/lang_extvocab
utils/lang/extend_lang.sh $lang_base $lexicon $lang_ext
cat <<EOF > $lang_ext/G.txt
0    1    #nonterm_begin <eps>
2    3    #nonterm_end <eps>
3
EOF

num_words=$(wc -l <$lexicon)
cost=$(perl -e "print log($num_words)");
awk -v cost=$cost '{print 1, 2, $1, $1, cost}' <$lexicon >>$lang_ext/G.txt
fstcompile --isymbols=$lang_ext/words.txt --osymbols=$lang_ext/words.txt <$lang_ext/G.txt | \
    fstarcsort --sort_type=ilabel >$lang_ext/G.fst

utils/mkgraph.sh --self-loop-scale 1.0 $lang_ext $model_dir $output_dir/extvocab_part