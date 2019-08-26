#!/usr/bin/env bash
# (c) 2019 sylvainlg@voicea.ai


generic_graph=/tmp/speech_hints/extvocab_top
extended_graph=/tmp/speech_hints/extvocab_part
lang_ext=/tmp/speech_hints/lang_extvocab
combined_graph=/tmp/speech_hints/extvocab_combined

./local/grammar/combine_graphs.sh $generic_graph $extended_graph $lang_ext $combined_graph