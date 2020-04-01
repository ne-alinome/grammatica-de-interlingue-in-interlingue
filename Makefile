# Makefile of _Grammatica de Interlingue in Interlingue_

# By Marcos Cruz (programandala.net)
# http://ne.alinome.net

# Last modified 202004012043
# See change log at the end of the file

# ==============================================================
# Requirements

# Asciidoctor (by Dan Allen, Sarah White et al.)
#   http://asciidoctor.org

# Asciidoctor EPUB3 (by Dan Allen and Sarah White)
#   http://github.com/asciidoctor/asciidoctor-epub3

# Asciidoctor PDF (by Dan Allen and Sarah White)
#   http://github.com/asciidoctor/asciidoctor-pdf

# dbtoepub
#   http://docbook.sourceforge.net/release/xsl/current/epub/README

# ImageMagick (by ImageMagick Studio LCC)
#   http://imagemagick.org

# img2pdf (by Johannes 'josch' Schauer)
#   https://gitlab.mister-muffin.de/josch/img2pdf

# Pandoc (by John MaFarlane)
#   http://pandoc.org

# xsltproc
#   http://xmlsoft.org/xslt/xsltproc.html

# ==============================================================
# Config

VPATH=./src:./target

book=grammatica_de_interlingue_in_interlingue
book_author="Dr. Fritz Haas"
title="Grammatica de Interlingue in Interlingue"
lang="ie"
editor="Marcos Cruz (programandala.net)"
publisher="ne alinome"
description="Grammatica del lingue international auxiliari Interlingue"

# ==============================================================
# Interface

.PHONY: all
all: epub odt pdf

.PHONY: epub
epub: epuba epubd epubp epubx

.PHONY: epuba
epuba: target/$(book).adoc.epub

.PHONY: epubd
epubd: target/$(book).adoc.dbk.dbtoepub.epub

.PHONY: epubp
epubp: target/$(book).adoc.dbk.pandoc.epub

.PHONY: epubx
epubx: target/$(book).adoc.dbk.xsltproc.epub

.PHONY: odt
odt: target/$(book).adoc.dbk.pandoc.odt

.PHONY: pdf
pdf: pdfa4 pdfletter

.PHONY: pdfa4
pdfa4: target/$(book).adoc.a4.pdf

.PHONY: pdfletter
pdfletter: target/$(book).adoc.letter.pdf

.PHONY: dbk
dbk: target/$(book).adoc.dbk

.PHONY: cover
cover: target/book_cover.jpg

