import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:family_star/providers/tutorial_provider.dart';
import 'package:family_star/providers/auth_provider.dart';
import 'package:family_star/models/tutorial_state.dart';
import 'package:family_star/screens/tutorial/tutorial_screen.dart';

void main() {
  group('Tutorial Tests', () {
    late TutorialProvider tutorialProvider;
    late AuthProvider authProvider;

    setUp(() {
      tutorialProvider = TutorialProvider();
      authProvider = AuthProvider();
    });

    test('TutorialState initialization', () {
      final tutorialState = TutorialState(
        id: 'test_id',
        parentId: 'test_parent_id',
        hasCompletedTutorial: false,
        currentStep: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(tutorialState.hasCompletedTutorial, false);
      expect(tutorialState.currentStep, 0);
      expect(tutorialState.totalSteps, 4);
      expect(tutorialState.progress, 0.0);
      expect(tutorialState.stepTitle, 'Ajouter vos enfants');
    });

    test('TutorialState step completion', () {
      final tutorialState = TutorialState(
        id: 'test_id',
        parentId: 'test_parent_id',
        hasCompletedTutorial: false,
        currentStep: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Marquer la première étape comme complétée
      final updatedState = tutorialState.markStepCompleted(0);

      expect(updatedState.currentStep, 1);
      expect(updatedState.hasAddedChildren, true);
      expect(updatedState.stepTitle, 'Configurer les tâches quotidiennes');
      expect(updatedState.progress, 0.25);
    });

    test('TutorialState completion', () {
      final tutorialState = TutorialState(
        id: 'test_id',
        parentId: 'test_parent_id',
        hasCompletedTutorial: false,
        currentStep: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Marquer la dernière étape comme complétée
      final updatedState = tutorialState.markStepCompleted(3);

      expect(updatedState.hasCompletedTutorial, true);
      expect(updatedState.hasConfiguredSanctions, true);
      expect(updatedState.progress, 1.0);
    });

    test('TutorialProvider initialization', () async {
      // Simuler l'initialisation du tutoriel
      await tutorialProvider.initializeTutorialState('test_parent_id');

      expect(tutorialProvider.isLoading, false);
      expect(tutorialProvider.errorMessage, null);
    });

    test('TutorialProvider step progression', () async {
      // Simuler l'initialisation du tutoriel
      await tutorialProvider.initializeTutorialState('test_parent_id');

      // Simuler la complétion de la première étape
      await tutorialProvider.completeCurrentStep();

      expect(tutorialProvider.currentStep, 1);
      expect(tutorialProvider.progress, 0.25);
    });

    test('TutorialProvider skip tutorial', () async {
      // Simuler l'initialisation du tutoriel
      await tutorialProvider.initializeTutorialState('test_parent_id');

      // Simuler le saut du tutoriel
      await tutorialProvider.skipTutorial();

      expect(tutorialProvider.needsTutorial, false);
      expect(tutorialProvider.currentStep, 4);
    });

    testWidgets('TutorialScreen renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: tutorialProvider),
          ],
          child: MaterialApp(
            home: TutorialScreen(),
          ),
        ),
      );

      // Vérifier que l'écran du tutoriel s'affiche
      expect(find.text('Ajoutez vos enfants'), findsOneWidget);
      expect(find.text('Passer'), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);
    });

    testWidgets('TutorialScreen navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: tutorialProvider),
          ],
          child: MaterialApp(
            home: TutorialScreen(),
          ),
        ),
      );

      // Vérifier que le bouton "Suivant" est présent
      expect(find.text('Suivant'), findsOneWidget);

      // Simuler le tap sur le bouton "Suivant"
      await tester.tap(find.text('Suivant'));
      await tester.pump();

      // Vérifier que l'étape a changé
      expect(find.text('Configurer les tâches quotidiennes'), findsOneWidget);
      expect(find.text('2/4'), findsOneWidget);
    });

    test('Tutorial step titles are correct', () {
      final tutorialState = TutorialState(
        id: 'test_id',
        parentId: 'test_parent_id',
        hasCompletedTutorial: false,
        currentStep: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Vérifier les titres des étapes
      expect(tutorialState.stepTitle, 'Ajouter vos enfants');
      
      final step1 = tutorialState.copyWith(currentStep: 1);
      expect(step1.stepTitle, 'Configurer les tâches quotidiennes');
      
      final step2 = tutorialState.copyWith(currentStep: 2);
      expect(step2.stepTitle, 'Définir les récompenses');
      
      final step3 = tutorialState.copyWith(currentStep: 3);
      expect(step3.stepTitle, 'Configurer les sanctions');
    });

    test('Tutorial step descriptions are correct', () {
      final tutorialState = TutorialState(
        id: 'test_id',
        parentId: 'test_parent_id',
        hasCompletedTutorial: false,
        currentStep: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Vérifier les descriptions des étapes
      expect(tutorialState.stepDescription, 'Commencez par ajouter vos enfants à votre famille');
      
      final step1 = tutorialState.copyWith(currentStep: 1);
      expect(step1.stepDescription, 'Configurez les tâches quotidiennes pour vos enfants');
      
      final step2 = tutorialState.copyWith(currentStep: 2);
      expect(step2.stepDescription, 'Définissez les récompenses que vos enfants peuvent obtenir');
      
      final step3 = tutorialState.copyWith(currentStep: 3);
      expect(step3.stepDescription, 'Configurez les sanctions en cas de non-respect des règles');
    });
  });
}