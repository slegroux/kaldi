#!/usr/bin/env bash

stage=0
run_g2p=false  
set -e

. ./path.sh
. utils/parse_options.sh


tree_dir=/home/workfit/Sylvain/Data/kaldi_models/aspire/exp/chain/tdnn_7b
lang_base=data/lang_basevocab
lang_ext=data/lang_extvocab


if [ $stage -eq 0 ]; then
  cp -r data/local/dict data/local/dict_basevocab
  echo "#nonterm:unk" > data/local/dict_basevocab/nonterminals.txt

  utils/prepare_lang.sh data/local/dict_basevocab \
       "<unk>" data/local/lang_tmp $lang_base
fi

if [ $stage -eq 1 ]; then
  
  nonterm_unk=$(grep '#nonterm:unk' $lang_base/words.txt | awk '{print $2}')

  gunzip -c  data/local/lm/3gram-mincount/lm_unpruned.gz | \
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

  mkdir -p $tree_dir/extvocab_lexicon
  awk -v w=data/lang/words.txt 'BEGIN{while(getline <w) seen[$1] = $1} {for(n=2;n<=NF;n++) if(!($n in seen)) oov[$n] = 1}
                                END{ for(k in oov) print k;}' < data/dev_clean_2/text > $tree_dir/extvocab_lexicon/words
  echo "$0: generating g2p entries for $(wc -l <$tree_dir/extvocab_lexicon/words) words"

  if $run_g2p; then
    steps/dict/apply_g2p.sh $tree_dir/extvocab_lexicon/words $tree_dir  $tree_dir/extvocab_lexicon
  else
    cat <<EOF >$tree_dir/extvocab_lexicon//lexicon.lex
