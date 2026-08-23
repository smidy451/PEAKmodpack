@echo off
setlocal enabledelayedexpansion

echo === PEAK Modpack Sync ===

:: Переходим в папку репозитория (батник должен лежать в PEAK/PEAKmodpack)
cd /d "%~dp0"

:: Проверяем наличие git
git --version >nul 2>&1
if errorlevel 1 (
    echo Git не установлен! Пропускаем синхронизацию.
    goto :copy_files
)

:: Обновляем репозиторий
echo Обновление репозитория...
git pull
if errorlevel 1 (
    echo Ошибка при git pull. Продолжаем с имеющимися файлами.
)

:copy_files
echo Копирование файлов модов в папку игры...

:: Копируем BepInEx (плагины, конфиги, core) в родительскую папку (корень игры)
if exist "BepInEx" (
    xcopy /E /I /Y "BepInEx" "..\BepInEx"
)

:: Копируем файлы конфигурации в корень игры
if exist "doorstop_config.ini" (
    copy /Y "doorstop_config.ini" "..\"
)
if exist "winhttp.dll" (
    copy /Y "winhttp.dll" "..\"
)

echo Синхронизация завершена. Запуск игры...
cd /d "..\"
start "" "PEAK.exe"

pause
