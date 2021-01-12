# set to "./Setup" if you lack a cabal program. Or can be set to "stack"
BUILDER?=cabal
GHC?=ghc

PREFIX=/usr

build: Build/SysConfig.hs
	$(BUILDER) build $(BUILDEROPTIONS)
	if [ "$(BUILDER)" = stack ]; then \
		ln -sf $$(stack path --dist-dir)/build/git-repair/git-repair git-repair; \
	else \
		if [ -d dist-newstyle ]; then \
			ln -sf $$(cabal exec -- sh -c 'command -v git-repair') git-repair; \
		else \
			ln -sf dist/build/git-repair/git-repair git-repair; \
		fi; \
	fi
	@$(MAKE) tags >/dev/null 2>&1 &

Build/SysConfig.hs: Build/TestConfig.hs Build/Configure.hs
	if [ "$(BUILDER)" = ./Setup ]; then ghc --make Setup; fi
	if [ "$(BUILDER)" = stack ]; then \
		$(BUILDER) build $(BUILDEROPTIONS); \
	else \
		$(BUILDER) configure --ghc-options="$(shell Build/collect-ghc-options.sh)"; \
	fi

install: build
	install -d $(DESTDIR)$(PREFIX)/bin
	install git-repair $(DESTDIR)$(PREFIX)/bin
	install -d $(DESTDIR)$(PREFIX)/share/man/man1
	install -m 0644 git-repair.1 $(DESTDIR)$(PREFIX)/share/man/man1

clean:
	rm -rf git-repair git-repair-test.log \
		dist dist-newstyle configure Build/SysConfig.hs Setup tags
	find . -name \*.o -exec rm {} \;
	find . -name \*.hi -exec rm {} \;

# tags file for vim
tags:
	@$(MAKE) --quiet hothasktags HOTHASKTAGS_OPT= TAGFILE=tags

# TAGS file for emacs
TAGS:
	@$(MAKE) --quiet hothasktags HOTHASKTAGS_OPT=-e TAGFILE=TAGS

# https://github.com/luqui/hothasktags/issues/18
HOTHASKTAGS_ARGS=-XLambdaCase -XPackageImports --cpp

hothasktags:
	@if ! cabal exec hothasktags -- $(HOTHASKTAGS_OPT) $(HOTHASKTAGS_ARGS) \
		$$(find . | grep -v /.git/ | grep -v /tmp/ | grep -v dist/ | grep -v /doc/ | egrep '\.hs$$') 2>/dev/null \
		| sort > $(TAGFILE); then \
		echo "** hothasktags failed"; \
	fi

.PHONY: tags
