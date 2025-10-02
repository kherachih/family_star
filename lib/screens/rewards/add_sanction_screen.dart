import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../models/sanction.dart';
import '../../models/duration_unit.dart';

class AddSanctionScreen extends StatefulWidget {
  final Sanction? sanction;

  const AddSanctionScreen({super.key, this.sanction});

  @override
  State<AddSanctionScreen> createState() => _AddSanctionScreenState();
}

class _AddSanctionScreenState extends State<AddSanctionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _starsCostController;
  late TextEditingController _durationValueController;
  DurationUnit? _selectedDurationUnit;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.sanction?.name ?? '');
    _starsCostController = TextEditingController(
      text: widget.sanction?.starsCost.toString() ?? '',
    );
    _durationValueController = TextEditingController(
      text: widget.sanction?.durationValue?.toString() ?? '',
    );
    _selectedDurationUnit = widget.sanction?.durationUnit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _starsCostController.dispose();
    _durationValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sanction == null ? 'Nouvelle Sanction' : 'Modifier la Sanction'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la sanction',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _starsCostController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre d\'étoiles négatives requises',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.star, color: Colors.red),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un coût';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Veuillez entrer un nombre valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Durée (optionnel)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _durationValueController,
                        decoration: const InputDecoration(
                          labelText: 'Valeur',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_selectedDurationUnit != null && (value == null || value.isEmpty)) {
                            return 'Veuillez entrer une valeur';
                          }
                          if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<DurationUnit>(
                        value: _selectedDurationUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unité',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: DurationUnit.hours,
                            child: Text('Heure(s)'),
                          ),
                          DropdownMenuItem(
                            value: DurationUnit.days,
                            child: Text('Jour(s)'),
                          ),
                          DropdownMenuItem(
                            value: DurationUnit.weeks,
                            child: Text('Semaine(s)'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDurationUnit = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveSanction,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text(widget.sanction == null ? 'Ajouter' : 'Modifier'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveSanction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final rewardsProvider = context.read<RewardsProvider>();

    final newSanction = Sanction(
      id: widget.sanction?.id,
      parentId: authProvider.currentUser!.id,
      name: _nameController.text,
      description: '', // Champ description laissé vide
      starsCost: int.parse(_starsCostController.text),
      durationValue: _durationValueController.text.isNotEmpty
          ? int.parse(_durationValueController.text)
          : null,
      durationUnit: _selectedDurationUnit,
    );

    try {
      if (widget.sanction == null) {
        await rewardsProvider.addSanction(newSanction);
      } else {
        await rewardsProvider.updateSanction(newSanction);
      }
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.sanction == null
              ? 'Sanction ajoutée avec succès'
              : 'Sanction modifiée avec succès'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}