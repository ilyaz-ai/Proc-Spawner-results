#!/bin/bash
# run.sh: 4 Windows processes under one wineserver append 2000 lines each to one file; count the lines that arrive
cd /runwin/apt; rm -f log.txt
for t in A B C D; do wine app.exe 'Z:\runwin\apt\log.txt' $t 2000 & done; wait
echo "lines: $(wc -l < log.txt) of 8000; bytes: $(wc -c < log.txt); per writer: $(cut -d' ' -f1 log.txt | sort | uniq -c | tr '\n' ' ')"
