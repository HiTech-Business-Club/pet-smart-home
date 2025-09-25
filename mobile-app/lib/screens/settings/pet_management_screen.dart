import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/firebase_service.dart';
import '../../models/pet.dart';
import '../../widgets/custom_button.dart';

class PetManagementScreen extends ConsumerWidget {
  const PetManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsStream = ref.watch(firebaseServiceProvider).getPets();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes animaux'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPetDialog(context, ref),
          ),
        ],
      ),
      body: StreamBuilder<List<Pet>>(
        stream: petsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pets = snapshot.data ?? [];

          if (pets.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(firebaseServiceProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                return _buildPetCard(context, ref, pet);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun animal enregistré',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ajoutez vos animaux de compagnie pour commencer à utiliser le système',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Ajouter mon premier animal',
              icon: Icons.add,
              onPressed: () => _showAddPetDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, WidgetRef ref, Pet pet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getPetColor(pet.species).withOpacity(0.1),
                  backgroundImage: pet.photoUrl != null 
                      ? NetworkImage(pet.photoUrl!)
                      : null,
                  child: pet.photoUrl == null
                      ? Icon(
                          _getPetIcon(pet.species),
                          size: 30,
                          color: _getPetColor(pet.species),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pet.speciesDisplayName}${pet.breed.isNotEmpty ? ' • ${pet.breed}' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (pet.age > 0 || pet.weight > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${pet.age > 0 ? pet.ageDisplayText : ''}${pet.age > 0 && pet.weight > 0 ? ' • ' : ''}${pet.weight > 0 ? pet.weightDisplayText : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditPetDialog(context, ref, pet);
                        break;
                      case 'delete':
                        _showDeletePetDialog(context, ref, pet);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Modifier'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informations d'identification
            if (pet.hasIdentification) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.nfc,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Identification',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (pet.hasRfidTag) ...[
                      Text(
                        'RFID: ${pet.rfidTag}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if (pet.hasBleMacAddress) ...[
                      Text(
                        'Bluetooth: ${pet.bleMacAddress}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aucune identification configurée',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showEditPetDialog(context, ref, pet),
                      child: const Text('Configurer'),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Statut
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pet.isActive 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pet.isActive ? Icons.check_circle : Icons.pause_circle,
                        size: 14,
                        color: pet.isActive ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pet.isActive ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: pet.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Ajouté le ${_formatDate(pet.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPetIcon(String species) {
    switch (species.toLowerCase()) {
      case 'cat':
        return Icons.pets;
      case 'dog':
        return Icons.pets;
      case 'rabbit':
        return Icons.cruelty_free;
      case 'bird':
        return Icons.flutter_dash;
      default:
        return Icons.pets;
    }
  }

  Color _getPetColor(String species) {
    switch (species.toLowerCase()) {
      case 'cat':
        return Colors.orange;
      case 'dog':
        return Colors.brown;
      case 'rabbit':
        return Colors.grey;
      case 'bird':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showAddPetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => PetFormDialog(
        onPetSaved: (pet) async {
          try {
            await ref.read(firebaseServiceProvider).addPet(pet);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${pet.name} a été ajouté avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditPetDialog(BuildContext context, WidgetRef ref, Pet pet) {
    showDialog(
      context: context,
      builder: (context) => PetFormDialog(
        pet: pet,
        onPetSaved: (updatedPet) async {
          try {
            await ref.read(firebaseServiceProvider).updatePet(updatedPet);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${updatedPet.name} a été modifié avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeletePetDialog(BuildContext context, WidgetRef ref, Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'animal'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${pet.name} ?\n\n'
          'Cette action est irréversible et supprimera également tous les horaires et logs associés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(firebaseServiceProvider).deletePet(pet.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${pet.name} a été supprimé'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class PetFormDialog extends StatefulWidget {
  final Pet? pet;
  final Function(Pet) onPetSaved;

  const PetFormDialog({
    super.key,
    this.pet,
    required this.onPetSaved,
  });

  @override
  State<PetFormDialog> createState() => _PetFormDialogState();
}

class _PetFormDialogState extends State<PetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _rfidController;
  late TextEditingController _bleController;
  
  String _selectedSpecies = 'cat';
  bool _isActive = true;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _species = [
    {'value': 'cat', 'label': 'Chat', 'icon': Icons.pets},
    {'value': 'dog', 'label': 'Chien', 'icon': Icons.pets},
    {'value': 'rabbit', 'label': 'Lapin', 'icon': Icons.cruelty_free},
    {'value': 'bird', 'label': 'Oiseau', 'icon': Icons.flutter_dash},
    {'value': 'other', 'label': 'Autre', 'icon': Icons.pets},
  ];

  @override
  void initState() {
    super.initState();
    
    final pet = widget.pet;
    _nameController = TextEditingController(text: pet?.name ?? '');
    _breedController = TextEditingController(text: pet?.breed ?? '');
    _ageController = TextEditingController(text: pet?.age.toString() ?? '');
    _weightController = TextEditingController(text: pet?.weight.toString() ?? '');
    _rfidController = TextEditingController(text: pet?.rfidTag ?? '');
    _bleController = TextEditingController(text: pet?.bleMacAddress ?? '');
    
    if (pet != null) {
      _selectedSpecies = pet.species;
      _isActive = pet.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _rfidController.dispose();
    _bleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.pet != null;
    
    return AlertDialog(
      title: Text(isEditing ? 'Modifier l\'animal' : 'Ajouter un animal'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nom
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir un nom';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Espèce
                DropdownButtonFormField<String>(
                  value: _selectedSpecies,
                  decoration: const InputDecoration(
                    labelText: 'Espèce *',
                    border: OutlineInputBorder(),
                  ),
                  items: _species.map((species) => DropdownMenuItem<String>(
                    value: species['value'],
                    child: Row(
                      children: [
                        Icon(species['icon'], size: 20),
                        const SizedBox(width: 8),
                        Text(species['label']),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSpecies = value!;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Race
                TextFormField(
                  controller: _breedController,
                  decoration: const InputDecoration(
                    labelText: 'Race (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Âge et poids
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: 'Âge (mois)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final age = int.tryParse(value);
                            if (age == null || age < 0 || age > 300) {
                              return 'Âge invalide';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: 'Poids (kg)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final weight = double.tryParse(value);
                            if (weight == null || weight < 0 || weight > 100) {
                              return 'Poids invalide';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Section identification
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Identification (optionnel)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configurez les moyens d\'identification pour l\'accès automatique',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Tag RFID
                TextFormField(
                  controller: _rfidController,
                  decoration: const InputDecoration(
                    labelText: 'Tag RFID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.nfc),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length < 8 || value.length > 16) {
                        return 'Tag RFID invalide (8-16 caractères)';
                      }
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Adresse Bluetooth
                TextFormField(
                  controller: _bleController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse Bluetooth',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bluetooth),
                    hintText: 'XX:XX:XX:XX:XX:XX',
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final regex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
                      if (!regex.hasMatch(value)) {
                        return 'Adresse Bluetooth invalide';
                      }
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Statut actif
                SwitchListTile(
                  title: const Text('Animal actif'),
                  subtitle: const Text('L\'animal peut utiliser le système'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _savePet,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final pet = Pet(
        id: widget.pet?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        species: _selectedSpecies,
        breed: _breedController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 0,
        weight: double.tryParse(_weightController.text) ?? 0.0,
        rfidTag: _rfidController.text.trim().isEmpty ? null : _rfidController.text.trim(),
        bleMacAddress: _bleController.text.trim().isEmpty ? null : _bleController.text.trim(),
        isActive: _isActive,
        createdAt: widget.pet?.createdAt ?? now,
        updatedAt: now,
      );

      widget.onPetSaved(pet);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}