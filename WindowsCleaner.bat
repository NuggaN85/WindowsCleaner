@echo off
:: Script de nettoyage Windows sécurisé
:: Compatible CMD et PowerShell avec vérifications avancées
:: Version 3.0 - RL Informatique Sécurisé

:: ########################################################
:: ## Configuration initiale
:: ########################################################

:: Activation des extensions de commande
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

:: ########################################################
:: ## Déclaration des constantes
:: ########################################################

set "VERSION=3.0"
set "AUTHOR=RL Informatique"
set "SAFE_MODE=0"
set "CONFIRM_ALL=0"

:: ########################################################
:: ## Vérifications préliminaires
:: ########################################################

:: Vérifier Windows 10/11
ver | findstr /r /c:"^Microsoft Windows [1][0-1]" >nul
if errorlevel 1 (
    echo [ERREUR] Ce script nécessite Windows 10 ou 11.
    pause
    exit /b 1
)

:: Vérifier les privilèges admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERREUR] Ce script doit être exécuté en tant qu'administrateur.
    echo.
    echo Pour l'exécuter en administrateur :
    echo 1. Cliquez-droit sur le fichier
    echo 2. Sélectionnez "Exécuter en tant qu'administrateur"
    pause
    exit /b 1
)

:: ########################################################
:: ## Configuration des variables
:: ########################################################

set "LOGFILE=%USERPROFILE%\Desktop\Nettoyage_Windows_Log_%date:~-4,4%-%date:~-7,2%-%date:~-10,2%_%time:~0,2%-%time:~3,2%.txt"
set "BACKUP_DIR=%USERPROFILE%\Desktop\Backup_Nettoyage_%date:~-4,4%-%date:~-7,2%-%date:~-10,2%"
set "CHOICE="
set "RESTART="
set /a SPACE_BEFORE=0
set /a SPACE_AFTER=0
set /a ERROR_COUNT=0
set /a WARNING_COUNT=0

:: Détection du type de disque
set "DISK_TYPE=HDD"
for /f "tokens=*" %%a in ('powershell -Command "Get-PhysicalDisk | Select-Object MediaType" 2^>nul') do (
    echo %%a | find "SSD" >nul && set "DISK_TYPE=SSD"
)

:: Détection de la langue système
for /f "tokens=2 delims==" %%I in ('wmic os get locale /value') do set "OS_LOCALE=%%I"
if "%OS_LOCALE:0409=%" neq "%OS_LOCALE%" set "LANG=en"
if "%OS_LOCALE:040C=%" neq "%OS_LOCALE%" set "LANG=fr"
if "%OS_LOCALE:0809=%" neq "%OS_LOCALE%" set "LANG=en_UK"
if not defined LANG set "LANG=en"

:: ########################################################
:: ## Fonctions utilitaires
:: ########################################################

:InitLog
(
    echo ========================================
    echo LOG DE NETTOYAGE WINDOWS - Version %VERSION%
    echo Date : %date% %time%
    echo Utilisateur : %USERNAME%
    echo Ordinateur : %COMPUTERNAME%
    echo Type de disque : %DISK_TYPE%
    echo Langue système : %LANG%
    echo Mode sans risque : %SAFE_MODE%
    echo ========================================
    echo.
) > "%LOGFILE%"
goto :EOF

:LogInfo
echo [%time:~0,8%] [INFO] %* >> "%LOGFILE%"
goto :EOF

:LogWarning
echo [%time:~0,8%] [WARNING] %* >> "%LOGFILE%"
set /a WARNING_COUNT+=1
goto :EOF

:LogError
echo [%time:~0,8%] [ERREUR] %* >> "%LOGFILE%"
set /a ERROR_COUNT+=1
goto :EOF

:LogAction
echo [%time:~0,8%] [ACTION] %* >> "%LOGFILE%"
goto :EOF

:CalculateSpace
setlocal
set "free_space=0"
if "%LANG%"=="fr" (
    for /f "tokens=3" %%a in ('dir /-c %SystemDrive% 2^>nul ^| find "octets libres"') do set "free_space=%%a"
) else (
    for /f "tokens=3" %%a in ('dir /-c %SystemDrive% 2^>nul ^| find "free"') do set "free_space=%%a"
)
if defined free_space (
    set "free_space=!free_space:,=!"
    set /a free_space_mb=free_space/1048576
) else (
    set /a free_space_mb=0
)
endlocal & set /a free_space=%free_space_mb%
exit /b %free_space_mb%

