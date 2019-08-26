#!/usr/bin/env bash

stage=0
run_g2p=false  # set this to true to run the g2p stuff, it's slow so
               # by default we fake it by providing what it previously output
set -e

. ./path.sh
. utils/parse_options.sh

tree_dir=exp/chain/tree_sp
lang_base=data/lang_base
lang_ext=data/lang_ext
mkdir -p $lang_ext
dict_base=data/local/dict_nosp
dict_base_nonterm=data/local/dict_base_nonterm
dict_new=$tree_dir/dict_new
lexicon_new=$tree_dir/lexicon_new
mkdir -p $lexicon_new

if [ $stage -eq 0 ]; then
  # generate L & words in data/lang_base
  cp -r $dict_base $dict_base_nonterm
  echo "#nonterm:unk" > $dict_base_nonterm/nonterminals.txt

  utils/prepare_lang.sh $dict_base \
       "<UNK>" data/local/lang_tmp_nosp $lang_base
fi

if [ $stage -eq 1 ]; then
  # create base G (removing nonterm at the output)
  nonterm_unk=$(grep '#nonterm:unk' $lang_base/words.txt | awk '{print $2}')
  gunzip -c  data/local/lm/lm_tgsmall.arpa.gz | \
    sed 's/<UNK>/#nonterm:unk/g' | \
    arpa2fst --disambig-symbol=#0 \
             --read-symbol-table=$lang_base/words.txt - | \
    fstrmsymbols --remove-from-output=true "echo $nonterm_unk|" - $lang_base/G.fst
fi

if [ $stage -eq 2 ]; then
  # make base HCLG graph with non-term trick
  utils/mkgraph.sh --self-loop-scale 1.0 $lang_base $tree_dir $tree_dir/graph_base
fi

if [ $stage -eq 3 ] && $run_g2p; then
  # train g2p model
  dict=data/local/dict_nosp_basevocab
  steps/dict/train_g2p.sh --silence-phones $dict/silence_phones.txt $dict/lexicon.txt  $tree_dir/extvocab_nosp_g2p
fi

if [ $stage -eq 4 ]; then
  # Create new dict-dir with new OOV just added
  mkdir -p $dict_new

  # Find list of words in the test set that are out of vocabulary.
  awk -v w=data/lang/words.txt 'BEGIN{while(getline <w) seen[$1] = $1} {for(n=2;n<=NF;n++) if(!($n in seen)) oov[$n] = 1}
                                END{ for(k in oov) print k;}' < data/dev_clean_2/text > $lexicon_new/words
  echo "$0: generating g2p entries for $(wc -l <$tree_dir/extvocab_nosp_lexicon/words) words"
  
  if $run_g2p; then
    steps/dict/apply_g2p.sh $tree_dir/extvocab_nosp_lexicon/words $tree_dir/extvocab_nosp_g2p  $tree_dir/extvocab_nosp_lexicon
  fi

  # extend_lang.sh needs it to have basename 'lexiconp.txt'.
  mv $tree_dir/extvocab_nosp_lexicon/lexicon.lex $tree_dir/extvocab_nosp_lexicon/lexiconp.txt

  [ -f data/lang_nosp_extvocab/G.fst ] && rm data/lang_nosp_extvocab/G.fst
  utils/lang/extend_lang.sh  data/lang_nosp_basevocab $tree_dir/extvocab_nosp_lexicon/lexiconp.txt  data/lang_nosp_extvocab
fi

if [ $stage -eq 5 ]; then
  # make the G.fst for the extra words. assign equal probabilities to all ofthem.
  cat <<EOF > $lang_ext/G.txt
0    1    #nonterm_begin <eps>
2    3    #nonterm_end <eps>
3
EOF
  lexicon=$tree_dir/extvocab_nosp_lexicon/lexiconp.txt
  num_words=$(wc -l <$lexicon)
  cost=$(perl -e "print log($num_words)");
  awk -v cost=$cost '{print 1, 2, $1, $1, cost}' <$lexicon >>$lang_ext/G.txt
  fstcompile --isymbols=$lang_ext/words.txt --osymbols=$lang_ext/words.txt <$lang_ext/G.txt | \
    fstarcsort --sort_type=ilabel >$lang_ext/G.fst
fi

if [ $stage -eq 6 ]; then
  # make the part of the graph that will be included.
  # Refer to the 'compile-graph' commands in ./simple_demo.sh for how you'd do
  # this in code.
  utils/mkgraph.sh --self-loop-scale 1.0 $lang_ext $tree_dir $tree_dir/extvocab_nosp_part
fi

