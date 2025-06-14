# Solução de Problemas em Produção

## Erro: "could not create a primitive"

Este erro é comum em ambientes de produção e pode ter várias causas:

### 1. **Problemas de Threading**

```bash
# Configurar variáveis de ambiente
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
```

### 2. **Problemas de Memória**

```bash
# Configurar alocação de memória do PyTorch (CPU apenas)
export PYTORCH_JIT=0
```

### 3. **Problemas de JIT**

```bash
# Desabilitar JIT compilation
export PYTORCH_JIT=0
```

### 4. **Usando Docker**

```dockerfile
# No Dockerfile, adicionar:
ENV OMP_NUM_THREADS=1
ENV MKL_NUM_THREADS=1
ENV NUMEXPR_NUM_THREADS=1
ENV OPENBLAS_NUM_THREADS=1
ENV PYTORCH_JIT=0
ENV FORCE_CPU=true
ENV TORCH_FORCE_CPU=1
```

### 5. **Configuração Específica do Código**

O código já foi atualizado com:

-   `torch.set_num_threads(1)` - Limita threads
-   `torch.set_grad_enabled(False)` - Modo inferência
-   Retry automático em caso de erro "primitive"
-   Limpeza de cache automática

### 6. **Iniciando o Servidor**

#### Opção 1: Script de Produção

```bash
python production_start.py
```

#### Opção 2: Comando Direto

```bash
# Configurar variáveis
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export WORKERS=1

# Iniciar servidor
python main.py
```

#### Opção 3: Docker Compose

```yaml
version: "3.8"
services:
    app:
        build: .
        environment:
            - OMP_NUM_THREADS=1
            - MKL_NUM_THREADS=1
            - WORKERS=1
            - PYTORCH_JIT=0
        ports:
            - "8000:8000"
```

### 7. **Monitoramento**

#### Health Check dos Modelos

```bash
curl http://localhost:8000/health/models
```

#### Logs Detalhados

Os logs agora incluem:

-   Informações detalhadas sobre erros
-   Tentativas de retry automático
-   Estado dos modelos em cache
-   Informações do sistema

### 8. **Solução de Problemas Específicos**

#### Se o erro persistir:

1. Verificar logs detalhados
2. Testar o endpoint `/health/models`
3. Verificar versões das dependências
4. Verificar configurações de CPU

#### Versões Testadas:

-   PyTorch: >= 1.13.0
-   transparent-background: >= 1.3.4
-   Python: >= 3.8

### 9. **Configuração para CPU**

#### Para garantir uso apenas de CPU:

```python
# Forçar CPU apenas
os.environ['FORCE_CPU'] = 'true'
os.environ['TORCH_FORCE_CPU'] = '1'
```

#### Para containers com pouca memória:

```python
# Reduzir cache de modelos
import gc
gc.collect()  # Limpar cache regularmente
```