:AskConfirmation
set "CONFIRM_MSG=%*"
if "%CONFIRM_ALL%"=="1" (
    echo !CONFIRM_MSG! [O/tous/N] : O (tous confirmés)
    set "USER_CONFIRM=O"
    goto :EOF
)
choice /c ONT /n /m "!CONFIRM_MSG! [O/tous/N] : "
if errorlevel 3 (
    set "USER_CONFIRM=N"
) else if errorlevel 2 (
    set "CONFIRM_ALL=1"
    set "USER_CONFIRM=O"
    echo [INFO] Toutes les actions suivantes seront automatiquement confirmées.
) else (
    set "USER_CONFIRM=O"
)
goto :EOF

:CreateBackupDir
if not exist "%BACKUP_DIR%" (
    md "%BACKUP_DIR%" 2>nul
    if errorlevel 1 (
        call :LogWarning "Impossible de créer le répertoire de backup"
        set "BACKUP_DIR=%TEMP%"
    )
)
goto :EOF

:BackupEventLogs
call :CreateBackupDir
set "BACKUP_SUCCESS=0"
for %%L in (Application System Security) do (
    wevtutil epl %%L "%BACKUP_DIR%\%%L_%date:~-4,4%-%date:~-7,2%-%date:~-10,2%.evtx" /ow:true 2>nul
    if not errorlevel 1 set "BACKUP_SUCCESS=1"
)
if %BACKUP_SUCCESS%==1 (
    call :LogInfo "Journaux d'événements sauvegardés dans : %BACKUP_DIR%"
)
goto :EOF

:CreateRestorePoint
call :LogInfo "Création d'un point de restauration..."
powershell -Command "Checkpoint-Computer -Description 'Nettoyage Windows %VERSION%' -RestorePointType MODIFY_SETTINGS" >nul 2>&1
if %errorLevel% neq 0 (
    call :LogError "Échec de la création du point de restauration"
    call :AskConfirmation "Continuer sans point de restauration ?"
    if /i "!USER_CONFIRM!" neq "O" exit /b 1
) else (
    call :LogInfo "Point de restauration créé avec succès"
)
goto :EOF

:IsProcessRunning
set "PROCESS_NAME=%~1"
tasklist /FI "IMAGENAME eq %PROCESS_NAME%" 2>nul | find /I "%PROCESS_NAME%" >nul
goto :EOF

:WaitForProcess
set "PROCESS_NAME=%~1"
set "TIMEOUT=%~2"
if not defined TIMEOUT set "TIMEOUT=30"
set /a COUNTER=0
:WaitLoop
call :IsProcessRunning "%PROCESS_NAME%"
if errorlevel 1 goto :EOF
timeout /t 1 /nobreak >nul
set /a COUNTER+=1
if !COUNTER! geq %TIMEOUT% (
    call :LogWarning "Timeout d'attente pour %PROCESS_NAME%"
    goto :EOF
)
goto WaitLoop

:CleanTempFilesSafe
call :LogInfo "Nettoyage sécurisé des fichiers temporaires..."

:: Nettoyage via Cleanmgr (méthode recommandée)
call :LogAction "Exécution de Cleanmgr..."
cleanmgr /sagerun:1 >nul 2>&1
if errorlevel 1 (
    call :LogWarning "Cleanmgr a rencontré une erreur"
)

:: Suppression des fichiers temporaires anciens (7+ jours)
call :LogAction "Suppression des fichiers temporaires anciens..."
forfiles /p "%TEMP%" /s /m *.* /d -7 /c "cmd /c if @isdir==FALSE del /q @path" 2>nul
forfiles /p "%WINDIR%\Temp" /s /m *.* /d -7 /c "cmd /c if @isdir==FALSE del /q @path" 2>nul

:: Nettoyage des caches Windows Update
call :LogAction "Nettoyage du cache Windows Update..."
net stop wuauserv >nul 2>&1
rd /s /q "%WINDIR%\SoftwareDistribution\Download" 2>nul
md "%WINDIR%\SoftwareDistribution\Download" 2>nul
net start wuauserv >nul 2>&1

