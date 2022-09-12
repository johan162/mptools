# Build documentation with the help of doxygen
DOC_FILES := $(wildcard *.md)
OUT_DIR := out
MAKE := /usr/bin/make

all: $(OUT_DIR)/html/index.html

html: $(OUT_DIR)/html/index.html

pdf: $(OUT_DIR)/latex/refman.pdf

out:
	mkdir -p out/html
	mkdir -p out/latex

$(OUT_DIR)/latex/refman.tex $(OUT_DIR)/html/index.html: Doxyfile $(DOC_FILES) | out
	doxygen

$(OUT_DIR)/latex/refman.pdf: $(OUT_DIR)/latex/refman.tex
	cd out/latex && $(MAKE)

clean:
	rm -rf $(OUT_DIR)

.phony: clean out all html pdf

