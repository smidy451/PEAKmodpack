## Установка
1. **Клонирование репозитория**

   Откройте терминал в папке с игрой:
   ```bash
   cd путь_к_steam/steamapps/common/PEAK
   git clone git@github.com:smidy451/PEAKmodpack.git
   ```
    Если у вас нет SSH-ключа, используйте HTTPS:
    ```bash
    git clone https://github.com/smidy451/PEAKmodpack.git
    ```


2. **Первый запуск синхронизации**
   ### Windows / через Proton
   
   Добавьте в параметры запуска Steam:
   ```text
   WINEDLLOVERRIDES="winhttp=n,b" cmd /c "PEAKmodpack\sync.bat & PEAK.exe"
   ```
   ### Linux (нативный)
   
   Чтобы сделать скрипт исполняемым запустите:
   ```bash
   cd PEAKmodpack
   chmod +x sync.sh
   ./sync.sh
   ```

   Для автоматического запуска при старте игры добавьте в параметры Steam:
   ```text
   WINEDLLOVERRIDES="winhttp=n,b" /путь_к_игре/PEAK/PEAKmodpack/sync.sh
   ```

3. **Запустите игру**

   После запуска игры через steam с указанными параметрами запуска, скрипт синхронизации запулит актуальную сборку из этого репозитория в папку PEAKmodpack а потом скопирует содержимое в корень игры. После этого ирга PEAK запустится.
