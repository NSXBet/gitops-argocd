.PHONY: scaffold-addon
scaffold-addon:
	@read -p "Enter addon name: " addon_name; \
	read -p "Enter chart repository URL: " chart_repo; \
	read -p "Enter chart version: " chart_version; \
	read -p "Enter chart namespace: " namespace; \
	read -p "Enter addon type (oss, aws, nsx): " addon_type; \
	./scripts/scaffold-addon.sh "$$addon_name" "$$chart_repo" "$$chart_version" "$$namespace" "$$addon_type"