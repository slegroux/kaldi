#!/bin/bash

set -x
# Begin configuration section.
dir=$KALDI_ASR/egs/ami/s5b/exp/rnnlm_ami
embedding_dim=800
lstm_rpd=200
lstm_nrpd=200
stage=-10
train_stage=-10
epochs=20

. ./cmd.sh
. utils/parse_options.sh
[ -z "$cmd" ] && cmd=$train_cmd

wordlist=$KALDI_ASR/egs/ami/s5b/data/lang/words.txt
#dev_sents=10000
# text_dir=data/rnnlm/text
text_dir=$KALDI_ASR/egs/ami/s5b/data/ihm/kaldirnnlm
mkdir -p $text_dir
#text_dir=$BABEL/graphs/fisher_vca_rev_webex/mixpocolm_folded_3g/data_dir_rnnlm
mkdir -p $dir/config
#set -e

for f in $text $wordlist; do
  [ ! -f $f ] && \
    echo "$0: expected file $f to exist; search for local/prepare_data.sh and utils/prepare_lang.sh in run.sh" && exit 1
done

if [ $stage -eq -42 ]; then

  for dataset in {train,dev}; do
    cat $KALDI_ASR/egs/ami/s5b/data/ihm/$dataset/text |awk '{ $1="";print $0 }'|tr '[:upper:]' '[:lower:]' > $text_dir/$dataset.txt
  done
fi


if [ $stage -le 1 ]; then
  cp $wordlist $dir/config/
  n=`cat $dir/config/words.txt | wc -l`
  echo "<brk> $n" >> $dir/config/words.txt

  # words that are not present in words.txt but are in the training or dev data, will be
  # mapped to <unk> during training.
  echo "<unk>" >$dir/config/oov.txt

  cat > $dir/config/data_weights.txt <<EOF
train 4 1
EOF

  rnnlm/get_unigram_probs.py --vocab-file=$dir/config/words.txt \
                             --unk-word="<unk>" \
                             --data-weights-file=$dir/config/data_weights.txt \
                             $text_dir | awk 'NF==2' >$dir/config/unigram_probs.txt

  # choose features
  rnnlm/choose_features.py --unigram-probs=$dir/config/unigram_probs.txt \
                           --use-constant-feature=true \
                           --top-word-features=10000 \
                           --min-frequency 1.0e-03 \
                           --special-words='<s>,</s>,<brk>,<unk>' \
                           $dir/config/words.txt > $dir/config/features.txt

  cat >$dir/config/xconfig <<EOF
input dim=$embedding_dim name=input
relu-renorm-layer name=tdnn1 dim=$embedding_dim input=Append(0, IfDefined(-1))
fast-lstmp-layer name=lstm1 cell-dim=$embedding_dim recurrent-projection-dim=$lstm_rpd non-recurrent-projection-dim=$lstm_nrpd
relu-renorm-layer name=tdnn2 dim=$embedding_dim input=Append(0, IfDefined(-2))
fast-lstmp-layer name=lstm2 cell-dim=$embedding_dim recurrent-projection-dim=$lstm_rpd non-recurrent-projection-dim=$lstm_nrpd
relu-renorm-layer name=tdnn3 dim=$embedding_dim input=Append(0, IfDefined(-1))
output-layer name=output include-log-softmax=false dim=$embedding_dim
EOF
  rnnlm/validate_config_dir.sh $text_dir $dir/config
fi

if [ $stage -le 2 ]; then
  # the --unigram-factor option is set larger than the default (100)
  # in order to reduce the size of the sampling LM, because rnnlm-get-egs
  # was taking up too much CPU (as much as 10 cores).
  rnnlm/prepare_rnnlm_dir.sh --unigram-factor 200.0 \
                             $text_dir $dir/config $dir
fi
echo "rnnlm dir done"

if [ $stage -le 3 ]; then
  rnnlm/train_rnnlm.sh --num-jobs-initial 1 --num-jobs-final 1 \
                       --stage $train_stage --num-epochs $epochs --cmd "$cmd" $dir
fi


exit 0
