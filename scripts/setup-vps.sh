#!/bin/bash

# Script de Configuração Automática para Deploy do GitHub
# Execute este script no seu VPS para configurar tudo automaticamente

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Configuração Automática - Deploy GitHub${NC}"
echo "============================================="
echo ""

# Verificar se está rodando como root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}❌ Não execute como root. Execute como usuário normal.${NC}"
   exit 1
fi

# Configurações
PROJECT_NAME="tira-fundo-backend"
PROJECT_DIR="/opt/$PROJECT_NAME"
REPO_URL=""
BRANCH="main"

# Função para input do usuário
read_input() {
    local prompt="$1"
    local var_name="$2"
    local default_value="$3"
    
    if [ -n "$default_value" ]; then
        read -p "$prompt [$default_value]: " input
        input="${input:-$default_value}"
    else
        read -p "$prompt: " input
    fi
    
    declare -g "$var_name"="$input"
}

# Coletar informações
echo -e "${YELLOW}📋 Configuração Inicial${NC}"
echo "------------------------"

read_input "🔗 URL do repositório GitHub (https://github.com/usuario/repo.git)" "REPO_URL"
read_input "🌿 Branch para deploy" "BRANCH" "main"
read_input "📂 Diretório de deploy" "PROJECT_DIR" "/opt/$PROJECT_NAME"
read_input "🌐 Domínio (opcional, ex: api.seudominio.com)" "DOMAIN" ""
read_input "📧 Email para SSL (se usando domínio)" "EMAIL" ""

echo ""
echo -e "${BLUE}📋 Resumo da Configuração:${NC}"
echo "Repositório: $REPO_URL"
echo "Branch: $BRANCH"
echo "Diretório: $PROJECT_DIR"
echo "Domínio: ${DOMAIN:-"localhost"}"
echo ""

read -p "Continuar com a instalação? (y/n): " confirm
if [[ $confirm != [yY] ]]; then
    echo "Instalação cancelada."
    exit 0
fi

echo ""
echo -e "${GREEN}🔧 Iniciando configuração...${NC}"

# 1. Atualizar sistema
echo -e "${YELLOW}📦 Atualizando sistema...${NC}"
sudo apt update && sudo apt upgrade -y

# 2. Instalar dependências
echo -e "${YELLOW}📦 Instalando dependências...${NC}"
sudo apt install -y git curl wget unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# 3. Instalar Docker
echo -e "${YELLOW}🐳 Instalando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo -e "${GREEN}✅ Docker instalado${NC}"
else
    echo -e "${GREEN}✅ Docker já instalado${NC}"
fi

# 4. Instalar Docker Compose
echo -e "${YELLOW}🐳 Instalando Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✅ Docker Compose instalado${NC}"
else
    echo -e "${GREEN}✅ Docker Compose já instalado${NC}"
fi

# 5. Criar diretório do projeto
echo -e "${YELLOW}📂 Configurando diretório do projeto...${NC}"
sudo mkdir -p "$PROJECT_DIR"
sudo chown $USER:$USER "$PROJECT_DIR"

# 6. Clonar repositório
echo -e "${YELLOW}📥 Clonando repositório...${NC}"
if [ -d "$PROJECT_DIR/.git" ]; then
    echo -e "${YELLOW}⚠️ Repositório já existe. Fazendo pull...${NC}"
    cd "$PROJECT_DIR"
    git pull origin $BRANCH
else
    echo -e "${YELLOW}📥 Clonando repositório...${NC}"
    cd "$(dirname "$PROJECT_DIR")"
    git clone -b $BRANCH "$REPO_URL" "$(basename "$PROJECT_DIR")"
fi

cd "$PROJECT_DIR"

# 7. Configurar .env
echo -e "${YELLOW}⚙️ Configurando ambiente...${NC}"
if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}✅ Arquivo .env criado${NC}"
    
    # Configurar domínio se fornecido
    if [ -n "$DOMAIN" ]; then
        sed -i "s|CORS_ORIGINS=.*|CORS_ORIGINS=https://$DOMAIN,https://www.$DOMAIN|g" .env
        echo -e "${GREEN}✅ CORS configurado para $DOMAIN${NC}"
    fi
else
    echo -e "${GREEN}✅ Arquivo .env já existe${NC}"
fi

