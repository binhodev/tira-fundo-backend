#!/bin/bash

# ========================================
# Script de Deploy Simples - Tira Fundo Backend
# ========================================

set -e  # Para em caso de erro

# Configurações (edite conforme necessário)
PROJECT_DIR="/opt/tira-fundo-backend"
GITHUB_REPO="https://github.com/SEU_USUARIO/tira-fundo-backend.git"
BRANCH="main"

echo "🚀 Iniciando deploy do Tira Fundo Backend..."

# Verificar se o diretório do projeto existe
if [ ! -d "$PROJECT_DIR" ]; then
    echo "📁 Criando diretório do projeto..."
    sudo mkdir -p "$PROJECT_DIR"
    sudo chown $USER:$USER "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"

# Se é o primeiro deploy, clonar o repositório
if [ ! -d ".git" ]; then
    echo "📥 Clonando repositório pela primeira vez..."
    git clone "$GITHUB_REPO" .
else
    echo "🔄 Atualizando código do GitHub..."
    
    # Fazer backup do .env se existir
    if [ -f ".env" ]; then
        echo "💾 Fazendo backup do .env..."
        cp .env .env.backup
    fi
    
    # Resetar mudanças locais e puxar do GitHub
    git reset --hard HEAD
    git pull origin "$BRANCH"
    
    # Restaurar .env se havia backup
    if [ -f ".env.backup" ]; then
        echo "🔧 Restaurando configurações..."
        cp .env.backup .env
    fi
fi

echo "🛑 Parando containers antigos..."
docker-compose -f docker-compose.simple.yml down || true

echo "🏗️ Construindo nova imagem..."
docker-compose -f docker-compose.simple.yml build --no-cache

echo "🚀 Iniciando aplicação..."
docker-compose -f docker-compose.simple.yml up -d

echo "⏳ Aguardando aplicação inicializar..."
sleep 15

# Verificar se a aplicação está funcionando
echo "🔍 Verificando saúde da aplicação..."
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Deploy realizado com sucesso!"
    echo "🌐 Aplicação disponível em: http://localhost:8000"
    
    # Limpar imagens antigas
    echo "🧹 Limpando imagens antigas..."
    docker image prune -f
    
else
    echo "❌ Erro no deploy! Verificando logs..."
    docker-compose -f docker-compose.simple.yml logs --tail=50
    exit 1
fi

echo "🎉 Deploy concluído!"
