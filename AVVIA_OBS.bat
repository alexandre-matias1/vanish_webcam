@echo off
call "%~dp0AVVIA_LOCALE.bat" --no-virtual-camera --no-countdown %*
exit /b %errorlevel%
