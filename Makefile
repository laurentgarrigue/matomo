.PHONY: help init start stop clean create-networks restart rebuild logs status shell-matomo shell-db backup-db restore-db

# Couleurs pour le terminal
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Fichiers et variables
ENV_FILE := .env
ENV_DIST := .env.dist
COMPOSE_PROD := compose.prod.yaml

##@ Aide

help: ## Affiche cette aide
	@echo "$(BLUE)Makefile autodocumenté - Matomo Analytics$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(YELLOW)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Initialisation

init: ## Initialise le projet en créant le fichier .env de manière interactive
	@if [ -f $(ENV_FILE) ]; then \
		printf "$(YELLOW)⚠ Le fichier .env existe déjà.$(NC)\n"; \
		read -p "Voulez-vous le réinitialiser ? (y/N): " confirm; \
		if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
			printf "$(RED)Initialisation annulée.$(NC)\n"; \
			exit 1; \
		fi; \
		rm -f $(ENV_FILE); \
	fi; \
	printf "$(BLUE)🚀 Initialisation du projet Matomo Analytics$(NC)\n\n"; \
	cp $(ENV_DIST) $(ENV_FILE); \
	printf "$(GREEN)✓ Fichier .env créé à partir de .env.dist$(NC)\n\n"; \
	printf "$(BLUE)Configuration de l'environnement:$(NC)\n\n"; \
	printf "$(YELLOW)Nom de domaine (ex: example.com):$(NC) "; \
	read domain; \
	sed -i "s/^DOMAIN=.*/DOMAIN=$$domain/" $(ENV_FILE); \
	printf "\n$(YELLOW)Utilisateurs Traefik (format: user:hash,user2:hash2) [Entrée pour garder la valeur par défaut]:$(NC) "; \
	read traefik_users; \
	if [ -n "$$traefik_users" ]; then \
		escaped_users=$$(echo "$$traefik_users" | sed 's/\$$/\$\$$$/g'); \
		sed -i "s|^TRAEFIK_USERS=.*|TRAEFIK_USERS=$$escaped_users|" $(ENV_FILE); \
	fi; \
	printf "\n$(GREEN)✓ Configuration terminée !$(NC)\n\n"; \
	printf "$(BLUE)Fichier .env créé avec succès.$(NC)\n"; \
	printf "$(YELLOW)Vous pouvez maintenant lancer 'make start' pour démarrer le projet.$(NC)\n"

##@ Docker

create-networks: ## Crée les réseaux Docker s'ils n'existent pas
	@printf "$(BLUE)🔧 Vérification des réseaux Docker...$(NC)\n"
	@if ! docker network ls | grep -q matomo_network; then \
		printf "$(YELLOW)Création du réseau matomo_network...$(NC)\n"; \
		docker network create matomo_network; \
		printf "$(GREEN)✓ Réseau matomo_network créé$(NC)\n"; \
	else \
		printf "$(GREEN)✓ Réseau matomo_network existe déjà$(NC)\n"; \
	fi
	@if ! docker network ls | grep -q pma_network; then \
		printf "$(YELLOW)Création du réseau pma_network...$(NC)\n"; \
		docker network create pma_network; \
		printf "$(GREEN)✓ Réseau pma_network créé$(NC)\n"; \
	else \
		printf "$(GREEN)✓ Réseau pma_network existe déjà$(NC)\n"; \
	fi
	@if ! docker network ls | grep -q traefiknetwork; then \
		printf "$(YELLOW)Création du réseau traefiknetwork...$(NC)\n"; \
		docker network create traefiknetwork; \
		printf "$(GREEN)✓ Réseau traefiknetwork créé$(NC)\n"; \
	else \
		printf "$(GREEN)✓ Réseau traefiknetwork existe déjà$(NC)\n"; \
	fi

start: create-networks ## Lance Docker Compose avec Matomo
	@if [ ! -f $(ENV_FILE) ]; then \
		printf "$(RED)❌ Le fichier .env n'existe pas !$(NC)\n"; \
		printf "$(YELLOW)Veuillez d'abord exécuter 'make init'$(NC)\n"; \
		exit 1; \
	fi
	@printf "$(BLUE)🚀 Démarrage de Matomo Analytics...$(NC)\n"
	@docker compose -f $(COMPOSE_PROD) up -d
	@printf "$(GREEN)✓ Matomo démarré avec succès !$(NC)\n"
	@printf "$(BLUE)🌐 Accédez à Matomo sur https://matomo.$$DOMAIN$(NC)\n"

stop: ## Arrête les conteneurs Docker
	@if [ ! -f $(ENV_FILE) ]; then \
		printf "$(RED)❌ Le fichier .env n'existe pas !$(NC)\n"; \
		exit 1; \
	fi
	@printf "$(BLUE)🛑 Arrêt de Matomo...$(NC)\n"
	@docker compose -f $(COMPOSE_PROD) down
	@printf "$(GREEN)✓ Conteneurs arrêtés$(NC)\n"

restart: ## Redémarre les conteneurs Docker
	@$(MAKE) stop
	@$(MAKE) start

rebuild: ## Reconstruit et redémarre les conteneurs
	@printf "$(BLUE)🔄 Reconstruction des conteneurs...$(NC)\n"
	@docker compose -f $(COMPOSE_PROD) up -d --build
	@printf "$(GREEN)✓ Conteneurs reconstruits et redémarrés$(NC)\n"

clean: stop ## Arrête et supprime les conteneurs, volumes et réseaux
	@printf "$(YELLOW)⚠ Nettoyage complet...$(NC)\n"
	@docker compose -f $(COMPOSE_PROD) down -v
	@printf "$(GREEN)✓ Nettoyage terminé$(NC)\n"

##@ Utilitaires

logs: ## Affiche les logs des conteneurs
	@docker compose -f $(COMPOSE_PROD) logs -f

status: ## Affiche le statut des conteneurs
	@docker compose -f $(COMPOSE_PROD) ps

shell-matomo: ## Ouvre un shell dans le conteneur Matomo
	@printf "$(BLUE)🐚 Ouverture du shell Matomo...$(NC)\n"
	@docker compose -f $(COMPOSE_PROD) exec matomo bash

shell-db: ## Ouvre un shell dans le conteneur de base de données
	@printf "$(BLUE)🐚 Ouverture du shell base de données...$(NC)\n"
	@docker compose -f $(COMPOSE_PROD) exec dbmatomo bash

backup-db: ## Sauvegarde la base de données
	@printf "$(BLUE)💾 Sauvegarde de la base de données...$(NC)\n"
	@mkdir -p ./backups
	@docker compose -f $(COMPOSE_PROD) exec -T dbmatomo mysqldump -u root -proot matomo_database > ./backups/matomo_backup_$$(date +%Y%m%d_%H%M%S).sql
	@printf "$(GREEN)✓ Sauvegarde terminée dans ./backups/$(NC)\n"

restore-db: ## Restaure la base de données (usage: make restore-db FILE=backup.sql)
	@if [ -z "$(FILE)" ]; then \
		printf "$(RED)❌ Veuillez spécifier un fichier: make restore-db FILE=backup.sql$(NC)\n"; \
		exit 1; \
	fi
	@printf "$(BLUE)📥 Restauration de la base de données...$(NC)\n"
	@docker compose -f $(COMPOSE_PROD) exec -T dbmatomo mysql -u root -proot matomo_database < $(FILE)
	@printf "$(GREEN)✓ Restauration terminée$(NC)\n"
