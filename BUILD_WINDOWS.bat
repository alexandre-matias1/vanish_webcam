@echo off
setlocal
cd /d "%~dp0"

where py >nul 2>nul
if errorlevel 1 (
  echo Instale o Python 3 para Windows antes de criar o executavel.
  goto :error
)

py -3 -c "import PyInstaller, cv2, mediapipe, numpy, pyvirtualcam, pygame" >nul 2>nul
if errorlevel 1 (
  echo Instalando as dependencias de build...
  py -3 -m pip install -r requirements.txt "pyinstaller>=6,<7"
  if errorlevel 1 goto :error
)

echo Verificando os modelos do MediaPipe necessarios...
py -3 -c "from vanish_cam import download_models; download_models('normal'); download_models('goku')"
if errorlevel 1 goto :error

py -3 -m PyInstaller --noconfirm --distpath dist --workpath build VanishCam.spec
if errorlevel 1 goto :error

"dist\VanishCam.exe" --self-test
if errorlevel 1 goto :error
"dist\Naruto Vanish Effect.exe" --self-test
if errorlevel 1 goto :error
"dist\Goku Vanish Effect.exe" --self-test
if errorlevel 1 goto :error
"dist\Normal and Particles Vanish.exe" --self-test
if errorlevel 1 goto :error

echo.
echo Prontos em dist: VanishCam.exe, Naruto Vanish Effect.exe,
echo Goku Vanish Effect.exe, Normal and Particles Vanish.exe
exit /b 0

:error
echo.
echo O build falhou. Confira as mensagens acima.
pause
exit /b 1
