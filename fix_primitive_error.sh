#!/bin/bash
# CORREÇÃO EMERGENCIAL para "could not create a primitive"
# Execute este script no servidor que está dando erro

echo "🚨 CORREÇÃO EMERGENCIAL - 'could not create a primitive'"
echo "=========================================================="

# 1. Verificar CPU
echo "🔍 1. Verificando suporte AVX2..."
if grep -q avx2 /proc/cpuinfo; then
    echo "✅ AVX2 suportado"
else
    echo "❌ AVX2 NÃO suportado - aplicando correções..."
fi

# 2. Definir variáveis de ambiente
echo "🔧 2. Definindo variáveis de ambiente..."
cat >> ~/.bashrc << 'EOF'

# Correção para CPUs sem AVX2 - PyTorch
export DNNL_MAX_CPU_ISA=SSE41
export MKL_ENABLE_INSTRUCTIONS=SSE4_2
export OPENBLAS_CORETYPE=NEHALEM  
export DNNL_VERBOSE=0
export MKLDNN_VERBOSE=0
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export PYTORCH_JIT=0
EOF

# 3. Aplicar para sessão atual
echo "🔧 3. Aplicando variáveis na sessão atual..."
export DNNL_MAX_CPU_ISA=SSE41
export MKL_ENABLE_INSTRUCTIONS=SSE4_2
export OPENBLAS_CORETYPE=NEHALEM
export DNNL_VERBOSE=0
export MKLDNN_VERBOSE=0
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export PYTORCH_JIT=0

# 4. Reinstalar PyTorch com versão mais compatível
echo "🔧 4. Reinstalando PyTorch compatível..."
pip uninstall -y torch torchvision
pip install torch==1.13.1+cpu torchvision==0.14.1+cpu --index-url https://download.pytorch.org/whl/cpu

# 5. Teste rápido
echo "🧪 5. Teste rápido..."
python3 -c "
import os
import torch
from PIL import Image

print('✅ PyTorch importado')
print(f'Versão: {torch.__version__}')

try:
    from transparent_background import Remover
    print('✅ transparent-background importado')
    
    # Teste crítico
    test_img = Image.new('RGB', (32, 32), 'red')
    remover = Remover(mode='base', device='cpu', jit=False)
    result = remover.process(test_img, type='rgba')
    print('🎉 SUCESSO! Primitive error resolvido!')
    
except Exception as e:
    print(f'❌ Ainda com erro: {e}')
    if 'primitive' in str(e):
        print('💡 TENTE: Usar versão ainda mais antiga do PyTorch')
        print('pip install torch==1.12.1+cpu torchvision==0.13.1+cpu --index-url https://download.pytorch.org/whl/cpu')
"

echo ""
echo "✅ CORREÇÃO APLICADA!"
echo "📋 Próximos passos:"
echo "1. Reiniciar o servidor Python"
echo "2. Se ainda der erro, tente versão mais antiga do PyTorch"
echo "3. Considere atualizar o servidor para CPU com AVX2"
echo ""
echo "🔄 Para recarregar variáveis: source ~/.bashrc"
