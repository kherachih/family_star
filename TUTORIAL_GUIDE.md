# Guide du système de tutoriel Family Star

## Vue d'ensemble

Le système de tutoriel Family Star guide les nouveaux utilisateurs à travers les étapes essentielles de configuration de leur système familial. Ce tutoriel apparaît automatiquement lors de la première connexion et peut être consulté à tout moment depuis les paramètres.

## Fonctionnalités

### 1. Suivi de progression
- Le système suit l'état d'avancement du tutoriel pour chaque utilisateur
- Barre de progression visuelle montrant les étapes complétées
- Possibilité de reprendre le tutoriel là où il a été arrêté

### 2. Étapes du tutoriel

#### Étape 1 : Ajouter vos enfants
- Interface simplifiée pour ajouter les enfants à la famille
- Configuration des informations essentielles (nom, âge, avatar, etc.)
- Attribution d'étoiles d'anniversaire

#### Étape 2 : Configurer les tâches quotidiennes
- Suggestions de tâches prédéfinies (ranger sa chambre, brosser les dents, etc.)
- Possibilité de créer des tâches personnalisées
- Configuration des étoiles gagnées par tâche
- Option pour les tâches quotidiennes ou ponctuelles

#### Étape 3 : Définir les récompenses
- Suggestions de récompenses adaptées aux enfants
- Configuration du coût en étoiles pour chaque récompense
- Récompenses variées (temps d'écran, sorties, jouets, etc.)

#### Étape 4 : Configurer les sanctions
- Suggestions de sanctions éducatives
- Configuration de la durée et de la sévérité
- Sanctions temporaires ou permanentes

### 3. Navigation intuitive
- Boutons "Précédent" et "Suivant" pour naviguer entre les étapes
- Option pour "Passer" le tutoriel
- Sauvegarde automatique de la progression

## Implémentation technique

### Modèle de données
Le tutoriel utilise le modèle `TutorialState` pour stocker :
- L'ID du parent
- L'état de complétion du tutoriel
- L'étape actuelle
- Les étapes spécifiques complétées (enfants, tâches, récompenses, sanctions)
- Les dates de création et de mise à jour

### Services
- `FirestoreService` : Gère les opérations de base de données pour les états du tutoriel
- `TutorialProvider` : Gère l'état du tutoriel dans l'application

### Écrans
- `TutorialScreen` : Écran principal avec navigation entre étapes
- `TutorialChildrenStep` : Étape d'ajout des enfants
- `TutorialTasksStep` : Étape de configuration des tâches
- `TutorialRewardsStep` : Étape de configuration des récompenses
- `TutorialSanctionsStep` : Étape de configuration des sanctions
- `TutorialCompletionScreen` : Écran de fin de tutoriel

### Intégration avec l'authentification
- Initialisation automatique de l'état du tutoriel lors de l'inscription
- Chargement de l'état du tutoriel lors de la connexion
- Redirection automatique vers le tutoriel pour les nouveaux utilisateurs

## Sécurité

Les règles de sécurité Firestore garantissent que :
- Chaque utilisateur ne peut accéder qu'à son propre état de tutoriel
- Les opérations CRUD sont limitées au propriétaire de l'état
- Les requêtes sont autorisées pour la recherche par parentId

## Personnalisation

Le système de tutoriel est conçu pour être facilement personnalisable :
- Ajout de nouvelles étapes
- Modification des suggestions prédéfinies
- Adaptation du design et des animations
- Configuration des messages et des textes

## Dépannage

### Problèmes courants

1. **Erreur de permission Firestore**
   - Vérifiez que les règles de sécurité sont correctement déployées
   - Assurez-vous que l'utilisateur est authentifié

2. **Le tutoriel n'apparaît pas**
   - Vérifiez que l'état du tutoriel est correctement initialisé
   - Confirmez que l'utilisateur n'a pas déjà terminé le tutoriel

3. **La progression n'est pas sauvegardée**
   - Vérifiez la connexion Internet
   - Assurez-vous que les opérations Firestore réussissent

### Tests

Le système inclut des tests unitaires dans `test/tutorial_test.dart` pour vérifier :
- L'initialisation de l'état du tutoriel
- La progression entre les étapes
- La complétion du tutoriel
- Le saut du tutoriel

## Conclusion

Le système de tutoriel Family Star offre une expérience d'intégration fluide pour les nouveaux utilisateurs, les guidant à travers la configuration essentielle de leur système familial. Avec des suggestions prédéfinies et une interface intuitive, les utilisateurs peuvent rapidement mettre en place un système fonctionnel adapté à leurs besoins.