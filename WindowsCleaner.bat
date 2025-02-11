@echo off
:: Script de nettoyage Windows complet
:: Compatible avec CMD et PowerShell
:: Auteur : RL Informatique

:: Définir les variables
set LOGFILE=%USERPROFILE%\Desktop\Nettoyage_Windows_Log.txt
set CHOICE=
set RESTORE_POINT=
set RESTART=

:: Créer un fichier de log
echo Log du nettoyage Windows > %LOGFILE%
echo Date et heure : %date% %time% >> %LOGFILE%
echo =================================== >> %LOGFILE%

:: Demander à l'utilisateur s'il souhaite créer un point de restauration
echo.
echo Voulez-vous créer un point de restauration avant de continuer ? (O/N)
set /p RESTORE_POINT=
if /I "%RESTORE_POINT%"=="O" (
    echo Création d'un point de restauration... >> %LOGFILE%
    powershell -Command "Checkpoint-Computer -Description 'Point de restauration avant nettoyage' -RestorePointType MODIFY_SETTINGS"
    echo Point de restauration créé. >> %LOGFILE%
)

:: Afficher les options de nettoyage
echo.
echo Sélectionnez les étapes de nettoyage à exécuter :
echo 1. Nettoyage des fichiers temporaires
echo 2. Nettoyage des fichiers de pilotes inutiles
echo 3. Nettoyage des fichiers temporaires de Microsoft Office
echo 4. Optimisation des SSD
echo 5. Nettoyage des journaux d'événements
echo 6. Nettoyage des fichiers de mise à jour Windows
echo 7. Vider la corbeille
echo 8. Vider le cache DNS
echo 9. Nettoyage des fichiers de cache du navigateur (Chrome, Firefox, Edge)
echo 10. Nettoyage des fichiers de cache du système
echo 11. Suppression des fichiers et cache de Microsoft Defender
echo 12. Vérification de l'intégrité des fichiers système avec SFC
echo 13. Tout exécuter
echo.
echo Entrez les numéros des étapes à exécuter (séparés par des virgules) :
set /p CHOICE=

:: Exécuter les étapes de nettoyage sélectionnées
echo.
echo Début du nettoyage... >> %LOGFILE%

if "%CHOICE%"=="" (
    echo Aucune étape sélectionnée. >> %LOGFILE%
    goto END
)

:: Nettoyage des fichiers temporaires
if "%CHOICE:~0,1%"=="1" OR "%CHOICE%"=="13" (
    echo Nettoyage des fichiers temporaires... >> %LOGFILE%
    rd /s /q %TEMP%
    md %TEMP%
    echo Fichiers temporaires nettoyés. >> %LOGFILE%
)

:: Nettoyage des fichiers de pilotes inutiles
if "%CHOICE:~2,1%"=="2" OR "%CHOICE%"=="13" (
    echo Nettoyage des fichiers de pilotes inutiles... >> %LOGFILE%
    pnputil.exe /delete-driver
    echo Fichiers de pilotes inutiles nettoyés. >> %LOGFILE%
)

:: Nettoyage des fichiers temporaires de Microsoft Office
if "%CHOICE:~4,1%"=="3" OR "%CHOICE%"=="13" (
    echo Nettoyage des fichiers temporaires de Microsoft Office... >> %LOGFILE%
    rd /s /q %USERPROFILE%\AppData\Local\Temp\Office
    echo Fichiers temporaires de Microsoft Office nettoyés. >> %LOGFILE%
)

:: Optimisation des SSD
if "%CHOICE:~6,1%"=="4" OR "%CHOICE%"=="13" (
    echo Optimisation des SSD... >> %LOGFILE%
    defrag /C /O
    echo SSD optimisés. >> %LOGFILE%
)

:: Nettoyage des journaux d'événements
if "%CHOICE:~8,1%"=="5" OR "%CHOICE%"=="13" (
    echo Nettoyage des journaux d'événements... >> %LOGFILE%
    wevtutil.exe clear-log Application
    wevtutil.exe clear-log System
    wevtutil.exe clear-log Security
    echo Journaux d'événements nettoyés. >> %LOGFILE%
)

:: Nettoyage des fichiers de mise à jour Windows
if "%CHOICE:~10,1%"=="6" OR "%CHOICE%"=="13" (
    echo Nettoyage des fichiers de mise à jour Windows... >> %LOGFILE%
    dism /Online /Cleanup-Image /StartComponentCleanup
    echo Fichiers de mise à jour Windows nettoyés. >> %LOGFILE%
)

:: Vider la corbeille
if "%CHOICE:~12,1%"=="7" OR "%CHOICE%"=="13" (
    echo Vidage de la corbeille... >> %LOGFILE%
    rd /s /q %SYSTEMDRIVE%\$Recycle.bin
    echo Corbeille vidée. >> %LOGFILE%
)

:: Vider le cache DNS
if "%CHOICE:~14,1%"=="8" OR "%CHOICE%"=="13" (
    echo Vidage du cache DNS... >> %LOGFILE%
    ipconfig /flushdns
    echo Cache DNS vidé. >> %LOGFILE%
)

:: Nettoyage des fichiers de cache du navigateur
if "%CHOICE:~16,1%"=="9" OR "%CHOICE%"=="13" (
    echo Nettoyage des fichiers de cache du navigateur... >> %LOGFILE%
    rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache"
    rd /s /q "%LOCALAPPDATA%\Mozilla\Firefox\Profiles"
    rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache"
    echo Fichiers de cache du navigateur nettoyés. >> %LOGFILE%
)

:: Nettoyage des fichiers de cache du système
if "%CHOICE:~18,1%"=="10" OR "%CHOICE%"=="13" (
    echo Nettoyage des fichiers de cache du système... >> %LOGFILE%
    rd /s /q %WINDIR%\Temp
    md %WINDIR%\Temp
    echo Fichiers de cache du système nettoyés. >> %LOGFILE%
)

:: Suppression des fichiers et cache de Microsoft Defender
if "%CHOICE:~20,1%"=="11" OR "%CHOICE%"=="13" (
    echo Suppression des fichiers et cache de Microsoft Defender... >> %LOGFILE%
    MpCmdRun.exe -RemoveDefinitions -All
    echo Fichiers et cache de Microsoft Defender supprimés. >> %LOGFILE%
)

:: Vérification de l'intégrité des fichiers système avec SFC
if "%CHOICE:~22,1%"=="12" OR "%CHOICE%"=="13" (
    echo Vérification de l'intégrité des fichiers système avec SFC... >> %LOGFILE%
    sfc /scannow
    echo Vérification de l'intégrité des fichiers système terminée. >> %LOGFILE%
)

:: Fin du nettoyage
:END
echo.
echo Nettoyage terminé. >> %LOGFILE%
echo =================================== >> %LOGFILE%

:: Demander à l'utilisateur s'il souhaite redémarrer l'ordinateur
echo.
echo Voulez-vous redémarrer l'ordinateur maintenant ? (O/N)
set /p RESTART=
if /I "%RESTART%"=="O" (
    shutdown /r /t 0
)

:: Fin du script
exit
