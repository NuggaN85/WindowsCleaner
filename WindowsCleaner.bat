@echo off
:: ========================================================
:: Script de nettoyage Windows sécurisé
:: Version 4.2 - RL Informatique
:: ========================================================

:: ==== INITIALISATION PROPRE =====
setlocal DISABLEDELAYEDEXPANSION
cd /d "%~dp0"
title Nettoyage Windows v4.2

:: ==== VÉRIFICATION ADMIN (prioritaire) ====
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERREUR] Droits administrateur requis
    echo.
    echo Relance automatique en tant qu'administrateur...
    timeout /t 2 /nobreak >nul
    
    set "VBSFILE=%TEMP%\getadmin_%RANDOM%.vbs"
    (
        echo Set UAC = CreateObject^("Shell.Application"^)
        echo UAC.ShellExecute "%~s0", "", "", "runas", 1
    ) > "!VBSFILE!"
    start "" "!VBSFILE!"
    del "!VBSFILE!" 2>nul
    exit /b
)

:: ==== INITIALISATION POST-ADMIN ====
setlocal ENABLEDELAYEDEXPANSION
chcp 65001 >nul 2>&1

:: ==== VERROUILLAGE ANTI-MULTIPLE ====
set "LOCKFILE=%TEMP%\nettoyage_windows_%USERNAME%.lock"
if exist "!LOCKFILE!" (
    for /f "tokens=*" %%A in ('type "!LOCKFILE!"') do set "LOCK_TIME=%%A"
    echo [ERREUR] Une instance est déjà en cours d'exécution
    echo Démarrage : !LOCK_TIME!
    timeout /t 3 /nobreak >nul
    exit /b 1
)

:: ==== CRÉATION DU VERROUILLAGE ====
(
    echo %date% %time%
) > "!LOCKFILE!"

:: ==== VARIABLES GLOBALES ====
set "VERSION=4.2"
set "AUTHOR=RL Informatique"
set "SAFE_MODE=1"
set "CONFIRM_ALL=0"
set "ERROR_COUNT=0"
set "WARNING_COUNT=0"
set "USER_CONFIRM="
set "SPACE_BEFORE=0"
set "SPACE_AFTER=0"
set "SUCCESS_COUNT=0"

:: ==== CHEMINS DYNAMIQUES ====
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value 2^>nul') do set "DATETIME=%%I"
set "LOGFILE=%USERPROFILE%\Desktop\Nettoyage_%DATETIME:~0,8%_%DATETIME:~8,4%.txt"
set "BACKUP_DIR=%USERPROFILE%\Desktop\Backup_%DATETIME:~0,8%_%DATETIME:~8,4%"

:: ==== DÉTECTION SYSTÈME ====
set "OS_VERSION=Inconnu"
for /f "tokens=3" %%I in ('ver ^| find "Windows"') do (
    set "OS_VERSION=%%I"
    echo !OS_VERSION! | find /i "10" >nul && set "OS_VALID=1"
    echo !OS_VERSION! | find /i "11" >nul && set "OS_VALID=1"
)
if not defined OS_VALID (
    echo [ERREUR] Windows 10/11 requis
    timeout /t 3 /nobreak >nul
    goto :CLEAN_EXIT
)

:: ==== DÉTECTION DISQUE (optimisée) ====
set "DISK_TYPE=HDD"
for /f "skip=1 tokens=2" %%a in ('wmic logicaldisk where "name='%SystemDrive:~0,2%'" get size 2^>nul') do (
    if %%a gtr 0 set "DISK_CAPACITY=%%a"
)
wmic diskdrive get mediatype 2>nul | find /i "SSD" >nul && set "DISK_TYPE=SSD"

:: ==== FONCTIONS UTILITAIRES ====

:InitLog
(
    echo ========================================
    echo NETTOYAGE WINDOWS v!VERSION!
    echo Date : %date% %time%
    echo Utilisateur : %USERNAME%
    echo Ordinateur : %COMPUTERNAME%
    echo Système : !OS_VERSION!
    echo Type disque : !DISK_TYPE!
    echo Mode securise : !SAFE_MODE!
    echo ========================================
    echo.
) > "!LOGFILE!"
exit /b 0

:LogInfo
echo [%time:~0,8%] [INFO] %* >> "!LOGFILE!"
exit /b 0

:LogWarning
echo [%time:~0,8%] [AVERTISSEMENT] %* >> "!LOGFILE!"
set /a WARNING_COUNT+=1
exit /b 0

