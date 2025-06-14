# 🚀 Guia Completo: Deploy Automático do GitHub

Este guia mostra como configurar deploy automático do seu repositório privado GitHub para seu VPS.

## 🎯 **Opções de Deploy Disponíveis**

### 1. **GitHub Actions** (Recomendado) ✨

-   ✅ Build automático no push
-   ✅ Testes antes do deploy
-   ✅ Deploy apenas se tests passarem
-   ✅ Notificações automáticas
-   ✅ Rollback automático em caso de falha

### 2. **Webhook Deploy** (Simples)

-   ✅ Deploy direto no push
-   ✅ Mais rápido que GitHub Actions
-   ⚠️ Sem testes automáticos
-   ⚠️ Sem notificações

### 3. **Watchtower** (Automático)

-   ✅ Atualização automática por polling
-   ✅ Zero configuração
-   ⚠️ Requer imagem no registry

### 4. **Coolify Integration** (Platform)

-   ✅ Interface visual
-   ✅ Fácil configuração
-   ✅ Monitoramento integrado

---

## 🔧 **Setup Completo - GitHub Actions**

### **Etapa 1: Preparar o VPS**

```bash
# Conectar no VPS via SSH
ssh usuario@seu-vps-ip

# 1. Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 2. Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 3. Criar diretório do projeto
sudo mkdir -p /opt/tira-fundo-backend
sudo chown $USER:$USER /opt/tira-fundo-backend

# 4. Clonar repositório (primeira vez)
cd /opt
git clone https://github.com/SEU_USUARIO/tira-fundo-backend.git
cd tira-fundo-backend

# 5. Configurar ambiente
cp .env.example .env
nano .env  # Configure suas variáveis
```

### **Etapa 2: Configurar Chaves SSH**

```bash
# No seu computador local:
# Gerar chave SSH para deploy
ssh-keygen -t rsa -b 4096 -C "deploy@github-actions" -f ~/.ssh/deploy_key

# Adicionar chave pública ao VPS
ssh-copy-id -i ~/.ssh/deploy_key.pub usuario@seu-vps-ip

# Testar conexão
ssh -i ~/.ssh/deploy_key usuario@seu-vps-ip

# Copiar chave privada (para adicionar nos secrets)
cat ~/.ssh/deploy_key
```

### **Etapa 3: Configurar Secrets no GitHub**

1. Vá para seu repositório no GitHub
2. `Settings` → `Secrets and variables` → `Actions`
3. Adicione estes secrets:

```env
VPS_HOST=192.168.1.100        # IP do seu VPS
VPS_USERNAME=usuario          # Usuário SSH
VPS_PRIVATE_KEY=-----BEGIN... # Chave privada SSH (conteúdo completo)
VPS_PORT=22                   # Porta SSH (opcional)
DEPLOY_PATH=/opt/tira-fundo-backend  # Caminho no VPS (opcional)
```

### **Etapa 4: Configurar .env de Produção**

No VPS, edite o arquivo `.env`:

```env
# .env no VPS
HOST=0.0.0.0
PORT=8000
WORKERS=3
LOG_LEVEL=info

# Configure seu domínio
CORS_ORIGINS=https://seudominio.com,https://www.seudominio.com

# Configurações IA
DEFAULT_MODE=base
MAX_BATCH_SIZE=3
MAX_FILE_SIZE=3145728
SUPPRESS_PYTORCH_WARNINGS=true
```

### **Etapa 5: Testar Deploy**

```bash
# Fazer um commit e push
git add .
git commit -m "Configure GitHub Actions deploy"
git push origin main

# Verificar no GitHub
# Vá em "Actions" e acompanhe o workflow
```

---

## ⚡ **Setup Rápido - Webhook Deploy**

### **Etapa 1: Script no VPS**

```bash
# No VPS, criar o script de deploy
sudo mkdir -p /opt/scripts
sudo cp scripts/deploy-webhook.sh /opt/scripts/
sudo chmod +x /opt/scripts/deploy-webhook.sh

# Editar configurações no script
sudo nano /opt/scripts/deploy-webhook.sh
# Altere REPO_URL para sua URL do repositório
```

### **Etapa 2: Webhook Listener**

```bash
# Instalar webhook listener (no VPS)
sudo apt install webhook

# Criar configuração do webhook
sudo nano /etc/webhook/hooks.json
```