HARDWIGG	0.962436	HH AA1 R D W IH1 G
SUDVESTR	0.162048	S AH1 D V EY1 S T R
SUDVESTR	0.133349	S AH1 D V EH1 S T R
SUDVESTR	0.114376	S AH1 D V EH1 S T ER0
VINOS	0.558345	V IY1 N OW0 Z
VINOS	0.068883	V AY1 N OW0 Z
VINOS	0.068431	V IY1 N OW0 S
DOMA	0.645714	D OW1 M AH0
DOMA	0.118255	D UW1 M AH0
DOMA	0.080682	D OW0 M AH0
GWYNPLAINE'S	0.983053	G W IH1 N P L EY1 N Z
SHIMERDA	0.610922	SH IH0 M EH1 R D AH0
SHIMERDA	0.175678	SH IY0 M EH1 R D AH0
SHIMERDA	0.069785	SH AY1 M ER1 D AH0
MYRDALS	0.479183	M IH1 R D AH0 L Z
MYRDALS	0.135225	M ER1 D AH0 L Z
MYRDALS	0.115478	M IH1 R D L Z
HEUCHERA	0.650042	HH OY1 K IH1 R AH0
HEUCHERA	0.119363	HH OY1 K EH1 R AH0
HEUCHERA	0.077907	HH OY1 K ER0 AH0
IMPARA	0.906222	IH0 M P AA1 R AH0
VERLOC'S	0.564847	V ER0 L AA1 K S
VERLOC'S	0.173540	V ER1 L AH0 K S
VERLOC'S	0.050543	V ER1 L AA1 K S
UNTRUSSING	0.998019	AH0 N T R AH1 S IH0 NG
DARFHULVA	0.317057	D AA2 F UH1 L V AH0
DARFHULVA	0.262882	D AA2 F HH UH1 L V AH0
DARFHULVA	0.064055	D AA2 F HH UW1 L V AH0
FINNACTA	0.594586	F IH1 N AH0 K T AH0
FINNACTA	0.232454	F IH1 N AE1 K T AH0
FINNACTA	0.044733	F IH1 N IH0 K T AH0
YOKUL	0.845279	Y OW1 K AH0 L
YOKUL	0.051082	Y OW2 K AH0 L
YOKUL	0.029435	Y OW0 K AH0 L
CONGAL	0.504228	K AA1 NG G AH0 L
CONGAL	0.151648	K AA2 NG G AH0 L
CONGAL	0.137837	K AH0 N JH AH0 L
DELECTASTI	0.632180	D IH0 L EH0 K T EY1 S T IY0
DELECTASTI	0.203808	D IH0 L EH1 K T EY1 S T IY0
DELECTASTI	0.066722	D IH0 L EH0 K T AE1 S T IY0
YUNDT	0.975077	Y AH1 N T
QUINCI	0.426115	K W IH1 N S IY0
QUINCI	0.369324	K W IH1 N CH IY0
QUINCI	0.064507	K W IY0 N CH IY0
BIRDIKINS	0.856979	B ER1 D IH0 K AH0 N Z
BIRDIKINS	0.045315	B ER1 D AH0 K AH0 N Z
SNEFFELS	0.928413	S N EH1 F AH0 L Z
FJORDUNGR	0.130629	F Y AO1 R D UW0 NG G R
FJORDUNGR	0.125082	F Y AO1 R D AH0 NG G R
FJORDUNGR	0.111035	F Y AO1 R D UH1 NG R
YULKA	0.540253	Y UW1 L K AH0
YULKA	0.295588	Y AH1 L K AH0
YULKA	0.076631	Y UH1 L K AH0
LACQUEY'S	0.987908	L AE1 K IY0 Z
OSSIPON'S	0.651400	AA1 S AH0 P AA2 N Z
OSSIPON'S	0.118444	AA1 S AH0 P AA0 N Z
OSSIPON'S	0.106377	AA1 S AH0 P AH0 N Z
SAKNUSSEMM	0.060270	S AE1 K N AH1 S EH1 M
SAKNUSSEMM	0.044992	S AE1 K N AH0 S EH1 M
SAKNUSSEMM	0.044084	S AA0 K N AH1 S EH1 M
CONGAL'S	0.618287	K AA1 NG G AH0 L Z
CONGAL'S	0.185952	K AA2 NG G AH0 L Z
CONGAL'S	0.115143	K AH0 N G AH0 L Z
TARRINZEAU	0.159153	T AA1 R IY0 N Z OW1
TARRINZEAU	0.136536	T AA1 R AH0 N Z OW1
TARRINZEAU	0.100924	T EH1 R IY0 N Z OW1
SHIMERDAS	0.230819	SH IH0 M EH1 R D AH0 Z
SHIMERDAS	0.216235	SH IH0 M EH1 R D AH0 S
SHIMERDAS	0.073311	SH AY1 M ER1 D AH0 Z
RUGGEDO'S	0.821285	R UW0 JH EY1 D OW0 Z
RUGGEDO'S	0.166825	R AH1 G AH0 D OW0 Z
CORNCAKES	0.934118	K AO1 R N K EY2 K S
VENDHYA	0.616662	V EH0 N D Y AH0
VENDHYA	0.178349	V EH1 N D Y AH0
VENDHYA	0.160768	V AA1 N D Y AH0
GINGLE	0.919815	G IH1 NG G AH0 L
STUPIRTI	0.422653	S T UW0 P IH1 R T IY0
STUPIRTI	0.126925	S T UW1 P IH0 R T IY0
STUPIRTI	0.078422	S T UW1 P AH0 R T IY0
HERBIVORE	0.950887	HH ER1 B IH0 V AO2 R
BRION'S	0.838326	B R AY1 AH0 N Z
BRION'S	0.140310	B R IY0 AH0 N Z
DELAUNAY'S	0.993259	D EH1 L AO0 N EY0 Z
KHOSALA	0.920908	K OW0 S AA1 L AH0
BRANDD	0.827461	B R AE1 N D
BRANDD	0.085646	B R AE2 N D
GARDAR	0.598675	G AA0 R D AA1 R
GARDAR	0.289831	G AA1 R D AA2 R
GARDAR	0.057983	G AA0 R D AA2 R
MACKLEWAIN	0.570209	M AE1 K AH0 L W EY0 N
MACKLEWAIN	0.101477	M AH0 K AH0 L W EY0 N
MACKLEWAIN	0.067905	M AE1 K AH0 L W EY2 N
LIBANO	0.993297	L IY0 B AA1 N OW0
MOLING	0.782578	M OW1 L IH0 NG
MOLING	0.059362	M OW2 L IH0 NG
MOLING	0.056217	M AA1 L IH0 NG
BENNYDECK'S	0.583859	B EH1 N IY0 D EH0 K S
BENNYDECK'S	0.276699	B EH1 N IH0 D EH0 K S
BENNYDECK'S	0.028343	B EH1 N IH0 D IH0 K S
MACKLEWAIN'S	0.615766	M AE1 K AH0 L W EY0 N Z
MACKLEWAIN'S	0.109585	M AH0 K AH0 L W EY0 N Z
MACKLEWAIN'S	0.039423	M AE1 K AH0 L W AH0 N Z
PRESTY	0.616071	P R EH1 S T IY0
PRESTY	0.288701	P R AH0 S T IY0
BREADHOUSE	0.995874	B R EH1 D HH AW2 S
BUZZER'S	0.992495	B AH1 Z ER0 Z
BHUNDA	0.502439	B UW1 N D AH0
BHUNDA	0.267733	B AH0 N D AH0
BHUNDA	0.193772	B UH1 N D AH0
PINKIES	0.998440	P IH1 NG K IY0 Z
TROKE	0.723320	T R OW1 K
TROKE	0.269707	T R OW2 K
OSSIPON	0.728486	AA1 S AH0 P AA2 N
OSSIPON	0.098752	AA1 S AH0 P AH0 N
OSSIPON	0.033957	AA1 S AH0 P AO0 N
RIVERLIKE	0.991731	R IH1 V ER0 L AY2 K
NICLESS	0.478183	N IH1 K L AH0 S
NICLESS	0.159889	N IH0 K L AH0 S
NICLESS	0.120611	N IH1 K L IH0 S
TRAMPE	0.959184	T R AE1 M P
VERLOC	0.610461	V ER0 L AA1 K
VERLOC	0.128479	V ER1 L AH0 K
VERLOC	0.073687	V ER1 L AA0 K
GANNY	0.991703	G AE1 N IY0
AMBROSCH	0.302906	AE0 M B R OW1 SH
AMBROSCH	0.201163	AE0 M B R AO1 SH
AMBROSCH	0.109274	AE1 M B R AO1 SH
FIBI	0.619154	F IH1 B IY0
FIBI	0.163168	F IY1 B IY0
FIBI	0.083443	F AY1 B IY0
IROLG	0.823123	IH0 R OW1 L G
IROLG	0.053196	IH0 R OW1 L JH
IROLG	0.021038	IH0 R OW1 L JH IY1
BALVASTRO	0.251546	B AA0 L V AA1 S T R OW0
BALVASTRO	0.213351	B AE0 L V AE1 S T R OW0
BALVASTRO	0.133005	B AA0 L V AE1 S T R OW0
BOOLOOROO	0.676757	B UW1 L UW1 R UW0
BOOLOOROO	0.173653	B UW1 L UH2 R UW0
BOOLOOROO	0.086501	B UW1 L UH0 R UW0
EOF
  fi


  cp $tree_dir/extvocab_lexicon/lexicon.lex $tree_dir/extvocab_lexicon/lexiconp.txt

  [ -f data/lang_extvocab/G.fst ] && rm data/lang_extvocab/G.fst
  utils/lang/extend_lang.sh  data/lang_basevocab $tree_dir/extvocab_lexicon/lexiconp.txt  data/lang_extvocab
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



  make-grammar-fst --write-as-grammar=true --nonterm-phones-offset=$offset $tree_dir/extvocab_top/HCLG.fst \
                $nonterm_unk $tree_dir/extvocab_part/HCLG.fst  $tree_dir/extvocab_combined/HCLG.gra
