### Description du Script

Ce script batch Windows, est conçu pour effectuer un nettoyage sécurisé du système. Il automatise plusieurs tâches de maintenance pour libérer de l'espace disque et améliorer les performances du système. Voici un aperçu de ce que fait le script :

### Fonctionnalités du Script

1. **Vérification des Privilèges Administrateur** : Le script commence par vérifier si l'utilisateur exécute le script avec des privilèges d'administrateur. Si ce n'est pas le cas, il affiche un message et se termine.

2. **Téléchargement et Extraction de SDelete** : Il télécharge l'outil SDelete de Microsoft Sysinternals, qui est utilisé pour supprimer de manière sécurisée les fichiers, et l'extrait dans un dossier nommé `Tools`.

3. **Création d'un Point de Restauration** : Avant de procéder au nettoyage, le script crée un point de restauration système, permettant à l'utilisateur de restaurer le système à son état précédent si nécessaire.

4. **Nettoyage des Fichiers Temporaires** : Utilise SDelete pour supprimer de manière sécurisée les fichiers temporaires dans divers répertoires système et utilisateur.

5. **Suppression des Fichiers de Pilotes Inutiles** : Supprime les fichiers des pilotes AMD, NVIDIA, et Intel qui ne sont plus nécessaires.

6. **Nettoyage des Journaux d'Événements** : Efface les journaux d'événements Windows pour libérer de l'espace.

7. **Nettoyage des Fichiers de Mise à Jour Windows** : Supprime les fichiers de mise à jour Windows téléchargés.

8. **Vidage de la Corbeille** : Vide la corbeille de manière forcée.

9. **Vidage du Cache DNS** : Efface le cache DNS pour résoudre les problèmes de résolution de noms de domaine.

10. **Nettoyage des Fichiers de Cache du Navigateur** : Supprime les fichiers de cache du navigateur Chrome.

11. **Nettoyage des Fichiers de Cache du Système** : Utilise l'outil de nettoyage de disque intégré de Windows pour supprimer les fichiers de cache système.

12. **Nettoyage des fichiers et cache de Microsoft Defender** : Supprime les fichiers et cache de Microsoft Defender.

13. **Nettoyage Microsoft Office** : Ajout d'une étape pour nettoyer les fichiers temporaires de Microsoft Office.

14. **Optimisation des SSD** : Ajout d'une commande PowerShell pour optimiser les SSD.

15. **Choix des étapes de nettoyage** : L'utilisateur peut choisir quelles étapes de nettoyage exécuter.

16. **Fichier de log** : Création d'un fichier de log sur le bureau pour enregistrer les actions effectuées par le script.

### Sécurité du Script

- **Vérification des Privilèges** : Le script s'assure qu'il est exécuté avec des privilèges administratifs pour éviter des erreurs d'exécution.
- **Point de Restauration** : La création d'un point de restauration avant le nettoyage permet de restaurer le système en cas de problème.
- **Suppression Sécurisée** : L'utilisation de SDelete garantit que les fichiers sont supprimés de manière sécurisée, rendant leur récupération difficile.

### Risques Potentiels

- **Suppression de Fichiers Importants** : Bien que le script cible des fichiers temporaires et des caches, une mauvaise configuration ou une erreur pourrait entraîner la suppression de fichiers importants.
- **Interruption des Services** : La suppression de certains fichiers ou dossiers pourrait interrompre des services ou applications en cours d'exécution.

### Conclusion

Ce script est utile pour automatiser le nettoyage de Windows, mais il doit être utilisé avec précaution. Il est recommandé de vérifier les chemins et les fichiers ciblés avant l'exécution pour éviter toute suppression accidentelle de données importantes.

### Informations

Ce script n'est pas associé à Microsoft. Il a été développé indépendamment et n'a aucune affiliation avec Microsoft ou ses produits. Pour toute question ou support concernant ce script, veuillez contacter son auteur ou consulter la documentation associée.

--------------------------------------------------------------------------------------------------------------------------------------

[![Donate](https://img.shields.io/badge/paypal-donate-yellow.svg?style=flat)](https://www.paypal.me/nuggan85) [![v1.0.0](http://img.shields.io/badge/zip-v1.0.0-blue.svg)](https://github.com/NuggaN85/WindowsCleaner/archive/master.zip) [![GitHub license](https://img.shields.io/github/license/NuggaN85/WindowsCleaner)](https://github.com/NuggaN85/WindowsCleaner)

--------------------------------------------------------------------------------------------------------------------------------------
