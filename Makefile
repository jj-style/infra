.PHONY: all
all:
	@echo "Targets"
	@echo "  init"
	@echo "  decrypt"
	@echo "  encrypt"
	@echo "  test"
	@echo "  check"
	@echo "  run"
	@echo " bwunlock"

.PHONY: init
init:
	./git-init.sh

.PHONY: decrypt
decrypt:
	for file in vars/*vault.yml; do \
		ansible-vault decrypt $$file; \
	done

.PHONY: encrypt
encrypt:
	for file in vars/*vault.yml; do \
		ansible-vault encrypt $$file; \
	done

TAGS ?= 
TAGS_ARG := $(if $(TAGS),--tags $(TAGS),)

.PHONY: test
test:
	ansible-playbook --check --ask-become-pass $(TAGS_ARG) server.yml

.PHONY: run
run:
	ansible-playbook --ask-become-pass $(TAGS_ARG) server.yml

.PHONY: check
check:
	ansible-playbook --syntax-check --verbose server.yml

.PHONY: bwunlock
bwunlock:
	bw unlock