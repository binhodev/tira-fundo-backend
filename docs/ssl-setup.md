# Configuração SSL para Produção

## 🔒 HTTPS com SSL/TLS

Para produção, é essencial configurar HTTPS. Aqui estão as opções:

### Opção 1: Let's Encrypt (Recomendado)

1. **Instalar Certbot:**

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install certbot python3-certbot-nginx

# CentOS/RHEL
sudo yum install certbot python3-certbot-nginx
```

2. **Gerar certificado:**

```bash
sudo certbot --nginx -d seudominio.com -d www.seudominio.com
```

3. **Configurar renovação automática:**

```bash
sudo crontab -e
# Adicionar linha:
0 12 * * * /usr/bin/certbot renew --quiet
```

### Opção 2: Certificado próprio (Desenvolvimento)

1. **Gerar certificado autoassinado:**

```bash
mkdir -p ssl
cd ssl

# Gerar chave privada
openssl genrsa -out private.key 2048

# Gerar certificado
openssl req -new -x509 -key private.key -out certificate.crt -days 365

# Para development, use:
# Country: BR
# State: Seu Estado
# City: Sua Cidade
# Organization: Sua Empresa
# Unit: IT
# Common Name: localhost (IMPORTANTE!)
# Email: seu@email.com
```

### Opção 3: Configuração Nginx HTTPS

Crie: `nginx/conf.d/ssl.conf`

```nginx
server {
    listen 443 ssl http2;
    server_name seudominio.com www.seudominio.com;

    ssl_certificate /etc/nginx/ssl/certificate.crt;
    ssl_certificate_key /etc/nginx/ssl/private.key;

    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Proxy para backend
    location / {
        proxy_pass http://backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name seudominio.com www.seudominio.com;
    return 301 https://$server_name$request_uri;
}
```

### Opção 4: Cloudflare (Recomendado para facilidade)

1. **Configure seu domínio no Cloudflare**
2. **Ative SSL/TLS no painel**
3. **Configure Origin Certificate:**

    - Vá em SSL/TLS > Origin Server
    - Create Certificate
    - Baixe os arquivos e coloque em `ssl/`

4. **Configure nginx para usar certificados Cloudflare**

### Testando SSL

```bash
# Testar certificado
openssl s_client -connect seudominio.com:443

# Testar com curl
curl -I https://seudominio.com/health

# Verificar rating SSL
# https://www.ssllabs.com/ssltest/
```

## 🔐 Configurações de Segurança Adicionais

### 1. Firewall (UFW)

```bash
# Permitir apenas portas necessárias
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw enable
```

### 2. Fail2Ban

```bash
# Instalar
sudo apt install fail2ban

# Configurar
sudo nano /etc/fail2ban/jail.local
```

### 3. Docker Security

```bash
# Executar como usuário não-root (já configurado no Dockerfile)
# Limitar recursos (já configurado no docker-compose)
# Scannear vulnerabilidades
docker scan removal-bg-backend
```

### 4. Monitoramento

-   Configure alertas para alta CPU/RAM
-   Monitore logs de acesso suspeito
-   Configure backup automático dos dados

## 🚀 Deploy com SSL

Após configurar SSL, atualize suas variáveis:

```env
# .env
CORS_ORIGINS=https://seudominio.com,https://www.seudominio.com
```

E execute o deploy:

```bash
# PowerShell
.\deploy.ps1 -Production

# Bash
./deploy.sh production
```
