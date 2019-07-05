.PHONY: check test
.DEFAULT_GOAL := all

# shellcheck tests
#
scripts = placebo
check:
	for i in $(scripts) ; do \
		shellcheck --exclude=SC1090 $$i ; \
		done

# unit tests
#
tests = shunit2/placebo.sh
unit:
	for i in $(tests) ; do \
		printf "\n%s:\n" $$i ; \
		bash $$i ; \
		done

all: check unit
