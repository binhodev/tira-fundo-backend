"""
Backend API para Remoção de Fundo com IA
Utiliza a biblioteca transparent-background para processamento avançado
"""

import os
import io
import base64
import time
import logging
from typing import Optional, Dict, Any, List
from contextlib import asynccontextmanager
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

import torch
import numpy as np
from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from PIL import Image
from transparent_background import Remover
import warnings

# Configurações específicas para produção
# Configurar PyTorch para ambiente de produção
torch.set_num_threads(1)  # Limita threads para evitar conflitos em produção
torch.set_grad_enabled(False)  # Desabilita gradientes (modo inferência)

# Configurar OpenMP para evitar conflitos de threading
os.environ['OMP_NUM_THREADS'] = '1'
os.environ['MKL_NUM_THREADS'] = '1'

# Configuração de warnings (adicione após os imports existentes)
if os.getenv("SUPPRESS_PYTORCH_WARNINGS", "true").lower() == "true":
    warnings.filterwarnings("ignore", category=UserWarning, module="torch")
    warnings.filterwarnings("ignore", category=UserWarning, module="torchvision")
    warnings.filterwarnings("ignore", category=FutureWarning, module="torch")

# Configuração de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Função lifespan para gerenciar eventos de startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup    logger.info("🚀 Iniciando servidor de remoção de fundo...")
    logger.info(f"📱 Dispositivo: CPU (forçado)")
    
    # Pré-carrega o modelo base para melhor performance
    try:
        logger.info("⚡ Pré-carregando modelo base...")
        get_or_create_model('base')
        logger.info("✅ Modelo base carregado com sucesso!")
    except Exception as e:
        logger.warning(f"⚠️ Erro ao pré-carregar modelo: {e}")
    
    yield
    
    # Shutdown
    logger.info("🛑 Desligando servidor...")

# Inicialização da aplicação FastAPI
app = FastAPI(
    title="Background Removal API",
    description="API para remoção de fundo usando IA com transparent-background",
    version="1.0.0",
    lifespan=lifespan
)

