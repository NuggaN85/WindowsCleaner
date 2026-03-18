@echo off
:: ========================================================
:: Script de nettoyage Windows sécurisé
:: Version 4.1 - RL Informatique
:: ========================================================

:: ==== INITIALISATION PROPRE =====
setlocal DISABLEDELAYEDEXPANSION
cd /d "%~dp0"
title Nettoyage Windows v4.1

:: ==== DÉTECTION DE RELANCE ====
if "%RELOAD%"=="1" goto :MAIN
set "RELOAD=1"
start "" /b cmd /c "%~f0" 
exit /b

:MAIN
setlocal ENABLEDELAYEDEXPANSION
chcp 65001 >nul 2>&1

:: ==== VERROUILLAGE ANTI-MULTIPLE ====
set "LOCKFILE=%TEMP%\nettoyage_windows_%USERNAME%.lock"
2>nul (
    >"%LOCKFILE%" (
        echo %date% %time%
    )
) || (
    echo [ERREUR] Une instance est déjà en cours d'exécution
    timeout /t 3 /nobreak >nul
    exit /b 1
)

:: ==== VARIABLES GLOBALES ====
set "VERSION=4.1"
set "AUTHOR=RL Informatique"
set "SAFE_MODE=1"
set "CONFIRM_ALL=0"
set "ERROR_COUNT=0"
set "WARNING_COUNT=0"
set "USER_CONFIRM="
set "CHOICE="
set "CUSTOM_CHOICE="
set "SPACE_BEFORE=0"
set "SPACE_AFTER=0"

:: ==== CHEMINS DYNAMIQUES ====
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do set "DATETIME=%%I"
set "LOGFILE=%USERPROFILE%\Desktop\Nettoyage_%DATETIME:~0,8%_%DATETIME:~8,4%.txt"
set "BACKUP_DIR=%USERPROFILE%\Desktop\Backup_%DATETIME:~0,8%_%DATETIME:~8,4%"

:: ==== DÉTECTION SYSTÈME ====
set "OS_VERSION=Inconnu"
ver | findstr /r /c:"^Microsoft Windows [1][0-1]" >nul && set "OS_VERSION=Windows 10/11" || (
    echo [ERREUR] Windows 10/11 requis
    goto :CLEAN_EXIT
)

:: ==== VÉRIFICATION ADMIN ====
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERREUR] Droits administrateur requis
    echo.
    echo Relance automatique en tant qu'administrateur...
    timeout /t 2 /nobreak >nul
    
    :: Création du script VBS pour élévation
    set "VBSFILE=%TEMP%\getadmin.vbs"
    (
        echo Set UAC = CreateObject^("Shell.Application"^)
        echo UAC.ShellExecute "%~s0", "", "", "runas", 1
    ) > "%VBSFILE%"
    "%VBSFILE%"
    del "%VBSFILE%" 2>nul
    exit /b
)

:: ==== DÉTECTION DISQUE ====
set "DISK_TYPE=HDD"
for /f "skip=1 tokens=2" %%a in ('wmic diskdrive where "index=0" get mediatype 2^>nul') do (
    echo %%a | find "SSD" >nul && set "DISK_TYPE=SSD"
)

:: ==== FONCTIONS UTILITAIRES ====

:InitLog
if exist "%LOGFILE%" del "%LOGFILE%" 2>nul
(
    echo ========================================
    echo NETTOYAGE WINDOWS v%VERSION%
    echo Date : %date% %time%
    echo Utilisateur : %USERNAME%
    echo Ordinateur : %COMPUTERNAME%
    echo Type disque : %DISK_TYPE%
    echo Mode securise : %SAFE_MODE%
    echo ========================================
    echo.
) > "%LOGFILE%"
goto :EOF

:LogInfo
echo [%time:~0,8%] [INFO] %* >> "%LOGFILE%"
exit /b 0

:LogWarning
echo [%time:~0,8%] [WARN] %* >> "%LOGFILE%"
set /a WARNING_COUNT+=1
exit /b 0

:LogError
echo [%time:~0,8%] [ERREUR] %* >> "%LOGFILE%"
set /a ERROR_COUNT+=1
exit /b 0

:GetFreeSpace
setlocal
set "free_mb=0"
for /f "tokens=3" %%a in ('dir /-c %SystemDrive% ^| find "libres" ^| find "octets"') do set "free_bytes=%%a"
if defined free_bytes (
    set /a "free_mb=!free_bytes:,=!/1048576"
) else (
    for /f "tokens=3" %%a in ('dir /-c %SystemDrive% ^| find "free"') do set "free_bytes=%%a"
    if defined free_bytes set /a "free_mb=!free_bytes:,=!/1048576"
)
endlocal & set "FREE_SPACE=%free_mb%"
exit /b %free_mb%

