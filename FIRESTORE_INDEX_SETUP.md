# Configuration de l'index Firestore pour les sanctions appliquées

## Problème identifié

L'erreur suivante apparaît dans les logs :
```
W/Firestore( 9690): (25.1.4) [Firestore]: Listen for Query(target=Query(sanctions_applied where childId==1759231250063 order by -appliedAt, -__name__);limitType=LIMIT_TO_FIRST) failed: Status{code=FAILED_PRECONDITION, description=The query requires an index. You can create it here: https://console.firebase.google.com/v1/r/project/family-star-8be98/firestore/indexes?create_composite=Cltwcm9qZWN0cy9mYW1pbHktc3Rhci04YmU5OC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvc2FuY3Rpb25zX2FwcGxpZWQvaW5kZXhlcy9fEAEaCwoHY2hpbGRJZBABGg0KCWFwcGxpZWRBdBACGgwKCF9fbmFtZV9fEAI, cause=null}
```

## Solution

### 1. Index créé dans le code

J'ai déjà modifié la requête dans `lib/services/firestore_service.dart` pour inclure un ordre supplémentaire sur `__name__` qui est nécessaire pour Firestore.

### 2. Créer l'index manuellement dans Firebase Console

1. Allez à l'URL fournie dans l'erreur :
   https://console.firebase.google.com/v1/r/project/family-star-8be98/firestore/indexes?create_composite=Cltwcm9qZWN0cy9mYW1pbHktc3Rhci04YmU5OC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvc2FuY3Rpb25zX2FwcGxpZWQvaW5kZXhlcy9fEAEaCwoHY2hpbGRJZBABGg0KCWFwcGxpZWRBdBACGgwKCF9fbmFtZV9fEAI

2. Ou créez manuellement l'index avec ces paramètres :
   - Collection: `sanctions_applied`
   - Champ 1: `childId` (Ordre croissant)
   - Champ 2: `appliedAt` (Ordre décroissant)
   - Champ 3: `__name__` (Ordre décroissant)

### 3. Utiliser le fichier d'index JSON

Vous pouvez également utiliser le fichier `firestore_indexes.json` créé pour déployer l'index via la CLI Firebase :

```bash
firebase deploy --only firestore:indexes
```

## Modifications apportées au code

1. **Dans `lib/services/firestore_service.dart`**:
   - Ajout de `.orderBy('__name__', descending: true)` à la requête `getSanctionsAppliedStreamByChildId`

2. **Dans `lib/screens/children/child_profile_screen.dart`**:
   - Augmentation du délai d'attente après l'application d'une sanction (500ms → 1000ms)
   - Augmentation du délai d'attente après la désactivation d'une sanction (500ms → 1000ms)

Ces modifications devraient résoudre les problèmes de latence dans l'affichage des sanctions et le problème où les sanctions ne disparaissent pas après avoir cliqué sur "Terminer".