# Configuração CORS dinâmica baseada em variáveis de ambiente
cors_origins = os.getenv("CORS_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[origin.strip() for origin in cors_origins],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Variáveis globais para cache dos modelos
models_cache: Dict[str, Remover] = {}
device_info = {
    "cuda_available": False,
    "device_count": 0,
    "current_device": "cpu"
}

def get_device():
    """Retorna o dispositivo disponível (apenas CPU)"""
    return "cpu"

def get_or_create_model(mode: str = "base") -> Remover:
    """
    Obtém ou cria um modelo em cache
    """
    if mode not in models_cache:
        logger.info(f"Carregando modelo {mode}...")
        start_time = time.time()
        
        try:
            device = get_device()            
            logger.info(f"🔧 Configurando modelo no dispositivo: {device}")
            logger.info(f"🔧 PyTorch version: {torch.__version__}")
            logger.info(f"🔧 Dispositivo: CPU (forçado)")
            
            # Configurações específicas para produção
            torch.set_num_threads(1)  # Limita threads para evitar conflitos
            
            models_cache[mode] = Remover(
                mode=mode,
                device=device,
                jit=False  # Desabilitado para compatibilidade
            )
            
            load_time = time.time() - start_time
            logger.info(f"✅ Modelo {mode} carregado em {load_time:.2f}s no dispositivo {device}")
            
        except Exception as e:
            logger.error(f"❌ Erro detalhado ao carregar modelo {mode}: {type(e).__name__}: {str(e)}")
            # Log de informações do sistema para debug
            logger.error(f"🔍 Sistema: device={get_device()}, torch_version={torch.__version__}")
            logger.error(f"🔍 Dispositivo: CPU (forçado)")
            raise HTTPException(status_code=500, detail=f"Erro ao carregar modelo: {str(e)}")
    
    return models_cache[mode]

def process_image(
    image: Image.Image,
    mode: str = "base",
    output_type: str = "rgba",
    threshold: Optional[float] = None
) -> tuple[Image.Image, Dict[str, Any]]:
    """
    Processa uma imagem para remover o fundo
    """
    start_time = time.time()
    
    try:
        logger.info(f"🔄 Iniciando processamento - modo: {mode}, tipo: {output_type}, threshold: {threshold}")
        
        # Obtém o modelo
        remover = get_or_create_model(mode)
        
        # Converte para RGB se necessário
        original_mode = image.mode
        if image.mode != 'RGB':
            logger.info(f"🔄 Convertendo imagem de {original_mode} para RGB")
            image = image.convert('RGB')
        
        logger.info(f"🔄 Processando imagem {image.size} com {remover}")
        
        # Processa a imagem com tratamento específico para o erro "primitive"
        try:
            result = remover.process(
                image,
                type=output_type,
                threshold=threshold
            )
        except RuntimeError as e:
            if "could not create a primitive" in str(e):
                logger.error(f"❌ Erro 'primitive' detectado: {e}")
                logger.error("🔧 Tentando recriar o modelo...")                # Remove do cache e tenta recriar
                if mode in models_cache:
                    del models_cache[mode]
                # Força limpeza de memória (CPU apenas)
                import gc
                gc.collect()
                # Tenta novamente
                remover = get_or_create_model(mode)
                result = remover.process(
                    image,
                    type=output_type,
                    threshold=threshold
                )
            else:
                raise e
        
        processing_time = int((time.time() - start_time) * 1000)
        
        info = {
            "mode": mode,
            "device": get_device(),
            "type": output_type,
            "threshold": threshold,
            "processing_time_ms": processing_time,
            "input_size": image.size,
            "output_size": result.size,
            "original_mode": original_mode
        }
        
        logger.info(f"✅ Processamento concluído em {processing_time}ms")
        return result, info # type: ignore
        
    except Exception as e:
        error_type = type(e).__name__
        error_msg = str(e)
        logger.error(f"❌ Erro no processamento [{error_type}]: {error_msg}")
        
        # Log adicional para debug em produção
        logger.error(f"🔍 Detalhes do erro - Modo: {mode}, Tipo: {output_type}")
        logger.error(f"🔍 Imagem - Tamanho: {image.size}, Modo: {image.mode}")
        logger.error(f"🔍 Sistema - Device: {get_device()}, Models em cache: {list(models_cache.keys())}")
        
        raise HTTPException(status_code=500, detail=f"Erro no processamento: {error_msg}")

def image_to_base64(image: Image.Image) -> str:
    """
    Converte uma imagem PIL para base64
    """
    buffer = io.BytesIO()
    
    # Salva como PNG para manter transparência
    if image.mode in ('RGBA', 'LA'):
        image.save(buffer, format='PNG')
    else:
        image.save(buffer, format='JPEG', quality=95)
    
    buffer.seek(0)
    image_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
    return image_base64


@app.get("/")
async def root():
    """Endpoint raiz"""
    return {
        "message": "Background Removal API",
        "version": "1.0.0",
        "status": "running",
        "device": get_device()
    }

@app.get("/health")
async def health_check():
    """Verificação de saúde do servidor"""
    return {
        "status": "healthy",
        "device_info": device_info,
        "current_device": get_device(),
        "models_loaded": list(models_cache.keys()),
        "timestamp": time.time()
    }

@app.get("/health/models")
async def models_health_check():
    """Verificação de saúde específica dos modelos"""
    try:
        # Testa carregamento do modelo base
        start_time = time.time()
        model = get_or_create_model('base')
        load_time = time.time() - start_time
        
        # Cria uma imagem de teste pequena
        test_image = Image.new('RGB', (32, 32), color='red')
        
        # Testa processamento básico
        try:
            result, info = process_image(test_image, mode='base', output_type='rgba')
            test_success = True
            test_error = None
        except Exception as e:
            test_success = False
            test_error = str(e)
        
        return {
            "status": "healthy" if test_success else "error",
            "model_load_time": f"{load_time:.2f}s",
            "test_processing": {
                "success": test_success,
                "error": test_error
            },
            "models_cached": list(models_cache.keys()),
            "device": get_device(),            "torch_info": {
                "version": torch.__version__,
                "device": "cpu",
                "num_threads": torch.get_num_threads()
            }
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e),
            "error_type": type(e).__name__
        }

@app.get("/models")
async def get_models_info():
    """Informações sobre modelos disponíveis"""
    return {
        "available_modes": ["base", "fast", "base-nightly"],
        "output_types": ["rgba", "white", "green", "map", "blur", "overlay"],
        "loaded_models": list(models_cache.keys()),
        "device_info": device_info,
        "current_device": get_device()
    }

@app.post("/remove-background")
async def remove_background(
    file: UploadFile = File(...),
    mode: str = Form("base"),
    output_type: str = Form("rgba"),
    threshold: Optional[float] = Form(None)
):
    """
    Remove o fundo de uma imagem
    """    # Validações
    # Verifica se é uma imagem pelo content_type ou extensão do arquivo
    valid_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.webp']
    is_valid_image = False
    
    if file.content_type and file.content_type.startswith('image/'):
        is_valid_image = True
    elif file.filename:
        file_ext = os.path.splitext(file.filename.lower())[1]
        if file_ext in valid_extensions:
            is_valid_image = True
    
    if not is_valid_image:
        raise HTTPException(
            status_code=400, 
            detail=f"Arquivo deve ser uma imagem. Content-type: {file.content_type}, Filename: {file.filename}"
        )
    
    if mode not in ["base", "fast", "base-nightly"]:
        raise HTTPException(status_code=400, detail="Modo inválido")
    
    if output_type not in ["rgba", "white", "green", "map", "blur", "overlay"]:
        raise HTTPException(status_code=400, detail="Tipo de saída inválido")
    
    if threshold is not None and (threshold < 0.0 or threshold > 1.0):
        raise HTTPException(status_code=400, detail="Threshold deve estar entre 0.0 e 1.0")
    
    try:
        # Lê a imagem
        image_data = await file.read()
        image = Image.open(io.BytesIO(image_data))
        
        logger.info(f"📷 Processando imagem: {file.filename}, tamanho: {image.size}, modo: {mode}")
        
        # Processa a imagem
        result_image, processing_info = process_image(
            image, 
            mode=mode, 
            output_type=output_type, 
            threshold=threshold
        )
        
        # Converte para base64
        result_base64 = image_to_base64(result_image)
        
        logger.info(f"✅ Processamento concluído em {processing_info['processing_time_ms']}ms")
        
        return JSONResponse(content={
            "success": True,
            "image": result_base64,
            "processing_time": processing_info["processing_time_ms"],
            "model_info": processing_info,
            "filename": file.filename
        })
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erro inesperado: {e}")
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")

