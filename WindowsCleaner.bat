@echo off
:: Script de nettoyage Windows complet
:: Compatible CMD et PowerShell avec vérifications avancées
:: Version 2.0 - RL Informatique

:: ########################################################
:: ## Configuration initiale
:: ########################################################

:: Activation des extensions de commande
setlocal enabledelayedexpansion

:: ########################################################
:: ## Vérifications préliminaires
:: ########################################################

:: Vérifier les privilèges admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERREUR] Ce script doit être exécuté en tant qu'administrateur.
    pause
    exit /b
)

:: Détection du type de disque
set DISK_TYPE=HDD
for /f "tokens=*" %%a in ('wmic diskdrive get MediaType ^| find "SSD"') do set DISK_TYPE=SSD

:: ########################################################
:: ## Configuration des variables
:: ########################################################

set LOGFILE=%USERPROFILE%\Desktop\Nettoyage_Windows_Log_%date:~-4,4%-%date:~-7,2%-%date:~-10,2%_%time:~0,2%-%time:~3,2%.txt
set CHOICE=
set RESTORE_POINT=
set RESTART=
set SPACE_BEFORE=0
set SPACE_AFTER=0
set /a ERROR_COUNT=0

:: ########################################################
:: ## Fonctions
:: ########################################################

:InitLog
echo =================================== > %LOGFILE%
echo LOG DE NETTOYAGE WINDOWS >> %LOGFILE%
echo Date : %date% %time% >> %LOGFILE%
echo Utilisateur : %USERNAME% >> %LOGFILE%
echo Système : %COMPUTERNAME% >> %LOGFILE%
echo Type de disque : %DISK_TYPE% >> %LOGFILE%
echo =================================== >> %LOGFILE%
echo. >> %LOGFILE%
goto :EOF

:LogInfo
echo [%time%] [INFO] %* >> %LOGFILE%
goto :EOF

:LogWarning
echo [%time%] [WARNING] %* >> %LOGFILE%
goto :EOF

:LogError
echo [%time%] [ERREUR] %* >> %LOGFILE%
set /a ERROR_COUNT+=1
goto :EOF

:CalculateSpace
for /f "tokens=3" %%a in ('dir /-c %SystemDrive% ^| find "octets libres"') do set free=%%a
set /a free=%free:~0,-8%
exit /b %free%

:ShowMenu
cls
echo.
echo #######################################################
echo #                                                     #
echo #              NETTOYAGE WINDOWS COMPLET              #
echo #            Version 2.0 - RL Informatique            #
echo #                                                     #
echo #######################################################
echo.
echo Sélectionnez les options de nettoyage :
echo.
echo 1.  Nettoyage de base (fichiers temporaires, cache)
echo 2.  Nettoyage des fichiers système (WinSxS, logs)
echo 3.  Nettoyage des navigateurs (Chrome, Firefox, Edge)
echo 4.  Maintenance système (SFC, DISM, CHKDSK)
echo 5.  Nettoyage complet (toutes les options)
echo 6.  Personnaliser le nettoyage
echo.
echo 0.  Quitter
echo.
set /p CHOICE=Choix : 
goto :EOF

:CreateRestorePoint
call :LogInfo "Création d'un point de restauration..."
powershell -Command "Checkpoint-Computer -Description 'Nettoyage Windows RL Info' -RestorePointType MODIFY_SETTINGS"
if %errorLevel% neq 0 (
    call :LogError "Échec de la création du point de restauration"
) else (
    call :LogInfo "Point de restauration créé avec succès"
)
goto :EOF

:CleanTempFiles
call :LogInfo "Nettoyage des fichiers temporaires..."
rd /s /q %TEMP% 2>nul
md %TEMP% 2>nul
rd /s /q %WINDIR%\Temp 2>nul
md %WINDIR%\Temp 2>nul
del /s /q %SystemDrive%\*.tmp 2>nul
del /s /q %SystemDrive%\*.temp 2>nul
call :LogInfo "Fichiers temporaires nettoyés"
goto :EOF

:CleanSystemFiles
call :LogInfo "Nettoyage des fichiers système..."
dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase
dism /Online /Cleanup-Image /AnalyzeComponentStore
cleanmgr /sagerun:1
rd /s /q %SystemDrive%\Windows.old 2>nul
call :LogInfo "Fichiers système nettoyés"
goto :EOF

:CleanBrowsers
call :LogInfo "Nettoyage des navigateurs..."
:: Chrome
rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" 2>nul
rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cookies" 2>nul

:: Firefox
for /d %%i in ("%APPDATA%\Mozilla\Firefox\Profiles\*") do (
    rd /s /q "%%i\cache2" 2>nul
    rd /s /q "%%i\thumbnails" 2>nul
)

:: Edge
rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" 2>nul
call :LogInfo "Navigateurs nettoyés"
goto :EOF

:SystemMaintenance
call :LogInfo "Maintenance système en cours..."
sfc /scannow
dism /Online /Cleanup-Image /RestoreHealth
if "%DISK_TYPE%"=="SSD" (
    defrag /C /O /U /V
) else (
    defrag /C /U /V
)
chkdsk /f /r
call :LogInfo "Maintenance système terminée"
goto :EOF

