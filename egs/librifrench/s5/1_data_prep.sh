#!/bin/bash


data='/home/workfit/Sylvain/Data/Librifrench' # Set this to directory where you put the data
adapt=false # Set this to true if you want to make the data as the vocabulary file,
	    # example: dès que (original text) => dès_que (vocabulary word)
liaison=true # Set this to true if you want to makes lexicon while taking into account liaison for French language
stage=0
data_train=train
data_test=test


. ./path.sh
. utils/parse_options.sh


if [ $stage == 0 ]; then
  echo "Preparing data as Kaldi data directories"
  for part in {$data_train,$data_test}; do
    local/data_prep.sh --apply_adaptation $adapt $data/$part data/$part
  done
fi


if [ $stage == 1 ]; then
  ## Optional G2P training scripts.
  #local/g2p/train_g2p.sh lexicon conf
  echo "Preparing dictionary"
  local/dic_prep.sh lexicon conf/model-2
fi


if [ $stage == 2 ]; then
  echo "Preparing language model"
  local/lm_prep.sh --order 3 --lm_system IRSTLM
  local/lm_prep.sh --order 3 --lm_system SRILM
  ## Optional Perplexity of the built models
  # local/compute_perplexity.sh --order 3 --text data/test test IRSTLM
  # local/compute_perplexity.sh --order 3 --text data/test test SRILM
fi


if [ $stage == 3 ]; then
  echo "Prepare data/lang and data/local/lang directories"
  [ $liaison == false ] && echo "No liaison is applied" && \
  utils/prepare_lang.sh --position-dependent-phones true data/local/dict "!SIL" data/local/lang data/lang
  [ $liaison == true ] && echo "Liaison is applied in the creation of lang directories" && \
  local/language_liaison/prepare_lang_liaison.sh --sil-prob 0.3 data/local/dict "!SIL" data/local/lang data/lang
  [ ! $liaison == true ] && [ ! $liaison == false ] && echo "verify the value of the variable liaison" && exit 1
fi


if [ $stage == 4 ]; then
  echo "Prepare G.fst and data/{train,dev,test} directories"
  local/format_lm.sh --liaison $liaison
fi