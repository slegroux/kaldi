#!/usr/bin/env bash

export KALDI_SLG=/home/workfit/Sylvain/kaldi-slg
export KALDI_SLG_ASPIRE=${KALDI_SLG}/egs/aspire/s5
test_data=$DATA/kaldi_sets/rdi/test_1000_16k

stage=0
run_g2p=false  
set -e

. ./path.sh
. utils/parse_options.sh

model=exp/nut-1120-big-conv-epoch10-rnn/model
tree_dir=$model
lang_base=data/lang_basevocab
lang_ext=data/lang_extvocab


if [ $stage -eq 0 ]; then
  cp -r ${KALDI_SLG_ASPIRE}/data/local/dict data/local/dict_basevocab
  echo "#nonterm:unk" > data/local/dict_basevocab/nonterminals.txt

  utils/prepare_lang.sh data/local/dict_basevocab \
       "<unk>" data/local/lang_tmp $lang_base
fi

if [ $stage -eq 100 ]; then
  rm -rf data/local/dict
  cp -r ${KALDI_SLG_ASPIRE}/data/local/dict data/local/dict
  
  utils/prepare_lang.sh data/local/dict \
       "<unk>" data/local/lang_tmp data/lang
  
  lm_base_dir=$KALDI_SLG_ASPIRE/data/local/lm/3gram-mincount/lm_unpruned.gz
  
  gunzip -c $lm_base_dir | \
    arpa2fst --disambig-symbol=#0 \
             --read-symbol-table=data/lang/words.txt - data/lang/G.fst
  
  utils/mkgraph.sh --self-loop-scale 1.0 data/lang $tree_dir $tree_dir/default
fi



if [ $stage -eq 1 ]; then
  # original lm_dir: data/local/lm/lm_tgsmall.arpa.gz
  # get base lm from aspire
  
  lm_base_dir=$KALDI_SLG_ASPIRE/data/local/lm/3gram-mincount/lm_unpruned.gz
  nonterm_unk=$(grep '#nonterm:unk' $lang_base/words.txt | awk '{print $2}')

  gunzip -c $lm_base_dir | \
    sed 's/<unk>/#nonterm:unk/g' | \
    arpa2fst --disambig-symbol=#0 \
             --read-symbol-table=$lang_base/words.txt - | \
    fstrmsymbols --remove-from-output=true "echo $nonterm_unk|" - $lang_base/G.fst
fi


if [ $stage -eq 2 ]; then
  
  utils/mkgraph.sh --self-loop-scale 1.0 $lang_base $tree_dir $tree_dir/extvocab_top
fi



if [ $stage -eq 3 ] && $run_g2p; then
  
  dict=data/local/dict_basevocab
  steps/dict/train_g2p.sh --silence-phones $dict/silence_phones.txt $dict/lexicon.txt  $tree_dir/extvocab_g2p
fi


if [ $stage -eq 4 ]; then

  g2p_model_dir='/home/workfit/Sylvain/kaldi-slg/tools/g2p/en_us/models'
  g2p_model='order-9'
  mkdir -p $tree_dir/extvocab_lexicon
  awk -v w=$lang_base/words.txt 'BEGIN{while(getline <w) seen[$1] = $1} {for(n=2;n<=NF;n++) if(!($n in seen)) oov[$n] = 1}
                                END{ for(k in oov) print k;}' < $test_data/text > $tree_dir/extvocab_lexicon/words
  # get rid of words starting or ending with -
  cat $tree_dir/extvocab_lexicon/words |grep -v '\-$'|grep -v '^-' >/tmp/words; mv /tmp/words $tree_dir/extvocab_lexicon/words

  echo "$0: generating g2p entries for $(wc -l <$tree_dir/extvocab_lexicon/words) words"


  if $run_g2p; then
    #steps/dict/apply_g2p.sh $tree_dir/extvocab_lexicon/words $tree_dir  $tree_dir/extvocab_lexicon
    steps/dict/apply_g2p.sh --model 'order-9' $tree_dir/extvocab_lexicon/words $g2p_model_dir $tree_dir/extvocab_lexicon
  fi

  cat $tree_dir/extvocab_lexicon/lexicon.lex | tr '[:upper:]' '[:lower:]' >/tmp/lexicon.lex; mv /tmp/lexicon.lex $tree_dir/extvocab_lexicon/lexicon.lex
  cp $tree_dir/extvocab_lexicon/lexicon.lex $tree_dir/extvocab_lexicon/lexiconp.txt

  [ -f data/lang_extvocab/G.fst ] && rm data/lang_extvocab/G.fst
  utils/lang/extend_lang.sh  $lang_base $tree_dir/extvocab_lexicon/lexiconp.txt $lang_ext
