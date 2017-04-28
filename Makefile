################################################################################
#	Makefile for hint.sh
#
#	Technically, no 'making' occurs, since it's just a shell script, but
#	let us not quibble over trivialities such as these.
################################################################################
PREFIX=/usr/local
SRC=src
SRCFILE=hint.sh
DESTFILE=hint
DOC=doc
DATA=data
MANPATH=$(PREFIX)/share/man/man1
MANFILE=hint.1.gz
DATAPATH=$(PREFIX)/share/hint
SHEETPATH=$(DATAPATH)/sheets

install:
	install -D -m 0755 $(SRC)/$(SRCFILE) $(PREFIX)/bin/$(DESTFILE)
	mkdir -vp $(DATAPATH)
	cp -rv $(DATA) $(SHEETPATH)
	install -v -D -m 0644 LICENSE $(DATAPATH)/LICENSE
	install -v -D -m 0644 README $(DATAPATH)/README
	install -D -m 0644 $(DOC)/$(MANFILE) $(MANPATH)/$(MANFILE)

uninstall:
	rm -f $(PREFIX)/bin/$(DESTFILE)
	rm -rf $(DATAPATH)
	rm -f $(MANPATH)/$(MANFILE)
