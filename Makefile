# Makefile — install the agent update scripts.
#
#   make install     test, then copy bin/* into $(BINDIR)
#   make uninstall   remove them from $(BINDIR)
#   make test        bash -n, shellcheck, --help on every script
#   make check       update-agents --check (reports versions, changes nothing)
#   make deploy      ./deploy: stage bucket + ~/bin (writes the shared bucket)
#
# Note: update-all re-copies every *-update in ~/bin from the stage bucket, so
# a script installed only locally is replaced on the next update-all. Use
# `make deploy` to make a change stick on every machine.
#
# Overrides: PREFIX (default $HOME), BINDIR (default $(PREFIX)/bin), DESTDIR.

PREFIX  ?= $(HOME)
BINDIR  ?= $(PREFIX)/bin
SCRIPTS := $(notdir $(wildcard bin/*))

.PHONY: all install uninstall test check deploy dry-run help

all: help

help:
	@sed -n '2,/^[^#]/s/^# \{0,1\}//p' Makefile

test:
	./test

install: test
	install -d '$(DESTDIR)$(BINDIR)'
	install -m 755 $(addprefix bin/,$(SCRIPTS)) '$(DESTDIR)$(BINDIR)/'

uninstall:
	rm -f $(addprefix '$(DESTDIR)$(BINDIR)'/,$(SCRIPTS))

check:
	bin/update-agents --check

dry-run:
	./deploy --dry-run

deploy:
	./deploy