:AskUser
set "PROMPT_MSG=%~1"
if "%CONFIRM_ALL%"=="1" (
    echo %PROMPT_MSG% [O/tous/N] : O (auto)
    set "USER_CONFIRM=O"
    exit /b 0
)
choice /c ONT /n /m "%PROMPT_MSG% [O/tous/N] : "
if errorlevel 3 set "USER_CONFIRM=N" & exit /b 1
if errorlevel 2 set "CONFIRM_ALL=1" & set "USER_CONFIRM=O" & echo [INFO] Auto-confirmation active
if errorlevel 1 set "USER_CONFIRM=O"
exit /b 0

:CreateBackupDir
if not exist "%BACKUP_DIR%" (
    md "%BACKUP_DIR%" 2>nul || set "BACKUP_DIR=%TEMP%"
)
exit /b 0

:CreateRestorePoint
call :LogInfo "Creation point restauration..."
powershell -Command "Checkpoint-Computer -Description 'Nettoyage v%VERSION%' -RestorePointType MODIFY_SETTINGS" >nul 2>&1
if errorlevel 1 (
    call :LogError "Echec creation point restauration"
    call :AskUser "Continuer sans point restauration ?"
    if "!USER_CONFIRM!"=="N" goto :CLEAN_EXIT
) else (
    call :LogInfo "Point restauration cree"
)
exit /b 0

:IsRunning
tasklist /FI "IMAGENAME eq %1" 2>nul | find /I "%1" >nul
exit /b %errorlevel%

:CleanTemp
call :LogInfo "Nettoyage fichiers temporaires..."
cleanmgr /sagerun:1 >nul 2>&1
for %%D in ("%TEMP%" "%WINDIR%\Temp") do (
    if exist %%D (
        del /f /s /q "%%D\*.*" 2>nul
        for /d %%S in ("%%D\*") do rd /s /q "%%S" 2>nul
    )
)
net stop wuauserv >nul 2>&1
rd /s /q "%WINDIR%\SoftwareDistribution\Download" 2>nul
md "%WINDIR%\SoftwareDistribution\Download" 2>nul
net start wuauserv >nul 2>&1
call :LogInfo "Temporaires nettoyes"
exit /b 0

:CleanSystem
call :LogInfo "Nettoyage fichiers systeme..."
if exist "%SystemDrive%\Windows.old" (
    call :AskUser "Supprimer Windows.old ?"
    if "!USER_CONFIRM!"=="O" (
        rd /s /q "%SystemDrive%\Windows.old" 2>nul
        call :LogInfo "Windows.old supprime"
    )
)
dism /online /cleanup-image /startcomponentcleanup /resetbase >nul 2>&1
call :LogInfo "Systeme nettoye"
exit /b 0

:CleanBrowsers
call :LogInfo "Nettoyage navigateurs..."
set "BROWSERS=chrome.exe firefox.exe msedge.exe iexplore.exe"
for %%B in (%BROWSERS%) do (
    call :IsRunning "%%B"
    if !errorlevel! equ 0 (
        call :AskUser "Fermer %%B ?"
        if "!USER_CONFIRM!"=="O" (
            taskkill /F /IM %%B >nul 2>&1
            timeout /t 2 /nobreak >nul
        )
    )
)
:: Chrome
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" 2>nul
)
:: Firefox
for /d %%P in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do (
    if exist "%%P\cache2" rd /s /q "%%P\cache2" 2>nul
)
:: Edge
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" 2>nul
)
call :LogInfo "Caches navigateurs nettoyes"
exit /b 0

:Maintenance
call :LogInfo "Maintenance systeme..."
sfc /scannow >nul 2>&1
dism /online /cleanup-image /restorehealth >nul 2>&1
if /i "%DISK_TYPE%"=="SSD" (
    powershell -Command "Optimize-Volume -DriveLetter C -ReTrim -Verbose" >nul 2>&1
) else (
    defrag %SystemDrive% /O /U >nul 2>&1
)
call :LogInfo "Maintenance terminee"
exit /b 0

:CleanRecycle
call :LogInfo "Vidage corbeille..."
call :AskUser "Vider la corbeille ?"
if "!USER_CONFIRM!"=="O" (
    rd /s /q %SystemDrive%\$Recycle.bin 2>nul
    call :LogInfo "Corbeille videe"
)
exit /b 0

:CleanDNS
call :LogInfo "Vidage cache DNS..."
ipconfig /flushdns >nul 2>&1
call :LogInfo "DNS vide"
exit /b 0

:CleanEvents
call :LogInfo "Nettoyage journaux..."
call :CreateBackupDir
for %%L in (Application System Security) do (
    wevtutil epl %%L "%BACKUP_DIR%\%%L.evtx" /ow:true 2>nul
    wevtutil clear-log %%L 2>nul
)
call :LogInfo "Journaux nettoyes"
exit /b 0

:CleanThumbs
call :LogInfo "Nettoyage miniatures..."
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" 2>nul
call :LogInfo "Miniatures nettoyees"
exit /b 0