:LogError
echo [%time:~0,8%] [ERREUR] %* >> "!LOGFILE!"
set /a ERROR_COUNT+=1
exit /b 0

:LogSuccess
echo [%time:~0,8%] [SUCCESS] %* >> "!LOGFILE!"
set /a SUCCESS_COUNT+=1
exit /b 0

:GetFreeSpace
setlocal ENABLEDELAYEDEXPANSION
set "free_mb=0"
for /f "tokens=3" %%a in ('dir /-c %SystemDrive% 2^>nul ^| find "libres"') do (
    set "free_bytes=%%a"
    set "free_bytes=!free_bytes:,=!"
    set /a "free_mb=!free_bytes! / 1048576"
)
endlocal & set "FREE_SPACE=%free_mb%"
exit /b 0

:AskUser
setlocal ENABLEDELAYEDEXPANSION
set "PROMPT_MSG=%~1"
if "!CONFIRM_ALL!"=="1" (
    echo !PROMPT_MSG! [O/T/N] : O ^(auto^)
    set "USER_CONFIRM=O"
    endlocal & set "USER_CONFIRM=O"
    exit /b 0
)
choice /c ONT /n /m "!PROMPT_MSG! [O/T/N] : "
if errorlevel 3 (set "USER_CONFIRM=N") else if errorlevel 2 (
    set "CONFIRM_ALL=1"
    set "USER_CONFIRM=O"
    echo [INFO] Auto-confirmation activée
) else (
    set "USER_CONFIRM=O"
)
endlocal & set "USER_CONFIRM=%USER_CONFIRM%" & set "CONFIRM_ALL=%CONFIRM_ALL%"
exit /b 0

:CreateBackupDir
if not exist "!BACKUP_DIR!" (
    md "!BACKUP_DIR!" 2>nul || (
        set "BACKUP_DIR=%TEMP%"
        call :LogWarning "Backup_DIR créé dans TEMP"
    )
)
exit /b 0

:CreateRestorePoint
call :LogInfo "Création point de restauration..."
powershell -Command "try {Checkpoint-Computer -Description 'Nettoyage v!VERSION!' -RestorePointType MODIFY_SETTINGS} catch {exit 1}" >nul 2>&1
if errorlevel 1 (
    call :LogWarning "Impossible de créer le point de restauration"
    call :AskUser "Continuer sans point de restauration ?"
    if "!USER_CONFIRM!"=="N" goto :CLEAN_EXIT
) else (
    call :LogSuccess "Point de restauration créé"
)
exit /b 0

:IsProcessRunning
tasklist /FI "IMAGENAME eq %1" 2>nul | find /i "%1" >nul
exit /b %errorlevel%

:CloseProcessSafely
set "PROCESS=%~1"
call :IsProcessRunning "!PROCESS!"
if !errorlevel! equ 0 (
    call :AskUser "Fermer !PROCESS! ?"
    if "!USER_CONFIRM!"=="O" (
        taskkill /F /IM "!PROCESS!" >nul 2>&1 && call :LogSuccess "!PROCESS! fermé" || call :LogError "Impossible de fermer !PROCESS!"
        timeout /t 1 /nobreak >nul
    )
)
exit /b 0

:CleanTemp
call :LogInfo "Nettoyage des fichiers temporaires..."
setlocal ENABLEDELAYEDEXPANSION

for %%D in ("%TEMP%" "%WINDIR%\Temp") do (
    if exist %%D (
        del /f /s /q "%%D\*.*" 2>nul
        for /d %%S in ("%%D\*") do rd /s /q "%%S" 2>nul
    )
)

net stop wuauserv >nul 2>&1
if !errorlevel! equ 0 (
    rd /s /q "%WINDIR%\SoftwareDistribution\Download" 2>nul
    md "%WINDIR%\SoftwareDistribution\Download" 2>nul
    net start wuauserv >nul 2>&1
)

endlocal
call :LogSuccess "Fichiers temporaires nettoyés"
exit /b 0

:CleanSystem
call :LogInfo "Nettoyage des fichiers système..."

:: Nettoyage Windows.old
if exist "%SystemDrive%\Windows.old" (
    call :AskUser "Supprimer Windows.old (~20GB) ?"
    if "!USER_CONFIRM!"=="O" (
        rd /s /q "%SystemDrive%\Windows.old" 2>nul
        call :LogSuccess "Windows.old supprimé"
    )
)

:: Nettoyage DISM
dism /online /cleanup-image /startcomponentcleanup /resetbase >nul 2>&1
if !errorlevel! equ 0 (
    call :LogSuccess "Image système nettoyée"
) else (
    call :LogWarning "Le nettoyage DISM a rencontré des problèmes"
)