if [ $stage -eq 7 ]; then
  offset=$(grep nonterm_bos $lang_ext/phones.txt | awk '{print $2}')
  nonterm_unk=$(grep nonterm:unk $lang_ext/phones.txt | awk '{print $2}')

  mkdir -p $tree_dir/extvocab_nosp_combined
  [ -d $tree_dir/extvocab_nosp_combined/phones ] && rm -r $tree_dir/extvocab_nosp_combined/phones
  # the decoding script expects words.txt and phones/, copy them from the extvocab_part
  # graph directory where they will have suitable values.
  cp -r $tree_dir/extvocab_nosp_part/{words.txt,phones.txt,phones/} $tree_dir/extvocab_nosp_combined

  # the following, due to --write-as-grammar=false, compiles it into an FST
  # which can be decoded by our normal decoder.
  make-grammar-fst --write-as-grammar=false --nonterm-phones-offset=$offset $tree_dir/extvocab_nosp_top/HCLG.fst \
                   $nonterm_unk $tree_dir/extvocab_nosp_part/HCLG.fst  $tree_dir/extvocab_nosp_combined/HCLG.fst

  # the following compiles it and writes as GrammarFst.  The size is 176M, vs. 182M for HCLG.fst.
  # In other examples, of course the difference might be more.

  make-grammar-fst --write-as-grammar=true --nonterm-phones-offset=$offset $tree_dir/extvocab_nosp_top/HCLG.fst \
                $nonterm_unk $tree_dir/extvocab_nosp_part/HCLG.fst  $tree_dir/extvocab_nosp_combined/HCLG.gra
fi


if [ $stage -eq 8 ]; then
  # OK, now we actually decode the test data.  For reference, the command which was used to
  # decode the test data in the current (at the time of writing) chain TDNN system
  # local/chain/run_tdnn.sh (as figured out by running it from that stage), was:
  # steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 --frames-per-chunk 140 --nj 38 \
  #   --cmd "queue.pl --mem 4G --num-threads 4" --online-ivector-dir exp/nnet3/ivectors_dev_clean_2_hires \
  #   exp/chain/tree_sp/graph_tgsmall data/dev_clean_2_hires exp/chain/tdnn1h_sp/decode_tgsmall_dev_clean_2

  # We just replace the graph with the one in $treedir/extvocab_nosp_combined.

  steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 --frames-per-chunk 140 --nj 38 \
    --cmd "queue.pl --mem 4G --num-threads 4" --online-ivector-dir exp/nnet3/ivectors_dev_clean_2_hires \
    exp/chain/tree_sp/extvocab_nosp_combined data/dev_clean_2_hires exp/chain/tdnn1h_sp/decode_tgsmall_dev_clean_2_ev_nosp_comb



#  grep WER exp/chain/tdnn1h_sp/decode_tgsmall_dev_clean_2_ev_nosp_comb/wer_* | utils/best_wer.sh
#%WER 11.79 [ 2375 / 20138, 195 ins, 343 del, 1837 sub ] exp/chain/tdnn1h_sp/decode_tgsmall_dev_clean_2_ev_nosp_comb/wer_12_0.0# s5: grep WER exp/chain/tdnn1h_sp/decode_tgsmall_dev_clean_2_ev_nosp_comb/wer_* | utils/best_wer.sh

 #.. versus the baseline below note, the baseline is not 100% comparable as it used the
 #   silence probabilities, which the grammar-decoding does not (yet) support...
 # s5: grep WER exp/chain/tdnn1h_sp/decode_tgsmall_dev_clean_2/wer_* | utils/best_wer.sh
 # %WER 12.01 [ 2418 / 20138, 244 ins, 307 del, 1867 sub ] exp/chain/tdnn1h_sp/decode_tgsmall_dev_clean_2/wer_13_0.0
fi

if [ $stage -eq 9 ]; then
  steps/nnet3/decode_grammar.sh --acwt 1.0 --post-decode-acwt 10.0 --frames-per-chunk 140 --nj 38 \
    --cmd "queue.pl --mem 4G --num-threads 4" --online-ivector-dir exp/nnet3/ivectors_dev_clean_2_hires \
    exp/chain/tree_sp/extvocab_nosp_combined data/dev_clean_2_hires exp/chain/tdnn1h_sp/decode_tgsmall_dev_clean_2_ev_nosp_comb_gra

  #  The WER when decoding with the grammar FST directly is exactly the same:
  # s5:  grep WER exp/chain/tdnn1h_sp/decode_tgsmall_dev_clean_2_ev_nosp_comb_gra/wer_* | utils/best_wer.sh
  # %WER 11.79 [ 2375 / 20138, 195 ins, 343 del, 1837 sub ] exp/chain/tdnn1h_sp/decode_tgsmall_dev_clean_2_ev_nosp_comb_gra/wer_12_0.0
fi
