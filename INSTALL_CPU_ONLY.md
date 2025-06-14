# 🖥️ Instalação CPU-Only

## 🎯 **Objetivo**

Garantir que o PyTorch seja instalado APENAS com suporte CPU, evitando o download das bibliotecas NVIDIA/CUDA pesadas.

## ⚠️ **Problema**

Mesmo especificando `torch+cpu` no requirements.txt, o pip pode ainda baixar dependências CUDA, resultando em:

-   Downloads desnecessários (~571MB de CUDA libraries)
-   Dependências NVIDIA pesadas
-   Problemas de compatibilidade

## ✅ **Solução Implementada**

### **1. Dockerfile Atualizado**

```dockerfile
# Instalar PyTorch CPU-only primeiro usando índice específico
RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch torchvision && \
    pip install --no-cache-dir -r requirements.txt
```

### **2. Requirements.txt Limpo**

```txt
# PyTorch CPU-only versions (use --index-url for installation)
torch>=1.13.0
torchvision>=0.14.0
```

### **3. Instalação Local**

Para desenvolvimento local, use:

```bash
# Instalar PyTorch CPU-only
pip install --index-url https://download.pytorch.org/whl/cpu torch torchvision

# Depois instalar outras dependências
pip install -r requirements.txt
```

### **4. Verificação**

Para verificar se foi instalado corretamente:

```python
import torch
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")  # Deve ser False
print(f"Is CPU version: {'+cpu' in torch.__version__}")  # Deve ser True
```

## 📦 **Vantagens**

-   ✅ **Tamanho reduzido**: Sem bibliotecas CUDA (~571MB economizados)
-   ✅ **Compatibilidade**: Funciona em qualquer ambiente
-   ✅ **Velocidade**: Build mais rápido do Docker
-   ✅ **Simplicidade**: Sem dependências GPU complexas

## 🚀 **Deploy**

Com essas mudanças:

1. O Docker build será mais rápido
2. Não haverá downloads de bibliotecas NVIDIA
3. A imagem final será menor
4. Funcionará em qualquer servidor (mesmo sem GPU)

## 🔍 **Logs Esperados**

Agora você verá logs como:

```
Looking in indexes: https://download.pytorch.org/whl/cpu
Collecting torch>=1.13.0
  Downloading torch-2.1.0%2Bcpu-cp311-cp311-linux_x86_64.whl
```

**Sem** os downloads das bibliotecas NVIDIA:

-   ❌ nvidia_cuda_nvrtc_cu12
-   ❌ nvidia_cudnn_cu12
-   ❌ nvidia_cufft_cu12
-   ❌ nvidia_curand_cu12
