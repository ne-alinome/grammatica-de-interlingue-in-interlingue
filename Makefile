# Makefile of _Grammatica de Interlingue_

# By Marcos Cruz (programandala.net)

# Last modified 201902082342
# See change log at the end of the file

# ==============================================================
# Requirements

# - asciidoctor
# - asciidoctor-pdf
# - dbtoepub
# - pandoc
# - xsltproc

# ==============================================================
# Config

VPATH=./src:./target

book=grammatica_de_interlingue
title="Grammatica de Interlingue"
editor="Marcos Cruz (programandala.net)"
publisher="ne.alinome"
description="Grammatica de Interlingue in Interlingue"

# ==============================================================
# Interface

.PHONY: all
all: epub odt pdf

.PHONY: epub
epub: epubd epubx

.PHONY: epubd
epubd: target/$(book).adoc.xml.dbtoepub.epub

.PHONY: epubp
epubp: target/$(book).adoc.xml.pandoc.epub

.PHONY: epubx
epubx: target/$(book).adoc.xml.xsltproc.epub

.PHONY: odt
odt: target/$(book).adoc.xml.pandoc.odt

.PHONY: pdf
pdf: pdfa4 pdfletter

.PHONY: pdfa4
pdfa4: target/$(book).adoc.a4.pdf

.PHONY: pdfletter
pdfletter: target/$(book).adoc.letter.pdf

.PHONY: clean
clean:
	rm -f target/* tmp/*

# ----------------------------------------------
# Development

.PHONY: it
it: epubd pdfa4 

.PHONY: xml
xml: tmp/$(book).adoc.xml

# ==============================================================
# Convert Asciidoctor to PDF

target/%.adoc.a4.pdf: src/%.adoc
	asciidoctor-pdf \
		--out-file=$@ $<

target/%.adoc.letter.pdf: src/%.adoc
	asciidoctor-pdf \
		--attribute pdf-page-size=letter \
		--out-file=$@ $<

# ==============================================================
# Convert Asciidoctor to DocBook

.SECONDARY: tmp/$(book).adoc.xml

tmp/%.adoc.xml: src/%.adoc
	asciidoctor --backend=docbook5 --out-file=$@ $<

# ==============================================================
# Convert DocBook to EPUB

# ------------------------------------------------
# With dbtoepub

target/$(book).adoc.xml.dbtoepub.epub: \
	tmp/$(book).adoc.xml \
	src/$(book)-docinfo.xml \
	src/dbtoepub_stylesheet.css
	dbtoepub \
		--css src/dbtoepub_stylesheet.css \
		--output $@ $<

# ------------------------------------------------
# With pandoc

# Deprecated: The cross references dont't work.

target/$(book).adoc.xml.pandoc.epub: \
	tmp/$(book).adoc.xml \
	src/$(book)-docinfo.xml \
	src/pandoc_epub_template.txt \
	src/pandoc_epub_stylesheet.css
	pandoc \
		--from docbook \
		--to epub3 \
		--template=src/pandoc_epub_template.txt \
		--css=src/pandoc_epub_stylesheet.css \
		--variable=lang:$(lang) \
		--variable=editor:$(author) \
		--variable=publisher:$(editor) \
		--variable=description:$(description) \
		--output $@ $<

# ------------------------------------------------
# With xsltproc

target/%.adoc.xml.xsltproc.epub: tmp/%.adoc.xml
	rm -fr tmp/xsltproc/* && \
	xsltproc \
		--output tmp/xsltproc/ \
		/usr/share/xml/docbook/stylesheet/docbook-xsl/epub/docbook.xsl \
		$< && \
	echo -n application/epub+zip > tmp/xsltproc/mimetype && \
	cd tmp/xsltproc/ && \
	zip -0 -X ../../$@.zip mimetype && \
	zip -rg9 ../../$@.zip META-INF && \
	zip -rg9 ../../$@.zip OEBPS && \
	cd - && \
	mv $@.zip $@

# XXX TODO -- Find out how to pass parameters and their names, from the XLS:
#    --param epub.ncx.filename testing.ncx \

# XXX TODO -- Add the stylesheet. The XLS must be modified first,
# or the resulting XHTML must be modified at the end.
#  cp -f src/xsltproc/stylesheet.css tmp/xsltproc/OEBPS/ && \

# ==============================================================
# Convert DocBook to OpenDocument

target/$(book).adoc.xml.pandoc.odt: \
	tmp/$(book).adoc.xml \
	src/$(book)-docinfo.xml \
	src/pandoc_odt_template.txt
	pandoc \
		--from docbook \
		--to odt \
		--template=src/pandoc_odt_template.txt \
		--variable=lang:$(lang) \
		--variable=editor:$(author) \
		--variable=publisher:$(editor) \
		--variable=description:$(description) \
		--output $@ $<

# ==============================================================
# Change log

# 2019-02-05: Start.
#
# 2019-02-07: Add stylesheet to dbtoepub.
#
# 2019-02-08: Add debugging rule `xml`. Deprecate pandoc to make the EPUB.
# Make an OpenDocument version.
