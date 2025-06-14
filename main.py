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

# Configuração de warnings (adicione após os imports existentes)
if os.getenv("SUPPRESS_PYTORCH_WARNINGS", "true").lower() == "true":
    warnings.filterwarnings("ignore", category=UserWarning, module="torch")

# Configuração de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Função lifespan para gerenciar eventos de startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("🚀 Iniciando servidor de remoção de fundo...")
    logger.info(f"📱 Dispositivo: {get_device()}")
    logger.info(f"🔧 CUDA disponível: {device_info['cuda_available']}")
    
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
    "cuda_available": torch.cuda.is_available(),
    "device_count": torch.cuda.device_count() if torch.cuda.is_available() else 0,
    "current_device": "cuda:0" if torch.cuda.is_available() else "cpu"
}

def get_device():
    """Retorna o dispositivo disponível (CUDA ou CPU)"""
    if torch.cuda.is_available():
        return "cuda:0"
    elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
        return "mps:0"
    else:
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
            models_cache[mode] = Remover(
                mode=mode,
                device=device,
                jit=False  # Desabilitado para compatibilidade
            )
            
            load_time = time.time() - start_time
            logger.info(f"Modelo {mode} carregado em {load_time:.2f}s no dispositivo {device}")
            
        except Exception as e:
            logger.error(f"Erro ao carregar modelo {mode}: {e}")
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
        # Obtém o modelo
        remover = get_or_create_model(mode)
        
        # Converte para RGB se necessário
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Processa a imagem
        result = remover.process(
            image,
            type=output_type,
            threshold=threshold
        )
        
        processing_time = int((time.time() - start_time) * 1000)
        
        info = {
            "mode": mode,
            "device": get_device(),
            "type": output_type,
            "threshold": threshold,
            "processing_time_ms": processing_time,
            "input_size": image.size,
            "output_size": result.size
        }
        
        return result, info # type: ignore
        
    except Exception as e:
        logger.error(f"Erro no processamento: {e}")
        raise HTTPException(status_code=500, detail=f"Erro no processamento: {str(e)}")

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
    Remove o fundo de múltiplas imagens
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
    
    # Configuração do servidor com variáveis de ambiente
    host = os.getenv("HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "8000"))
    workers = int(os.getenv("WORKERS", "1"))
    log_level = os.getenv("LOG_LEVEL", "info")
    
    logger.info(f"🌟 Iniciando servidor em http://{host}:{port}")
    logger.info(f"👥 Workers: {workers}")
    logger.info(f"📝 Log Level: {log_level}")
    
    if workers > 1:
        # Modo produção com múltiplos workers
        uvicorn.run(
            "main:app",
            host=host,
            port=port,
            workers=workers,
            log_level=log_level,
            access_log=True,
            loop="uvloop"
        )
    else:
        # Modo desenvolvimento
        uvicorn.run(
            "main:app",
            host=host,
            port=port,
            reload=False,
            log_level=log_level,
            access_log=True
        )
