# 🎨 Background Removal API

API para remoção de fundo usando IA com a biblioteca `transparent-background`. Solução completa dockerizada pronta para produção.

## 🚀 Features

-   ✅ Remoção de fundo com IA avançada (InSPyReNet)
-   ✅ Suporte a processamento individual e em lote
-   ✅ Múltiplos formatos de saída (RGBA, white, green, etc.)
-   ✅ Configuração Docker completa
-   ✅ Nginx com rate limiting e proxy reverso
-   ✅ Redis para cache (implementação futura)
-   ✅ Health checks e monitoramento
-   ✅ Configurações otimizadas para produção

## 📋 Requisitos

-   Docker 20.10+
-   Docker Compose 2.0+
-   4GB+ RAM (recomendado 8GB)
-   GPU opcional (CUDA/ROCm)

## 🏗️ Instalação

### Desenvolvimento Local

```bash
# 1. Clone o repositório
git clone <url-do-repo>
cd tira-fundo-backend

# 2. Configure o ambiente
cp .env.example .env
# Edite o arquivo .env conforme necessário

# 3. Execute com Docker
docker-compose up --build

# Ou use o script PowerShell (Windows)
.\deploy.ps1

# Ou use o script Bash (Linux/Mac)
chmod +x deploy.sh
./deploy.sh
```

### Produção

```bash
# 1. Configure o ambiente de produção
cp .env.example .env
# Configure CORS_ORIGINS, domínio, etc.

# 2. Deploy em produção
docker-compose -f docker-compose.prod.yml up --build -d

# Ou use o script PowerShell (Windows)
.\deploy.ps1 -Production

# Ou use o script Bash (Linux/Mac)
./deploy.sh production
```

## 🔧 Configuração

### Variáveis de Ambiente (.env)

```env
# Servidor
HOST=0.0.0.0
PORT=8000
WORKERS=2
LOG_LEVEL=info

# CORS - Configure seus domínios
CORS_ORIGINS=https://seudominio.com,https://www.seudominio.com

# IA e Processamento
DEFAULT_MODE=base
MAX_BATCH_SIZE=5
MAX_FILE_SIZE=10485760  # 10MB
SUPPRESS_PYTORCH_WARNINGS=true

# Cache
CACHE_DIR=/app/cache
MODEL_CACHE_SIZE=2
```

### Nginx Rate Limiting

-   API geral: 10 req/s
-   Upload de imagens: 2 req/s
-   Batch processing: 2 req/s com burst menor

## 📡 Endpoints

### GET `/`

Informações gerais da API

### GET `/health`

Health check do serviço

### GET `/models`

Informações sobre modelos disponíveis

### POST `/remove-background`

Remove o fundo de uma imagem

**Parâmetros:**

-   `file`: Arquivo de imagem (multipart/form-data)
-   `mode`: Modo do modelo ('base', 'fast', 'base-nightly') - padrão: 'base'
-   `output_type`: Tipo de saída ('rgba', 'white', 'green', 'map', 'blur', 'overlay') - padrão: 'rgba'
-   `threshold`: Limiar para predição (0.0-1.0) - opcional

**Resposta:**

```json
{
    "success": true,
    "image": "base64_encoded_image",
    "processing_time": 1250,
    "model_info": {
        "mode": "base",
        "device": "cuda:0",
        "type": "rgba",
        "processing_time_ms": 1250,
        "input_size": [1920, 1080],
        "output_size": [1920, 1080]
    },
    "filename": "image.jpg"
}
```

### POST `/batch-remove`

Remove o fundo de múltiplas imagens

**Parâmetros:**

-   `files`: Array de arquivos de imagem
-   `mode`, `output_type`, `threshold`: Mesmos da rota individual

**Resposta:**

```json
{
    "results": [
        {
            "success": true,
            "image": "base64_encoded_image",
            "filename": "image1.jpg",
            "processing_time": 1200
        }
    ],
    "total_processing_time": 2500,
    "total_images": 3,
    "successful": 3,
    "failed": 0
}
```

