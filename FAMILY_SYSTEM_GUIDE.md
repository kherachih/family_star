# Guide du système de familles - Family Star

## Vue d'ensemble

Le système de familles permet à plusieurs parents de gérer ensemble les mêmes enfants dans l'application Family Star. Chaque parent peut ajouter, modifier et supprimer des enfants, attribuer des étoiles, et gérer les récompenses et sanctions.

## Fonctionnalités

### 1. Création automatique de famille
- Lors de l'inscription d'un nouveau parent, une famille est automatiquement créée
- Le nom de la famille est "Famille de [Nom du parent]"
- Le parent qui crée le compte est automatiquement ajouté comme créateur de la famille

### 2. Ajout de parents à une famille
- Un parent existant peut ajouter d'autres parents à sa famille
- L'ajout se fait via l'email du parent à ajouter
- Le parent doit déjà avoir un compte dans l'application
- Un parent ne peut être ajouté que s'il n'est pas déjà dans la famille

### 3. Accès partagé aux enfants
- Tous les parents d'une famille ont accès aux mêmes enfants
- Chaque parent peut voir et modifier les informations des enfants
- Les modifications sont synchronisées en temps réel entre tous les parents

### 4. Gestion des étoiles et récompenses
- Tous les parents peuvent attribuer des étoiles aux enfants
- Les récompenses et sanctions sont partagées entre tous les parents
- L'historique des actions est visible par tous les parents

## Structure des données

### Modèle Family
```dart
class Family {
  final String id;              // ID unique de la famille
  final String name;            // Nom de la famille
  final List<String> parentIds; // Liste des IDs des parents
  final List<String> childIds;  // Liste des IDs des enfants
  final String createdBy;       // ID du parent créateur
  final DateTime createdAt;     // Date de création
  final DateTime updatedAt;     // Date de dernière mise à jour
}
```

### Modèle Child (modifié)
```dart
class Child {
  final String id;              // ID unique de l'enfant
  final String familyId;        // ID de la famille (remplace parentId)
  final String name;            // Nom de l'enfant
  // ... autres champs
}
```

## Flux d'utilisation

### 1. Inscription d'un nouveau parent
1. Le parent s'inscrit avec email et mot de passe
2. Une famille est automatiquement créée
3. Le parent est ajouté comme créateur de la famille
4. Le parent peut commencer à ajouter des enfants

### 2. Ajout d'un parent existant
1. Un parent de la famille accède à "Gestion de la famille" dans le profil
2. Il saisit l'email du parent à ajouter
3. Le système vérifie si un compte existe avec cet email
4. Si le compte existe, le parent est ajouté à la famille
5. Le nouveau parent a immédiatement accès aux enfants de la famille

### 3. Connexion d'un parent
1. Le parent se connecte avec son email et mot de passe
2. Le système charge toutes les familles auxquelles il appartient
3. S'il n'a pas de famille, une famille est automatiquement créée
4. Le parent peut voir et gérer les enfants de ses familles

## Compatibilité

Le système maintient la compatibilité avec les données existantes :
- Les enfants créés avant la mise à jour utilisent `parentId` comme `familyId`
- Les méthodes `getChildrenByParentId` sont conservées pour la rétrocompatibilité
- Les données sont automatiquement migrées lors de l'utilisation

## Sécurité

- Un parent ne peut être ajouté à une famille que s'il a un compte valide
- Le créateur de la famille ne peut pas être retiré de la famille
- Les modifications sont validées côté serveur
- Seuls les parents de la famille peuvent accéder aux enfants de cette famille

## Limitations actuelles

- Un parent ne peut appartenir qu'à une seule famille
- Le nom de la famille ne peut pas être modifié (peut être ajouté plus tard)
- Il n'y a pas de système d'invitations (peut être ajouté plus tard)

## Améliorations futures

1. **Invitations par email** : Envoyer une invitation par email au lieu de rechercher un compte existant
2. **Plusieurs familles par parent** : Permettre à un parent d'appartenir à plusieurs familles
3. **Rôles dans la famille** : Définir des rôles (admin, parent, tuteur, etc.)
4. **Historique des modifications** : Suivre qui a modifié quoi et quand
5. **Notifications** : Notifier les parents lorsqu'un enfant est ajouté ou modifié