@app.post("/batch-remove")
async def batch_remove_background(
    files: list[UploadFile] = File(...),
    mode: str = Form("base"),
    output_type: str = Form("rgba"),
    threshold: Optional[float] = Form(None)
):
    """
    Removes the background from multiple images
    """
    max_batch_size = int(os.getenv("MAX_BATCH_SIZE", "5"))
    if len(files) > max_batch_size:  # Limite configurável
        raise HTTPException(status_code=400, detail=f"Máximo {max_batch_size} imagens por vez")
    
    results = []
    total_start_time = time.time()
    
    for i, file in enumerate(files):
        try:
            if not file.content_type or not file.content_type.startswith('image/'):
                results.append({
                    "success": False,
                    "filename": file.filename,
                    "error": "Arquivo não é uma imagem"
                })
                continue
            
            # Processa cada imagem
            image_data = await file.read()
            image = Image.open(io.BytesIO(image_data))
            
            result_image, processing_info = process_image(
                image, 
                mode=mode, 
                output_type=output_type, 
                threshold=threshold
            )
            
            result_base64 = image_to_base64(result_image)
            
            results.append({
                "success": True,
                "filename": file.filename,
                "image": result_base64,
                "processing_time": processing_info["processing_time_ms"],
                "model_info": processing_info
            })
            
        except Exception as e:
            results.append({
                "success": False,
                "filename": file.filename,
                "error": str(e)
            })
    
    total_time = int((time.time() - total_start_time) * 1000)
    
    return JSONResponse(content={
        "results": results,
        "total_processing_time": total_time,
        "total_images": len(files),
        "successful": len([r for r in results if r["success"]]),
        "failed": len([r for r in results if not r["success"]])
    })

if __name__ == "__main__":
    import uvicorn
    import multiprocessing
    
    # Proteção para Windows multiprocessing
    multiprocessing.freeze_support()
    
    # Configuração do servidor com variáveis de ambiente
    host = os.getenv("HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "8000"))
    workers = int(os.getenv("WORKERS", "1"))
    log_level = os.getenv("LOG_LEVEL", "info")
    
    # No Windows, forçar workers=1 para evitar problemas
    if os.name == 'nt':  # Windows
        workers = 1
        logger.info("🪟 Windows detectado - forçando workers=1 para estabilidade")
    
    # Detectar se uvloop está disponível
    try:
        import uvloop
        uvloop_available = True and os.name != 'nt'  # Não usar uvloop no Windows
        if uvloop_available:
            logger.info("🔥 uvloop disponível - usando para melhor performance")
        else:
            logger.info("⚡ uvloop não disponível no Windows - usando asyncio padrão")
    except ImportError:
        uvloop_available = False
        logger.info("⚡ uvloop não disponível - usando asyncio padrão")
    
    logger.info(f"🌟 Iniciando servidor em http://{host}:{port}")
    logger.info(f"👥 Workers: {workers}")
    logger.info(f"📝 Log Level: {log_level}")
    
    try:
        if workers > 1 and os.name != 'nt':
            # Modo produção com múltiplos workers (apenas Linux/Mac)
            kwargs = {
                "host": host,
                "port": port,
                "workers": workers,
                "log_level": log_level,
                "access_log": True
            }
            
            # Adicionar uvloop apenas se disponível
            if uvloop_available:
                kwargs["loop"] = "uvloop"
                
            uvicorn.run("main:app", **kwargs)
        else:
            # Modo desenvolvimento ou Windows
            uvicorn.run(
                "main:app",
                host=host,
                port=port,
                reload=False,
                log_level=log_level,
                access_log=True,
                loop="asyncio"  # Forçar asyncio no Windows
            )
    except KeyboardInterrupt:
        logger.info("🛑 Servidor interrompido pelo usuário")
    except Exception as e:
        logger.error(f"❌ Erro ao iniciar servidor: {e}")
        raise
