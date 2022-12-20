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
	ansible-vault decrypt vars/vault.yml

.PHONY: encrypt
encrypt:
	ansible-vault encrypt vars/vault.yml

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