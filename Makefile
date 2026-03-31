.PHONY: setup

setup:
	@if [ ! -f "backend/supabase/.env" ]; then \
		cp "backend/supabase/.env.example" "backend/supabase/.env"; \
		echo "backend/supabase/.env created. Fill in the required values before running the deploy script."; \
	else \
		echo "backend/supabase/.env already exists, skipping."; \
	fi