fi


if [ $stage -eq 8 ]; then


  steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 --frames-per-chunk 140 --nj 38 \
    --cmd "run.pl --mem 4G --num-threads 4" --online-ivector-dir exp/nnet3/ivectors_dev_clean_2_hires \
    exp/chain/tree_sp/extvocab_combined data/dev_clean_2_hires exp/chain/tdnn1i_sp/decode_tgsmall_dev_clean_2_ev_comb

  grep WER exp/chain/tdnn1i_sp/decode_tgsmall_dev_clean_2_ev_comb/wer_* | utils/best_wer.sh
  # %WER 10.35 [ 2300 / 20138, 227 ins, 275 del, 1798 sub ] exp/chain/tdnn1i_sp/decode_tgsmall_dev_clean_2_ev_comb/wer_12_0.0

  #.. versus the baseline below:
  grep WER exp/chain/tdnn1i_sp/decode_tgsmall_dev_clean_2/wer_* | utils/best_wer.sh
  # %WER 10.81 [ 2418 / 20138, 244 ins, 307 del, 1867 sub ] exp/chain/tdnn1i_sp/decode_tgsmall_dev_clean_2/wer_13_0.0
fi

if [ $stage -eq 9 ]; then
 steps/nnet3/decode_grammar.sh --acwt 1.0 --post-decode-acwt 10.0 --frames-per-chunk 140 --nj 38 \
    --cmd "run.pl --mem 4G --num-threads 4" --online-ivector-dir exp/nnet3/ivectors_dev_clean_2_hires \
    exp/chain/tree_sp/extvocab_combined data/dev_clean_2_hires exp/chain/tdnn1i_sp/decode_tgsmall_dev_clean_2_ev_comb_gra

 # WER with grammar decoding is exactly the same as decoding from the converted FST.
 grep WER exp/chain/tdnn1i_sp/decode_tgsmall_dev_clean_2_ev_comb_gra/wer_* | utils/best_wer.sh
 # %WER 10.5 [ 2300 / 20138, 227 ins, 275 del, 1798 sub ] exp/chain/tdnn1i_sp/decode_tgsmall_dev_clean_2_ev_comb_gra/wer_12_0.0
fi
