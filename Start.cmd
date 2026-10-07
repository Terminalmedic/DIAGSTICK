@echo off
rem Kaynnistaa DIAGSTICK-valikon jarjestelmanvalvojana. WinPE:ssa ollaan jo valmiiksi.
fltmc >nul 2>&1 || (powershell -NoProfile -Command "Start-Process -Verb RunAs '%~f0'" & exit /b)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Scripts\Start.ps1"