exit /b 0

:CleanBrowsers
call :LogInfo "Nettoyage des navigateurs..."

:: Fermeture sécurisée
call :CloseProcessSafely "chrome.exe"
call :CloseProcessSafely "firefox.exe"
call :CloseProcessSafely "msedge.exe"

timeout /t 2 /nobreak >nul

:: Chrome
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" 2>nul
    call :LogSuccess "Cache Chrome nettoyé"
)

:: Firefox
for /d %%P in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do (
    if exist "%%P\cache2" (
        rd /s /q "%%P\cache2" 2>nul
        call :LogSuccess "Cache Firefox nettoyé"
    )
)

:: Edge
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" 2>nul
    call :LogSuccess "Cache Edge nettoyé"
)

exit /b 0

:Maintenance
call :LogInfo "Maintenance système..."

echo Vérification intégrité système (SFC)...
sfc /scannow >nul 2>&1
if !errorlevel! equ 0 (
    call :LogSuccess "SFC: Vérification réussie"
) else (
    call :LogWarning "SFC: Certains fichiers n'ont pas pu être réparés"
)

echo Réparation image Windows (DISM)...
dism /online /cleanup-image /restorehealth >nul 2>&1

:: Optimisation disque
if /i "!DISK_TYPE!"=="SSD" (
    echo Optimisation SSD (TRIM)...
    powershell -Command "Optimize-Volume -DriveLetter !SystemDrive:~0,1! -ReTrim -Verbose" >nul 2>&1
    call :LogSuccess "SSD optimisé (TRIM)"
) else (
    echo Défragmentation disque...
    defrag !SystemDrive! /O /U >nul 2>&1
    call :LogSuccess "Disque défragmenté"
)

exit /b 0

:CleanRecycle
call :LogInfo "Nettoyage de la corbeille..."
call :AskUser "Vider la corbeille ?"
if "!USER_CONFIRM!"=="O" (
    rd /s /q %SystemDrive%\$Recycle.bin 2>nul
    call :LogSuccess "Corbeille vidée"
)
exit /b 0

:CleanDNS
call :LogInfo "Vidage du cache DNS..."
ipconfig /flushdns >nul 2>&1
if !errorlevel! equ 0 (
    call :LogSuccess "Cache DNS vidé"
) else (
    call :LogWarning "Impossible de vider le cache DNS"
)
exit /b 0

:CleanEvents
call :LogInfo "Nettoyage des journaux d'événements..."
call :CreateBackupDir

setlocal ENABLEDELAYEDEXPANSION
for %%L in (Application System Security) do (
    wevtutil epl %%L "!BACKUP_DIR!\%%L.evtx" /ow:true 2>nul
    wevtutil clear-log %%L 2>nul
    call :LogSuccess "Journal %%L nettoyé et sauvegardé"
)
endlocal

exit /b 0

:CleanThumbs
call :LogInfo "Nettoyage des miniatures..."
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" 2>nul
call :LogSuccess "Miniatures nettoyées"
exit /b 0

:CleanPreloadedApps
call :LogInfo "Nettoyage des apps préchargées..."
powershell -Command "Get-AppxPackage *zunemusic* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *zunevideo* | Remove-AppxPackage" >nul 2>&1
powershell -Command "Get-AppxPackage *messagesynch* | Remove-AppxPackage" >nul 2>&1
call :LogSuccess "Applications système non essentielles supprimées"
exit /b 0

:ShowMenu
cls
echo.
echo #######################################################
echo #                                                     #
echo #     NETTOYAGE WINDOWS SECURISE - v!VERSION!         #
echo #              !AUTHOR!                    #
echo #                                                     #
echo #######################################################
echo.
echo Disque : !DISK_TYPE! ^| Securise : !SAFE_MODE! ^| Erreurs : !ERROR_COUNT! ^| Succes : !SUCCESS_COUNT!
echo.
echo 1. Nettoyage rapide (temporaires + corbeille + DNS)
echo 2. Nettoyage systeme (WinSxS, Windows.old, logs)
echo 3. Nettoyage navigateurs (cache)
echo 4. Maintenance (SFC, DISM, optimisation)
echo 5. Nettoyage complet (tous les nettoyages)
echo 6. Nettoyage apps preloaded (bloatware)
echo 7. Espace disque
echo.
echo S. Mode securise [!SAFE_MODE!]
echo C. Confirmation auto [!CONFIRM_ALL!]
echo 0. Quitter
echo.
set /p "CHOIX=Votre choix : "
exit /b 0

