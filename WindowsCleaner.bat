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

:: Vérifier chaque choix individuellement
for %%C in (%CHOICE%) do (
    if "%%C"=="1" (
        echo Nettoyage des fichiers temporaires... >> %LOGFILE%
        rd /s /q %TEMP%
        md %TEMP%
        echo Fichiers temporaires nettoyés. >> %LOGFILE%
    )
    if "%%C"=="2" (
        echo Nettoyage des fichiers de pilotes inutiles... >> %LOGFILE%
        pnputil.exe /delete-driver
        echo Fichiers de pilotes inutiles nettoyés. >> %LOGFILE%
    )
    if "%%C"=="3" (
        echo Nettoyage des fichiers temporaires de Microsoft Office... >> %LOGFILE%
        rd /s /q %USERPROFILE%\AppData\Local\Temp\Office
        echo Fichiers temporaires de Microsoft Office nettoyés. >> %LOGFILE%
    )
    if "%%C"=="4" (
        echo Optimisation des SSD... >> %LOGFILE%
        defrag /C /O
        echo SSD optimisés. >> %LOGFILE%
    )
    if "%%C"=="5" (
        echo Nettoyage des journaux d'événements... >> %LOGFILE%
        wevtutil.exe clear-log Application
        wevtutil.exe clear-log System
        wevtutil.exe clear-log Security
        echo Journaux d'événements nettoyés. >> %LOGFILE%
    )
    if "%%C"=="6" (
        echo Nettoyage des fichiers de mise à jour Windows... >> %LOGFILE%
        dism /Online /Cleanup-Image /StartComponentCleanup
        echo Fichiers de mise à jour Windows nettoyés. >> %LOGFILE%
    )
    if "%%C"=="7" (
        echo Vidage de la corbeille... >> %LOGFILE%
        rd /s /q %SYSTEMDRIVE%\$Recycle.bin
        echo Corbeille vidée. >> %LOGFILE%
    )
    if "%%C"=="8" (
        echo Vidage du cache DNS... >> %LOGFILE%
        ipconfig /flushdns
        echo Cache DNS vidé. >> %LOGFILE%
    )
    if "%%C"=="9" (
        echo Nettoyage des fichiers de cache du navigateur... >> %LOGFILE%
        rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache"
        rd /s /q "%LOCALAPPDATA%\Mozilla\Firefox\Profiles"
        rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache"
        echo Fichiers de cache du navigateur nettoyés. >> %LOGFILE%
    )
    if "%%C"=="10" (
        echo Nettoyage des fichiers de cache du système... >> %LOGFILE%
        rd /s /q %WINDIR%\Temp
        md %WINDIR%\Temp
        echo Fichiers de cache du système nettoyés. >> %LOGFILE%
    )
    if "%%C"=="11" (
        echo Suppression des fichiers et cache de Microsoft Defender... >> %LOGFILE%
        MpCmdRun.exe -RemoveDefinitions -All
        echo Fichiers et cache de Microsoft Defender supprimés. >> %LOGFILE%
    )
    if "%%C"=="12" (
        echo Vérification de l'intégrité des fichiers système avec SFC... >> %LOGFILE%
        sfc /scannow
        echo Vérification de l'intégrité des fichiers système terminée. >> %LOGFILE%
    )
    if "%%C"=="13" (
        :: Exécuter toutes les étapes
        echo Exécution de toutes les étapes... >> %LOGFILE%
        call :EXECUTE_ALL
    )
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

:: Sous-routine pour exécuter toutes les étapes
:EXECUTE_ALL
echo Nettoyage des fichiers temporaires... >> %LOGFILE%
rd /s /q %TEMP%
md %TEMP%
echo Fichiers temporaires nettoyés. >> %LOGFILE%

echo Nettoyage des fichiers de pilotes inutiles... >> %LOGFILE%
pnputil.exe /delete-driver
echo Fichiers de pilotes inutiles nettoyés. >> %LOGFILE%

echo Nettoyage des fichiers temporaires de Microsoft Office... >> %LOGFILE%
rd /s /q %USERPROFILE%\AppData\Local\Temp\Office
echo Fichiers temporaires de Microsoft Office nettoyés. >> %LOGFILE%

echo Optimisation des SSD... >> %LOGFILE%
defrag /C /O
echo SSD optimisés. >> %LOGFILE%

echo Nettoyage des journaux d'événements... >> %LOGFILE%
wevtutil.exe clear-log Application
wevtutil.exe clear-log System
wevtutil.exe clear-log Security
echo Journaux d'événements nettoyés. >> %LOGFILE%

echo Nettoyage des fichiers de mise à jour Windows... >> %LOGFILE%
dism /Online /Cleanup-Image /StartComponentCleanup
echo Fichiers de mise à jour Windows nettoyés. >> %LOGFILE%

echo Vidage de la corbeille... >> %LOGFILE%
rd /s /q %SYSTEMDRIVE%\$Recycle.bin
echo Corbeille vidée. >> %LOGFILE%

echo Vidage du cache DNS... >> %LOGFILE%
ipconfig /flushdns
echo Cache DNS vidé. >> %LOGFILE%

echo Nettoyage des fichiers de cache du navigateur... >> %LOGFILE%
rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache"
rd /s /q "%LOCALAPPDATA%\Mozilla\Firefox\Profiles"
rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache"
echo Fichiers de cache du navigateur nettoyés. >> %LOGFILE%

echo Nettoyage des fichiers de cache du système... >> %LOGFILE%
rd /s /q %WINDIR%\Temp
md %WINDIR%\Temp
echo Fichiers de cache du système nettoyés. >> %LOGFILE%

echo Suppression des fichiers et cache de Microsoft Defender... >> %LOGFILE%
MpCmdRun.exe -RemoveDefinitions -All
echo Fichiers et cache de Microsoft Defender supprimés. >> %LOGFILE%

echo Vérification de l'intégrité des fichiers système avec SFC... >> %LOGFILE%
sfc /scannow
echo Vérification de l'intégrité des fichiers système terminée. >> %LOGFILE%

exit /b
