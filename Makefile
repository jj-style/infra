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
	@bash git-init.sh
	@ansible-galaxy install -r requirements.yml

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
	ansible-playbook --check $(TAGS_ARG) playbooks/server.yml

.PHONY: run
run:
	ansible-playbook $(TAGS_ARG) playbooks/server.yml

.PHONY: check
check:
	ansible-playbook --syntax-check --verbose playbooks/server.yml

.PHONY: bwunlock
bwunlock:
	bw unlock
