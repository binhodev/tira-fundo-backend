# Deploy Simples - GitHub para Servidor

Este é um guia para fazer deploy simples direto do GitHub, sem webhooks ou configurações complexas.

## 🎯 Conceito Simples

1. **Servidor puxa código do GitHub**
2. **Faz build local com Docker**
3. **Roda com docker-compose**
4. **Sem registry externo, sem CI/CD complexo**

---

## 📋 Pré-requisitos

### No seu servidor (VPS/Cloud):

-   Docker e Docker Compose instalados
-   Git instalado
-   Acesso SSH ao servidor

---

## 🔐 Configuração do Repositório Privado

### 1. Gerar Token do GitHub

1. Vá em GitHub → Settings → Developer Settings → Personal Access Tokens
2. Gere um token com permissões:
    - `repo` (acesso completo ao repositório)
3. Copie o token (só aparece uma vez!)

### 2. Configurar Git no Servidor

```bash
# Conecte no seu servidor via SSH
ssh usuario@seu-servidor.com

# Configure git para usar o token
git config --global credential.helper store

# Ao fazer o primeiro clone, use:
# https://SEU_TOKEN@github.com/SEU_USUARIO/tira-fundo-backend.git
```

---

## 🚀 Instalação e Primeiro Deploy

### 1. Copiar Script de Deploy

```bash
# No servidor, baixe o script
wget https://raw.githubusercontent.com/SEU_USUARIO/tira-fundo-backend/main/deploy-simple.sh
chmod +x deploy-simple.sh

# OU copie manualmente o arquivo deploy-simple.sh para o servidor
```

### 2. Editar Configurações

```bash
nano deploy-simple.sh
```

Altere essas linhas:

```bash
PROJECT_DIR="/opt/tira-fundo-backend"  # Onde instalar
GITHUB_REPO="https://SEU_TOKEN@github.com/SEU_USUARIO/tira-fundo-backend.git"
BRANCH="main"  # ou master
```

### 3. Executar Primeiro Deploy

```bash
sudo ./deploy-simple.sh
```

---

## 🔄 Deploy de Atualizações

Para atualizar a aplicação após mudanças no GitHub:

```bash
# Simplesmente execute o script novamente
sudo ./deploy-simple.sh
```

**O script automaticamente:**

-   Puxa as mudanças do GitHub
-   Preserva seu arquivo `.env`
-   Reconstrói a aplicação
-   Reinicia os containers

---

## 📁 Estrutura no Servidor

```
/opt/tira-fundo-backend/
├── .env                 # Suas configurações (preservado)
├── docker-compose.yml   # Do GitHub
├── Dockerfile          # Do GitHub
├── main.py             # Do GitHub
├── requirements.txt    # Do GitHub
└── ...                 # Outros arquivos do projeto
```

---

## 🛠️ Comandos Úteis

### Ver logs da aplicação:

```bash
cd /opt/tira-fundo-backend
docker-compose logs -f
```

### Parar aplicação:

```bash
cd /opt/tira-fundo-backend
docker-compose down
```

### Iniciar aplicação:

```bash
cd /opt/tira-fundo-backend
docker-compose up -d
```

### Ver status:

```bash
cd /opt/tira-fundo-backend
docker-compose ps
```

---

## ⚙️ Configuração do .env

Crie o arquivo `.env` no servidor com suas configurações:

```env
# Configurações da aplicação
HOST=0.0.0.0
PORT=8000
DEBUG=false

# Configurações específicas do seu ambiente
# (adicione conforme necessário)
```

---

## 🔧 Personalização

### Para usar porta diferente:

Edite `docker-compose.yml` e altere a porta:

```yaml
ports:
    - "3000:8000" # porta_externa:porta_interna
```

### Para usar domínio personalizado:

Configure um proxy reverso (nginx) apontando para `localhost:8000`

---

## 🆘 Troubleshooting

### Erro de permissão:

```bash
sudo chown -R $USER:$USER /opt/tira-fundo-backend
```

### Erro de token GitHub:

```bash
# Gere um novo token e atualize a URL no script
```

### Aplicação não inicia:

```bash
# Verifique os logs
docker-compose logs
```

### Porta ocupada:

```bash
# Verifique o que está usando a porta
sudo netstat -tulpn | grep :8000
```

---

## ✨ Vantagens desta Abordagem

-   ✅ **Simples**: Um script, um comando
-   ✅ **Rápido**: Build local, sem registry
-   ✅ **Confiável**: Preserva configurações
-   ✅ **Transparente**: Você vê tudo acontecendo
-   ✅ **Fácil debug**: Logs diretos no servidor
