TERRAFORM_DIRS := terraform/cloudflare terraform/github

.PHONY: check fmt validate validate-template

check: validate-template fmt validate

fmt:
	terraform fmt -check -recursive terraform

validate:
	@set -e; for directory in $(TERRAFORM_DIRS); do \
		terraform -chdir=$$directory init -backend=false -input=false -lockfile=readonly; \
		terraform -chdir=$$directory validate; \
	done

validate-template:
	./scripts/validate-template.sh
