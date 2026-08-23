@echo off
setlocal enabledelayedexpansion

:: Установка кодировки для корректного отображения
chcp 65001 >nul 2>&1

cd /d "%~dp0"

:: Создаём папку для логов
set "LOGDIR=logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

:: Формируем имя лог-файла: log_YYYYMMDD_HHMMSS.txt
set "LOGFILE=%LOGDIR%\log_%DATE:~-4,4%%DATE:~-10,2%%DATE:~-7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%.txt"
set "LOGFILE=%LOGFILE: =0%"

:: Создаём пустой файл
type nul > "%LOGFILE%" 2>nul

:: Функция логирования
:log
echo %*
echo %* >> "%LOGFILE%"
goto :eof

:: Начинаем запись
call :log "============================================="
call :log "       PEAK Modpack Sync"
call :log "       Started at %DATE% %TIME%"
call :log "============================================="

:: Цвета для вывода (работает в cmd, в Wine может не поддерживаться)
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "RESET=[0m"

:: Проверка наличия Git
where git >nul 2>&1
if errorlevel 1 (
    call :log "%RED%[ОШИБКА]%RESET% Git не найден в системе."
    call :log "%YELLOW%[РЕКОМЕНДАЦИЯ]%RESET% Установите Git:"
    call :log "    - Windows: https://git-scm.com/download/win"
    call :log "    - Linux: sudo apt install git  или  sudo pacman -S git"
    call :log "%YELLOW%[ДЕЙСТВИЕ]%RESET% Продолжаем без обновления (будут использованы локальные файлы)."
    goto :copy_files
)

:: Проверка версии Git
for /f "tokens=*" %%i in ('git --version') do set "GIT_VER=%%i"
call :log "%GREEN%[ИНФО]%RESET% Найден %GIT_VER%"

:: Проверка интернет-соединения (пинг до github.com)
call :log "Проверка соединения с GitHub..."
ping -n 1 github.com >nul 2>&1
if errorlevel 1 (
    call :log "%YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Нет доступа к интернету (или GitHub недоступен)."
    call :log "%YELLOW%[ДЕЙСТВИЕ]%RESET% Пропускаем обновление, используем локальные файлы."
    goto :copy_files
)

:: Проверка, является ли папка Git-репозиторием
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    call :log "%RED%[ОШИБКА]%RESET% Текущая папка не является Git-репозиторием."
    call :log "%YELLOW%[РЕКОМЕНДАЦИЯ]%RESET% Убедитесь, что вы клонировали репозиторий правильно:"
    call :log "    git clone git@github.com:smidy451/PEAKmodpack.git"
    call :log "%YELLOW%[ДЕЙСТВИЕ]%RESET% Продолжаем с локальными файлами."
    goto :copy_files
)

:: Проверка удалённого репозитория
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    call :log "%RED%[ОШИБКА]%RESET% Не удалось получить URL удалённого репозитория."
    call :log "%YELLOW%[РЕКОМЕНДАЦИЯ]%RESET% Проверьте настройки: git remote -v"
    goto :copy_files
)

:: Попытка обновления
call :log "%GREEN%[ИНФО]%RESET% Обновление репозитория..."
git pull 2>&1 | findstr /C:"Already up to date" >nul
if errorlevel 1 (
    :: Если не up-to-date, проверим ошибки
    git pull 2>&1 | findstr /C:"fatal:" >nul
    if errorlevel 1 (
        :: Ошибка не fatal - возможно, конфликт или другое
        call :log "%YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Обновление завершилось с предупреждениями."
        call :log "Проверьте вывод выше для деталей."
    ) else (
        :: fatal ошибка - авторизация, сеть и т.д.
        set "ERR_MSG="
        git pull 2>&1 | findstr /C:"Permission denied" >nul
        if not errorlevel 1 set "ERR_MSG=Ошибка авторизации (Permission denied). Убедитесь, что SSH-ключ добавлен в GitHub."
        git pull 2>&1 | findstr /C:"Could not resolve host" >nul
        if not errorlevel 1 set "ERR_MSG=Не удаётся разрешить DNS-имя github.com. Проверьте интернет-соединение."
        git pull 2>&1 | findstr /C:"Repository not found" >nul
        if not errorlevel 1 set "ERR_MSG=Репозиторий не найден. Проверьте, что URL правильный."
        git pull 2>&1 | findstr /C:"Authentication failed" >nul
        if not errorlevel 1 set "ERR_MSG=Ошибка аутентификации. Возможно, вы используете HTTPS без токена или SSH-ключ не настроен."

        if "!ERR_MSG!"=="" set "ERR_MSG=Неизвестная ошибка. Проверьте вывод выше."
        call :log "%RED%[ОШИБКА]%RESET% !ERR_MSG!"
        call :log "%YELLOW%[РЕКОМЕНДАЦИЯ]%RESET% "
        call :log "  - Убедитесь, что у вас есть доступ к репозиторию (публичный или SSH-ключ)."
        call :log "  - Если используете HTTPS, создайте токен и сохраните его в credential.helper."
        call :log "  - Проверьте интернет-соединение."
        call :log "  - Попробуйте вручную выполнить: git pull"
    )
) else (
    call :log "%GREEN%[УСПЕШНО]%RESET% Репозиторий обновлён до последней версии."
)

:copy_files
call :log ""
call :log "Копирование файлов модов в папку игры..."
if exist "BepInEx" (
    xcopy /E /I /Y "BepInEx" "..\BepInEx" >nul
    if errorlevel 1 (
        call :log "%YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Ошибка при копировании BepInEx. Проверьте права доступа."
    ) else (
        call :log "%GREEN%[ОК]%RESET% BepInEx скопирован."
    )
) else (
    call :log "%YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Папка BepInEx не найдена в репозитории."
)

if exist "doorstop_config.ini" (
    copy /Y "doorstop_config.ini" "..\" >nul
    if errorlevel 1 (
        call :log "%YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Ошибка при копировании doorstop_config.ini."
    ) else (
        call :log "%GREEN%[ОК]%RESET% doorstop_config.ini скопирован."
    )
) else (
    call :log "%YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Файл doorstop_config.ini не найден."
)

if exist "winhttp.dll" (
    copy /Y "winhttp.dll" "..\" >nul
    if errorlevel 1 (
        call :log "%YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Ошибка при копировании winhttp.dll."
    ) else (
        call :log "%GREEN%[ОК]%RESET% winhttp.dll скопирован."
    )
) else (
    call :log "%YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Файл winhttp.dll не найден."
)

call :log ""
call :log "%GREEN%[ГОТОВО]%RESET% Синхронизация завершена."
call :log "============================================="
call :log "       Finished at %DATE% %TIME%"
call :log "============================================="

:: Завершаем без паузы, чтобы игра запустилась автоматически