```json
[
    {
        "id": "deploy-tira-fundo",
        "execute-command": "/opt/scripts/deploy-webhook.sh",
        "command-working-directory": "/opt/tira-fundo-backend",
        "http-methods": ["POST"],
        "match": [
            {
                "type": "payload-hash-sha256",
                "secret": "seu-secret-webhook",
                "parameter": {
                    "source": "header",
                    "name": "X-Hub-Signature-256"
                }
            }
        ]
    }
]
```

```bash
# Iniciar webhook listener
sudo systemctl enable webhook
sudo systemctl start webhook
```

### **Etapa 3: Configurar no GitHub**

1. Repositório → `Settings` → `Webhooks`
2. Add webhook:
    - URL: `http://seu-vps-ip:9000/hooks/deploy-tira-fundo`
    - Content type: `application/json`
    - Secret: `seu-secret-webhook`
    - Events: `Just the push event`

---

## 🐳 **Setup Registry - Docker Hub/GHCR**

### **Usando GitHub Container Registry**

```bash
# No workflow já está configurado para GHCR
# Imagem será: ghcr.io/seu-usuario/tira-fundo-backend:latest

# No VPS, usar docker-compose.registry.yml
cp docker-compose.registry.yml docker-compose.prod.yml

# Editar e configurar sua imagem
nano docker-compose.prod.yml
# Altere: ghcr.io/SEU_USUARIO/tira-fundo-backend:latest
```

### **Deploy com Registry**

```bash
# Login no registry (no VPS)
echo $GITHUB_TOKEN | docker login ghcr.io -u seu-usuario --password-stdin

# Pull e deploy
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

---

## 🔄 **Setup Watchtower (Auto-Update)**

```bash
# Adicionar ao docker-compose.prod.yml (já incluído)
docker-compose -f docker-compose.prod.yml --profile auto-update up -d

# Watchtower verificará atualizações a cada 5 minutos
# E fará deploy automático de novas versões
```

---

## 📊 **Monitoramento e Logs**

### **Verificar Status**

```bash
# Status dos containers
docker-compose -f docker-compose.prod.yml ps

# Logs em tempo real
docker-compose -f docker-compose.prod.yml logs -f

# Health check
curl http://localhost/health

# Métricas de sistema
docker stats
```

### **Logs de Deploy**

```bash
# GitHub Actions
# Veja em: https://github.com/seu-usuario/repositorio/actions

# Webhook logs
sudo journalctl -u webhook -f

# Container logs
docker logs removal-bg-backend --tail=50
```

---

## 🚨 **Troubleshooting**

### **Erro: Permission denied (publickey)**

```bash
# Verificar chave SSH
ssh -i ~/.ssh/deploy_key -v usuario@vps-ip

# Recriar chaves se necessário
ssh-keygen -t rsa -b 4096 -C "deploy@github"
```

### **Erro: Docker build failed**

```bash
# Verificar Dockerfile
docker build -t test .

# Verificar recursos do VPS
free -h
df -h
```

### **Erro: Health check failed**

```bash
# Verificar logs do container
docker logs removal-bg-backend

# Verificar porta e bind
netstat -tlnp | grep 8000

# Testar manualmente
curl -v http://localhost:8000/health
```

### **Erro: Out of memory**

```bash
# Reduzir workers
echo "WORKERS=1" >> .env

# Adicionar swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

## ✅ **Checklist Final**

-   [ ] VPS configurado com Docker
-   [ ] Repositório clonado no VPS
-   [ ] Arquivo .env configurado
-   [ ] Chaves SSH configuradas
-   [ ] Secrets do GitHub configurados
-   [ ] Primeiro deploy testado
-   [ ] Health check funcionando
-   [ ] Domínio configurado (se aplicável)
-   [ ] SSL configurado (se aplicável)
-   [ ] Monitoramento configurado

---

## 🎉 **Deploy Finalizado!**

Após seguir este guia, você terá:

✅ **Deploy automático** a cada push na branch main  
✅ **Testes automáticos** antes do deploy  
✅ **Rollback automático** em caso de falha  
✅ **Notificações** do status do deploy  
✅ **Monitoramento** da aplicação

Seu backend estará acessível em:

-   **Health Check**: `http://seu-vps/health`
-   **API**: `http://seu-vps/remove-background`
-   **Docs**: `http://seu-vps/docs` (se habilitado)

---

**🔥 Pronto para produção!** 🚀
