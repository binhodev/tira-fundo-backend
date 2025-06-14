@echo off
echo 🌟 Iniciando Backend Python...
echo.

cd backend

if not exist "venv" (
    echo ❌ Ambiente virtual não encontrado. Execute setup.bat primeiro.
    pause
    exit /b 1
)

call venv\Scripts\activate

echo 🚀 Iniciando servidor em http://127.0.0.1:8901
echo.
echo ⚠️ Primeira execução pode demorar para carregar o modelo de IA
echo.

python main.py
