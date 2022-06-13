#! /bin/bash

BIN=/usr/local/bin
SRC=/Users/gonzalorivero/Documents/predictive-weighting/txt
BIB=$SRC/ml-voting.bib

$BIN/pandoc $SRC/01_theory.md \
            $SRC/02_empirics.md \
            $SRC/03_conclusions.md \
            $SRC/00_metadata.md \
	        -f markdown+smart+yaml_metadata_block+simple_tables+table_captions \
            --filter $BIN/pandoc-crossref --filter $BIN/pandoc-citeproc \
            --bibliography=$BIB \
            --file-scope --standalone --number-sections
