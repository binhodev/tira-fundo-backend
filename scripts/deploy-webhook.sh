#!/bin/bash

# Script de Deploy via Webhook
# Coloque este script no seu VPS em /opt/scripts/deploy-webhook.sh

set -e

echo "🚀 Iniciando deploy via webhook..."

# Configurações (ajuste conforme necessário)
PROJECT_DIR="/opt/tira-fundo-backend"
REPO_URL="https://github.com/SEU_USUARIO/tira-fundo-backend.git"
BRANCH="main"
LOG_FILE="/var/log/deploy-webhook.log"

# Função de log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Verificar se o diretório existe
if [ ! -d "$PROJECT_DIR" ]; then
    log "❌ Diretório do projeto não existe: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"

# Backup do .env atual
if [ -f .env ]; then
    cp .env .env.backup
    log "📋 Backup do .env criado"
fi

# Parar containers
log "🛑 Parando containers..."
docker-compose -f docker-compose.prod.yml down || true

# Pull do código mais recente
log "📥 Baixando código mais recente do GitHub..."
if [ -d ".git" ]; then
    # Se é um repositório clonado
    git fetch origin
    git reset --hard origin/$BRANCH
else
    # Se não é um repositório, fazer clone
    cd ..
    rm -rf tira-fundo-backend
    git clone -b $BRANCH $REPO_URL tira-fundo-backend
    cd tira-fundo-backend
fi

# Restaurar .env
if [ -f .env.backup ]; then
    cp .env.backup .env
    log "📋 .env restaurado"
fi

# Build e deploy
log "🏗️ Construindo e iniciando containers..."
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# Aguardar containers
log "⏳ Aguardando containers ficarem saudáveis..."
sleep 30

# Verificar health check
log "🏥 Verificando health check..."
if curl -f http://localhost/health > /dev/null 2>&1; then
    log "✅ Deploy realizado com sucesso!"
    
    # Limpar imagens antigas
    docker image prune -f
    
    # Logs recentes
    log "📊 Logs dos containers:"
    docker-compose -f docker-compose.prod.yml logs --tail=10
else
    log "❌ Deploy falhou - verificar logs"
    docker-compose -f docker-compose.prod.yml logs
    exit 1
fi

log "🎉 Deploy concluído!"