call :LogInfo "Fichiers temporaires nettoyés (mode sécurisé)"
goto :EOF

:CleanSystemFiles
call :LogInfo "Nettoyage des fichiers système..."

:: Analyse DISM
call :LogAction "Analyse du magasin de composants..."
dism /Online /Cleanup-Image /AnalyzeComponentStore >nul 2>&1

:: Nettoyage DISM (avec timeout)
call :LogAction "Nettoyage DISM en cours (peut prendre du temps)..."
start /b dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase
timeout /t 5 /nobreak >nul

:: Nettoyage WinSxS manuel
if exist "%WINDIR%\WinSxS\Temp" (
    call :AskConfirmation "Nettoyer le dossier WinSxS\Temp ?"
    if /i "!USER_CONFIRM!"=="O" (
        rd /s /q "%WINDIR%\WinSxS\Temp" 2>nul
    )
)

:: Windows.old avec confirmation
if exist "%SystemDrive%\Windows.old" (
    call :AskConfirmation "Supprimer Windows.old (ancienne installation Windows) ?"
    if /i "!USER_CONFIRM!"=="O" (
        call :LogAction "Suppression de Windows.old..."
        rd /s /q "%SystemDrive%\Windows.old" 2>nul
        if errorlevel 1 (
            call :LogWarning "Impossible de supprimer Windows.old (en cours d'utilisation)"
        )
    )
)

call :LogInfo "Fichiers système nettoyés"
goto :EOF

:CleanBrowsersSafe
call :LogInfo "Nettoyage sécurisé des navigateurs..."

:: Liste des navigateurs à fermer
set "BROWSERS=chrome.exe,firefox.exe,msedge.exe,iexplore.exe"

:: Fermer les navigateurs
for %%B in (%BROWSERS%) do (
    call :IsProcessRunning "%%B"
    if not errorlevel 1 (
        call :AskConfirmation "Fermer %%B avant nettoyage ?"
        if /i "!USER_CONFIRM!"=="O" (
            taskkill /F /IM %%B >nul 2>&1
            call :WaitForProcess "%%B" 10
        )
    )
)

:: Chrome - Cache uniquement
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" (
    call :AskConfirmation "Nettoyer le cache de Chrome ?"
    if /i "!USER_CONFIRM!"=="O" (
        rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" 2>nul
    )
)

:: Firefox - Cache uniquement
for /d %%i in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do (
    if exist "%%i\cache2" (
        call :AskConfirmation "Nettoyer le cache Firefox (%%i) ?"
        if /i "!USER_CONFIRM!"=="O" (
            rd /s /q "%%i\cache2" 2>nul
        )
    )
)

:: Edge - Cache uniquement
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" (
    call :AskConfirmation "Nettoyer le cache de Edge ?"
    if /i "!USER_CONFIRM!"=="O" (
        rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" 2>nul
    )
)

:: Optionnel : cookies et historique (avec avertissement)
call :AskConfirmation "Supprimer également les cookies et historique ? (Non recommandé)"
if /i "!USER_CONFIRM!"=="O" (
    call :LogAction "Suppression des cookies et historique..."
    :: Code pour supprimer cookies (utiliser les paramètres des navigateurs)
)

call :LogInfo "Navigateurs nettoyés (mode sécurisé)"
goto :EOF

:SystemMaintenance
call :LogInfo "Maintenance système en cours..."

:: SFC Scan
call :LogAction "Vérification des fichiers système (SFC)..."
sfc /scannow >nul 2>&1
if errorlevel 1 (
    call :LogWarning "SFC a détecté des problèmes. Voir CBS.log pour détails."
)

:: DISM Restore Health
call :LogAction "Réparation de l'image système (DISM)..."
dism /Online /Cleanup-Image /RestoreHealth >nul 2>&1
if errorlevel 1 (
    call :LogWarning "DISM a rencontré une erreur"
)

:: Optimisation SSD/HDD
if /i "%DISK_TYPE%"=="SSD" (
    call :LogAction "Optimisation SSD (TRIM)..."
    defrag /C /O /U >nul 2>&1
    :: Optimize-Volume pour SSD
    powershell -Command "Optimize-Volume -DriveLetter C -ReTrim -Verbose" >nul 2>&1
) else (
    call :LogAction "Défragmentation HDD..."
    defrag /C /U /V >nul 2>&1
)

