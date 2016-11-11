# set to "./Setup" if you lack a cabal program. Or can be set to "stack"
BUILDER?=cabal
GHC?=ghc

PREFIX=/usr

build: Build/SysConfig.hs
	$(BUILDER) build $(BUILDEROPTIONS)
	if [ "$(BUILDER)" = stack ]; then \
		ln -sf $$(find .stack-work/ -name git-repair -type f | grep build/git-annex/git-repair | tail -n 1) git-repair; \
	else \
		ln -sf dist/build/git-repair/git-repair git-repair; \
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
		dist configure Build/SysConfig.hs Setup tags
	find . -name \*.o -exec rm {} \;
	find . -name \*.hi -exec rm {} \;

# hothasktags chokes on some template haskell etc, so ignore errors
tags:
	(for f in $$(find . | grep -v /.git/ | grep -v /tmp/ | grep -v /dist/ | grep -v /doc/ | egrep '\.hs$$'); do hothasktags -c --cpp -c -traditional -c --include=dist/build/autogen/cabal_macros.h $$f; done) 2>/dev/null | sort > tags

.PHONY: tags
