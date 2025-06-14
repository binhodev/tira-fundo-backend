#!/usr/bin/env python3
"""
Script de teste para verificar compatibilidade CPU e resolver "could not create a primitive"
"""

import os
import sys

# Configurações para CPUs sem AVX2 - DEVE ser feito ANTES de importar torch
print("🔧 Configurando variáveis de ambiente para compatibilidade CPU...")
os.environ['DNNL_MAX_CPU_ISA'] = 'SSE41'
os.environ['MKL_ENABLE_INSTRUCTIONS'] = 'SSE4_2'
os.environ['OPENBLAS_CORETYPE'] = 'NEHALEM'
os.environ['DNNL_VERBOSE'] = '0'
os.environ['MKLDNN_VERBOSE'] = '0'
os.environ['OMP_NUM_THREADS'] = '1'
os.environ['MKL_NUM_THREADS'] = '1'

try:
    import torch
    import numpy as np
    from PIL import Image
    print("✅ Importações básicas OK")
except ImportError as e:
    print(f"❌ Erro na importação: {e}")
    sys.exit(1)

def check_cpu_instructions():
    """Verifica instruções CPU disponíveis"""
    print("\n🔍 Verificando instruções CPU...")
    
    # Verificar se estamos no Linux
    if os.path.exists('/proc/cpuinfo'):
        with open('/proc/cpuinfo', 'r') as f:
            cpuinfo = f.read().lower()
            
        instructions = {
            'SSE4.1': 'sse4_1' in cpuinfo,
            'SSE4.2': 'sse4_2' in cpuinfo,
            'AVX': 'avx' in cpuinfo,
            'AVX2': 'avx2' in cpuinfo,
            'AVX-512': 'avx512' in cpuinfo
        }
        
        for instruction, available in instructions.items():
            status = "✅" if available else "❌"
            print(f"{status} {instruction}: {'Disponível' if available else 'Não disponível'}")
            
        if not instructions['AVX2']:
            print("\n⚠️  CPU sem AVX2 detectada - usando configurações de compatibilidade")
    else:
        print("ℹ️  Não foi possível verificar instruções CPU (não é Linux)")

def test_torch_basic():
    """Teste básico do PyTorch"""
    print("\n🧪 Testando PyTorch básico...")
    
    try:
        # Teste 1: Criação de tensor
        x = torch.randn(3, 3)
        print("✅ Criação de tensor OK")
        
        # Teste 2: Operações básicas
        y = torch.matmul(x, x)
        print("✅ Operações matemáticas OK")
        
        # Teste 3: Configurações
        print(f"📊 PyTorch version: {torch.__version__}")
        print(f"📊 Threads: {torch.get_num_threads()}")
        print(f"📊 CUDA available: {torch.cuda.is_available()}")
        
        return True
    except Exception as e:
        print(f"❌ Erro no teste PyTorch: {e}")
        return False

def test_transparent_background():
    """Teste do transparent-background (causa do primitive error)"""
    print("\n🎨 Testando transparent-background...")
    
    try:
        from transparent_background import Remover
        print("✅ Importação transparent-background OK")
        
        # Criar imagem de teste pequena
        test_image = Image.new('RGB', (32, 32), color='red')
        print("✅ Imagem de teste criada")
        
        # Tentar criar o removedor (aqui geralmente falha com primitive error)
        print("🔄 Criando Remover (teste crítico)...")
        remover = Remover(mode='base', device='cpu', jit=False)
        print("✅ Remover criado com sucesso!")
        
        # Teste de processamento
        print("🔄 Testando processamento...")
        result = remover.process(test_image, type='rgba')
        print("✅ Processamento concluído!")
        
        return True
        
    except Exception as e:
        print(f"❌ Erro no transparent-background: {e}")
        print(f"❌ Tipo do erro: {type(e).__name__}")
        
        # Sugestões específicas baseadas no erro
        if "primitive" in str(e).lower():
            print("\n💡 SOLUÇÃO SUGERIDA para 'primitive' error:")
            print("1. Verificar se variáveis de ambiente estão definidas")
            print("2. Usar versão mais antiga do PyTorch: pip install torch==1.13.1+cpu")
            print("3. Considerar usar CPU mais moderna com AVX2")
            
        return False

def main():
    """Função principal de teste"""
    print("🚀 Iniciando teste de compatibilidade CPU\n")
    
    # Verificar instruções CPU
    check_cpu_instructions()
    
    # Testar PyTorch básico
    torch_ok = test_torch_basic()
    
    if not torch_ok:
        print("\n❌ PyTorch básico falhou - parando testes")
        return False
        
    # Testar transparent-background (o mais crítico)
    tb_ok = test_transparent_background()
    
    # Resultado final
    print("\n" + "="*50)
    if tb_ok:
        print("🎉 SUCESSO! Todos os testes passaram")
        print("✅ O servidor deve funcionar sem 'primitive' errors")
    else:
        print("❌ FALHA! Problema com transparent-background")
        print("⚠️  Servidor pode ter 'primitive' errors")
        
    print("="*50)
    return tb_ok

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
