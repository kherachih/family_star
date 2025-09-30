import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/avatars.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthdayStarsController = TextEditingController(text: '10');

  DateTime? _birthDate;
  String _selectedGender = 'boy'; // 'boy' ou 'girl'
  int _selectedAvatarIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _birthdayStarsController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      locale: const Locale('fr', 'FR'),
      helpText: 'Sélectionner la date de naissance',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
    );

    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  int get _calculatedAge {
    if (_birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - _birthDate!.year;
    if (now.month < _birthDate!.month ||
        (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner la date de naissance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: utilisateur non connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await childrenProvider.addChild(
      parentId: authProvider.currentUser!.id,
      name: _nameController.text.trim(),
      age: _calculatedAge,
      birthDate: _birthDate!,
      gender: _selectedGender,
      avatarIndex: _selectedAvatarIndex,
      birthdayStars: int.parse(_birthdayStarsController.text),
    );

    if (success && mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_nameController.text.trim()} a été ajouté avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatars = ChildAvatars.getAvatarsByGender(_selectedGender);
    final selectedAvatar = avatars[_selectedAvatarIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un enfant'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Consumer<ChildrenProvider>(
            builder: (context, childrenProvider, child) {
              return TextButton(
                onPressed: childrenProvider.isLoading ? null : _handleSubmit,
                child: childrenProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'SAUVEGARDER',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChildrenProvider>(
        builder: (context, childrenProvider, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar display
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurple[50],
                        border: Border.all(
                          color: Colors.deepPurple,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          selectedAvatar,
                          style: const TextStyle(fontSize: 60),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Gender selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Genre',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedGender = 'boy';
                                      _selectedAvatarIndex = 0;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: _selectedGender == 'boy'
                                        ? Colors.blue[50]
                                        : null,
                                    side: BorderSide(
                                      color: _selectedGender == 'boy'
                                          ? Colors.blue
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  icon: const Text('👦', style: TextStyle(fontSize: 24)),
                                  label: const Text('Garçon'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedGender = 'girl';
                                      _selectedAvatarIndex = 0;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: _selectedGender == 'girl'
                                        ? Colors.pink[50]
                                        : null,
                                    side: BorderSide(
                                      color: _selectedGender == 'girl'
                                          ? Colors.pink
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  icon: const Text('👧', style: TextStyle(fontSize: 24)),
                                  label: const Text('Fille'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Avatar selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Choisir un avatar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: avatars.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedAvatarIndex = index;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedAvatarIndex == index
                                        ? Colors.deepPurple[100]
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedAvatarIndex == index
                                          ? Colors.deepPurple
                                          : Colors.grey[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      avatars[index],
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom de l\'enfant',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez saisir le prénom';
                      }
                      if (value.trim().length < 2) {
                        return 'Le prénom doit contenir au moins 2 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Birth date selector
                  InkWell(
                    onTap: _selectBirthDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cake, color: Colors.deepPurple),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date de naissance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _birthDate != null
                                      ? DateFormat('dd/MM/yyyy', 'fr_FR').format(_birthDate!)
                                      : 'Sélectionner la date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _birthDate != null ? Colors.black : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.calendar_today, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Display calculated age
                  if (_birthDate != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Âge calculé: $_calculatedAge ans',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Birthday stars field
                  TextFormField(
                    controller: _birthdayStarsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Étoiles d\'anniversaire',
                      prefixIcon: Icon(Icons.star),
                      border: OutlineInputBorder(),
                      helperText: 'Nombre d\'étoiles reçues chaque anniversaire',
                      suffixText: '⭐',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez saisir le nombre d\'étoiles';
                      }
                      final stars = int.tryParse(value);
                      if (stars == null) {
                        return 'Veuillez saisir un nombre valide';
                      }
                      if (stars < 1 || stars > 50) {
                        return 'Le nombre d\'étoiles doit être entre 1 et 50';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Error message
                  if (childrenProvider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              childrenProvider.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton.icon(
                    onPressed: childrenProvider.isLoading ? null : _handleSubmit,
                    icon: childrenProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Ajouter l\'enfant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}