
all:

EXTRA_CXXFLAGS = -Wno-c++11-extensions -D__MACOSX_CORE__ -D__USE_GLUT__ -g
EXTRA_LDLIBS = -framework CoreAudio -framework CoreFoundation \
    -framework OpenGL -framework GLUT \
    -framework AppKit -framework IOKit -framework Carbon -framework Foundation -framework CoreMIDI  \
    -lboost_system -lboost_filesystem -lstdc++ -lm -lstk -lsndfile -lslgaudiofile -lslgaudio -lrtaudio


include ../kaldi.mk

# BINFILES = test_decoder_offline
# BINFILES = slg_decoder_offline
# BINFILES = test_basics
BINFILES = online2-tcp-nnet3-decode-faster
# BINFILES = test_audio_stream
# BINFILES = test_stk

TESTFILES = 

OBJFILES = 

LIBNAME = 

ADDLIBS = ../base/kaldi-base.a \
    ../util/kaldi-util.a \
    ../feat/kaldi-feat.a \
    ../matrix/kaldi-matrix.a \
    ../decoder/kaldi-decoder.a \
    ../lat/kaldi-lat.a \
    ../online2/kaldi-online2.a \
    ../nnet3/kaldi-nnet3.a \
    ../hmm/kaldi-hmm.a \
    ../cudamatrix/kaldi-cudamatrix.a \
    ../fstext/kaldi-fstext.a \
    ../ivector/kaldi-ivector.a \
    ../rnnlm/kaldi-rnnlm.a \


include ../makefiles/default_rules.mk
