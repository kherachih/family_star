/// Classe pour gérer les avatars prédéfinis des enfants
class ChildAvatars {
  // Avatars pour garçons
  static const List<String> boyAvatars = [
    '👦', // Garçon
    '🧒', // Enfant
    '👶', // Bébé
    '🤓', // Garçon à lunettes
    '😊', // Souriant
    '😎', // Cool
    '🥳', // Fête
    '🤗', // Câlin
    '🤠', // Cowboy
    '🥷', // Ninja
    '🦸', // Super-héros
    '🧙', // Magicien
  ];

  // Avatars pour filles
  static const List<String> girlAvatars = [
    '👧', // Fille
    '🧒', // Enfant
    '👶', // Bébé
    '🤓', // Fille à lunettes
    '😊', // Souriante
    '😎', // Cool
    '🥳', // Fête
    '🤗', // Câlin
    '👸', // Princesse
    '🧚', // Fée
    '🦸', // Super-héroïne
    '🧙', // Magicienne
  ];

  /// Retourne l'avatar par défaut selon le genre
  static String getDefaultAvatar(String gender) {
    return gender == 'boy' ? boyAvatars[0] : girlAvatars[0];
  }

  /// Retourne la liste d'avatars selon le genre
  static List<String> getAvatarsByGender(String gender) {
    return gender == 'boy' ? boyAvatars : girlAvatars;
  }

  /// Retourne l'avatar à l'index spécifié pour le genre donné
  static String getAvatar(String gender, int index) {
    final avatars = getAvatarsByGender(gender);
    if (index >= 0 && index < avatars.length) {
      return avatars[index];
    }
    return getDefaultAvatar(gender);
  }
}