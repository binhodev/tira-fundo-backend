# Migração para CPU Apenas

## 📋 **Alterações Realizadas**

Este documento descreve as mudanças implementadas para remover completamente o suporte GPU e manter apenas o processamento CPU.

### ✅ **Arquivos Modificados**

#### 1. **main.py**

-   ✅ Removidas verificações de `torch.cuda.is_available()`
-   ✅ Info de dispositivo hardcoded para CPU apenas
-   ✅ Logs atualizados para indicar "CPU (forçado)"

#### 2. **requirements.txt**

-   ✅ `torch>=1.13.0` - Versão CPU-only (instalada via índice específico)
-   ✅ `torchvision>=0.14.0` - Versão CPU-only (instalada via índice específico)
-   ❌ **Problema identificado**: Sufixo `+cpu` não evita download de libs NVIDIA

#### 2.1. **Dockerfiles (Solução para libs NVIDIA)**

**Problema**: Mesmo com `torch+cpu`, o pip baixava:

-   `nvidia_cuda_nvrtc_cu12` (~8.9MB)
-   `nvidia_cudnn_cu12` (~571MB)
-   `nvidia_cufft_cu12` (~200MB)
-   `nvidia_curand_cu12` e outras...

**Solução implementada**:

```dockerfile
# Usar índice específico CPU-only do PyTorch
RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu torch torchvision && \
    pip install --no-cache-dir -r requirements.txt
```

#### 3. **Dockerfile.coolify**

-   ✅ Adicionadas variáveis de ambiente para forçar CPU:
    -   `FORCE_CPU=true`
    -   `TORCH_FORCE_CPU=1`
    -   `PYTORCH_JIT=0`
    -   Configurações de threading otimizadas

#### 4. **Documentação**

-   ✅ `docs/about.md` - Configuração atualizada para CPU apenas
-   ✅ `docs/production_scale.md` - Removida referência a CUDA/MPS

## 🔧 **Configurações CPU**

### **Variáveis de Ambiente Aplicadas**

```bash
OMP_NUM_THREADS=1
MKL_NUM_THREADS=1
NUMEXPR_NUM_THREADS=1
OPENBLAS_NUM_THREADS=1
PYTORCH_JIT=0
FORCE_CPU=true
TORCH_FORCE_CPU=1
```

### **Configurações PyTorch**

```python
torch.set_num_threads(1)  # Limita threads
torch.set_grad_enabled(False)  # Modo inferência
```

## 📊 **Impactos**

### ✅ **Benefícios**

-   **Compatibilidade**: Funciona em qualquer ambiente
-   **Simplicidade**: Sem dependências GPU complexas
-   **Estabilidade**: Menos problemas de drivers e versões
-   **Deployment**: Mais fácil em containers e cloud

### ⚠️ **Considerações**

-   **Performance**: Processamento mais lento que GPU
-   **Recursos**: Maior uso de CPU para tarefas intensivas

## 🚀 **Deploy**

Após as mudanças, o projeto:

-   ✅ Funciona apenas com CPU
-   ✅ Não tenta detectar ou usar GPU
-   ✅ Tem configurações otimizadas para CPU
-   ✅ É compatível com qualquer ambiente de deployment

## 🔍 **Verificação**

Para verificar se as mudanças foram aplicadas corretamente:

1. **Teste local:**

    ```bash
    python main.py
    # Deve mostrar: "📱 Dispositivo: CPU (forçado)"
    ```

2. **Endpoint de status:**

    ```
    GET /health/models
    # Deve retornar: "device": "cpu"
    ```

3. **Info de modelos:**
    ```
    GET /models
    # device_info.current_device deve ser "cpu"
    ```
