# Configuration des index Firestore

## Index pour les sanctions appliquées

### Problème identifié

L'erreur suivante apparaît dans les logs :
```
W/Firestore( 9690): (25.1.4) [Firestore]: Listen for Query(target=Query(sanctions_applied where childId==1759231250063 order by -appliedAt, -__name__);limitType=LIMIT_TO_FIRST) failed: Status{code=FAILED_PRECONDITION, description=The query requires an index. You can create it here: https://console.firebase.google.com/v1/r/project/family-star-8be98/firestore/indexes?create_composite=Cltwcm9qZWN0cy9mYW1pbHktc3Rhci04YmU5OC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvc2FuY3Rpb25zX2FwcGxpZWQvaW5kZXhlcy9fEAEaCwoHY2hpbGRJZBABGg0KCWFwcGxpZWRBdBACGgwKCF9fbmFtZV9fEAI, cause=null}
```

### Solution

#### 1. Index créé dans le code

J'ai déjà modifié la requête dans `lib/services/firestore_service.dart` pour inclure un ordre supplémentaire sur `__name__` qui est nécessaire pour Firestore.

#### 2. Créer l'index manuellement dans Firebase Console

1. Allez à l'URL fournie dans l'erreur :
   https://console.firebase.google.com/v1/r/project/family-star-8be98/firestore/indexes?create_composite=Cltwcm9qZWN0cy9mYW1pbHktc3Rhci04YmU5OC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvc2FuY3Rpb25zX2FwcGxpZWQvaW5kZXhlcy9fEAEaCwoHY2hpbGRJZBABGg0KCWFwcGxpZWRBdBACGgwKCF9fbmFtZV9fEAI

2. Ou créez manuellement l'index avec ces paramètres :
   - Collection: `sanctions_applied`
   - Champ 1: `childId` (Ordre croissant)
   - Champ 2: `appliedAt` (Ordre décroissant)
   - Champ 3: `__name__` (Ordre décroissant)

## Index pour l'historique

### Nouveaux index requis pour la fonctionnalité d'historique

Pour la nouvelle fonctionnalité d'historique qui affiche toutes les activités de l'enfant (tâches, pertes d'étoiles, récompenses, sanctions), les index suivants sont nécessaires :

1. **Collection `tasks`**:
   - Champ 1: `parentId` (Ordre croissant)
   - Champ 2: `createdAt` (Ordre décroissant)

2. **Collection `star_losses`**:
   - Champ 1: `childId` (Ordre croissant)
   - Champ 2: `createdAt` (Ordre décroissant)

3. **Collection `reward_exchanges`**:
   - Champ 1: `childId` (Ordre croissant)
   - Champ 2: `exchangedAt` (Ordre décroissant)

### Configuration de Firebase pour le déploiement

Si vous n'avez pas encore configuré Firebase dans votre projet, suivez ces étapes :

1. **Installer Firebase CLI** (si ce n'est pas déjà fait) :
   ```bash
   npm install -g firebase-tools
   ```

2. **Connectez-vous à Firebase** :
   ```bash
   firebase login
   ```

3. **Initialiser Firebase dans votre projet** (si ce n'est pas déjà fait) :
   ```bash
   firebase init firestore
   ```
   - Choisissez "Use an existing project" et sélectionnez votre projet Firebase
   - Choisissez le fichier de règles existant (`firestore.rules`)
   - Choisissez le fichier d'index existant (`firestore_indexes.json`)

4. **Déployer les index** :
   ```bash
   firebase deploy --only firestore:indexes
   ```

### Déploiement des index

Une fois Firebase configuré, utilisez le fichier `firestore_indexes.json` mis à jour pour déployer tous les index via la CLI Firebase :

```bash
firebase deploy --only firestore:indexes
```

## Modifications apportées au code

1. **Dans `lib/services/firestore_service.dart`**:
   - Ajout de `.orderBy('__name__', descending: true)` à la requête `getSanctionsAppliedStreamByChildId`
   - Ajout des méthodes `getHistoryByChildId` et `getHistoryStreamByChildId` pour récupérer l'historique unifié

2. **Dans `lib/screens/children/child_profile_screen.dart`**:
   - Augmentation du délai d'attente après l'application d'une sanction (500ms → 1000ms)
   - Augmentation du délai d'attente après la désactivation d'une sanction (500ms → 1000ms)
   - Ajout de la section historique avec pagination

3. **Nouveaux fichiers créés**:
   - `lib/models/history_item.dart`: Modèle pour unifier les éléments d'historique
   - `lib/widgets/history_item_widget.dart`: Widget pour afficher un élément d'historique

4. **Dépendances ajoutées**:
   - `async: ^2.11.0` dans `pubspec.yaml` pour la gestion des streams

Ces modifications devraient résoudre les problèmes de latence dans l'affichage des sanctions et permettre l'affichage de l'historique complet des activités de l'enfant avec pagination.