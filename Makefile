# Makefile for French Python Documentation
#
# Here is what you can do:
#
# - make  # Automatically build an html local version
# - make todo  # To list remaining tasks
# - make merge  # To merge pot from upstream
# - make fuzzy  # To find fuzzy strings
# - make progress  # To compute current progression
#
# Modes are: autobuild-stable, autobuild-dev, and autobuild-html,
# documented in gen/src/3.6/Doc/Makefile as we're only delegating the
# real work to the Python Doc Makefile.

CPYTHON_CLONE := ../cpython/
SPHINX_CONF := $(CPYTHON_CLONE)/Doc/conf.py
LANGUAGE := fr
VENV := ~/.venvs/python-docs-i18n/
PYTHON := $(shell which python3)
MODE := autobuild-dev-html
BRANCH = $(shell git describe --contains --all HEAD)


.PHONY: all
all: $(VENV)/bin/sphinx-build $(VENV)/bin/blurb $(SPHINX_CONF)
	mkdir -p $(CPYTHON_CLONE)/Doc/locales/$(LANGUAGE)/
	ln -nfs $(shell readlink -f .) $(CPYTHON_CLONE)/Doc/locales/$(LANGUAGE)/LC_MESSAGES
	. $(VENV)/bin/activate; $(MAKE) -C $(CPYTHON_CLONE)/Doc/ SPHINXOPTS='-D locale_dirs=locales -D language=$(LANGUAGE) -D gettext_compact=0' $(MODE)


$(SPHINX_CONF):
	git clone --depth 1 --no-single-branch https://github.com/python/cpython.git $(CPYTHON_CLONE)


$(VENV)/bin/activate:
	mkdir -p $(VENV)
	$(PYTHON) -m venv $(VENV)


$(VENV)/bin/sphinx-build: $(VENV)/bin/activate
	. $(VENV)/bin/activate; python3 -m pip install sphinx


$(VENV)/bin/blurb: $(VENV)/bin/activate
	. $(VENV)/bin/activate; python3 -m pip install blurb


.PHONY: progress
progress:
	@python3 -c 'import sys; print("{:.1%}".format(int(sys.argv[1]) / int(sys.argv[2])))'  \
	$(shell msgcat **/*.po | msgattrib --translated | grep -c '^msgid') \
	$(shell msgcat **/*.po | grep -c '^msgid')


.PHONY: todo
todo:
	for file in *.po */*.po; do echo $$(msgattrib --untranslated $$file | grep ^msgid | sed 1d | wc -l ) $$file; done | grep -v ^0 | sort -gr


.PHONY: merge
merge: $(VENV)/bin/sphinx-build
ifneq "$(shell cd $(CPYTHON_CLONE) 2>/dev/null && git describe --contains --all HEAD)" "$(BRANCH)"
	$(error "You're merging from a different branch")
endif
	(cd $(CPYTHON_CLONE); $(VENV)/bin/sphinx-build -Q -b gettext -D gettext_compact=0 Doc pot/)
	find $(CPYTHON_CLONE)/pot/ -name '*.pot' |\
	    while read -r POT;\
	    do\
	        PO="./$$(echo "$$POT" | sed "s#$(CPYTHON_CLONE)/pot/##; s#\.pot\$$#.po#")";\
	        mkdir -p "$$(dirname "$$PO")";\
	        if [ -f "$$PO" ];\
	        then\
	            msgmerge --backup=off --force-po -U "$$PO" "$$POT";\
	        else\
	            msgcat -o "$$PO" "$$POT";\
	        fi\
	    done


.PHONY: fuzzy
fuzzy:
	find -name '*.po' | xargs -L1 msgattrib --only-fuzzy --no-obsolete
