#!/usr/bin/env bash
# (c) 2019 sylvainlg@voicea.ai

audio=$1
sr=16000
bn=$(basename $audio .wav)
data_dir=$(dirname $audio)/$bn
if [ ! -d $data_dir ]; then
    mkdir -p $data_dir
else
    rm -rf $data_dir
    mkdir -p $data_dir
fi
echo "$bn sox $(realpath $audio) -b 16 -r $sr -c 1 -t wav - |" >> $data_dir/wav.scp
echo $bn $bn >> $data_dir/utt2spk
utils/utt2spk_to_spk2utt.pl $data_dir/utt2spk > $data_dir/spk2utt
echo $(realpath $data_dir)