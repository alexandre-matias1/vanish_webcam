@echo off
setlocal
cd /d "%~dp0\.."

set "VENV_DIR=.venv-local"
set "VENV_PY=%VENV_DIR%\Scripts\python.exe"

if not exist "%VENV_PY%" (
  echo [Vanish Lab] Criando o ambiente Python local...
  where py >nul 2>nul
  if not errorlevel 1 (
    py -3 -m venv "%VENV_DIR%"
  ) else (
    python -m venv "%VENV_DIR%"
  )
  if errorlevel 1 goto :error
)

"%VENV_PY%" -c "import cv2, mediapipe, numpy, pyvirtualcam" >nul 2>nul
if errorlevel 1 (
  echo [Vanish Lab] Instalando os componentes necessarios. A internet so e necessaria desta vez...
  "%VENV_PY%" -m pip install --upgrade pip
  if errorlevel 1 goto :error
  "%VENV_PY%" -m pip install -r "local_app\requirements.txt"
  if errorlevel 1 goto :error
)

echo [Vanish Lab] Abrindo a webcam...
"%VENV_PY%" "local_app\vanish_cam.py" %*
if errorlevel 1 goto :error
exit /b 0

:error
echo.
echo Nao foi possivel abrir o Vanish Lab. Leia local_app\README.md para as solucoes comuns.
pause
exit /b 1
