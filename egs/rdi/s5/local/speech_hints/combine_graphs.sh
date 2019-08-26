#!/usr/bin/env bash
# (c) 2019 sylvainlg@voicea.ai

generic_graph=$1
extended_graph=$2
lang_ext=$3
combined_graph=$4

offset=$(grep nonterm_bos $lang_ext/phones.txt | awk '{print $2}')
nonterm_unk=$(grep nonterm:unk $lang_ext/phones.txt | awk '{print $2}')

mkdir -p $combined_graph
  
cp -r $extended_graph/{words.txt,phones.txt,phones/} $combined_graph

make-grammar-fst --write-as-grammar=false --nonterm-phones-offset=$offset $generic_graph/HCLG.fst \
                $nonterm_unk $extended_graph/HCLG.fst  $combined_graph/HCLG.fst