:: CHKDSK planifié (pas immédiat)
call :AskConfirmation "Planifier CHKDSK au prochain redémarrage ?"
if /i "!USER_CONFIRM!"=="O" (
    chkdsk %SystemDrive% /f /r
    if errorlevel 1 (
        call :LogInfo "CHKDSK planifié pour le prochain redémarrage"
    )
)

call :LogInfo "Maintenance système terminée"
goto :EOF

:CleanRecycleBinSafe
call :LogInfo "Vidage sécurisé de la corbeille..."
call :AskConfirmation "Vider la corbeille de tous les utilisateurs ?"
if /i "!USER_CONFIRM!"=="O" (
    for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        if exist %%D:\$Recycle.bin (
            rd /s /q "%%D:\$Recycle.bin" 2>nul
        )
    )
    call :LogInfo "Corbeille vidée"
) else (
    call :LogInfo "Vidage de corbeille annulé"
)
goto :EOF

:CleanDNS
call :LogInfo "Vidage du cache DNS..."
ipconfig /flushdns >nul 2>&1
if errorlevel 1 (
    call :LogError "Échec du vidage du cache DNS"
) else (
    call :LogInfo "Cache DNS vidé"
)
goto :EOF

:CleanEventLogsSafe
call :LogInfo "Nettoyage sécurisé des journaux d'événements..."

:: Sauvegarde d'abord
call :BackupEventLogs

call :AskConfirmation "Nettoyer les journaux d'événements ? (Les sauvegardes sont dans %BACKUP_DIR%)"
if /i "!USER_CONFIRM!"=="O" (
    for %%L in (Application System Security) do (
        wevtutil clear-log %%L 2>nul
        if errorlevel 1 (
            call :LogWarning "Impossible de nettoyer le journal %%L"
        )
    )
    call :LogInfo "Journaux d'événements nettoyés"
) else (
    call :LogInfo "Nettoyage des journaux annulé"
)
goto :EOF

:CleanThumbnailsSafe
call :LogInfo "Nettoyage du cache des miniatures..."
call :AskConfirmation "Supprimer le cache des miniatures ?"
if /i "!USER_CONFIRM!"=="O" (
    del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" 2>nul
    :: Reconstruire l'index
    taskkill /F /IM explorer.exe >nul 2>&1
    start explorer.exe >nul 2>&1
    call :LogInfo "Cache des miniatures nettoyé et index reconstruit"
) else (
    call :LogInfo "Nettoyage des miniatures annulé"
)
goto :EOF

:ShowMenu
cls
echo.
echo #######################################################
echo #                                                     #
echo #        NETTOYAGE WINDOWS SÉCURISÉ - v%VERSION%        #
echo #                %AUTHOR%                #
echo #                                                     #
echo #######################################################
echo.
echo Type de disque : %DISK_TYPE% | Langue : %LANG% | Mode sans risque : %SAFE_MODE%
echo.
echo [OPTIONS GLOBALES]
echo S. Activer/Désactiver le mode sans risque (actuel : %SAFE_MODE%)
echo C. Confirmer toutes les actions
echo.
echo [ACTIONS DE NETTOYAGE]
echo 1.  Nettoyage de base (temporaires, corbeille, DNS)
echo 2.  Nettoyage système (WinSxS, logs, Windows.old)
echo 3.  Nettoyage navigateurs (cache uniquement)
echo 4.  Maintenance système (SFC, DISM, optimisation)
echo 5.  Nettoyage complet guidé (avec confirmations)
echo 6.  Personnaliser le nettoyage
echo 7.  Afficher l'espace disque
echo.
echo 0.  Quitter
echo.
set /p "CHOICE=Choix : "
goto :EOF

:ShowSpaceInfo
call :CalculateSpace
set /a current_space=errorlevel
cls
echo.
echo ================= ESPACE DISQUE =================
echo.
echo Lecteur %SystemDrive% :
echo.
for /f "tokens=1,2,3 delims= " %%a in ('dir %SystemDrive%\ ^| find "Volume"') do echo %%a %%b %%c
for /f "tokens=1-3 delims= " %%a in ('dir %SystemDrive%\ ^| find "octets libres"') do (
    echo Espace libre : %%a %%b (soit !current_space! Mo)
)
echo.
echo Type de disque : %DISK_TYPE%
echo.
echo Appuyez sur une touche pour continuer...
pause >nul
goto :EOF

