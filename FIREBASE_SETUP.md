# Configuration Firebase pour Family Star

## Étapes de configuration

### 1. Créer un projet Firebase

1. Allez sur [console.firebase.google.com](https://console.firebase.google.com)
2. Cliquez sur "Créer un projet"
3. Donnez un nom à votre projet (ex: "family-star")
4. Activez Google Analytics (optionnel)

### 2. Activer Authentication

1. Dans la console Firebase, allez dans "Authentication"
2. Cliquez sur "Commencer"
3. Dans l'onglet "Sign-in method", activez :
   - **Email/Password**
   - **Google** (vous devrez configurer le support OAuth)

### 3. Créer Firestore Database

1. Dans la console Firebase, allez dans "Firestore Database"
2. Cliquez sur "Créer une base de données"
3. Choisissez "Commencer en mode test" (vous pourrez changer les règles plus tard)
4. Sélectionnez une région proche de vos utilisateurs

### 4. Configurer les applications

#### Pour Android :
1. Dans les paramètres du projet, cliquez sur "Ajouter une application"
2. Sélectionnez Android
3. Nom du package : `com.example.family_star` (ou votre nom de package personnalisé)
4. Téléchargez le fichier `google-services.json`
5. Placez-le dans `android/app/`

#### Pour iOS :
1. Ajoutez une application iOS
2. Bundle ID : `com.example.familyStar`
3. Téléchargez le fichier `GoogleService-Info.plist`
4. Placez-le dans `ios/Runner/`

#### Pour Web :
1. Ajoutez une application Web
2. Donnez un surnom à votre application
3. Copiez la configuration et mettez à jour `lib/firebase_options.dart`

### 5. Mettre à jour firebase_options.dart

Remplacez les valeurs placeholder dans `lib/firebase_options.dart` avec vos vraies clés de configuration Firebase :

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-android-api-key',
  appId: 'your-android-app-id',
  messagingSenderId: 'your-sender-id',
  projectId: 'your-project-id',
  storageBucket: 'your-project-id.appspot.com',
);

// Même chose pour ios, web, etc.
```

### 6. Configuration Google Sign-In

#### Android :
1. Dans la console Firebase, allez dans Authentication > Sign-in method > Google
2. Téléchargez le fichier `google-services.json` mis à jour
3. Remplacez l'ancien fichier dans `android/app/`

#### iOS :
1. Dans `ios/Runner/Info.plist`, ajoutez votre URL scheme :
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 7. Règles de sécurité Firestore

Remplacez les règles par défaut par celles-ci pour sécuriser vos données :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Parents peuvent accéder à leurs propres données
    match /parents/{parentId} {
      allow read, write: if request.auth != null && request.auth.uid == parentId;
    }

    // Parents peuvent accéder aux enfants qu'ils ont créés
    match /children/{childId} {
      allow read, write: if request.auth != null &&
        resource.data.parentId == request.auth.uid;
      allow create: if request.auth != null &&
        request.resource.data.parentId == request.auth.uid;
    }

    // Parents peuvent accéder aux tâches de leurs enfants
    match /tasks/{taskId} {
      allow read, write: if request.auth != null &&
        exists(/databases/$(database)/documents/children/$(resource.data.childId)) &&
        get(/databases/$(database)/documents/children/$(resource.data.childId)).data.parentId == request.auth.uid;
      allow create: if request.auth != null &&
        exists(/databases/$(database)/documents/children/$(request.resource.data.childId)) &&
        get(/databases/$(database)/documents/children/$(request.resource.data.childId)).data.parentId == request.auth.uid;
    }

    // Parents peuvent accéder aux pertes d'étoiles de leurs enfants
    match /star_losses/{starLossId} {
      allow read, write: if request.auth != null &&
        exists(/databases/$(database)/documents/children/$(resource.data.childId)) &&
        get(/databases/$(database)/documents/children/$(resource.data.childId)).data.parentId == request.auth.uid;
      allow create: if request.auth != null &&
        exists(/databases/$(database)/documents/children/$(request.resource.data.childId)) &&
        get(/databases/$(database)/documents/children/$(request.resource.data.childId)).data.parentId == request.auth.uid;
    }
  }
}
```

### 8. Test de l'application

1. Assurez-vous que Firebase est correctement configuré
2. Lancez l'application : `flutter run`
3. Testez la création de compte avec email/password
4. Testez la connexion avec Google
5. Vérifiez que les données sont bien stockées dans Firestore

## Dépannage

### Erreurs communes :

1. **"Default Firebase app has not been initialized"**
   - Vérifiez que `Firebase.initializeApp()` est appelé dans `main()`
   - Vérifiez que `firebase_options.dart` a les bonnes configurations

2. **"PlatformException: sign_in_failed"** (Google Sign-In)
   - Vérifiez que Google Sign-In est activé dans la console Firebase
   - Vérifiez les fichiers de configuration (`google-services.json`, `GoogleService-Info.plist`)
   - Pour Android : vérifiez le SHA-1 fingerprint dans la console Firebase

3. **Problèmes de permissions Firestore**
   - Vérifiez les règles de sécurité Firestore
   - Assurez-vous que l'utilisateur est bien authentifié

### Commandes utiles :

```bash
# Installer les dépendances
flutter pub get

# Analyser le code
flutter analyze

# Lancer l'application
flutter run

# Nettoyer le projet
flutter clean
```