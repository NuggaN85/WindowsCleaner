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

rem Demander à l'utilisateur quelles étapes de nettoyage exécuter
set /p cleanTemp=Nettoyer les fichiers temporaires ? (oui/non) :
set /p cleanDrivers=Nettoyer les fichiers de pilotes inutiles ? (oui/non) :
set /p cleanOffice=Nettoyer les fichiers temporaires de Microsoft Office ? (oui/non) :
set /p optimizeSSD=Optimiser les SSD ? (oui/non) :

rem Créer un fichier de log
set logFile=%USERPROFILE%\Desktop\nettoyage_log.txt
echo Début du nettoyage > "%logFile%"

rem Obtenir l'espace libre avant le nettoyage
for /f "tokens=3" %%a in ('PowerShell -Command "Get-PSDrive C | Select-Object -ExpandProperty Free"') do set freeSpaceBefore=%%a

rem Nettoyage des fichiers temporaires
if /i "%cleanTemp%"=="oui" (
    echo Nettoyage sécurisé des fichiers temporaires...
    "%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%WinDir%\Temp\*.*"
    "%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%WinDir%\Prefetch\*.*"
    "%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%Temp%\*.*"
    "%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%AppData%\Temp\*.*"
    "%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%HomePath%\AppData\LocalLow\Temp\*.*"
    echo Fichiers temporaires nettoyés >> "%logFile%"
)

rem Nettoyage des fichiers de pilotes inutiles
if /i "%cleanDrivers%"=="oui" (
    echo Nettoyage sécurisé des fichiers de pilotes inutiles...
    "%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%SYSTEMDRIVE%\AMD\*.*"
    "%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%SYSTEMDRIVE%\NVIDIA\*.*"
    "%SYSTEMDRIVE%\Tools\sdelete.exe" -s -q "%SYSTEMDRIVE%\INTEL\*.*"
    echo Fichiers de pilotes inutiles nettoyés >> "%logFile%"
)

rem Nettoyage des fichiers temporaires de Microsoft Office
if /i "%cleanOffice%"=="oui" (
    echo Nettoyage des fichiers temporaires de Microsoft Office...
    "%SYSTEMDRIVE%\Tools\sdelete.exe" -s -r "%LocalAppData%\Microsoft\Office\*.*"
    echo Fichiers temporaires de Microsoft Office nettoyés >> "%logFile%"
)

rem Optimisation des SSD
if /i "%optimizeSSD%"=="oui" (
    echo Optimisation des SSD...
    PowerShell -Command "Optimize-Volume -DriveLetter C -ReTrim -Verbose"
    echo SSD optimisés >> "%logFile%"
)

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

rem Obtenir l'espace libre après le nettoyage
for /f "tokens=3" %%a in ('PowerShell -Command "Get-PSDrive C | Select-Object -ExpandProperty Free"') do set freeSpaceAfter=%%a

rem Calculer l'espace récupéré
set /a reclaimedSpace=%freeSpaceAfter%-%freeSpaceBefore%

echo.
echo Nettoyage sécurisé de Windows terminé !
echo Espace récupéré : %reclaimedSpace% octets

rem Ajouter l'espace récupéré au fichier de log
echo Espace récupéré : %reclaimedSpace% octets >> "%logFile%"

rem Vérification de l'intégrité des fichiers système avec SFC
echo Vérification de l'intégrité des fichiers système avec SFC...
sfc /scannow

rem Demander à l'utilisateur s'il souhaite redémarrer l'ordinateur
set /p reboot=Voulez-vous redémarrer l'ordinateur maintenant ? (oui/non) :
if /i "%reboot%"=="oui" (
    echo Redémarrage de l'ordinateur...
    shutdown /r /t 0
) else (
    echo Appuyez sur une touche pour quitter.
    pause > NUL
)

echo Fin du nettoyage >> "%logFile%"

exit /b 0