:ShowMenu
cls
echo.
echo #######################################################
echo #                                                     #
echo #     NETTOYAGE WINDOWS SECURISE - v%VERSION%          #
echo #              %AUTHOR%                    #
echo #                                                     #
echo #######################################################
echo.
echo Disque : %DISK_TYPE% ^| Securise : %SAFE_MODE% ^| Erreurs : %ERROR_COUNT%
echo.
echo 1. Nettoyage rapide (temporaires + corbeille + DNS)
echo 2. Nettoyage systeme (WinSxS, Windows.old, logs)
echo 3. Nettoyage navigateurs (cache)
echo 4. Maintenance (SFC, DISM, optimisation)
echo 5. Nettoyage complet (tout avec confirmations)
echo 6. Espace disque
echo.
echo S. Mode securise [%SAFE_MODE%]
echo C. Confirmation auto [%CONFIRM_ALL%]
echo 0. Quitter
echo.
set /p "CHOIX=Choix : "
exit /b 0

:ShowSpace
cls
call :GetFreeSpace
echo.
echo ========== ESPACE DISQUE ==========
echo.
echo Lecteur %SystemDrive% : %FREE_SPACE% Mo libres
echo Type : %DISK_TYPE%
echo.
pause
exit /b 0

:RunCleanup
set "ACTION=%~1"
call :LogInfo "Demarrage: %ACTION%"
call %ACTION%
exit /b 0

:RunGuided
call :CreateRestorePoint
call :RunCleanup CleanTemp
call :RunCleanup CleanSystem
call :RunCleanup CleanBrowsers
call :RunCleanup Maintenance
call :RunCleanup CleanRecycle
call :RunCleanup CleanDNS
call :RunCleanup CleanEvents
call :RunCleanup CleanThumbs
exit /b 0

:ShowSummary
call :GetFreeSpace
set "SPACE_AFTER=%FREE_SPACE%"
set /a GAINED=SPACE_AFTER-SPACE_BEFORE
cls
echo.
echo ============ RESUME ============
echo.
echo Avant : %SPACE_BEFORE% Mo
echo Apres  : %SPACE_AFTER% Mo
echo Gagne  : %GAINED% Mo
echo.
echo Avertissements : %WARNING_COUNT%
echo Erreurs : %ERROR_COUNT%
echo Log : %LOGFILE%
echo.
if exist "%BACKUP_DIR%" echo Backup : %BACKUP_DIR%
echo.
(
    echo.
    echo ============ RESUME ============
    echo Espace gagne : %GAINED% Mo
    echo Avertissements : %WARNING_COUNT%
    echo Erreurs : %ERROR_COUNT%
) >> "%LOGFILE%"
pause
exit /b 0

:AskRestart
echo.
choice /c ON /n /m "Redemarrer maintenant ? (O/N) : "
if errorlevel 2 exit /b 0
shutdown /r /t 30 /c "Redemarrage pour finaliser le nettoyage"
echo Redemarrage dans 30 secondes...
exit /b 0

:: ==== PROGRAMME PRINCIPAL ====

call :InitLog
call :GetFreeSpace
set "SPACE_BEFORE=%FREE_SPACE%"

cls
echo.
echo ========================================
echo   NETTOYAGE WINDOWS v%VERSION%
echo ========================================
echo.
echo Bienvenue dans l'outil de nettoyage securise
echo.
echo - Droits admin : OUI
echo - Windows 10/11 : OUI
echo - Log : %LOGFILE%
echo.
pause

:LOOP
call :ShowMenu

if "%CHOIX%"=="0" goto :FIN
if /i "%CHOIX%"=="S" (
    if "%SAFE_MODE%"=="1" (set "SAFE_MODE=0") else (set "SAFE_MODE=1")
    call :LogInfo "Mode securise: %SAFE_MODE%"
    goto :LOOP
)
if /i "%CHOIX%"=="C" (
    if "%CONFIRM_ALL%"=="1" (set "CONFIRM_ALL=0") else (set "CONFIRM_ALL=1")
    call :LogInfo "Confirmation auto: %CONFIRM_ALL%"
    goto :LOOP
)
if "%CHOIX%"=="1" call :CreateRestorePoint & call :RunCleanup CleanTemp & call :RunCleanup CleanRecycle & call :RunCleanup CleanDNS & goto :SUMMARY
if "%CHOIX%"=="2" call :CreateRestorePoint & call :RunCleanup CleanSystem & call :RunCleanup CleanEvents & call :RunCleanup CleanThumbs & goto :SUMMARY
if "%CHOIX%"=="3" call :RunCleanup CleanBrowsers & goto :SUMMARY
if "%CHOIX%"=="4" call :CreateRestorePoint & call :RunCleanup Maintenance & goto :SUMMARY
if "%CHOIX%"=="5" call :RunGuided & goto :SUMMARY
if "%CHOIX%"=="6" call :ShowSpace & goto :LOOP

goto :LOOP

:SUMMARY
call :ShowSummary
call :AskRestart

:FIN
echo.
echo Nettoyage termine.

:: ==== NETTOYAGE AVANT SORTIE ====
:CLEAN_EXIT
if exist "%LOCKFILE%" del "%LOCKFILE%" 2>nul
endlocal
endlocal
timeout /t 2 /nobreak >nul
exit
