import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../utils/app_colors.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final tutorialProvider = Provider.of<TutorialProvider>(context, listen: false);
    
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
      familyProvider: familyProvider,
      notificationProvider: notificationProvider,
      tutorialProvider: tutorialProvider,
    );

    if (success && mounted) {
      // Vérifier si l'utilisateur a besoin du tutoriel
      if (tutorialProvider.needsTutorial) {
        Navigator.of(context).pushReplacementNamed('/tutorial');
      } else {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    final tutorialProvider = Provider.of<TutorialProvider>(context, listen: false);
    
    final success = await authProvider.signInWithGoogle(
      familyProvider: familyProvider,
      notificationProvider: notificationProvider,
      tutorialProvider: tutorialProvider,
    );

    if (success && mounted) {
      // Vérifier si l'utilisateur a besoin du tutoriel
      if (tutorialProvider.needsTutorial) {
        Navigator.of(context).pushReplacementNamed('/tutorial');
      } else {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Logo
                    Image.asset(
                      'assets/logo.png',
                      height: 150,
                    ),
                    const SizedBox(height: 48),

                    // Champ email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'auth.email'.tr(),
                        prefixIcon: const Icon(Icons.email),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'auth.email_required'.tr();
                        }
                        if (!value.contains('@')) {
                          return 'auth.email_invalid'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Champ mot de passe
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'auth.password'.tr(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'auth.password_required'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Case à cocher "Se souvenir de moi"
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                        Text('auth.remember_me'.tr()),
                      ],
                    ),

                    // Message d'erreur
                    if (authProvider.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF3A2326) // Fond rouge sombre pour mode sombre
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTaskNegative // Bordure rouge foncé pour mode sombre
                                : Colors.red[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTaskNegative // Rouge foncé pour mode sombre
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authProvider.errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.darkTextPrimary // Texte clair pour mode sombre
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Bouton de connexion
                    ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'auth.login'.tr(),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // Divider avec "OU"
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'auth.or'.tr(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Bouton de connexion Google
                    OutlinedButton.icon(
                      onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
                      icon: Icon(
                        Icons.account_circle,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTaskNegative // Rouge foncé pour mode sombre
                            : Colors.red,
                        size: 20,
                      ),
                      label: Text('auth.login_with_google'.tr()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary // Texte clair pour mode sombre
                            : Colors.black87,
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.lightGray // Gris clair pour mode sombre
                              : Colors.grey[300]!,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Lien vers l'inscription
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : Colors.grey,
                          ),
                          children: [
                            TextSpan(text: 'auth.no_account'.tr()),
                            TextSpan(
                              text: 'auth.register'.tr(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Espace supplémentaire en bas
                  ],
                ),
              ),
            );
            },
          ),
        ),
      ),
    );
  }
}