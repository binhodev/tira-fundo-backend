# 🔍 Verificação de Instruções CPU - Linux

## Como verificar se a CPU tem as instruções necessárias

### 1. **Comando `lscpu`**
```bash
lscpu | grep -i flags
# ou mais específico:
lscpu | grep -E "(avx|avx2|avx512|sse)"
```

### 2. **Arquivo `/proc/cpuinfo`**
```bash
# Verificar todas as flags da CPU
cat /proc/cpuinfo | grep flags | head -1

# Verificar instruções específicas
grep -o -E "(avx|avx2|avx512|sse|sse2|sse3|sse4)" /proc/cpuinfo | sort | uniq
```

### 3. **Comando específico para AVX**
```bash
# Verificar se suporta AVX2 (mais importante para oneDNN)
grep -q avx2 /proc/cpuinfo && echo "✅ AVX2 suportado" || echo "❌ AVX2 não suportado"

# Verificar AVX-512
grep -q avx512 /proc/cpuinfo && echo "✅ AVX-512 suportado" || echo "❌ AVX-512 não suportado"
```

### 4. **Script completo de verificação**
```bash
#!/bin/bash
echo "🔍 Verificando instruções CPU..."

# Função para verificar instrução
check_instruction() {
    local instruction=$1
    if grep -q "$instruction" /proc/cpuinfo; then
        echo "✅ $instruction: Suportado"
        return 0
    else
        echo "❌ $instruction: NÃO suportado"
        return 1
    fi
}

# Verificar instruções importantes
echo "📋 Instruções necessárias para PyTorch/oneDNN:"
check_instruction "sse2"
check_instruction "sse3" 
check_instruction "sse4_1"
check_instruction "sse4_2"
check_instruction "avx"
check_instruction "avx2"
check_instruction "avx512f"

echo ""
echo "📊 Resumo da CPU:"
echo "Modelo: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
echo "Cores: $(nproc)"
echo "Arquitetura: $(uname -m)"
```

## 🚨 **Instruções Críticas para oneDNN**

### **Mínimas necessárias:**
- ✅ **SSE2** - Básico (presente em quase todas CPUs modernas)
- ✅ **SSE4.1/4.2** - Necessário para muitas operações

### **Recomendadas:**
- ✅ **AVX** - Melhora significativa de performance
- ✅ **AVX2** - **CRÍTICO** para oneDNN/MKL-DNN funcionar bem

### **Opcionais:**
- ✅ **AVX-512** - Performance máxima (CPUs mais novas)

## ⚠️ **Problemas Comuns**

### **CPU sem AVX2:**
- Comum em CPUs mais antigas (pré-2013)
- AMD antes da série Ryzen
- Alguns processadores embarcados

### **Soluções para CPUs sem AVX2:**
1. **Forçar backend básico**
2. **Desabilitar oneDNN**
3. **Usar versão PyTorch sem otimizações**

# ❌ Problema Identificado: CPU sem AVX2

## 🔍 **Diagnóstico**
```bash
root@Dataweb:~# grep -q avx2 /proc/cpuinfo && echo "✅ AVX2 suportado" || echo "❌ AVX2 não suportado"
❌ AVX2 não suportado
```

**Resultado**: A CPU do servidor não suporta AVX2, causando o erro "could not create a primitive".

## 🔧 **Soluções Implementadas**

### 1. **Variáveis de Ambiente para Forçar Fallback**
```bash
export DNNL_VERBOSE=0
export DNNL_MAX_CPU_ISA=SSE41
export MKL_ENABLE_INSTRUCTIONS=SSE4_2
export OPENBLAS_CORETYPE=NEHALEM
```

### 2. **Versão PyTorch Compatível**
Usar versão mais antiga com melhor compatibilidade para CPUs legacy:
```bash
pip install torch==1.13.1+cpu torchvision==0.14.1+cpu --index-url https://download.pytorch.org/whl/cpu
```

### 3. **Biblioteca Alternativa**
Para CPUs muito antigas, considerar usar versão com OpenBLAS:
```bash
pip install torch==1.13.1+cpu torchvision==0.14.1+cpu -f https://download.pytorch.org/whl/cpu/torch_stable.html
```

## 🐳 **Correção Docker**

### **Dockerfile Atualizado**
```dockerfile
# Variáveis para CPUs sem AVX2
ENV DNNL_MAX_CPU_ISA=SSE41 \
    MKL_ENABLE_INSTRUCTIONS=SSE4_2 \
    OPENBLAS_CORETYPE=NEHALEM \
    DNNL_VERBOSE=0
```

### **Versão PyTorch Específica**
```dockerfile
# Usar versão específica com melhor compatibilidade
RUN pip install torch==1.13.1+cpu torchvision==0.14.1+cpu --index-url https://download.pytorch.org/whl/cpu
```

## 🔄 **Implementação Imediata**

### **1. Atualizar Servidor**
```bash
# Definir variáveis de ambiente
export DNNL_MAX_CPU_ISA=SSE41
export MKL_ENABLE_INSTRUCTIONS=SSE4_2
export OPENBLAS_CORETYPE=NEHALEM

# Reinstalar PyTorch com versão compatível
pip uninstall torch torchvision
pip install torch==1.13.1+cpu torchvision==0.14.1+cpu --index-url https://download.pytorch.org/whl/cpu
```

### **2. Teste Rápido**
```python
import torch
import os
os.environ['DNNL_MAX_CPU_ISA'] = 'SSE41'
print("✅ PyTorch carregado com fallback SSE4.1")
```

## 🔧 **Verificação Automática**

### **No Python:**
```python
import subprocess
import platform

def check_cpu_instructions():
    if platform.system() == "Linux":
        try:
            result = subprocess.run(['cat', '/proc/cpuinfo'], 
                                  capture_output=True, text=True)
            flags = result.stdout
            
            instructions = {
                'sse2': 'sse2' in flags,
                'sse4_1': 'sse4_1' in flags,
                'avx': 'avx' in flags and 'avx2' not in flags,  # AVX1
                'avx2': 'avx2' in flags,
                'avx512f': 'avx512f' in flags
            }
            
            return instructions
        except:
            return None
    return None

# Usar na aplicação
cpu_features = check_cpu_instructions()
if cpu_features:
    print("🔍 Instruções CPU detectadas:")
    for instruction, supported in cpu_features.items():
        status = "✅" if supported else "❌"
        print(f"{status} {instruction.upper()}: {supported}")
        
    if not cpu_features.get('avx2', False):
        print("⚠️ AVX2 não suportado - possíveis problemas com oneDNN")
```

## 🐳 **Docker - Verificação**

### **Adicionar ao Dockerfile:**
```dockerfile
# Verificar instruções CPU durante build
RUN echo "🔍 Verificando CPU..." && \
    grep -E "(avx|avx2|sse)" /proc/cpuinfo | head -5 || \
    echo "⚠️ Instruções avançadas podem não estar disponíveis"
```

## 📋 **Comandos Úteis de Diagnóstico**

```bash
# Ver todas as flags de uma vez
cat /proc/cpuinfo | grep flags | head -1 | tr ' ' '\n' | grep -E "(sse|avx)" | sort

# Verificação rápida AVX2 (mais importante)
[ $(grep -c avx2 /proc/cpuinfo) -gt 0 ] && echo "AVX2 OK" || echo "AVX2 MISSING"

# Ver detalhes da CPU
lscpu | grep -E "(Model name|CPU\(s\)|Thread|Core|Socket)"

# Verificar se é VM (pode afetar instruções)
systemd-detect-virt 2>/dev/null || echo "Não é VM ou systemd-detect-virt não disponível"
```
