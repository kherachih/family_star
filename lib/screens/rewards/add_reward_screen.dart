import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../models/reward.dart';

class AddRewardScreen extends StatefulWidget {
  final Reward? reward;

  const AddRewardScreen({super.key, this.reward});

  @override
  State<AddRewardScreen> createState() => _AddRewardScreenState();
}

class _AddRewardScreenState extends State<AddRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _starsCostController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.reward?.name ?? '');
    _descriptionController = TextEditingController(text: widget.reward?.description ?? '');
    _starsCostController = TextEditingController(
      text: widget.reward?.starsCost.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _starsCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reward == null ? 'Nouvelle Récompense' : 'Modifier la Récompense'),
        backgroundColor: Colors.amber,
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
                    labelText: 'Nom de la récompense',
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
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _starsCostController,
                  decoration: const InputDecoration(
                    labelText: 'Coût en étoiles',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.star, color: Colors.amber),
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
                        onPressed: _saveReward,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                        child: Text(widget.reward == null ? 'Ajouter' : 'Modifier'),
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

  Future<void> _saveReward() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final rewardsProvider = context.read<RewardsProvider>();

    final newReward = Reward(
      id: widget.reward?.id,
      parentId: authProvider.currentUser!.id,
      name: _nameController.text,
      description: _descriptionController.text,
      starsCost: int.parse(_starsCostController.text),
    );

    try {
      if (widget.reward == null) {
        await rewardsProvider.addReward(newReward);
      } else {
        await rewardsProvider.updateReward(newReward);
      }
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.reward == null
              ? 'Récompense ajoutée avec succès'
              : 'Récompense modifiée avec succès'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
}