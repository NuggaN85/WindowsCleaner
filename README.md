# **Nettoyage Windows Complet - Script d'Optimisation Système**  

![Windows Cleanup Script](https://img.shields.io/badge/Version-4.3-blue)  
![License](https://img.shields.io/badge/License-MIT-green)  
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey)  

Un script Batch/CMD complet pour nettoyer, optimiser et maintenir votre système Windows.  
**Idéal pour les techniciens informatiques et utilisateurs avancés.**  

---

## **📝 Fonctionnalités Principales**  

✅ **Nettoyage des fichiers temporaires** (Temp, Cache, Logs inutiles)  
✅ **Nettoyage des navigateurs** (Chrome, Firefox, Edge)  
✅ **Optimisation des disques** (SSD/HDD) avec défragmentation adaptée  
✅ **Maintenance système** (SFC, DISM, CHKDSK)  
✅ **Suppression des fichiers obsolètes** (Windows.old, fichiers .tmp)  
✅ **Vidage de la corbeille et du cache DNS**  
✅ **Nettoyage des journaux d'événements** (Event Logs)  
✅ **Création automatique d'un point de restauration**  
✅ **Calcul de l'espace disque libéré**  
✅ **Journalisation détaillée (log)**  

---

## **⚙️ Installation et Utilisation**  

### **📥 Téléchargement**  
1. **Téléchargez le script** :  
   ```bash
   git clone https://github.com/NuggaN85/WindowsCleaner.git
   ```
   Ou téléchargez directement `WindowsCleaner.bat`.  

2. **Placez-le sur le Bureau** ou dans un dossier facile d'accès.  

### **▶️ Exécution**  
1. **Ouvrir en tant qu'administrateur** (clic droit → *Exécuter en tant qu'administrateur*).  
2. **Choisir une option** dans le menu interactif :  
   - **Nettoyage de base** (fichiers temporaires, cache)  
   - **Nettoyage système complet** (WinSxS, logs)  
   - **Maintenance avancée** (SFC, DISM, CHKDSK)  
   - **Nettoyage personnalisé** (choix manuel)  

3. **Un rapport (log)** est généré sur le Bureau (`Nettoyage_Windows_Log_XXXX-XX-XX.txt`).  

---

## **📊 Options du Script**  

| Option | Description |
|--------|-------------|
| **1** | Nettoyage de base (fichiers temporaires, cache) |
| **2** | Nettoyage des fichiers système (WinSxS, logs) |
| **3** | Nettoyage des navigateurs (Chrome, Firefox, Edge) |
| **4** | Maintenance système (SFC, DISM, CHKDSK) |
| **5** | **Nettoyage complet** (toutes les options) |
| **6** | Nettoyage personnalisé (choix manuel) |
| **0** | Quitter |

---

## **⚠️ Précautions**  
- **Toujours exécuter en tant qu'administrateur** (requiert des droits élevés).  
- **Un point de restauration est créé automatiquement** avant les modifications critiques.  
- **Redémarrage recommandé** après certaines opérations (DISM, CHKDSK).  

---

## **📜 Licence**  
Ce projet est sous licence **MIT**.  
➡️ **Libre d'utilisation, modification et distribution.**  

---

## **📌 Contributions**  
Les contributions sont les bienvenues !  
- **Signaler un bug** → [Issues](https://github.com/NuggaN85/WindowsCleaner/issues)  
- **Proposer une amélioration** → [Pull Requests](https://github.com/NuggaN85/WindowsCleaner/pulls)  

---

## **📊 Exemple de Résultat**  
```text
===================================
RÉSUMÉ DU NETTOYAGE
===================================
Espace libéré : 4.2 Go
Erreurs rencontrées : 0
===================================
```
➡️ **Le rapport complet est enregistré dans le fichier log.**  

---

## **🔗 Téléchargement & Support**  
📥 **[Télécharger la dernière version](https://github.com/NuggaN85/WindowsCleaner/releases)**  
💬 **[Support & Discussions](https://github.com/NuggaN85/WindowsCleaner/discussions)**  

---

✨ **Optimisez Windows en un clic !** ✨

© 2024 Ludovic Rose. Tous droits réservés.
