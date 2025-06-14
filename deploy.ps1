# Script de Deploy para Produção - PowerShell
# Background Removal API

param(
    [switch]$Production,
    [switch]$Development,
    [switch]$Stop,
    [switch]$Logs
)

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success { Write-ColorOutput Green $args }
function Write-Warning { Write-ColorOutput Yellow $args }
function Write-Error { Write-ColorOutput Red $args }

Write-Success "🚀 Background Removal API - Deploy Script"
Write-Output ""

# Verificar se Docker está rodando
try {
    docker info *>$null
} catch {
    Write-Error "❌ Docker não está rodando!"
    exit 1
}

# Verificar se docker-compose está instalado
if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Error "❌ docker-compose não está instalado!"
    exit 1
}

# Definir arquivo compose baseado no parâmetro
$composeFile = if ($Production) { "docker-compose.prod.yml" } else { "docker-compose.yml" }
$environment = if ($Production) { "PRODUÇÃO" } else { "DESENVOLVIMENTO" }

Write-Output "📋 Modo: $environment"
Write-Output "📋 Compose: $composeFile"
Write-Output ""

# Comando para parar
if ($Stop) {
    Write-Warning "🛑 Parando containers..."
    docker-compose -f $composeFile down
    Write-Success "✅ Containers parados!"
    exit 0
}

# Comando para logs
if ($Logs) {
    Write-Output "📊 Mostrando logs..."
    docker-compose -f $composeFile logs -f
    exit 0
}

# Verificar se arquivo .env existe
if (!(Test-Path .env)) {
    Write-Warning "⚠️ Arquivo .env não encontrado!"
    Write-Output "Copiando .env.example para .env..."
    Copy-Item .env.example .env
    Write-Warning "⚠️ Configure o arquivo .env antes de continuar!"
    exit 1
}

# Verificar configurações para produção
if ($Production) {
    $envContent = Get-Content .env -Raw
    if ($envContent -match "seudominio") {
        Write-Warning "⚠️ Configure o CORS_ORIGINS no arquivo .env para seu domínio!"
        Write-Output "Pressione qualquer tecla para continuar ou Ctrl+C para cancelar..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

Write-Output "📋 Verificando estrutura do projeto..."

# Criar diretórios necessários se não existirem
$dirs = @("ssl", "logs")
foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Output "📁 Criado diretório: $dir"
    }
}

Write-Output "🏗️ Construindo imagens Docker..."

# Build da imagem
docker-compose -f $composeFile build --no-cache

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Erro no build das imagens!"
    exit 1
}

Write-Output "🛑 Parando containers antigos..."

# Parar containers antigos
docker-compose -f $composeFile down

Write-Output "🔄 Removendo imagens antigas..."

# Cleanup de imagens antigas
docker image prune -f

Write-Output "🚀 Iniciando containers..."

# Iniciar containers
docker-compose -f $composeFile up -d

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Erro ao iniciar containers!"
    exit 1
}

Write-Output "⏳ Aguardando containers ficarem prontos..."

# Aguardar containers ficarem healthy
Start-Sleep -Seconds 30

Write-Output "🔍 Verificando status dos containers..."

# Verificar status
docker-compose -f $composeFile ps

Write-Output "🏥 Testando health check..."

# Testar endpoint de health
$healthOk = $false
for ($i = 1; $i -le 10; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost/health" -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Success "✅ API está respondendo!"
            $healthOk = $true
            break
        }
    } catch {
        Write-Output "Tentativa $i/10 - Aguardando API ficar disponível..."
        Start-Sleep -Seconds 5
    }
}

if (!$healthOk) {
    Write-Warning "⚠️ API pode não estar respondendo corretamente"
}

Write-Output ""
Write-Output "📊 Logs recentes dos containers:"
docker-compose -f $composeFile logs --tail=20

Write-Output ""
Write-Success "🎉 Deploy concluído!"
Write-Output ""
Write-Output "📍 Endpoints disponíveis:"
Write-Output "   - Health Check: http://localhost/health"
Write-Output "   - Remove Background: http://localhost/remove-background"  
Write-Output "   - Batch Remove: http://localhost/batch-remove"
Write-Output "   - API Info: http://localhost/"
Write-Output ""
Write-Output "📱 Comandos úteis:"
Write-Output "   - Ver logs: docker-compose -f $composeFile logs -f"
Write-Output "   - Parar: docker-compose -f $composeFile down"
Write-Output "   - Restart: docker-compose -f $composeFile restart"
Write-Output "   - Status: docker-compose -f $composeFile ps"
Write-Output ""
Write-Output "💡 Uso deste script:"
Write-Output "   - Desenvolvimento: .\deploy.ps1"
Write-Output "   - Produção: .\deploy.ps1 -Production"
Write-Output "   - Parar: .\deploy.ps1 -Stop"
Write-Output "   - Logs: .\deploy.ps1 -Logs"
Write-Output ""

if ($Production) {
    Write-Warning "⚠️ Lembre-se de configurar SSL para HTTPS em produção!"
}
