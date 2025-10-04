import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../services/firebase_storage_service.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _showPasswordFields = false;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      _nameController.text = authProvider.currentUser!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
        );
      }
    }
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Choisir une photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Appareil photo'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final XFile? image = await _imagePicker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 80,
                  );
                  
                  if (image != null) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur lors de la capture de l\'image: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });

    try {
      String? photoUrl;
      
      // Si une nouvelle image a été sélectionnée, l'uploader vers Firebase Storage
      if (_selectedImage != null && authProvider.currentUser != null) {
        photoUrl = await FirebaseStorageService.uploadParentPhoto(
          parentId: authProvider.currentUser!.id,
          imagePath: _selectedImage!.path,
        );
        
        if (photoUrl == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors du téléchargement de la photo')),
          );
          return;
        }
      }

      // Mettre à jour le nom
      bool success = await authProvider.updateProfile(
        name: _nameController.text.trim(),
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour du nom')),
        );
        return;
      }

      // Si une nouvelle photo a été uploadée, mettre à jour la photo de profil
      if (photoUrl != null) {
        success = await authProvider.updateProfilePhoto(photoUrl);
        
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la mise à jour de la photo')),
          );
          return;
        }
      }

      // Si les champs de mot de passe sont visibles, mettre à jour le mot de passe
      if (_showPasswordFields && _newPasswordController.text.isNotEmpty) {
        success = await authProvider.changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la mise à jour du mot de passe')),
          );
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.gradientPrimary,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Enregistrer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Photo de profil
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showImagePickerOptions,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: AppColors.gradientPrimary,
                              ),
                            ),
                            child: _selectedImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      _selectedImage!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : authProvider.currentUser!.photoUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          authProvider.currentUser!.photoUrl!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.person_rounded,
                                              size: 50,
                                              color: Colors.white,
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person_rounded,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Appuyez pour changer la photo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Nom
                  const Text(
                    'Nom',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Votre nom',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Email (non modifiable)
                  const Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: authProvider.currentUser!.email,
                    enabled: false,
                    decoration: InputDecoration(
                      hintText: 'Votre email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section mot de passe
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mot de passe',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showPasswordFields = !_showPasswordFields;
                                });
                              },
                              child: Text(_showPasswordFields ? 'Annuler' : 'Modifier'),
                            ),
                          ],
                        ),
                        
                        if (_showPasswordFields) ...[
                          const SizedBox(height: 16),
                          
                          // Mot de passe actuel
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Mot de passe actuel',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                            validator: (value) {
                              if (_showPasswordFields && (value == null || value.isEmpty)) {
                                return 'Veuillez entrer votre mot de passe actuel';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Nouveau mot de passe
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Nouveau mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                            validator: (value) {
                              if (_showPasswordFields && value != null && value.isNotEmpty) {
                                if (value.length < 6) {
                                  return 'Le mot de passe doit contenir au moins 6 caractères';
                                }
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Confirmer le nouveau mot de passe
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Confirmer le nouveau mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                            validator: (value) {
                              if (_showPasswordFields && _newPasswordController.text.isNotEmpty) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez confirmer votre nouveau mot de passe';
                                }
                                if (value != _newPasswordController.text) {
                                  return 'Les mots de passe ne correspondent pas';
                                }
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Text(
                            'Pour des raisons de sécurité, vous ne pouvez modifier votre mot de passe qu\'après avoir confirmé votre mot de passe actuel.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Bouton de sauvegarde
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.gradientPrimary,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _updateProfile,
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_rounded, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Enregistrer les modifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}