:CleanRecycleBin
call :LogInfo "Vidage de la corbeille..."
rd /s /q %SYSTEMDRIVE%\$Recycle.bin 2>nul
call :LogInfo "Corbeille vidée"
goto :EOF

:CleanDNS
call :LogInfo "Vidage du cache DNS..."
ipconfig /flushdns
call :LogInfo "Cache DNS vidé"
goto :EOF

:CleanEventLogs
call :LogInfo "Nettoyage des journaux d'événements..."
wevtutil.exe clear-log Application
wevtutil.exe clear-log System
wevtutil.exe clear-log Security
call :LogInfo "Journaux d'événements nettoyés"
goto :EOF

:CleanThumbnails
call :LogInfo "Nettoyage du cache des miniatures..."
del /f /s /q %LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db 2>nul
call :LogInfo "Cache des miniatures nettoyé"
goto :EOF

:CompleteClean
call :CleanTempFiles
call :CleanSystemFiles
call :CleanBrowsers
call :SystemMaintenance
call :CleanRecycleBin
call :CleanDNS
call :CleanEventLogs
call :CleanThumbnails
goto :EOF

:CustomClean
echo.
echo Sélectionnez les actions à effectuer (séparées par des virgules) :
echo 1. Nettoyage fichiers temporaires
echo 2. Nettoyage fichiers système
echo 3. Nettoyage navigateurs
echo 4. Maintenance système
echo 5. Vider corbeille
echo 6. Vider cache DNS
echo 7. Nettoyer journaux événements
echo 8. Nettoyer miniatures
echo.
set /p CUSTOM_CHOICE="Vos choix : "

for %%C in (%CUSTOM_CHOICE%) do (
    if "%%C"=="1" call :CleanTempFiles
    if "%%C"=="2" call :CleanSystemFiles
    if "%%C"=="3" call :CleanBrowsers
    if "%%C"=="4" call :SystemMaintenance
    if "%%C"=="5" call :CleanRecycleBin
    if "%%C"=="6" call :CleanDNS
    if "%%C"=="7" call :CleanEventLogs
    if "%%C"=="8" call :CleanThumbnails
)
goto :EOF

:ShowSummary
call :CalculateSpace
set /a SPACE_AFTER=%errorlevel%

set /a SPACE_GAINED=SPACE_AFTER-SPACE_BEFORE

echo. >> %LOGFILE%
echo =================================== >> %LOGFILE%
echo RÉSUMÉ DU NETTOYAGE >> %LOGFILE%
echo =================================== >> %LOGFILE%
echo Espace libéré : %SPACE_GAINED% Mo >> %LOGFILE%
echo Erreurs rencontrées : %ERROR_COUNT% >> %LOGFILE%
echo =================================== >> %LOGFILE%

echo.
echo Résumé du nettoyage :
echo ---------------------
echo Espace libéré : %SPACE_GAINED% Mo
echo Erreurs rencontrées : %ERROR_COUNT%
echo.
echo Le détail des opérations est disponible dans : %LOGFILE%
goto :EOF

:AskRestart
echo.
set /p RESTART="Voulez-vous redémarrer l'ordinateur maintenant ? (O/N) : "
if /I "%RESTART%"=="O" (
    shutdown /r /t 60 /c "Redémarrage dans 1 minute pour finaliser le nettoyage"
    echo L'ordinateur va redémarrer dans 1 minute...
)
goto :EOF

:: ########################################################
:: ## Programme principal
:: ########################################################

:: Initialisation
call :InitLog
call :CalculateSpace
set /a SPACE_BEFORE=%errorlevel%

:: Affichage du menu
:MAIN_MENU
call :ShowMenu

if "%CHOICE%"=="0" goto :EXIT
if "%CHOICE%"=="1" goto :BASIC_CLEAN
if "%CHOICE%"=="2" goto :SYSTEM_CLEAN
if "%CHOICE%"=="3" goto :BROWSERS_CLEAN
if "%CHOICE%"=="4" goto :MAINTENANCE
if "%CHOICE%"=="5" goto :FULL_CLEAN
if "%CHOICE%"=="6" goto :CUSTOM_CLEAN

goto :MAIN_MENU

:BASIC_CLEAN
call :CreateRestorePoint
call :CleanTempFiles
call :CleanRecycleBin
call :CleanDNS
goto :SUMMARY

:SYSTEM_CLEAN
call :CreateRestorePoint
call :CleanSystemFiles
call :CleanEventLogs
call :CleanThumbnails
goto :SUMMARY

:BROWSERS_CLEAN
call :CleanBrowsers
goto :SUMMARY

:MAINTENANCE
call :CreateRestorePoint
call :SystemMaintenance
goto :SUMMARY

:FULL_CLEAN
call :CreateRestorePoint
call :CompleteClean
goto :SUMMARY

:CUSTOM_CLEAN
call :CreateRestorePoint
call :CustomClean
goto :SUMMARY

:SUMMARY
call :ShowSummary
call :AskRestart

:EXIT
exit /b

:: ########################################################
:: ## Fin du script
:: ########################################################
