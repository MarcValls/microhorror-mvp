.PHONY: help setup deploy-supabase validate-supabase

help:
	@echo "Available targets:"
	@echo "  make setup                - Create backend/supabase/.env from backend/supabase/.env.example if it does not exist"
	@echo "  make deploy-supabase      - Run the remote Supabase deploy flow using backend/supabase/scripts/deploy_remote.sh"
	@echo "  make validate-supabase    - Run the remote Supabase validation flow using backend/supabase/scripts/validate_remote.sh"

setup:
	@if [ ! -f "backend/supabase/.env" ]; then \
		cp "backend/supabase/.env.example" "backend/supabase/.env"; \
		echo "backend/supabase/.env created. Fill in the required values before running the deploy script."; \
	else \
		echo "backend/supabase/.env already exists, skipping."; \
	fi

deploy-supabase:
	@bash "backend/supabase/scripts/deploy_remote.sh"

validate-supabase:
	@bash "backend/supabase/scripts/validate_remote.sh"