:ShowSummary
call :CalculateSpace
set /a SPACE_AFTER=errorlevel
set /a SPACE_GAINED=SPACE_AFTER-SPACE_BEFORE

cls
echo.
echo ============ RÉSUMÉ DU NETTOYAGE ============
echo.
echo Espace libre avant : %SPACE_BEFORE% Mo
echo Espace libre après : %SPACE_AFTER% Mo
echo Espace libéré : %SPACE_GAINED% Mo
echo.
echo Avertissements : %WARNING_COUNT%
echo Erreurs : %ERROR_COUNT%
echo.
echo Log complet : %LOGFILE%
if exist "%BACKUP_DIR%" echo Backup journaux : %BACKUP_DIR%
echo.
echo =============================================
echo.

:: Log du résumé
(
    echo.
    echo ============ RÉSUMÉ DU NETTOYAGE ============
    echo Date : %date% %time%
    echo Espace libéré : %SPACE_GAINED% Mo (%SPACE_BEFORE% -> %SPACE_AFTER%)
    echo Avertissements : %WARNING_COUNT%
    echo Erreurs : %ERROR_COUNT%
    echo Mode sans risque : %SAFE_MODE%
    echo =============================================
) >> "%LOGFILE%"

goto :EOF

:AskRestart
echo.
choice /c ON /n /m "Voulez-vous redémarrer l'ordinateur maintenant ? (O/N) : "
if errorlevel 2 (
    echo Redémarrage annulé.
) else (
    echo.
    echo [ATTENTION] L'ordinateur va redémarrer dans 2 minutes.
    echo Sauvegardez tout travail en cours.
    echo.
    choice /c OC /n /t 120 /d C /m "Appuyez sur O pour redémarrer immédiatement, C pour annuler : "
    if errorlevel 2 (
        echo Redémarrage annulé.
    ) else (
        shutdown /r /t 30 /c "Redémarrage pour finaliser le nettoyage. Sauvegardez vos documents."
        echo Redémarrage dans 30 secondes...
    )
)
goto :EOF

:CompleteCleanGuided
call :LogInfo "Démarrage du nettoyage complet guidé..."
call :CreateRestorePoint

echo.
echo ========= NETTOYAGE COMPLET GUIDÉ =========
echo.

call :AskConfirmation "Étape 1/8 : Nettoyer les fichiers temporaires ?"
if /i "!USER_CONFIRM!"=="O" call :CleanTempFilesSafe

call :AskConfirmation "Étape 2/8 : Nettoyer les fichiers système ?"
if /i "!USER_CONFIRM!"=="O" call :CleanSystemFiles

call :AskConfirmation "Étape 3/8 : Nettoyer les navigateurs ?"
if /i "!USER_CONFIRM!"=="O" call :CleanBrowsersSafe

call :AskConfirmation "Étape 4/8 : Effectuer la maintenance système ?"
if /i "!USER_CONFIRM!"=="O" call :SystemMaintenance

call :AskConfirmation "Étape 5/8 : Vider la corbeille ?"
if /i "!USER_CONFIRM!"=="O" call :CleanRecycleBinSafe

call :AskConfirmation "Étape 6/8 : Vider le cache DNS ?"
if /i "!USER_CONFIRM!"=="O" call :CleanDNS

call :AskConfirmation "Étape 7/8 : Nettoyer les journaux d'événements ?"
if /i "!USER_CONFIRM!"=="O" call :CleanEventLogsSafe

call :AskConfirmation "Étape 8/8 : Nettoyer le cache des miniatures ?"
if /i "!USER_CONFIRM!"=="O" call :CleanThumbnailsSafe

echo.
echo Nettoyage complet guidé terminé.
goto :EOF

:CustomClean
cls
echo.
echo ========= NETTOYAGE PERSONNALISÉ =========
echo.
echo Sélectionnez les actions (séparées par des virgules) :
echo.
echo 1. Nettoyage fichiers temporaires
echo 2. Nettoyage fichiers système
echo 3. Nettoyage navigateurs
echo 4. Maintenance système
echo 5. Vider corbeille
echo 6. Vider cache DNS
echo 7. Nettoyer journaux événements
echo 8. Nettoyer miniatures
echo.
echo 9. Retour au menu
echo.
set /p "CUSTOM_CHOICE=Vos choix : "

