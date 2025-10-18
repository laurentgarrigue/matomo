# Matomo Analytics

Plateforme d'analytics open-source deployee avec Docker et Traefik.

## Prerequis

- Docker et Docker Compose
- Traefik configure avec le reseau `traefiknetwork`
- Un nom de domaine configure

## Installation

### 1. Initialisation

```bash
make init
```

Cette commande va :
- Créer le fichier `.env` a partir de `.env.dist`
- Demander votre nom de domaine
- Configurer les utilisateurs Traefik (optionnel)

### 2. Demarrage

```bash
make start
```

Matomo sera accessible sur `https://matomo.votre-domaine.com`

## Commandes disponibles

### Gestion des conteneurs

- `make start` - Demarre Matomo
- `make stop` - Arrete les conteneurs
- `make restart` - Redemarre les conteneurs
- `make rebuild` - Reconstruit et redemarre les conteneurs
- `make status` - Affiche le statut des conteneurs
- `make logs` - Affiche les logs en temps reel

### Utilitaires

- `make shell-matomo` - Accede au shell du conteneur Matomo
- `make shell-db` - Accede au shell de la base de donnees
- `make backup-db` - Sauvegarde la base de donnees
- `make restore-db FILE=backup.sql` - Restaure une sauvegarde

### Nettoyage

- `make clean` - Arrete et supprime conteneurs + volumes

## Structure du projet

```
.
├── config/          # Configuration Matomo
├── plugins/         # Plugins Matomo
├── misc/            # Fichiers divers
├── tmp/             # Fichiers temporaires
├── db/              # Donnees MySQL
├── backups/         # Sauvegardes de la base de donnees
├── compose.prod.yaml
├── .env
└── Makefile
```

## Services

- **matomo** : Application Matomo (port 80)
- **dbmatomo** : Base de donnees MariaDB

## Configuration

Toute la configuration se trouve dans le fichier `.env` :

- `DOMAIN` : Votre nom de domaine
- `DBMATOMO_ROOT_PASSWORD` : Mot de passe root MySQL
- `DBMATOMO_USER` : Utilisateur MySQL
- `DBMATOMO_PASSWORD` : Mot de passe MySQL
- `DBMATOMO_NAME` : Nom de la base de donnees

## Sauvegardes

Les sauvegardes sont automatiquement creees dans le dossier `./backups/` avec un timestamp.

```bash
# Creer une sauvegarde
make backup-db

# Restaurer une sauvegarde
make restore-db FILE=backups/matomo_backup_20251018_143000.sql
```

## Aide

Pour voir toutes les commandes disponibles :

```bash
make help
```
