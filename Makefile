# Makefile of _Grammatica de Interlingue in Interlingue_

# By Marcos Cruz (programandala.net)
# http://ne.alinome.net

# Last modified 202008272028
# See change log at the end of the file

# ==============================================================
# Requirements {{{1

# Asciidoctor (by Dan Allen, Sarah White et al.)
#   http://asciidoctor.org

# Asciidoctor EPUB3 (by Dan Allen and Sarah White)
#   http://github.com/asciidoctor/asciidoctor-epub3

# Asciidoctor PDF (by Dan Allen and Sarah White)
#   http://github.com/asciidoctor/asciidoctor-pdf

# dbtoepub
#   http://docbook.sourceforge.net/release/xsl/current/epub/README

# ebook-convert
#   manual.calibre-ebook.com/generated/en/ebook-convert.html

# ImageMagick (by ImageMagick Studio LCC)
#   http://imagemagick.org

# img2pdf (by Johannes 'josch' Schauer)
#   https://gitlab.mister-muffin.de/josch/img2pdf

# Pandoc (by John MaFarlane)
#   http://pandoc.org

# xsltproc
#   http://xmlsoft.org/xslt/xsltproc.html

# ==============================================================
# Config {{{1

VPATH=./src:./target

book=grammatica_de_interlingue_in_interlingue
cover=$(book)_cover
cover_author="Dr. Fritz Haas"
cover_title="Grammatica\nde Interlingue\nin Interlingue"
lang="ie"
editor="Marcos Cruz (programandala.net)"
publisher="ne alinome"
description="Grammatica del lingue international auxiliari Interlingue"

# ==============================================================
# Interface {{{1

.PHONY: default
default: epuba pdfa4 thumb

.PHONY: all
all: azw3 epub odt pdf thumb

.PHONY: azw3
azw3: target/$(book).adoc.epub.azw3

.PHONY: epub
epub: epuba

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

# NOTE: First the zip (which preserves the PDF),
# then the gzip (which deletes it):
.PHONY: pdfa4
pdfa4: \
	target/$(book).adoc._a4.pdf.zip \
	target/$(book).adoc._a4.pdf.gz

# NOTE: First the zip (which preserves the PDF),
# then the gzip (which deletes it):
.PHONY: pdfletter
pdfletter: \
	target/$(book).adoc._letter.pdf.zip \
	target/$(book).adoc._letter.pdf.gz

.PHONY: dbk
dbk: target/$(book).adoc.dbk

.PHONY: cover
cover: target/$(cover).jpg

.PHONY: thumb
thumb: target/$(cover)_thumb.jpg