## 🐳 Docker

### Desenvolvimento

```bash
docker-compose up --build
```

### Produção

```bash
docker-compose -f docker-compose.prod.yml up --build -d
```

### Scripts de Deploy

**Windows (PowerShell):**

```powershell
# Desenvolvimento
.\deploy.ps1

# Produção
.\deploy.ps1 -Production

# Parar containers
.\deploy.ps1 -Stop

# Ver logs
.\deploy.ps1 -Logs
```

**Linux/Mac (Bash):**

```bash
# Desenvolvimento
./deploy.sh

# Produção
./deploy.sh production

# Parar containers
./deploy.sh stop

# Ver logs
./deploy.sh logs
```

## 📊 Monitoramento

### Health Check

```bash
curl http://localhost/health
```

### Logs dos Containers

```bash
docker-compose logs -f backend
docker-compose logs -f nginx
docker-compose logs -f redis
```

### Métricas de Sistema

```bash
docker stats
```

## 🔒 Segurança

-   Rate limiting configurado no Nginx
-   Validação de tipos de arquivo
-   Limite de tamanho de arquivo (10MB)
-   Headers de segurança configurados
-   CORS configurável por ambiente

## 🚀 Performance

### Otimizações Implementadas

-   Cache de modelos IA em memória
-   Processamento assíncrono
-   Nginx com gzip e buffers otimizados
-   Configuração otimizada de workers
-   Rate limiting para prevenir sobrecarga

### Recursos Recomendados

**VPS Mínimo:**

-   4 CPU cores
-   8GB RAM
-   50GB SSD

**VPS Recomendado:**

-   6+ CPU cores
-   16GB+ RAM
-   100GB+ SSD
-   GPU opcional (RTX 3060+ ou equivalente)

## 🔧 Troubleshooting

### Container não inicia

```bash
# Verificar logs
docker-compose logs backend

# Verificar recursos disponíveis
docker system df
free -h
```

### API não responde

```bash
# Verificar health check
curl http://localhost/health

# Verificar status dos containers
docker-compose ps

# Reiniciar containers
docker-compose restart
```

### Erro de memória

```bash
# Reduzir workers no .env
WORKERS=1

# Reduzir cache de modelos
MODEL_CACHE_SIZE=1

# Reduzir batch size
MAX_BATCH_SIZE=3
```

### Performance baixa

```bash
# Verificar uso de GPU
nvidia-smi  # Se disponível

# Monitorar recursos
docker stats

# Verificar logs de performance
docker-compose logs backend | grep "processing_time"
```

## 🛠️ Desenvolvimento

### Instalação Local (sem Docker)

```bash
# 1. Criar ambiente virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate  # Windows

# 2. Instalar dependências
pip install -r requirements.txt

# 3. Executar
python main.py
```

### Estrutura do Projeto

```
├── main.py              # API principal
├── requirements.txt     # Dependências Python
├── Dockerfile          # Imagem Docker
├── docker-compose.yml  # Desenvolvimento
├── docker-compose.prod.yml  # Produção
├── deploy.ps1          # Script deploy Windows
├── deploy.sh           # Script deploy Linux/Mac
├── .env.example        # Template de configuração
├── nginx/              # Configurações Nginx
│   ├── nginx.conf
│   └── conf.d/
├── docs/               # Documentação
└── utils/              # Utilitários (futuro)
```

## 📝 Changelog

### v1.0.0

-   ✅ API básica funcionando
-   ✅ Docker e docker-compose configurados
-   ✅ Nginx com rate limiting
-   ✅ Scripts de deploy
-   ✅ Documentação completa

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

---

## 🆘 Suporte

Para suporte, abra uma issue no GitHub ou entre em contato através do email.

**Desenvolvido com ❤️ usando FastAPI + transparent-background**

Verifica o status do servidor.

### GET `/models`

Lista os modelos disponíveis e informações do sistema.
