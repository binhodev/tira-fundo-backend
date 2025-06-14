#!/usr/bin/env python3
"""
Script de inicialização para produção
Aplica configurações específicas antes de iniciar o servidor
"""

import os
import sys
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def setup_production_environment():
    """Configura o ambiente para produção"""
    
    # Configurações de threading
    os.environ['OMP_NUM_THREADS'] = '1'
    os.environ['MKL_NUM_THREADS'] = '1'
    os.environ['NUMEXPR_NUM_THREADS'] = '1'
    os.environ['OPENBLAS_NUM_THREADS'] = '1'
    
    # Configurações PyTorch
    os.environ['PYTORCH_CUDA_ALLOC_CONF'] = 'max_split_size_mb:512'
    
    # Desabilitar JIT se necessário
    os.environ['PYTORCH_JIT'] = '0'
    
    logger.info("🔧 Configurações de produção aplicadas")
    logger.info(f"🔧 OMP_NUM_THREADS: {os.environ.get('OMP_NUM_THREADS')}")
    logger.info(f"🔧 MKL_NUM_THREADS: {os.environ.get('MKL_NUM_THREADS')}")

def main():
    """Função principal"""
    logger.info("🚀 Iniciando servidor em modo produção...")
    
    # Aplicar configurações
    setup_production_environment()
    
    # Importar e executar o servidor
    try:
        import torch
        logger.info(f"🔧 PyTorch {torch.__version__} carregado")
        
        # Configurar PyTorch
        torch.set_num_threads(1)
        torch.set_grad_enabled(False)
        
        # Importar aplicação
        from main import app
        import uvicorn
        
        # Configurações do servidor
        host = os.getenv("HOST", "0.0.0.0")
        port = int(os.getenv("PORT", "8000"))
        workers = 1  # Sempre 1 para evitar problemas
        
        logger.info(f"🌟 Iniciando servidor em http://{host}:{port}")
        
        # Iniciar servidor
        uvicorn.run(
            "main:app",
            host=host,
            port=port,
            workers=workers,
            log_level="info",
            access_log=True,
            loop="asyncio"
        )
        
    except Exception as e:
        logger.error(f"❌ Erro ao iniciar servidor: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