.PHONY: clean
clean:
	rm -fr target/* tmp/*

.PHONY: cleancover
cleancover:
	rm -f target/*.jpg tmp/*.png

# ==============================================================
# Convert Asciidoctor to EPUB {{{1

target/%.adoc.epub: src/%.adoc target/$(cover).jpg
	asciidoctor-epub3 \
		--out-file=$@ $<

# ==============================================================
# Convert Asciidoctor to DocBook {{{1

target/%.adoc.dbk: src/%.adoc
	asciidoctor --backend=docbook5 --out-file=$@ $<

# ==============================================================
# Convert Asciidoctor to PDF {{{1

target/%.adoc._a4.pdf: src/%.adoc tmp/$(cover).pdf
	asciidoctor-pdf \
		--out-file=$@ $<

target/%.adoc._letter.pdf: src/%.adoc tmp/$(cover).pdf
	asciidoctor-pdf \
		--attribute pdf-page-size=letter \
		--out-file=$@ $<

%.pdf.zip: %.pdf
	zip -9 $@ $<

%.pdf.gz: %.pdf
	gzip --force $<

# ==============================================================
# Convert DocBook to EPUB {{{1

# XXX OLD Deprecated.

# ------------------------------------------------
# Convert DocBook to EPUB with dbtoepub {{{2

# XXX TODO -- Add the cover image. There's no parameter to do it.

target/$(book).adoc.dbk.dbtoepub.epub: \
	target/$(book).adoc.dbk \
	src/$(book)-docinfo.xml \
	src/dbtoepub_stylesheet.css
	dbtoepub \
		--css src/dbtoepub_stylesheet.css \
		--output $@ $<

# ------------------------------------------------
# Convert DocBook to EPUB with pandoc {{{2

# XXX REMARK -- Deactivated by default. The cross references dont't work.

target/$(book).adoc.dbk.pandoc.epub: \
	target/$(book).adoc.dbk \
	src/$(book)-docinfo.xml \
	src/pandoc_epub_template.txt \
	src/pandoc_epub_stylesheet.css \
	target/$(cover).jpg
	pandoc \
		--from docbook \
		--to epub3 \
		--template=src/pandoc_epub_template.txt \
		--css=src/pandoc_epub_stylesheet.css \
		--variable=lang:$(lang) \
		--variable=editor:$(editor) \
		--variable=publisher:$(publisher) \
		--variable=description:$(description) \
		--epub-cover-image=target/$(cover).jpg \
		--output $@ $<

# ------------------------------------------------
# Convert DocBook to EPUB with xsltproc {{{2

# XXX REMARK -- Deactivated by default. Its result is identical to that of
# dbtoepub, which is a layer above xsltproc.

# XXX TODO -- Add the cover image. Beside copying the image, the files
# <toc.ncx> and <content.opf> must be modified:
#
#	cp -f target/$(cover).jpg tmp/xsltproc/OEBPS/cover-image.jpg && \

# XXX TODO -- Find out how to pass parameters and their names, from the XLS:
#    --param epub.ncx.filename testing.ncx \

# XXX TODO -- Add the stylesheet. The XLS must be modified first,
# or the resulting XHTML must be modified at the end.
#  cp -f src/xsltproc/stylesheet.css tmp/xsltproc/OEBPS/ && \


target/%.adoc.dbk.xsltproc.epub: target/%.adoc.dbk target/$(cover).jpg
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

# ==============================================================
# Convert DocBook to OpenDocument {{{1

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
# Convert EPUB to AZW3 {{{1

target/%.epub.azw3: target/%.epub
	ebook-convert $< $@

# ==============================================================
# Create the cover image {{{1

# ------------------------------------------------
# Create the canvas and texts of the cover image {{{2

font=Helvetica
background=yellow
fill=black
strokewidth=4
logo='\#FFD700' # gold

tmp/$(cover).title.png:
	convert \
		-background transparent \
		-fill $(fill) \
		-font $(font) \
		-pointsize 128 \
		-size 1200x \
		-gravity east \
		caption:$(cover_title) \
		$@

tmp/$(cover).author.png:
	convert \
		-background transparent \
		-fill $(fill) \
		-font $(font) \
		-pointsize 72 \
		-size 896x \
		-gravity east \
		caption:$(cover_author) \
		$@

tmp/$(cover).publisher.png:
	convert \
		-background transparent \
		-fill $(fill) \
		-font $(font) \
		-pointsize 24 \
		-gravity east \
		-size 128x \
		caption:$(publisher) \
		$@

tmp/$(cover).logo.png: img/icon_plaincircle.svg
	convert $< \
		-fuzz 50% \
		-fill $(background) \
		-opaque white \
		-fuzz 50% \
		-fill $(logo) \
		-opaque black \
		-resize 256% \
		$@

tmp/$(cover).decoration.png: img/$(book)_cover_decoration.png
	convert $< \
		-fuzz 10% \
		-fill $(background) \
		-opaque white \
		-resize 48% \
		$@

# ------------------------------------------------
# Create the cover image {{{2

target/$(cover).jpg: \
	tmp/$(cover).title.png \
	tmp/$(cover).author.png \
	tmp/$(cover).publisher.png \
	tmp/$(cover).logo.png \
	tmp/$(cover).decoration.png
	convert -size 1200x1600 canvas:$(background) $@
	composite -gravity south     -geometry +000+000 tmp/$(cover).logo.png $@ $@
	composite -gravity northeast -geometry +048+048 tmp/$(cover).title.png $@ $@
	composite -gravity northeast -geometry +048+512 tmp/$(cover).author.png $@ $@
	composite -gravity southeast -geometry +048+048 tmp/$(cover).publisher.png $@ $@
	composite -gravity west      -geometry +102+170 tmp/$(cover).decoration.png $@ $@

# ------------------------------------------------
# Convert the cover image to PDF {{{2

# This is needed in order to make sure the cover image ocuppies the whole page
# in the PDF versions of the book.

tmp/$(cover).pdf: target/$(cover).jpg
	img2pdf --output $@ --border 0 $<

# ------------------------------------------------
# Create a thumb version of the cover image {{{2

%_thumb.jpg: %.jpg
	convert $< -resize 190x $@

# ==============================================================
# Change log {{{1

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
# cover image to the documents. Rename the Asciidoctor PDF targets to make both
# variants be listed together. Add decoration to the cover image.
#
# 2020-04-02: Build only the recommended formats by default. Add rule
# "cleancover". Make the thumb cover by default. Fix: make Pandoc require the
# cover image to build the EPUB.
#
# 2020-04-06: Adjust the size and layout of the cover texts.
#
# 2020-08-24: Simplify the dependency between the cover and its thumb.
#
# 2020-08-27: Compress the PDF with zip and gzip. Convert also EPUB to AZW3.
# Deprecate the conversions from DocBook to EPUB.
