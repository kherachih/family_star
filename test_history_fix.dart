import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Ce fichier est un test pour vérifier que l'historique fonctionne correctement
// Il n'est pas destiné à être inclus dans l'application finale

void main() async {
  // Initialiser Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Test de correction de l\'historique');
  print('=====================================');
  
  // Simuler l'application d'une tâche
  await testTaskApplication();
  
  print('✅ Test terminé');
}

Future<void> testTaskApplication() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Créer une tâche de test
    final taskId = 'test_task_${DateTime.now().millisecondsSinceEpoch}';
    final childId = 'test_child_${DateTime.now().millisecondsSinceEpoch}';
    
    // Données de la tâche
    final taskData = {
      'id': taskId,
      'parentId': 'test_parent',
      'childIds': [childId],
      'title': 'Tâche de test',
      'description': 'Description de la tâche de test',
      'type': 'positive',
      'stars': 5,
      'isActive': true,
      'isDaily': false,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    // Créer la tâche dans Firestore
    await firestore.collection('tasks').doc(taskId).set(taskData);
    print('✅ Tâche créée: $taskId');
    
    // Simuler l'enregistrement dans l'historique
    final completionId = '${taskId}_${childId}_${DateTime.now().millisecondsSinceEpoch}';
    await firestore.collection('task_completions').doc(completionId).set({
      'id': completionId,
      'taskId': taskId,
      'childId': childId,
      'completedAt': DateTime.now().toIso8601String(),
      'taskData': taskData,
    });
    print('✅ Tâche enregistrée dans l\'historique: $completionId');
    
    // Vérifier que l'historique contient bien l'entrée
    final completionDoc = await firestore.collection('task_completions').doc(completionId).get();
    if (completionDoc.exists) {
      print('✅ Entrée trouvée dans l\'historique');
      print('   - Tâche: ${completionDoc.data()!['taskData']['title']}');
      print('   - Enfant: ${completionDoc.data()!['childId']}');
      print('   - Date: ${completionDoc.data()!['completedAt']}');
    } else {
      print('❌ Entrée non trouvée dans l\'historique');
    }
    
    // Nettoyer les données de test
    await firestore.collection('tasks').doc(taskId).delete();
    await firestore.collection('task_completions').doc(completionId).delete();
    print('🧹 Données de test nettoyées');
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
}