.PHONY: clean
clean:
	rm -fr target/* tmp/*

# ----------------------------------------------
# Development

.PHONY: it
it: epubd pdfa4 

# ==============================================================
# Convert Asciidoctor to PDF

target/%.adoc.a4.pdf: src/%.adoc tmp/book_cover.pdf
	asciidoctor-pdf \
		--out-file=$@ $<

target/%.adoc.letter.pdf: src/%.adoc tmp/book_cover.pdf
	asciidoctor-pdf \
		--attribute pdf-page-size=letter \
		--out-file=$@ $<

# ==============================================================
# Convert Asciidoctor to EPUB

target/%.adoc.epub: src/%.adoc target/book_cover.jpg
	asciidoctor-epub3 \
		--out-file=$@ $<

# ==============================================================
# Convert Asciidoctor to DocBook

target/%.adoc.dbk: src/%.adoc
	asciidoctor --backend=docbook5 --out-file=$@ $<

# ==============================================================
# Convert DocBook to EPUB

# ------------------------------------------------
# With dbtoepub

# XXX TODO -- Add the cover image. There's no parameter to do it.

target/$(book).adoc.dbk.dbtoepub.epub: \
	target/$(book).adoc.dbk \
	src/$(book)-docinfo.xml \
	src/dbtoepub_stylesheet.css
	dbtoepub \
		--css src/dbtoepub_stylesheet.css \
		--output $@ $<

# ------------------------------------------------
# With pandoc

# Deprecated: The cross references dont't work.

target/$(book).adoc.dbk.pandoc.epub: \
	target/$(book).adoc.dbk \
	src/$(book)-docinfo.xml \
	src/pandoc_epub_template.txt \
	src/pandoc_epub_stylesheet.css
	pandoc \
		--from docbook \
		--to epub3 \
		--template=src/pandoc_epub_template.txt \
		--css=src/pandoc_epub_stylesheet.css \
		--variable=lang:$(lang) \
		--variable=editor:$(editor) \
		--variable=publisher:$(publisher) \
		--variable=description:$(description) \
		--epub-cover-image=target/book_cover.jpg \
		--output $@ $<

# ------------------------------------------------
# With xsltproc

# Deactivated by default: Its result is identical to that of dbtoepub, which is
# a layer on it.

target/%.adoc.dbk.xsltproc.epub: target/%.adoc.dbk target/book_cover.jpg
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

# XXX TODO -- Add the cover image. Beside copying the image, the files
# <toc.ncx> and <content.opf> must be modified:
#
#	cp -f target/book_cover.jpg tmp/xsltproc/OEBPS/cover-image.jpg && \

# XXX TODO -- Find out how to pass parameters and their names, from the XLS:
#    --param epub.ncx.filename testing.ncx \

# XXX TODO -- Add the stylesheet. The XLS must be modified first,
# or the resulting XHTML must be modified at the end.
#  cp -f src/xsltproc/stylesheet.css tmp/xsltproc/OEBPS/ && \

# ==============================================================
# Convert DocBook to OpenDocument

target/$(book).adoc.dbk.pandoc.odt: \
	target/$(book).adoc.dbk \
	src/$(book)-docinfo.xml \
	src/pandoc_odt_template.txt
	pandoc \
		--from docbook \
		--to odt \
		--template=src/pandoc_odt_template.txt \
		--variable=lang:$(lang) \
		--variable=editor:$(editor) \
		--variable=publisher:$(publisher) \
		--variable=description:$(description) \
		--output $@ $<

# ==============================================================
# Create the cover image

# ------------------------------------------------
# Create the canvas and texts of the cover image

font=Helvetica
background=yellow
fill=black
strokewidth=4
logo='\#FFD700' # gold

tmp/book_cover.title.png:
	convert \
		-background transparent \
		-fill $(fill) \
		-font $(font) \
		-pointsize 145 \
		-size 990x \
		-gravity east \
		caption:$(title) \
		$@

tmp/book_cover.author.png:
	convert \
		-background transparent \
		-fill $(fill) \
		-font $(font) \
		-pointsize 90 \
		-size 990x \
		-gravity east \
		caption:$(book_author) \
		$@

tmp/book_cover.publisher.png:
	convert \
		-background transparent \
		-fill $(fill) \
		-font $(font) \
		-pointsize 24 \
		-size 1200x \
		-gravity center \
		caption:$(publisher) \
		$@

tmp/book_cover.logo.png: img/icon_plaincircle.svg
	convert $< \
		-fuzz 50% \
		-fill $(background) \
		-opaque white \
		-fuzz 50% \
		-fill $(logo) \
		-opaque black \
		-resize 256% \
		$@

# ------------------------------------------------
# Create the cover image


target/book_cover.jpg: \
	tmp/book_cover.title.png \
	tmp/book_cover.author.png \
	tmp/book_cover.publisher.png \
	tmp/book_cover.logo.png \
	Makefile
	convert -size 1200x1600 canvas:$(background) $@
	composite -gravity south -geometry +0+000 tmp/book_cover.logo.png $@ $@
	composite -gravity northeast -geometry +96+096 tmp/book_cover.title.png $@ $@
	composite -gravity northeast -geometry +96+640 tmp/book_cover.author.png $@ $@
	composite -gravity south -geometry +0+090 tmp/book_cover.publisher.png $@ $@

# ------------------------------------------------
# Convert the cover image to PDF

# This is needed in order to make sure the cover image ocuppies the whole page
# in the PDF versions of the book.

tmp/book_cover.pdf: target/book_cover.jpg
	img2pdf --output $@ --border 0 $<

# ------------------------------------------------
# Create a thumb version of the cover image

tmp/book_cover_thumb.jpg: target/book_cover.jpg
	convert $< -resize 190x $@

# ==============================================================
# Change log

# 2019-02-05: Start.
#
# 2019-02-07: Add stylesheet to dbtoepub.
#
# 2019-02-08: Add debugging rule `xml`. Deprecate pandoc to make the EPUB. Make
# an OpenDocument version.
#
# 2019-02-21: Fix: set `lang` variable. Fix metadata parameters in pandoc
# commands.
#
# 2019-02-27: Don't use xsltproc by default. Make clean recursive. Consider
# DocBook a target, not an intermediate step.
#
# 2019-03-09: Build all EPUB variants by default. This makes instructions
# clearer.
#
# 2019-08-02: Fix directory of the DocBook file.
#
# 2020-02-24: Add a cover image.
#
# 2020-03-30: Use "dkb" DocBook filename extension instead of "xml". Build an
# EPUB also with Asciidoctor EPUB3. Update and improve the list of
# requirements. Update the publisher.
#
# 2020-04-01: Update the project/book title. Improve the cover image. Add the
# cover image to the documents.
