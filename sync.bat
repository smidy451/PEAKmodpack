@echo off
setlocal enabledelayedexpansion

:: Установка кодировки для корректного отображения
chcp 65001 >nul 2>&1

cd /d "%~dp0"

:: Цвета для вывода (работает в cmd, в Wine может не поддерживаться, но игнорируется)
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "RESET=[0m"

echo =============================================
echo       PEAK Modpack Sync
echo =============================================

:: Проверка наличия Git
where git >nul 2>&1
if errorlevel 1 (
    echo %RED%[ОШИБКА]%RESET% Git не найден в системе.
    echo %YELLOW%[РЕКОМЕНДАЦИЯ]%RESET% Установите Git:
    echo    - Windows: https://git-scm.com/download/win
    echo    - Linux: sudo apt install git  или  sudo pacman -S git
    echo %YELLOW%[ДЕЙСТВИЕ]%RESET% Продолжаем без обновления (будут использованы локальные файлы).
    goto :copy_files
)

:: Проверка версии Git
for /f "tokens=*" %%i in ('git --version') do set "GIT_VER=%%i"
echo %GREEN%[ИНФО]%RESET% Найден %GIT_VER%

:: Проверка интернет-соединения (пинг до github.com)
echo Проверка соединения с GitHub...
ping -n 1 github.com >nul 2>&1
if errorlevel 1 (
    echo %YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Нет доступа к интернету (или GitHub недоступен).
    echo %YELLOW%[ДЕЙСТВИЕ]%RESET% Пропускаем обновление, используем локальные файлы.
    goto :copy_files
)

:: Проверка, является ли папка Git-репозиторием
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo %RED%[ОШИБКА]%RESET% Текущая папка не является Git-репозиторием.
    echo %YELLOW%[РЕКОМЕНДАЦИЯ]%RESET% Убедитесь, что вы клонировали репозиторий правильно:
    echo    git clone git@github.com:smidy451/PEAKmodpack.git
    echo %YELLOW%[ДЕЙСТВИЕ]%RESET% Продолжаем с локальными файлами.
    goto :copy_files
)

:: Проверка удалённого репозитория
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo %RED%[ОШИБКА]%RESET% Не удалось получить URL удалённого репозитория.
    echo %YELLOW%[РЕКОМЕНДАЦИЯ]%RESET% Проверьте настройки: git remote -v
    goto :copy_files
)

:: Попытка обновления
echo %GREEN%[ИНФО]%RESET% Обновление репозитория...
git pull 2>&1 | findstr /C:"Already up to date" >nul
if errorlevel 1 (
    :: Если не up-to-date, проверим ошибки
    git pull 2>&1 | findstr /C:"fatal:" >nul
    if errorlevel 1 (
        :: Ошибка не fatal - возможно, конфликт или другое
        echo %YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Обновление завершилось с предупреждениями.
        echo Проверьте вывод выше для деталей.
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
        echo %RED%[ОШИБКА]%RESET% !ERR_MSG!
        echo %YELLOW%[РЕКОМЕНДАЦИЯ]%RESET% 
        echo   - Убедитесь, что у вас есть доступ к репозиторию (публичный или SSH-ключ).
        echo   - Если используете HTTPS, создайте токен и сохраните его в credential.helper.
        echo   - Проверьте интернет-соединение.
        echo   - Попробуйте вручную выполнить: git pull
    )
) else (
    echo %GREEN%[УСПЕШНО]%RESET% Репозиторий обновлён до последней версии.
)

:copy_files
echo.
echo Копирование файлов модов в папку игры...
if exist "BepInEx" (
    xcopy /E /I /Y "BepInEx" "..\BepInEx" >nul
    if errorlevel 1 (
        echo %YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Ошибка при копировании BepInEx. Проверьте права доступа.
    ) else (
        echo %GREEN%[ОК]%RESET% BepInEx скопирован.
    )
) else (
    echo %YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Папка BepInEx не найдена в репозитории.
)

if exist "doorstop_config.ini" (
    copy /Y "doorstop_config.ini" "..\" >nul
    if errorlevel 1 (
        echo %YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Ошибка при копировании doorstop_config.ini.
    ) else (
        echo %GREEN%[ОК]%RESET% doorstop_config.ini скопирован.
    )
) else (
    echo %YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Файл doorstop_config.ini не найден.
)

if exist "winhttp.dll" (
    copy /Y "winhttp.dll" "..\" >nul
    if errorlevel 1 (
        echo %YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Ошибка при копировании winhttp.dll.
    ) else (
        echo %GREEN%[ОК]%RESET% winhttp.dll скопирован.
    )
) else (
    echo %YELLOW%[ПРЕДУПРЕЖДЕНИЕ]%RESET% Файл winhttp.dll не найден.
)

echo.
echo %GREEN%[ГОТОВО]%RESET% Синхронизация завершена.
echo =============================================

:: Завершаем без паузы, чтобы игра запустилась автоматически
