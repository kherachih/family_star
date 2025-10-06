import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/family_provider.dart';
import '../../utils/app_colors.dart';
import 'tutorial_introduction_step.dart';
import 'tutorial_children_step.dart';
import 'tutorial_tasks_step.dart';
import 'tutorial_rewards_step.dart';
import 'tutorial_sanctions_step.dart';
import 'tutorial_completion_screen.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Initialiser les animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Démarrer l'animation
    _animationController.forward();
    
    // Initialiser l'état du tutoriel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTutorial();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeTutorial() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tutorialProvider = Provider.of<TutorialProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      await tutorialProvider.initializeTutorialState(authProvider.currentUser!.id);
    }
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    final tutorialProvider = Provider.of<TutorialProvider>(context, listen: false);
    if (tutorialProvider.currentStep < 5) {
      _goToStep(tutorialProvider.currentStep + 1);
    }
  }

  void _previousStep() {
    final tutorialProvider = Provider.of<TutorialProvider>(context, listen: false);
    if (tutorialProvider.currentStep > 0) {
      _goToStep(tutorialProvider.currentStep - 1);
    }
  }

  Future<void> _completeStep() async {
    final tutorialProvider = Provider.of<TutorialProvider>(context, listen: false);
    await tutorialProvider.completeCurrentStep();
    
    if (tutorialProvider.currentStep < 5) {
      _nextStep();
    } else {
      // Tutoriel terminé, naviguer vers l'écran de complétion
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TutorialCompletionScreen(),
        ),
      );
    }
  }

  Future<void> _skipTutorial() async {
    final tutorialProvider = Provider.of<TutorialProvider>(context, listen: false);
    await tutorialProvider.skipTutorial();
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const TutorialCompletionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<TutorialProvider>(
        builder: (context, tutorialProvider, child) {
          if (tutorialProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (tutorialProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tutorialProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _initializeTutorial,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header avec progression
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.gradientPrimary,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Bouton pour sauter le tutoriel
                              TextButton(
                                onPressed: _skipTutorial,
                                child: const Text(
                                  'Passer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Titre de l'étape
                              Text(
                                tutorialProvider.stepTitle,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              // Indicateur de progression
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${tutorialProvider.currentStep + 1}/5',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Barre de progression
                          LinearProgressIndicator(
                            value: tutorialProvider.progress,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 6,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tutorialProvider.stepDescription,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Contenu du tutoriel
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const AlwaysScrollableScrollPhysics(), // Activer le swipe
                      onPageChanged: (index) {
                        // Mettre à jour l'état du tutoriel si nécessaire
                        final tutorialProvider = Provider.of<TutorialProvider>(context, listen: false);
                        tutorialProvider.setCurrentStep(index);
                      },
                      children: [
                        TutorialIntroductionStep(
                          onNextPressed: () {
                            _goToStep(1); // Aller à la page d'ajout des enfants
                          },
                        ),
                        TutorialChildrenStep(onStepCompleted: _completeStep),
                        TutorialTasksStep(onStepCompleted: _completeStep),
                        TutorialRewardsStep(onStepCompleted: _completeStep),
                        TutorialSanctionsStep(onStepCompleted: _completeStep),
                      ],
                    ),
                  ),
                  
                  // Plus de barre de navigation inférieure - navigation par swipe uniquement
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}