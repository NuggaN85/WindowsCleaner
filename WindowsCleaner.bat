@echo off
rem Script de nettoyage Windows avec point de restauration.
rem Développé par : RL Informatique.

cls

rem Vérifier si l'utilisateur a les privilèges d'administrateur
timeout /t 1 /nobreak > NUL
openfiles > NUL 2>&1
if %errorlevel%==0 (
    echo Exécution en cours...
) else (
    echo Vous devez exécuter ce script en tant qu'administrateur.
    echo.
    echo Faites un clic droit sur ce script et sélectionnez "Exécuter en tant qu'administrateur", puis réessayez.
    echo.
    echo Appuyez sur une touche pour quitter...
    pause > NUL
    exit /b 1
)

echo.

rem Télécharger sdelete et le dézipper
echo Téléchargement de sdelete...
PowerShell -Command "Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/SDelete.zip' -OutFile 'SDelete.zip'"

rem Créer le dossier Tools s'il n'existe pas
if not exist "%SYSTEMDRIVE%\Tools" (
    mkdir "%SYSTEMDRIVE%\Tools"
)

rem Dézipper sdelete dans le dossier Tools
echo Dézippage de sdelete...
PowerShell -Command "Expand-Archive -Path 'SDelete.zip' -DestinationPath '%SYSTEMDRIVE%\Tools'"

rem Supprimer le fichier zip après extraction
del "SDelete.zip"

echo.

rem Demander à l'utilisateur s'il souhaite créer un point de restauration
set /p createRestorePoint=Voulez-vous créer un point de restauration avant le nettoyage ? (oui/non) :
if /i "%createRestorePoint%"=="oui" (
    echo Création d'un point de restauration...
    wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "Point de restauration avant nettoyage", 100, 7
    echo Point de restauration créé.
) else (
    echo Aucun point de restauration créé.
)

echo.

rem Supprimer les fichiers temporaires de manière sécurisée
echo Nettoyage sécurisé des fichiers temporaires...
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%WinDir%\Temp\*.*"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%WinDir%\Prefetch\*.*"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%Temp%\*.*"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%AppData%\Temp\*.*"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%HomePath%\AppData\LocalLow\Temp\*.*"

rem Supprimer les fichiers des pilotes inutiles (déjà installés) de manière sécurisée
echo Nettoyage sécurisé des fichiers de pilotes inutiles...
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%SYSTEMDRIVE%\AMD\*.*"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%SYSTEMDRIVE%\NVIDIA\*.*"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%SYSTEMDRIVE%\INTEL\*.*"

rem Supprimer les dossiers temporaires de manière sécurisée
echo Suppression sécurisée des dossiers temporaires...
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%WinDir%\Temp"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%WinDir%\Prefetch"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%Temp%"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%AppData%\Temp"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%HomePath%\AppData\LocalLow\Temp"

rem Supprimer les dossiers des pilotes inutiles (déjà installés) de manière sécurisée
echo Suppression sécurisée des dossiers de pilotes inutiles...
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%SYSTEMDRIVE%\AMD"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%SYSTEMDRIVE%\NVIDIA"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%SYSTEMDRIVE%\INTEL"

rem Recréer les dossiers temporaires vides
echo Recréation des dossiers temporaires...
md "%WinDir%\Temp" 2>NUL
md "%WinDir%\Prefetch" 2>NUL
md "%Temp%" 2>NUL
md "%AppData%\Temp" 2>NUL
md "%HomePath%\AppData\LocalLow\Temp" 2>NUL

rem Nettoyage des journaux d'événements
echo Nettoyage des journaux d'événements...
wevtutil el | Foreach-Object {wevtutil cl "$_"}

rem Nettoyage des fichiers de mise à jour Windows
echo Nettoyage des fichiers de mise à jour Windows...
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%WinDir%\SoftwareDistribution\Download"

rem Vider la corbeille
echo Vidage de la corbeille...
PowerShell.exe -Command "Clear-RecycleBin -Force -Confirm:$false"

rem Vider le cache DNS
echo Vidage du cache DNS...
ipconfig /flushdns

rem Nettoyage des fichiers de cache du navigateur (exemple pour Chrome)
echo Nettoyage des fichiers de cache du navigateur...
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%LocalAppData%\Google\Chrome\User Data\Default\Cache"

rem Nettoyage des fichiers de cache du système
echo Nettoyage des fichiers de cache du système...
cleanmgr /sagerun:1

rem Suppression des fichiers et cache de Microsoft Defender
echo Suppression des fichiers et cache de Microsoft Defender...
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%ProgramData%\Microsoft\Windows Defender\Scans\History\Service"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%ProgramData%\Microsoft\Windows Defender\Scans\History\Results\Service"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%ProgramData%\Microsoft\Windows Defender\Scans\History\Results\Quick"
"%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%ProgramData%\Microsoft\Windows Defender\Scans\History\Results\Full"

echo.
echo Nettoyage sécurisé de Windows terminé !

rem Demander à l'utilisateur s'il souhaite redémarrer l'ordinateur
set /p reboot=Voulez-vous redémarrer l'ordinateur maintenant ? (oui/non) :
if /i "%reboot%"=="oui" (
    echo Redémarrage de l'ordinateur...
    shutdown /r /t 0
) else (
    echo Appuyez sur une touche pour quitter.
    pause > NUL
)

exit /b 0
