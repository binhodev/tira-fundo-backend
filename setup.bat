@echo off
echo 🚀 Configurando Backend Python para Remoção de Fundo
echo.

cd backend

echo 📦 Criando ambiente virtual...
python -m venv venv
if %ERRORLEVEL% neq 0 (
    echo ❌ Erro ao criar ambiente virtual
    pause
    exit /b 1
)

echo 🔄 Ativando ambiente virtual...
call venv\Scripts\activate

echo 📥 Instalando dependências...
pip install --upgrade pip
pip install -r requirements.txt
if %ERRORLEVEL% neq 0 (
    echo ❌ Erro ao instalar dependências
    pause
    exit /b 1
)

echo.
echo ✅ Setup concluído com sucesso!
echo.
echo Para iniciar o backend, execute:
echo   cd backend
echo   venv\Scripts\activate
echo   python main.py
echo.
pause
