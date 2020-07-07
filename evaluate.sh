#!/bin/bash
#
# This is the script for ZS2019 Challenge's evaluation of submissions

function failure { [ ! -z "$1" ] && echo "Error: $1"; exit 1; }

function on_exit() {
    source deactivate
    if [ ! $KEEP_TEMP ]
    then
       rm -rf $TMP_DIR;
    fi
}
trap on_exit EXIT


set -e


if [ "$#" -ne 3 ]; then
    echo "usage: bash evaluate_submission.sh <submission_zip> <which_embedding> <dtw_cosine|dtw_kl|levenshtein>"
    echo "This tool is for the english evaluation only!"
    echo "For the surprise dataset, we do not provide the evaluation task."
    echo ""
    echo "submission_zip: zip file containing submission"
    echo ""
    echo "which_embedding: embedding to evaluate ('test', 'auxiliary_embedding1', or"
    echo "                 'auxiliary_embedding2')"
    echo "distance: distance function to use in ABX ('levenshtein' or 'dtw')"
    echo ""
    echo "Please see http://www.zerospeech.com/2019/ for complete documentation"
    exit
fi

EVAL_DIR="$HOME/system/eval"
SUBMISSION_ZIP=$1
LANG='english'
EMBEDDING=$2
DISTANCE=$3


# Checking parameter consistancy
if [ ! $LANG = "english" ]; then
    failure "$LANG is not a valid language, it should be english"
fi

if [ ! $EMBEDDING = 'test' \
       -a ! $EMBEDDING = 'auxiliary_embedding1' -a ! $EMBEDDING = 'auxiliary_embedding2' ]
then
    failure "Embedding should correspond to test, auxiliary_embedding1 or auxiliary_embedding2"
fi

if [ ! $DISTANCE = 'dtw_cosine' -a ! $DISTANCE = 'levenshtein' -a ! $DISTANCE = 'dtw_kl' ]
then
    failure "Distance should be either dtw_cosine, dtw_kl or levenshtein"
fi


TASK_ACROSS="$HOME/system/info_test/$LANG/by-context-across-speakers.abx"
BITRATE_FILELIST="$HOME/system/info_test/$LANG/bitrate_filelist.txt"

SUBMISSION_NAME=$(basename $SUBMISSION_ZIP | rev | cut -d "." -f 2- | rev)
ABX_SCORE_FILE=$SUBMISSION_NAME.$LANG.abx.txt
SEG_ABX_SCORE_FILE=$SUBMISSION_NAME.$LANG.abx_seg.txt
BITRATE_SCORE_FILE=$SUBMISSION_NAME.$LANG.bitrate.txt
RLEBITRATE_SCORE_FILE=$SUBMISSION_NAME.$LANG.rlebitrate.txt

# make a temp directory (automatically erased at exit)
TMP_DIR=$(mktemp -d)

# initialize submission (may be a zip archive or a directory)
if [ -d $SUBMISSION_ZIP ]
then
    export SUBMISSION=$SUBMISSION_ZIP
elif [ -f $SUBMISSION_ZIP ]
then
    # checking the zip file integrity
    unzip -t "$SUBMISSION_ZIP" > /dev/null || failure "corrupted $SUBMISSION_ZIP"

    # unzip the archive in a temp directory (erase it at exit)
    export SUBMISSION=$(mktemp -d)
    trap "rm -rf $SUBMISSION" EXIT
    unzip "$SUBMISSION_ZIP" -d "$SUBMISSION" > /dev/null
else
    failure "submission not found: $SUBMISSION_ZIP"
fi

if [ ! -d "$SUBMISSION/$LANG/$EMBEDDING" ]
then
    failure "Embedding directory $LANG/$EMBEDDING does not exist in submission"
fi

source activate eval

echo "Evaluating ABX discriminability"
mkdir -p $TMP_DIR/abx_npz_files

# create npz files out of all onehot embeddings for ABX evaluation
python $EVAL_DIR/scripts/make_abx_files.py \
       $SUBMISSION/$LANG/$EMBEDDING $TMP_DIR/abx_npz_files || exit 1

# Create .features file
python $EVAL_DIR/ABXpy/ABXpy/misc/any2h5features.py \
       $TMP_DIR/abx_npz_files $TMP_DIR/features.features

