#!/bin/bash

# Script de Deploy para Produção
# Background Removal API

set -e

echo "🚀 Iniciando deploy da API de Remoção de Fundo..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar se Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker não está rodando!${NC}"
    exit 1
fi

# Verificar se docker-compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose não está instalado!${NC}"
    exit 1
fi

# Verificar se arquivo .env existe
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️ Arquivo .env não encontrado!${NC}"
    echo "Copiando .env.example para .env..."
    cp .env.example .env
    echo -e "${YELLOW}⚠️ Configure o arquivo .env antes de continuar!${NC}"
    exit 1
fi

# Verificar variáveis obrigatórias
if ! grep -q "CORS_ORIGINS.*seudominio" .env; then
    echo -e "${YELLOW}⚠️ Configure o CORS_ORIGINS no arquivo .env para seu domínio!${NC}"
fi

echo "📋 Verificando estrutura do projeto..."

# Criar diretórios necessários se não existirem
mkdir -p ssl
mkdir -p logs

echo "🏗️ Construindo imagens Docker..."

# Build da imagem
docker-compose -f docker-compose.prod.yml build --no-cache

echo "🛑 Parando containers antigos..."

# Parar containers antigos
docker-compose -f docker-compose.prod.yml down

echo "🔄 Removendo imagens antigas..."

# Cleanup de imagens antigas
docker image prune -f

echo "🚀 Iniciando containers em produção..."

# Iniciar containers
docker-compose -f docker-compose.prod.yml up -d

echo "⏳ Aguardando containers ficarem prontos..."

# Aguardar containers ficarem healthy
sleep 30

echo "🔍 Verificando status dos containers..."

# Verificar status
docker-compose -f docker-compose.prod.yml ps

echo "🏥 Testando health check..."

# Testar endpoint de health
for i in {1..10}; do
    if curl -f http://localhost/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ API está respondendo!${NC}"
        break
    else
        echo "Tentativa $i/10 - Aguardando API ficar disponível..."
        sleep 5
    fi
done

echo "📊 Logs dos containers:"
docker-compose -f docker-compose.prod.yml logs --tail=20

echo -e "${GREEN}🎉 Deploy concluído com sucesso!${NC}"
echo ""
echo "📍 Endpoints disponíveis:"
echo "   - Health Check: http://localhost/health"
echo "   - Remove Background: http://localhost/remove-background"  
echo "   - Batch Remove: http://localhost/batch-remove"
echo "   - API Info: http://localhost/"
echo ""
echo "📱 Comandos úteis:"
echo "   - Ver logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "   - Parar: docker-compose -f docker-compose.prod.yml down"
echo "   - Restart: docker-compose -f docker-compose.prod.yml restart"
echo "   - Status: docker-compose -f docker-compose.prod.yml ps"
echo ""
echo -e "${YELLOW}⚠️ Lembre-se de configurar SSL para HTTPS em produção!${NC}"