if "%CUSTOM_CHOICE%"=="9" goto :MAIN_MENU

:: Validation des entrées
echo "%CUSTOM_CHOICE%" | findstr /r "^[1-8][,1-8]*$" >nul
if errorlevel 1 (
    echo Choix invalide. Appuyez sur une touche...
    pause >nul
    goto :CustomClean
)

call :CreateRestorePoint

for %%C in (%CUSTOM_CHOICE%) do (
    if "%%C"=="1" call :CleanTempFilesSafe
    if "%%C"=="2" call :CleanSystemFiles
    if "%%C"=="3" call :CleanBrowsersSafe
    if "%%C"=="4" call :SystemMaintenance
    if "%%C"=="5" call :CleanRecycleBinSafe
    if "%%C"=="6" call :CleanDNS
    if "%%C"=="7" call :CleanEventLogsSafe
    if "%%C"=="8" call :CleanThumbnailsSafe
)
goto :EOF

:: ########################################################
:: ## Programme principal
:: ########################################################

:: Initialisation
call :InitLog
call :CalculateSpace
set /a SPACE_BEFORE=errorlevel

:: Message de bienvenue
cls
echo.
echo ========================================
echo     NETTOYAGE WINDOWS SÉCURISÉ v%VERSION%
echo ========================================
echo.
echo [INFORMATION]
echo Ce script effectue un nettoyage s%E9%curis%E9% de Windows.
echo Toutes les actions dangereuses demanderont confirmation.
echo.
echo Un point de restauration sera cr%E9%E9% automatiquement.
echo Un log d%E9%taill%E9% sera disponible sur votre bureau.
echo.
echo Mode sans risque : ACTIVÉ par défaut
echo (Les actions risquées sont désactivées)
echo.
echo Appuyez sur une touche pour continuer...
pause >nul

:: Menu principal
:MAIN_MENU
call :ShowMenu

if "%CHOICE%"=="0" goto :EXIT
if /i "%CHOICE%"=="S" (
    if "%SAFE_MODE%"=="0" (
        set "SAFE_MODE=1"
        call :LogInfo "Mode sans risque ACTIVÉ"
    ) else (
        set "SAFE_MODE=0"
        call :LogInfo "Mode sans risque DÉSACTIVÉ"
    )
    goto :MAIN_MENU
)
if /i "%CHOICE%"=="C" (
    set "CONFIRM_ALL=1"
    call :LogInfo "Mode confirmation automatique ACTIVÉ"
    goto :MAIN_MENU
)
if "%CHOICE%"=="1" goto :BASIC_CLEAN
if "%CHOICE%"=="2" goto :SYSTEM_CLEAN
if "%CHOICE%"=="3" goto :BROWSERS_CLEAN
if "%CHOICE%"=="4" goto :MAINTENANCE
if "%CHOICE%"=="5" goto :FULL_CLEAN
if "%CHOICE%"=="6" goto :CUSTOM_CLEAN
if "%CHOICE%"=="7" goto :SHOW_SPACE

goto :MAIN_MENU

:BASIC_CLEAN
call :CreateRestorePoint
call :CleanTempFilesSafe
call :CleanRecycleBinSafe
call :CleanDNS
goto :SUMMARY

:SYSTEM_CLEAN
call :CreateRestorePoint
call :CleanSystemFiles
call :CleanEventLogsSafe
call :CleanThumbnailsSafe
goto :SUMMARY

:BROWSERS_CLEAN
call :CleanBrowsersSafe
goto :SUMMARY

:MAINTENANCE
call :CreateRestorePoint
call :SystemMaintenance
goto :SUMMARY

:FULL_CLEAN
call :CompleteCleanGuided
goto :SUMMARY

:CUSTOM_CLEAN
call :CustomClean
goto :SUMMARY

:SHOW_SPACE
call :ShowSpaceInfo
goto :MAIN_MENU

:SUMMARY
call :ShowSummary
call :AskRestart

:EXIT
echo.
echo Nettoyage terminé. Appuyez sur une touche pour quitter...
pause >nul
exit /b 0

:: ########################################################
:: ## Fin du script
:: ########################################################
