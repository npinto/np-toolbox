#!/bin/bash

mkdir -p 1.8X
for f in *.mp3; do
    src=$f; dst="1.8X/$(basename "$f")-1.8X.mp3";
    echo "${src}" to "${dst}";
    sox "$src" "${dst}" tempo 1.8 50;
done;


