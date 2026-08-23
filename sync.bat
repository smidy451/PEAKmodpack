@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

:: Папка для логов
set "LOGDIR=logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

:: Имя лог-файла с датой/временем
set "LOGFILE=%LOGDIR%\log_%DATE:~-4,4%%DATE:~-10,2%%DATE:~-7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%.txt"
set "LOGFILE=%LOGFILE: =0%"

:: Очищаем файл и пишем заголовок
echo ============================================= > "%LOGFILE%"
echo        PEAK Modpack Sync >> "%LOGFILE%"
echo        Started at %DATE% %TIME% >> "%LOGFILE%"
echo ============================================= >> "%LOGFILE%"

:: Проверка Git
where git >nul 2>&1
if errorlevel 1 (
    echo Git не найден. Пропускаем обновление. >> "%LOGFILE%"
    echo Git не найден. Пропускаем обновление.
    goto :copy_files
)

:: Версия Git
for /f "tokens=*" %%i in ('git --version') do echo Найден %%i >> "%LOGFILE%"

:: Попытка git pull
echo Обновление репозитория... >> "%LOGFILE%"
echo Обновление репозитория...
git pull >> "%LOGFILE%" 2>&1
if errorlevel 1 (
    echo Ошибка git pull. >> "%LOGFILE%"
    echo Ошибка git pull.
) else (
    echo Успешно обновлено. >> "%LOGFILE%"
)

:copy_files
echo Копирование файлов... >> "%LOGFILE%"
echo Копирование файлов...

if exist "BepInEx" (
    xcopy /E /I /Y "BepInEx" "..\BepInEx" >> "%LOGFILE%" 2>&1
    if errorlevel 1 (
        echo Ошибка копирования BepInEx >> "%LOGFILE%"
    ) else (
        echo BepInEx скопирован >> "%LOGFILE%"
    )
) else (
    echo Папка BepInEx не найдена >> "%LOGFILE%"
)

if exist "doorstop_config.ini" (
    copy /Y "doorstop_config.ini" "..\" >> "%LOGFILE%" 2>&1
    if errorlevel 1 (
        echo Ошибка копирования doorstop_config.ini >> "%LOGFILE%"
    ) else (
        echo doorstop_config.ini скопирован >> "%LOGFILE%"
    )
) else (
    echo doorstop_config.ini не найден >> "%LOGFILE%"
)

if exist "winhttp.dll" (
    copy /Y "winhttp.dll" "..\" >> "%LOGFILE%" 2>&1
    if errorlevel 1 (
        echo Ошибка копирования winhttp.dll >> "%LOGFILE%"
    ) else (
        echo winhttp.dll скопирован >> "%LOGFILE%"
    )
) else (
    echo winhttp.dll не найден >> "%LOGFILE%"
)

echo ============================================= >> "%LOGFILE%"
echo        Finished at %DATE% %TIME% >> "%LOGFILE%"
echo ============================================= >> "%LOGFILE%"

echo Синхронизация завершена.
