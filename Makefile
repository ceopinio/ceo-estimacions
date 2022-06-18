# Prefix of file
PREFIX := ceobarometer

# Folder with text 
TXT := ./txt
# Input files 
INPUT_FILES := $(wildcard $(TXT)/*.md)
# Bibliography
BIB := $(TXT)/$(PREFIX).bib

## Output files
PDF := $(PREFIX).pdf

## Targets
all:	$(MODELS) $(PDF)
pdf:	clean $(PDF)

## Pandoc options
OPTIONS := --file-scope --standalone --number-sections --pdf-engine-opt=-shell-escape --citeproc
FILTERS := --filter pandoc-crossref
EXTENSIONS := markdown+smart+yaml_metadata_block+simple_tables+table_captions

## Run models
models:
	snakemake --cores all

# Count words
count:
	wc -w $(TXT)/*.md

# Bump version of the report
bump:
	git checkout $(BRANCH)
	git pull origin $(BRANCH)
	bumpversion $(version) 

## Paper
%.pdf: $(INPUT_FILES) 
	pandoc $^ \
	-f $(EXTENSIONS) \
	$(FILTERS) \
    --pdf-engine=xelatex \
    --template $(TXT)/templates/default.latex \
    --bibliography=$(BIB) \
	$(OPTIONS) \
	--output $@ \
	-V lang=es-ES \
	-M date="`date "+%B %e, %Y"`"

## Phonies
clean:
	rm -f *.pdf *.docx 

.PHONY : clean 

