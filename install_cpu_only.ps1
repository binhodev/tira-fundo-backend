# Script para instalação CPU-only no Windows
# Garante que PyTorch seja instalado apenas com suporte CPU

Write-Host "🚀 Instalando dependências CPU-only..." -ForegroundColor Green

# Verificar se está em ambiente virtual
if (-not $env:VIRTUAL_ENV) {
    Write-Host "⚠️  Recomendado usar ambiente virtual!" -ForegroundColor Yellow
    Write-Host "Exemplo: python -m venv venv && .\venv\Scripts\Activate.ps1" -ForegroundColor Yellow
}

Write-Host "📦 Instalando PyTorch CPU-only..." -ForegroundColor Cyan
pip install --index-url https://download.pytorch.org/whl/cpu torch torchvision

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ PyTorch CPU-only instalado com sucesso!" -ForegroundColor Green
} else {
    Write-Host "❌ Erro ao instalar PyTorch!" -ForegroundColor Red
    exit 1
}

Write-Host "📦 Instalando outras dependências..." -ForegroundColor Cyan
pip install -r requirements.txt

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Todas as dependências instaladas!" -ForegroundColor Green
} else {
    Write-Host "❌ Erro ao instalar dependências!" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Verificando instalação..." -ForegroundColor Cyan
python -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
print(f'Is CPU version: {\'+cpu\' in torch.__version__}')
if torch.cuda.is_available():
    print('❌ ATENÇÃO: CUDA ainda disponível!')
    exit(1)
else:
    print('✅ CPU-only configurado corretamente!')
"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n🎉 Instalação CPU-only concluída com sucesso!" -ForegroundColor Green
    Write-Host "Agora você pode executar: python main.py" -ForegroundColor White
} else {
    Write-Host "`n❌ Problema na verificação!" -ForegroundColor Red
}
