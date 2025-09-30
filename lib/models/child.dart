import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/avatars.dart';

class Child {
  final String id;
  final String parentId;
  final String name;
  final int age;
  final DateTime? birthDate;
  final String? photoUrl; // Deprecated - gardé pour compatibilité
  final String gender; // 'boy' ou 'girl'
  final int avatarIndex; // Index de l'avatar dans la liste
  final int totalStars;
  final int birthdayStars;
  final List<String> objectives;
  final DateTime createdAt;
  final DateTime updatedAt;

  Child({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    this.birthDate,
    this.photoUrl,
    this.gender = 'boy',
    this.avatarIndex = 0,
    this.totalStars = 0,
    this.birthdayStars = 10,
    this.objectives = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Retourne l'emoji de l'avatar de l'enfant
  String get avatar => ChildAvatars.getAvatar(gender, avatarIndex);

  factory Child.fromMap(Map<String, dynamic> map) {
    return Child(
      id: map['id'] as String,
      parentId: map['parentId'] as String,
      name: map['name'] as String,
      age: map['age'] as int,
      birthDate: map['birthDate'] != null
          ? (map['birthDate'] is String
              ? DateTime.parse(map['birthDate'] as String)
              : (map['birthDate'] as Timestamp).toDate())
          : null,
      photoUrl: map['photoUrl'] as String?,
      gender: map['gender'] as String? ?? 'boy',
      avatarIndex: map['avatarIndex'] as int? ?? 0,
      totalStars: map['totalStars'] as int? ?? 0,
      birthdayStars: map['birthdayStars'] as int? ?? 10,
      objectives: List<String>.from(map['objectives'] ?? []),
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] is String
          ? DateTime.parse(map['updatedAt'] as String)
          : (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'age': age,
      'birthDate': birthDate?.toIso8601String(),
      'photoUrl': photoUrl,
      'gender': gender,
      'avatarIndex': avatarIndex,
      'totalStars': totalStars,
      'birthdayStars': birthdayStars,
      'objectives': objectives,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Child copyWith({
    String? id,
    String? parentId,
    String? name,
    int? age,
    DateTime? birthDate,
    String? photoUrl,
    String? gender,
    int? avatarIndex,
    int? totalStars,
    int? birthdayStars,
    List<String>? objectives,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Child(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      age: age ?? this.age,
      birthDate: birthDate ?? this.birthDate,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      totalStars: totalStars ?? this.totalStars,
      birthdayStars: birthdayStars ?? this.birthdayStars,
      objectives: objectives ?? this.objectives,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calcule l'âge basé sur la date de naissance
  int get calculatedAge {
    if (birthDate == null) return age;

    final now = DateTime.now();
    int calculatedAge = now.year - birthDate!.year;

    // Vérifier si l'anniversaire n'est pas encore passé cette année
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      calculatedAge--;
    }

    return calculatedAge;
  }

  /// Vérifie si c'est l'anniversaire de l'enfant aujourd'hui
  bool get isBirthdayToday {
    if (birthDate == null) return false;

    final now = DateTime.now();
    return now.month == birthDate!.month && now.day == birthDate!.day;
  }

  /// Calcule les jours jusqu'au prochain anniversaire
  int get daysUntilBirthday {
    if (birthDate == null) return -1;

    final now = DateTime.now();
    final thisYearBirthday = DateTime(now.year, birthDate!.month, birthDate!.day);

    if (thisYearBirthday.isAfter(now)) {
      return thisYearBirthday.difference(now).inDays;
    } else {
      final nextYearBirthday = DateTime(now.year + 1, birthDate!.month, birthDate!.day);
      return nextYearBirthday.difference(now).inDays;
    }
  }
}