# Computing distances
if [ $DISTANCE = "levenshtein" ]; then
    abx-distance $TMP_DIR/features.features $TASK_ACROSS \
                 $TMP_DIR/distance_across -d $DISTANCE >/dev/null 2>&1
elif [ $DISTANCE = "dtw_kl" ]; then
    abx-distance $TMP_DIR/features.features $TASK_ACROSS \
                 $TMP_DIR/distance_across -d $DISTANCE >/dev/null 2>&1
elif [ $DISTANCE = "dtw_cosine" ]; then
    abx-distance $TMP_DIR/features.features $TASK_ACROSS \
                 $TMP_DIR/distance_across -n 1 >/dev/null 2>&1
else
    failure "$DISTANCE not implemented: choose 'dtw_kl', 'dtw_cosine' or 'levenshtein'"
fi

# Calculating scores
abx-score $TASK_ACROSS $TMP_DIR/distance_across $TMP_DIR/score_across
# Collapsing results in readable format
abx-analyze $TMP_DIR/score_across $TASK_ACROSS $TMP_DIR/analyze_across
# Print average score
python $EVAL_DIR/scripts/meanABX.py $TMP_DIR/analyze_across across > $ABX_SCORE_FILE
echo ABX calculated using $DISTANCE >> $ABX_SCORE_FILE
rm -rf $TMP_DIR/*


echo "Evaluating Segmental ABX discriminability"
mkdir -p $TMP_DIR/abx_npz_files

# create npz files out of all onehot embeddings for ABX evaluation
python make_seg_abx_files.py \
       $SUBMISSION/$LANG/$EMBEDDING $TMP_DIR/abx_npz_files || exit 1

# Create .features file
python $EVAL_DIR/ABXpy/ABXpy/misc/any2h5features.py \
       $TMP_DIR/abx_npz_files $TMP_DIR/features.features

# Computing distances
if [ $DISTANCE = "levenshtein" ]; then
    abx-distance $TMP_DIR/features.features $TASK_ACROSS \
                 $TMP_DIR/distance_across -d $DISTANCE >/dev/null 2>&1
elif [ $DISTANCE = "dtw_kl" ]; then
    abx-distance $TMP_DIR/features.features $TASK_ACROSS \
                 $TMP_DIR/distance_across -d $DISTANCE >/dev/null 2>&1
elif [ $DISTANCE = "dtw_cosine" ]; then
    abx-distance $TMP_DIR/features.features $TASK_ACROSS \
                 $TMP_DIR/distance_across -n 1 >/dev/null 2>&1
else
    failure "$DISTANCE not implemented: choose 'dtw_kl', 'dtw_cosine' or 'levenshtein'"
fi


# Calculating scores
abx-score $TASK_ACROSS $TMP_DIR/distance_across $TMP_DIR/score_across
# Collapsing results in readable format
abx-analyze $TMP_DIR/score_across $TASK_ACROSS $TMP_DIR/analyze_across
# Print average score
python $EVAL_DIR/scripts/meanABX.py $TMP_DIR/analyze_across across > $SEG_ABX_SCORE_FILE
echo Segmental ABX calculated using $DISTANCE >> $SEG_ABX_SCORE_FILE
rm -rf $TMP_DIR/*

echo "Evaluating bitrate"
python $EVAL_DIR/scripts/bitrate.py $SUBMISSION/$LANG/$EMBEDDING/ \
       $BITRATE_FILELIST > $BITRATE_SCORE_FILE || exit 1

echo "Evaluating RLE bitrate"
python rle_bitrate.py $SUBMISSION/$LANG/$EMBEDDING/ \
       $BITRATE_FILELIST > $RLEBITRATE_SCORE_FILE || exit 1

echo ""
cat $ABX_SCORE_FILE
cat $SEG_ABX_SCORE_FILE
cat $BITRATE_SCORE_FILE
cat $RLEBITRATE_SCORE_FILE

# echo ""
# echo "ABX score is stored at $PWD/$ABX_SCORE_FILE"
# echo "Bitrate score is stored at $PWD/$BITRATE_SCORE_FILE"
# echo "RLE Bitrate score is stored at $PWD/$RLEBITRATE_SCORE_FILE"

rm -rf /tmp/tmp.*