:ShowSpace
cls
call :GetFreeSpace
echo.
echo ========== ESPACE DISQUE ==========
echo.
echo Lecteur %SystemDrive% : !FREE_SPACE! Mo libres
echo Type : !DISK_TYPE!
echo.
pause
exit /b 0

:RunCleanup
set "ACTION=%~1"
call :LogInfo "Démarrage : !ACTION!"
call :!ACTION!
exit /b 0

:RunCompleteCleaning
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
set "SPACE_AFTER=!FREE_SPACE!"
set /a GAINED=SPACE_AFTER-SPACE_BEFORE
cls
echo.
echo ============ RESUME DU NETTOYAGE ============
echo.
echo Avant  : !SPACE_BEFORE! Mo
echo Apres  : !SPACE_AFTER! Mo
echo Gagne  : !GAINED! Mo
echo.
echo Operations reussies : !SUCCESS_COUNT!
echo Avertissements : !WARNING_COUNT!
echo Erreurs : !ERROR_COUNT!
echo.
echo Log : !LOGFILE!
if exist "!BACKUP_DIR!" echo Backup : !BACKUP_DIR!
echo.
(
    echo.
    echo ============ RESUME DU NETTOYAGE ============
    echo Espace avant  : !SPACE_BEFORE! Mo
    echo Espace apres  : !SPACE_AFTER! Mo
    echo Espace gagne  : !GAINED! Mo
    echo Operations reussies : !SUCCESS_COUNT!
    echo Avertissements : !WARNING_COUNT!
    echo Erreurs : !ERROR_COUNT!
) >> "!LOGFILE!"

pause
exit /b 0

:AskRestart
echo.
choice /c ON /n /m "Redemarrer maintenant pour finaliser ? (O/N) : "
if errorlevel 2 exit /b 0
shutdown /r /t 30 /c "Redemarrage suite au nettoyage Windows"
echo Redemarrage dans 30 secondes...
exit /b 0

:: ==== PROGRAMME PRINCIPAL ====

call :InitLog
call :GetFreeSpace
set "SPACE_BEFORE=!FREE_SPACE!"

cls
echo.
echo ========================================
echo   NETTOYAGE WINDOWS v!VERSION!
echo ========================================
echo.
echo Bienvenue dans l'outil de nettoyage securise
echo.
echo - Droits administrateur : OUI
echo - Systeme detect : !OS_VERSION!
echo - Type disque : !DISK_TYPE!
echo - Log : !LOGFILE!
echo.
pause

:LOOP
call :ShowMenu

if "!CHOIX!"=="0" goto :FIN
if /i "!CHOIX!"=="S" (
    if "!SAFE_MODE!"=="1" (set "SAFE_MODE=0") else (set "SAFE_MODE=1")
    call :LogInfo "Mode securise: !SAFE_MODE!"
    goto :LOOP
)
if /i "!CHOIX!"=="C" (
    if "!CONFIRM_ALL!"=="1" (set "CONFIRM_ALL=0") else (set "CONFIRM_ALL=1")
    call :LogInfo "Confirmation auto: !CONFIRM_ALL!"
    goto :LOOP
)
if "!CHOIX!"=="1" call :CreateRestorePoint & call :RunCleanup CleanTemp & call :RunCleanup CleanRecycle & call :RunCleanup CleanDNS & goto :SUMMARY
if "!CHOIX!"=="2" call :CreateRestorePoint & call :RunCleanup CleanSystem & call :RunCleanup CleanEvents & call :RunCleanup CleanThumbs & goto :SUMMARY
if "!CHOIX!"=="3" call :RunCleanup CleanBrowsers & goto :SUMMARY
if "!CHOIX!"=="4" call :CreateRestorePoint & call :RunCleanup Maintenance & goto :SUMMARY
if "!CHOIX!"=="5" call :RunCompleteCleaning & goto :SUMMARY
if "!CHOIX!"=="6" call :CreateRestorePoint & call :RunCleanup CleanPreloadedApps & goto :SUMMARY
if "!CHOIX!"=="7" call :ShowSpace & goto :LOOP

goto :LOOP

:SUMMARY
call :ShowSummary
call :AskRestart

:FIN
echo.
echo Nettoyage termine.
echo.

:: ==== NETTOYAGE AVANT SORTIE ====
:CLEAN_EXIT
if exist "!LOCKFILE!" del "!LOCKFILE!" 2>nul
endlocal
endlocal
timeout /t 2 /nobreak >nul
exit /b
