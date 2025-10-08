import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/children_provider.dart';
import 'providers/rewards_provider.dart';
import 'providers/family_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/tutorial_provider.dart';
import 'providers/tutorial_selections_provider.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/admob_service.dart';
import 'services/auto_ad_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/tutorial/tutorial_screen.dart';
import 'screens/language/language_selection_screen.dart';
import 'utils/app_colors.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser EasyLocalization
  await EasyLocalization.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized
  }
  
  runApp(EasyLocalization(
    supportedLocales: LanguageProvider.supportedLocales,
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    assetLoader: const RootBundleAssetLoader(),
    child: const FamilyStarApp(),
  ));
}

class FamilyStarApp extends StatelessWidget {
  const FamilyStarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => FamilyProvider()),
        ChangeNotifierProvider(create: (context) => ChildrenProvider()),
        ChangeNotifierProvider(create: (context) => RewardsProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(create: (context) => TutorialProvider()),
        ChangeNotifierProvider(create: (context) => TutorialSelectionsProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
        title: 'Family Star',
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          EasyLocalization.of(context)!.delegate,
        ],
        supportedLocales: context.supportedLocales,
            locale: languageProvider.currentLocale,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                tertiary: AppColors.tertiary,
                surface: AppColors.surface,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: AppColors.background,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: AppColors.surface,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              useMaterial3: true,
              fontFamily: 'Roboto',
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.darkPrimary,
                primary: AppColors.darkPrimary,
                secondary: AppColors.darkSecondary,
                tertiary: AppColors.darkTertiary,
                surface: AppColors.darkSurface,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: AppColors.darkBackground,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.darkSurface,
                foregroundColor: AppColors.darkTextPrimary,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: AppColors.darkCard,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkPrimary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: AppColors.darkPrimary.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: AppColors.darkPrimary,
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.darkCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.lightGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.lightGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
                ),
              ),
              useMaterial3: true,
              fontFamily: 'Roboto',
            ),
        home: const AppRouter(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/dashboard': (context) => const MainScreen(),
              '/tutorial': (context) => const TutorialScreen(),
              '/language': (context) => const LanguageSelectionScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _isInitialized = false;
  bool _languageChecked = false;
  bool? _languageProviderFirstTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Initialiser le provider de langue
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      await languageProvider.initialize();
      
      // Vérifier si c'est la première fois et si l'utilisateur n'a pas choisi de langue
      final isFirstTime = await languageProvider.isFirstTime();
      final hasChosenLanguage = await languageProvider.hasChosenLanguage();
      final shouldShowLanguageScreen = isFirstTime && !hasChosenLanguage;
      
      setState(() {
        _languageProviderFirstTime = shouldShowLanguageScreen;
        _languageChecked = true;
      });
      
      if (shouldShowLanguageScreen && mounted) {
        return; // Arrêter l'initialisation ici pour permettre la sélection de langue
      }
      
      // Initialiser le service de notifications
      await NotificationService().init();
      
      // Initialiser le service AdMob
      await AdMobService().initialize();

      // Configuration pour les appareils de test AdMob
      if (kDebugMode) {
        RequestConfiguration configuration = RequestConfiguration(
          testDeviceIds: ["8BD23F177E4DB9690175CF15BFEC9BC4"], // Votre ID d'appareil de test
        );
        MobileAds.instance.updateRequestConfiguration(configuration);
      }
      
      // Initialiser le service de publicités automatiques
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      AutoAdService().initialize(authProvider);
      
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final tutorialProvider = Provider.of<TutorialProvider>(context, listen: false);
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      
      // Initialiser le thème
      await themeProvider.initialize();
      
      await authProvider.initializeAuth();
      // Si l'utilisateur est déjà connecté, charger ses familles
      if (authProvider.currentUser != null) {
        await familyProvider.loadFamiliesByParentId(authProvider.currentUser!.id);
        
        // Initialiser le provider de notifications
        notificationProvider.initialize(authProvider.currentUser!.id);
        
        // Charger l'état du tutoriel
        await tutorialProvider.loadTutorialState(authProvider.currentUser!.id);
        
        // Si l'utilisateur n'a pas de famille, en créer une automatiquement
        if (familyProvider.currentFamily == null) {
          await familyProvider.createFamilyForParent(
            authProvider.currentUser!.id,
            authProvider.currentUser!.name,
          );
        }
      }
    } catch (e) {
      // Ignore errors during testing
      debugPrint('Erreur lors de l\'initialisation de l\'application: $e');
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _languageChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_languageChecked) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      AppColors.darkPrimary,
                      AppColors.darkSecondary,
                    ]
                  : [
                      Color(0xFFFF6B6B),
                      Color(0xFFFFD93D),
                    ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 100,
                  color: Colors.white,
                ),
                SizedBox(height: 24),
                Text(
                  'Family Star',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Système d\'étoiles familial',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 32),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Vérifier si c'est la première fois et si l'utilisateur n'a pas choisi de langue
    return Consumer2<LanguageProvider, AuthProvider>(
      builder: (context, languageProvider, authProvider, child) {
        // Vérifier si c'est la première fois et si l'utilisateur n'a pas choisi de langue
        if (_languageChecked && _languageProviderFirstTime != null && _languageProviderFirstTime!) {
          return const LanguageSelectionScreen();
        }
        
        if (!_isInitialized) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          AppColors.darkPrimary,
                          AppColors.darkSecondary,
                        ]
                      : [
                          Color(0xFFFF6B6B),
                          Color(0xFFFFD93D),
                        ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }

        return Consumer<TutorialProvider>(
          builder: (context, tutorialProvider, child) {
            // Si l'utilisateur a besoin du tutoriel, l'afficher
            if (authProvider.isAuthenticated && tutorialProvider.needsTutorial) {
              return const TutorialScreen();
            } else if (authProvider.isAuthenticated) {
              return const MainScreen();
            } else {
              return const LoginScreen();
            }
          },
        );
      },
    );
  }

}