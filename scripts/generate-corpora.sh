#!/bin/bash

start_dir=$( pwd )
main_dir="$( dirname "$0" )/.."
cd "$main_dir"
main_dir=$( pwd )

source scripts/read-netrc.sh

# set path to include bin/ first, so that we use the latest
# compiled versions of autocorpus tools
PATH="$main_dir/bin":"$PATH"

function ask() {
    echo -n "$1 [y/N]: "
    read ans
    if [[ "$ans" = "y" || "$ans" = "yes" ]];
    then
        ans=y
    else
        ans=n
    fi
}

ask "Would you like to extract, textify, extract sentences and tokenize a small Wikipedia excerpt?"
if [ "$ans" = y ];
then
    cd bin
    mkdir -p ../data/wikipedia/clean-sample
    pv ../data/wikipedia/enwiki-20110620-pages-articles.ascii.xml | head -n 100000 | \
        wiki-articles | tee ../data/wikipedia/clean-sample/articles.txt | \
        wiki-textify -h | tee ../data/wikipedia/clean-sample/textified.txt | \
        sentences | tee ../data/wikipedia/clean-sample/sentences.txt | \
        tokenize | tee ../data/wikipedia/clean-sample/tokenized.txt > /dev/null
    cd ..
fi

ask "Would you like to extract, textify, extract sentences and tokenize Wikipedia?"
if [ "$ans" = y ];
then
    cd bin
    mkdir -p ../data/wikipedia/clean
    mkdir -p ../data/wikipedia/ngrams
    pv ../data/wikipedia/enwiki-20110620-pages-articles.ascii.xml | \
        wiki-articles | tee ../data/wikipedia/clean/articles.txt | \
        wiki-textify -h | tee ../data/wikipedia/clean/textified.txt | \
        sentences | tee ../data/wikipedia/clean/sentences.txt | \
        tokenize | tee ../data/wikipedia/clean/tokenized.txt > /dev/null
    cd ..
fi

ask "Would you like to generate unigrams?"
if [ "$ans" = y ];
then
    cd bin
    pv ../data/wikipedia/clean/tokenized.txt | ngrams -m 500M -n 1 | ascii2uni > \
        ../data/wikipedia/ngrams/unigrams-unsorted.txt
    cd ..
fi

ask "Would you like to generate bigrams?"
if [ "$ans" = y ];
then
    cd bin
    pv ../data/wikipedia/clean/tokenized.txt | ngrams -m 500M -n 2 | ascii2uni > \
        ../data/wikipedia/ngrams/bigrams-unsorted.txt
    cd ..
fi

ask "Would you like to generate trigrams?"
if [ "$ans" = y ];
then
    cd bin
    pv ../data/wikipedia/clean/tokenized.txt | ngrams -m 500M -n 3 | ascii2uni > \
        ../data/wikipedia/ngrams/trigrams-unsorted.txt
    cd ..
fi

ask "Would you like to sort ngrams?"
if [ "$ans" = y ];
then
    cd bin
    for f in $( find ../data/wikipedia/ngrams -iname "*grams*unsorted.txt" );
    do
        echo "Sorting $f..."
        dest=$( echo -n "$f" | sed "s/-unsorted//g" )
        if [[ "$dest" -ot "$f" ]];
        then
            pv "$f" | ngrams-sort > "$dest"
        fi
    done
    cd ..
fi

ask "Would you like to compress ngrams?"
if [ "$ans" = y ];
then
    cd bin
    for f in $( find ../data/wikipedia/ngrams -iname "*grams.txt" );
    do
        echo "Compressing $f..."
        dest=$( echo -n "$f" | sed "s/.txt/.txt.bz2/g" )
        if [[ "$dest" -ot "$f" ]];
        then
            pv "$f" | bzip2 --best > "$dest"
        fi
    done
    cd ..
fi

ask "Would you like to generate sample data files?"
if [ "$ans" = y ];
then
    cd data/wikipedia/clean
    head -n 100000 tokenized.txt | ascii2uni > clean-sample.txt
    cd "$main_dir"
    cd data/wikipedia/ngrams
    for f in $( ls *grams.txt ); do
        target="${f/.txt/-sample.txt}"
        echo -e "\t$f -> $target"
        head -n 10000 "$f" > "$target"
        echo "# end of sample" >> "$target"
    done
    cd "$main_dir"
fi

ask "Would you like to upload corpora to FTP?"
if [ "$ans" = y ];
then
    cd "$main_dir/data/wikipedia"
    for f in $( find . -iname "*sample.txt" ) $( find ngrams -iname "*.txt.bz2" | grep -v "trigrams" ); do
        echo -e "\t$f"
        ftpup autocorpus/releases/1.0.1/wikipedia "$f"
    done
fi

cd "$start_dir"
