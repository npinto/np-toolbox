#!/bin/bash

mkdir -p 1.8X
for f in *.mp3; do 
    src=$f; dst="1.8X/$(basename $f)";
    echo "${src}" to "${dst}";
    sox "$src" "${dst}.wav" tempo 1.8 50;
    lame -b 320 "${dst}.wav" "${dst}";
    rm -vf "${dst}.wav";
done;


