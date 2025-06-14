# 🚀 Deploy no Coolify

## Pré-requisitos

-   VPS com Coolify instalado ✅
-   Repositório Git (GitHub/GitLab)
-   8GB RAM (perfeito para o projeto) ✅

## 📋 Passos para Deploy:

### 1. **Configurar Repositório**

```bash
# Push do projeto para GitHub/GitLab
git add .
git commit -m "Configuração para Coolify"
git push origin main
```

### 2. **Criar Aplicação no Coolify**

1. Acesse a interface web do Coolify
2. **New Resource** → **Application**
3. **Source**: Conectar seu repositório Git
4. **Build Pack**: Docker
5. **Port**: 8000

### 3. **Configurar Environment Variables**

Na interface do Coolify, adicione estas variáveis:

```bash
HOST=0.0.0.0
PORT=8000
WORKERS=3
LOG_LEVEL=info
CORS_ORIGINS=https://seu-frontend.com,https://www.seu-frontend.com
DEFAULT_MODE=base
MAX_BATCH_SIZE=3
ENABLE_MODEL_CACHE=true
SUPPRESS_PYTORCH_WARNINGS=true
CACHE_DIR=/app/cache
MODEL_CACHE_SIZE=2
MAX_FILE_SIZE=3145728
```

### 4. **Configurar Volumes Persistentes**

-   `/app/cache` → Para cache dos modelos IA
-   `/app/logs` → Para logs da aplicação

### 5. **Configurar Domínio**

-   **Domain**: `api.seudominio.com` (ou o que preferir)
-   **SSL**: Automático (Let's Encrypt)

### 6. **Deploy Automático**

-   Ative **Auto Deploy** em cada push
-   **Branch**: main

## 🔧 Configurações Avançadas:

### **Resource Limits (Recomendado para VPS 8GB):**

-   **Memory**: 4GB limit, 2GB reserved
-   **CPU**: 2 cores limit, 1 core reserved

### **Health Check:**

-   **Path**: `/health`
-   **Interval**: 30s
-   **Timeout**: 10s

### **Rate Limiting:**

O Coolify usa Traefik que já tem rate limiting nativo, mais simples que nossa configuração Nginx!

## 🎯 Vantagens do Coolify:

✅ **SSL Automático** - HTTPS configurado automaticamente
✅ **Proxy Reverso** - Traefik gerencia tudo
✅ **Deploy Automático** - Push no Git = deploy automático  
✅ **Monitoramento** - Logs e métricas na interface
✅ **Rollback Fácil** - Voltar versões com 1 clique
✅ **Zero Downtime** - Deploys sem interrupção
✅ **Backup Automático** - Volumes protegidos

## 🚨 Importante:

1. **Remova a configuração Nginx** - Coolify já tem proxy
2. **Use apenas o Dockerfile** - Não precisa docker-compose
3. **Configure CORS** para o domínio real do frontend
4. **Ajuste MAX_FILE_SIZE** se necessário

## 🚨 Soluções para Problemas Comuns:

### **Erro de Healthcheck (unhealthy)**

Se você ver o erro:

```
Healthcheck status: "unhealthy"
/bin/sh: 1: curl: not found
```

**Solução 1 - Usar Dockerfile com curl:**

-   Use o `Dockerfile` (já inclui curl)
-   Ou use `Dockerfile.coolify` (sem healthcheck)

**Solução 2 - Desabilitar healthcheck no Coolify:**

1. Vá em **Settings** da aplicação
2. **Health Check** → Desabilite
3. Faça redeploy

### **Erro de Memória/CPU**

Se o container for terminado por falta de recursos:

-   Reduza `WORKERS` para 1 ou 2
-   Aumente os limites de memória no Coolify

### **Erro de Timeout**

Se a aplicação demora para iniciar:

-   Aumente o `start_period` no healthcheck
-   Verifique se os modelos estão sendo baixados corretamente

## 📞 Próximos Passos:

1. Fazer push do código atualizado
2. Criar aplicação no Coolify
3. Configurar as environment variables
4. Testar o deployment
5. Configurar domínio do frontend

**Muito mais simples que gerenciar Docker manualmente!** 🎉