# 8. Criar diretórios necessários
echo -e "${YELLOW}📁 Criando diretórios...${NC}"
mkdir -p ssl logs scripts
chmod +x scripts/*.sh 2>/dev/null || true

# 9. Configurar SSL (se domínio fornecido)
if [ -n "$DOMAIN" ] && [ -n "$EMAIL" ]; then
    echo -e "${YELLOW}🔒 Configurando SSL com Let's Encrypt...${NC}"
    
    # Instalar certbot
    sudo apt install -y certbot python3-certbot-nginx
    
    # Configurar nginx temporário para validação
    sudo tee /etc/nginx/sites-available/temp-$DOMAIN > /dev/null <<EOL
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}
EOL
    
    sudo ln -sf /etc/nginx/sites-available/temp-$DOMAIN /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx
    
    # Gerar certificado
    sudo certbot certonly --webroot -w /var/www/html -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive
    
    # Copiar certificados para o projeto
    sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem ssl/certificate.crt
    sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem ssl/private.key
    sudo chown $USER:$USER ssl/*
    
    echo -e "${GREEN}✅ SSL configurado para $DOMAIN${NC}"
fi

# 10. Configurar firewall
echo -e "${YELLOW}🔥 Configurando firewall...${NC}"
sudo ufw allow 22      # SSH
sudo ufw allow 80      # HTTP
sudo ufw allow 443     # HTTPS
sudo ufw --force enable

# 11. Primeiro deploy
echo -e "${YELLOW}🚀 Realizando primeiro deploy...${NC}"
if [ -f docker-compose.prod.yml ]; then
    docker-compose -f docker-compose.prod.yml build --no-cache
    docker-compose -f docker-compose.prod.yml up -d
    
    # Aguardar containers
    echo -e "${YELLOW}⏳ Aguardando containers ficarem prontos...${NC}"
    sleep 30
    
    # Testar health check
    if curl -f http://localhost/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Deploy realizado com sucesso!${NC}"
    else
        echo -e "${YELLOW}⚠️ Health check falhou, mas containers estão rodando${NC}"
        docker-compose -f docker-compose.prod.yml logs --tail=10
    fi
else
    echo -e "${YELLOW}⚠️ docker-compose.prod.yml não encontrado. Deploy manual necessário.${NC}"
fi

# 12. Configurar cron para renovação SSL
if [ -n "$DOMAIN" ]; then
    echo -e "${YELLOW}🔄 Configurando renovação automática de SSL...${NC}"
    (crontab -l ; echo "0 2 * * * /usr/bin/certbot renew --quiet && docker-compose -f $PROJECT_DIR/docker-compose.prod.yml restart nginx") | crontab -
fi

# 13. Configurar webhook (opcional)
echo ""
read -p "🔗 Configurar webhook para deploy automático? (y/n): " setup_webhook
if [[ $setup_webhook == [yY] ]]; then
    echo -e "${YELLOW}🔗 Configurando webhook...${NC}"
    
    # Instalar webhook
    sudo apt install -y webhook
    
    # Configurar webhook
    sudo mkdir -p /etc/webhook
    sudo tee /etc/webhook/hooks.json > /dev/null <<EOL
[
  {
    "id": "deploy-$PROJECT_NAME",
    "execute-command": "$PROJECT_DIR/scripts/deploy-webhook.sh",
    "command-working-directory": "$PROJECT_DIR",
    "http-methods": ["POST"],
    "trigger-rule": {
      "match": {
        "type": "payload-hash-sha256",
        "secret": "$(openssl rand -hex 32)",
        "parameter": {
          "source": "header",
          "name": "X-Hub-Signature-256"
        }
      }
    }
  }
]
EOL
    
    # Configurar systemd service
    sudo tee /etc/systemd/system/webhook.service > /dev/null <<EOL
[Unit]
Description=Webhook Service
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/bin/webhook -hooks /etc/webhook/hooks.json -verbose -port 9000
Restart=always

[Install]
WantedBy=multi-user.target
EOL
    
    sudo systemctl daemon-reload
    sudo systemctl enable webhook
    sudo systemctl start webhook
    
    # Permitir porta do webhook
    sudo ufw allow 9000
    
    echo -e "${GREEN}✅ Webhook configurado na porta 9000${NC}"
    echo -e "${BLUE}🔗 URL do webhook: http://$(curl -s ifconfig.me):9000/hooks/deploy-$PROJECT_NAME${NC}"
fi

# 14. Informações finais
echo ""
echo -e "${GREEN}🎉 Configuração concluída com sucesso!${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}📋 Resumo da instalação:${NC}"
echo "• Docker e Docker Compose instalados"
echo "• Projeto clonado em: $PROJECT_DIR"
echo "• Arquivo .env configurado"
echo "• Firewall configurado"
[ -n "$DOMAIN" ] && echo "• SSL configurado para: $DOMAIN"
[ "$setup_webhook" == "y" ] && echo "• Webhook configurado"
echo ""

echo -e "${BLUE}🌐 Endpoints disponíveis:${NC}"
if [ -n "$DOMAIN" ]; then
    echo "• Health Check: https://$DOMAIN/health"
    echo "• API: https://$DOMAIN/remove-background"
    echo "• Documentação: https://$DOMAIN/docs"
else
    echo "• Health Check: http://$(curl -s ifconfig.me)/health"
    echo "• API: http://$(curl -s ifconfig.me)/remove-background"
fi
echo ""

echo -e "${BLUE}📱 Comandos úteis:${NC}"
echo "• Ver logs: cd $PROJECT_DIR && docker-compose -f docker-compose.prod.yml logs -f"
echo "• Restart: cd $PROJECT_DIR && docker-compose -f docker-compose.prod.yml restart"
echo "• Deploy manual: cd $PROJECT_DIR && ./scripts/deploy-webhook.sh"
echo "• Status: cd $PROJECT_DIR && docker-compose -f docker-compose.prod.yml ps"
echo ""

echo -e "${YELLOW}⚠️ Próximos passos:${NC}"
echo "1. Configure os secrets no GitHub (veja docs/github-deploy-setup.md)"
echo "2. Teste o primeiro deploy fazendo um push"
echo "3. Configure monitoramento (opcional)"
echo "4. Configure backup (opcional)"
echo ""

echo -e "${GREEN}✅ Servidor pronto para receber deploys automáticos do GitHub!${NC}"

# Reiniciar sessão para aplicar grupo docker
echo ""
echo -e "${YELLOW}🔄 Reinicie sua sessão SSH para aplicar as configurações do Docker.${NC}"
echo -e "${YELLOW}Ou execute: newgrp docker${NC}"
