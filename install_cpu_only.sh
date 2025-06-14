#!/bin/bash
# Script para instalação CPU-only no Linux/Mac
# Garante que PyTorch seja instalado apenas com suporte CPU

echo "🚀 Instalando dependências CPU-only..."

# Verificar se está em ambiente virtual
if [[ -z "$VIRTUAL_ENV" ]]; then
    echo "⚠️  Recomendado usar ambiente virtual!"
    echo "Exemplo: python -m venv venv && source venv/bin/activate"
fi

echo "📦 Instalando PyTorch CPU-only..."
pip install --index-url https://download.pytorch.org/whl/cpu torch torchvision

if [ $? -eq 0 ]; then
    echo "✅ PyTorch CPU-only instalado com sucesso!"
else
    echo "❌ Erro ao instalar PyTorch!"
    exit 1
fi

echo "📦 Instalando outras dependências..."
pip install -r requirements.txt

if [ $? -eq 0 ]; then
    echo "✅ Todas as dependências instaladas!"
else
    echo "❌ Erro ao instalar dependências!"
    exit 1
fi

echo "🔍 Verificando instalação..."
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

if [ $? -eq 0 ]; then
    echo "🧪 Executando teste de compatibilidade CPU..."
    python test_cpu_compatibility.py
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 Instalação CPU-only concluída com sucesso!"
        echo "✅ Teste de compatibilidade passou - sem 'primitive' errors esperados"
        echo "Agora você pode executar: python main.py"
    else
        echo ""
        echo "⚠️  Instalação OK, mas teste de compatibilidade falhou!"
        echo "Pode haver 'primitive' errors em CPUs sem AVX2"
        echo "Consulte: docs/cpu_instructions_check.md"
    fi
else
    echo ""
    echo "❌ Problema na verificação!"
    exit 1
fi