fi


if [ $stage -eq 5 ]; then
 
  cat <<EOF > $lang_ext/G.txt
0    1    #nonterm_begin <eps>
2    3    #nonterm_end <eps>
3
EOF
  lexicon=$tree_dir/extvocab_lexicon/lexiconp.txt
  num_words=$(wc -l <$lexicon)
  cost=$(perl -e "print log($num_words)");
  awk -v cost=$cost '{print 1, 2, $1, $1, cost}' <$lexicon >>$lang_ext/G.txt
  fstcompile --isymbols=$lang_ext/words.txt --osymbols=$lang_ext/words.txt <$lang_ext/G.txt | \
    fstarcsort --sort_type=ilabel >$lang_ext/G.fst
fi


if [ $stage -eq 6 ]; then

  utils/mkgraph.sh --self-loop-scale 1.0 $lang_ext $tree_dir $tree_dir/extvocab_part
fi


if [ $stage -eq 7 ]; then
  offset=$(grep nonterm_bos $lang_ext/phones.txt | awk '{print $2}')
  nonterm_unk=$(grep nonterm:unk $lang_ext/phones.txt | awk '{print $2}')

  mkdir -p $tree_dir/extvocab_combined
  [ -d $tree_dir/extvocab_combined/phones ] && rm -r $tree_dir/extvocab_combined/phones
  
  cp -r $tree_dir/extvocab_part/{words.txt,phones.txt,phones/} $tree_dir/extvocab_combined


  make-grammar-fst --write-as-grammar=false --nonterm-phones-offset=$offset $tree_dir/extvocab_top/HCLG.fst \
                   $nonterm_unk $tree_dir/extvocab_part/HCLG.fst  $tree_dir/extvocab_combined/HCLG.fst


  # make-grammar-fst --write-as-grammar=true --nonterm-phones-offset=$offset $tree_dir/extvocab_top/HCLG.fst \
  #               $nonterm_unk $tree_dir/extvocab_part/HCLG.fst  $tree_dir/extvocab_combined/HCLG.gra
fi


if [ $stage -eq 8 ]; then
  model_dir=exp/nut-1120-big-conv-epoch10-rnn/model
  #graph_dir=$model_dir/extvocab_top
  #graph_dir=$BABEL/graphs/f_v_r_w/mixpocolm_folded_3g/nut_1120_big_conv_epoch_10_graph
  lang_tag=extvocab_combined
  graph_dir=$model_dir/$lang_tag
  dataset=$test_data
  decode_dir=$model_dir/decode_$(basename $dataset)_${lang_tag}

  rm -rf $decode_dir

  nj=10
  ./decode_vca.sh \
    --graph_dir $graph_dir \
    --lang_tag $lang_tag \
    --nj $nj \
    $dataset

  grep WER $decode_dir/wer_* | utils/best_wer.sh
  trn=$(cat $decode_dir/scoring/log/best_path.13.-1.log |grep -v LOG|grep -v '\#' |grep -v 'lattice-')
  grep -f $tree_dir/extvocab_lexicon/words <($(trn))
  

fi


if [ $stage -eq 9 ]; then
  model_dir=exp/nut-1120-big-conv-epoch10-rnn/model
  #graph_dir=$model_dir/extvocab_top
  #graph_dir=$BABEL/graphs/f_v_r_w/mixpocolm_folded_3g/nut_1120_big_conv_epoch_10_graph
  lang_tag=default
  graph_dir=$model_dir/$lang_tag
  dataset=$test_data

  rm -rf $model_dir/decode_$(basename $dataset)_${lang_tag}

  nj=10
  ./decode_vca.sh \
    --graph_dir $graph_dir \
    --lang_tag $lang_tag \
    --nj $nj \
    $dataset

  grep WER $model_dir/decode_$(basename $dataset)_${lang_tag}/wer_* | utils/best_wer.sh

fi
