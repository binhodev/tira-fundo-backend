# Configuração de Secrets para GitHub Actions

# Adicione estes secrets no seu repositório GitHub

## SECRETS OBRIGATÓRIOS

### 1. VPS_HOST

# IP ou domínio do seu VPS

# Exemplo: 192.168.1.100 ou vps.seudominio.com

### 2. VPS_USERNAME

# Nome de usuário SSH do VPS

# Exemplo: root ou ubuntu

### 3. VPS_PRIVATE_KEY

# Chave privada SSH para acesso ao VPS

# Gere com: ssh-keygen -t rsa -b 4096 -C "deploy@github"

# Cole aqui o conteúdo do arquivo ~/.ssh/id_rsa (chave privada)

### 4. VPS_PORT (opcional)

# Porta SSH do VPS (padrão: 22)

# Exemplo: 22

### 5. DEPLOY_PATH (opcional)

# Caminho onde o projeto está no VPS

# Padrão: /opt/tira-fundo-backend

# Exemplo: /home/ubuntu/tira-fundo-backend

### 6. GITHUB_TOKEN

# Token de acesso do GitHub (já disponível automaticamente)

# Usado para pull de repositório privado

## SECRETS OPCIONAIS

### 7. SLACK_WEBHOOK_URL

# URL do webhook do Slack para notificações

# Exemplo: https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX

### 8. DOCKER_REGISTRY_USERNAME

# Nome de usuário do registry Docker (se usar registry privado)

### 9. DOCKER_REGISTRY_PASSWORD

# Senha do registry Docker (se usar registry privado)

### 10. ENVIRONMENT_VARIABLES

# Variáveis de ambiente específicas de produção

# Formato JSON: {"CORS_ORIGINS": "https://seudominio.com", "WORKERS": "3"}

## COMO CONFIGURAR NO GITHUB

1. Vá para o seu repositório no GitHub
2. Clique em "Settings" > "Secrets and variables" > "Actions"
3. Clique em "New repository secret"
4. Adicione cada secret com o nome exato listado acima
5. Cole o valor correspondente

## TESTE DE CONFIGURAÇÃO

Para testar se os secrets estão corretos:

1. Faça um push para branch main
2. Vá em "Actions" no GitHub
3. Verifique se o workflow executa sem erro
4. Confira os logs de cada job

## CONFIGURAÇÃO DO VPS

No seu VPS, certifique-se de que:

1. Docker e docker-compose estão instalados
2. A chave pública SSH está em ~/.ssh/authorized_keys
3. O usuário tem permissões sudo (se necessário)
4. O projeto está clonado em /opt/tira-fundo-backend (ou caminho configurado)

### Comandos para configurar o VPS:

```bash
# 1. Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 2. Criar diretório do projeto
sudo mkdir -p /opt/tira-fundo-backend
sudo chown $USER:$USER /opt/tira-fundo-backend

# 3. Clonar repositório (primeira vez)
cd /opt
git clone https://github.com/SEU_USUARIO/tira-fundo-backend.git

# 4. Configurar .env
cd tira-fundo-backend
cp .env.example .env
# Editar .env com suas configurações
nano .env

# 5. Testar deploy manual
chmod +x scripts/deploy-webhook.sh
./scripts/deploy-webhook.sh
```

## CONFIGURAÇÃO DO DOMÍNIO

Se você tem um domínio:

1. Configure DNS A record apontando para IP do VPS
2. Configure SSL (Let's Encrypt recomendado)
3. Atualize CORS_ORIGINS no .env
4. Configure nginx para HTTPS

## TROUBLESHOOTING

### Erro de conexão SSH:

-   Verifique se VPS_HOST, VPS_USERNAME e VPS_PRIVATE_KEY estão corretos
-   Teste conexão SSH manual: `ssh -i chave_privada usuario@vps_host`

### Erro de permissão Docker:

-   Adicione usuário ao grupo docker: `sudo usermod -aG docker $USER`
-   Reinicie a sessão SSH

### Erro de memória:

-   Reduza WORKERS para 1 ou 2
-   Aumente swap do VPS
-   Monitore uso de memória: `free -h`

### Deploy não funciona:

-   Verifique logs do workflow no GitHub Actions
-   Verifique logs do container: `docker logs removal-bg-backend`
-   Teste health check: `curl http://localhost/health`
