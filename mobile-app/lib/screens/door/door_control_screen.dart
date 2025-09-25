import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/firebase_service.dart';
import '../../models/device.dart';
import '../../models/pet.dart';
import '../../models/access_log.dart';
import '../../widgets/status_card.dart';
import '../../widgets/custom_button.dart';

class DoorControlScreen extends ConsumerStatefulWidget {
  const DoorControlScreen({super.key});

  @override
  ConsumerState<DoorControlScreen> createState() => _DoorControlScreenState();
}

class _DoorControlScreenState extends ConsumerState<DoorControlScreen> {
  String? _selectedDeviceId;
  bool _isOperating = false;

  @override
  Widget build(BuildContext context) {
    final devicesStream = ref.watch(firebaseServiceProvider).getDevices();
    final petsStream = ref.watch(firebaseServiceProvider).getPets();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Porte intelligente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showAccessHistory(),
          ),
        ],
      ),
      body: StreamBuilder<List<Device>>(
        stream: devicesStream,
        builder: (context, deviceSnapshot) {
          if (deviceSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = deviceSnapshot.data ?? [];
          final doorDevices = devices.where((d) => 
              d.type == DeviceType.door || d.type == DeviceType.combo).toList();

          if (doorDevices.isEmpty) {
            return _buildNoDevicesView();
          }

          return StreamBuilder<List<Pet>>(
            stream: petsStream,
            builder: (context, petSnapshot) {
              final pets = petSnapshot.data ?? [];
              
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(firebaseServiceProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statut des portes
                      Text(
                        'État des portes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      ...doorDevices.map((device) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDoorStatusCard(device),
                      )),
                      
                      const SizedBox(height: 24),
                      
                      // Contrôles manuels
                      Text(
                        'Contrôles manuels',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Ouvrir',
                                      icon: Icons.lock_open,
                                      backgroundColor: Colors.green,
                                      onPressed: _isOperating ? null : () => _operateDoor(true),
                                      isLoading: _isOperating,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Fermer',
                                      icon: Icons.lock,
                                      backgroundColor: Colors.red,
                                      onPressed: _isOperating ? null : () => _operateDoor(false),
                                      isLoading: _isOperating,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Verrouiller',
                                      icon: Icons.lock_outline,
                                      isOutlined: true,
                                      onPressed: _isOperating ? null : () => _lockDoor(true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Déverrouiller',
                                      icon: Icons.lock_open_outlined,
                                      isOutlined: true,
                                      onPressed: _isOperating ? null : () => _lockDoor(false),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Animaux autorisés
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Animaux autorisés',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddPetDialog(pets),
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildAuthorizedPetsList(pets),
                      
                      const SizedBox(height: 24),
                      
                      // Activité récente
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Activité récente',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showAccessHistory(),
                            child: const Text('Voir tout'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildRecentActivity(pets),
                      
                      const SizedBox(height: 24),
                      
                      // Actions rapides
                      Text(
                        'Actions rapides',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ActionCard(
                              title: 'Statistiques',
                              subtitle: 'Accès et passages',
                              icon: Icons.analytics,
                              color: Colors.blue,
                              onTap: _showStatistics,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ActionCard(
                              title: 'Paramètres',
                              subtitle: 'Configuration',
                              icon: Icons.settings,
                              color: Colors.orange,
                              onTap: _showSettings,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoDevicesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.door_front_door_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune porte intelligente trouvée',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez un appareil porte intelligente pour commencer',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Ajouter un appareil',
            icon: Icons.add,
            onPressed: () {
              // TODO: Navigation vers l'ajout d'appareil
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDoorStatusCard(Device device) {
    // TODO: Récupérer le vrai statut de la porte
    final bool isDoorOpen = false; // Exemple
    final bool isLocked = false; // Exemple
    
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isLocked) {
      statusColor = Colors.red;
      statusText = 'Verrouillée';
      statusIcon = Icons.lock;
    } else if (isDoorOpen) {
      statusColor = Colors.orange;
      statusText = 'Ouverte';
      statusIcon = Icons.lock_open;
    } else {
      statusColor = Colors.green;
      statusText = 'Fermée';
      statusIcon = Icons.door_front_door;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.door_front_door,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    device.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'Accès aujourd\'hui',
                    value: '12', // TODO: Valeur réelle
                    unit: '',
                    icon: Icons.login,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'Batterie',
                    value: device.batteryLevel.toString(),
                    unit: '%',
                    icon: Icons.battery_full,
                    color: device.batteryLevel > 20 ? Colors.green : Colors.red,
                    progress: device.batteryLevel / 100,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'Dernier accès',
                    content: 'Il y a 1h', // TODO: Valeur réelle
                    icon: Icons.access_time,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InfoCard(
                    title: 'Signal WiFi',
                    content: device.lastSeenDisplayText,
                    icon: Icons.wifi,
                    color: device.isOnline ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorizedPetsList(List<Pet> pets) {
    // TODO: Filtrer les animaux autorisés pour cette porte
    final authorizedPets = pets.take(3).toList(); // Exemple

    if (authorizedPets.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.pets_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun animal autorisé',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajoutez des animaux pour leur donner accès',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: authorizedPets.asMap().entries.map((entry) {
          final index = entry.key;
          final pet = entry.value;
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.1),
              child: Icon(
                pet.species == 'cat' ? Icons.pets : Icons.pets,
                color: Colors.green,
              ),
            ),
            title: Text(pet.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.speciesDisplayName),
                if (pet.hasRfidTag || pet.hasBleMacAddress)
                  Text(
                    '${pet.hasRfidTag ? "RFID" : ""}${pet.hasRfidTag && pet.hasBleMacAddress ? " + " : ""}${pet.hasBleMacAddress ? "BLE" : ""}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editPetAccess(pet);
                    break;
                  case 'remove':
                    _removePetAccess(pet);
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
                  value: 'remove',
                  child: ListTile(
                    leading: Icon(Icons.remove_circle, color: Colors.red),
                    title: Text('Retirer l\'accès', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivity(List<Pet> pets) {
    // TODO: Récupérer la vraie activité récente
    final recentLogs = <AccessLog>[]; // Exemple vide

    if (recentLogs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune activité récente',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: recentLogs.take(5).map((log) {
          final pet = pets.firstWhere(
            (p) => p.id == log.petId,
            orElse: () => Pet(
              id: '',
              name: 'Animal inconnu',
              species: 'unknown',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          Color statusColor;
          IconData statusIcon;

          switch (log.status) {
            case AccessStatus.success:
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
              break;
            case AccessStatus.denied:
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
              break;
            case AccessStatus.error:
            case AccessStatus.timeout:
              statusColor = Colors.orange;
              statusIcon = Icons.warning;
              break;
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            title: Text(pet.name.isNotEmpty ? pet.name : 'Accès non identifié'),
            subtitle: Text(
              '${log.directionDisplayName} • ${log.methodDisplayName} • ${log.timestampDisplayText}',
            ),
            trailing: Text(
              log.statusDisplayName,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _operateDoor(bool open) async {
    setState(() {
      _isOperating = true;
    });

    try {
      // TODO: Envoyer la commande d'ouverture/fermeture
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(open ? 'Porte en cours d\'ouverture...' : 'Porte en cours de fermeture...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOperating = false;
        });
      }
    }
  }

  Future<void> _lockDoor(bool lock) async {
    try {
      // TODO: Envoyer la commande de verrouillage/déverrouillage
      await Future.delayed(const Duration(seconds: 1)); // Simulation
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lock ? 'Porte verrouillée' : 'Porte déverrouillée'),
            backgroundColor: lock ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddPetDialog(List<Pet> pets) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Autoriser un animal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: pets.map((pet) => ListTile(
            leading: CircleAvatar(
              child: Icon(
                pet.species == 'cat' ? Icons.pets : Icons.pets,
              ),
            ),
            title: Text(pet.name),
            subtitle: Text(pet.speciesDisplayName),
            onTap: () {
              Navigator.of(context).pop();
              _addPetAccess(pet);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _addPetAccess(Pet pet) {
    // TODO: Implémenter l'ajout d'accès pour un animal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Accès accordé à ${pet.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editPetAccess(Pet pet) {
    // TODO: Implémenter la modification d'accès
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modification de l\'accès pour ${pet.name} - À implémenter'),
      ),
    );
  }

  void _removePetAccess(Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer l\'accès'),
        content: Text('Êtes-vous sûr de vouloir retirer l\'accès à ${pet.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Retirer l'accès
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Accès retiré pour ${pet.name}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  void _showAccessHistory() {
    // TODO: Implémenter l'historique des accès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Historique des accès - À implémenter'),
      ),
    );
  }

  void _showStatistics() {
    // TODO: Implémenter les statistiques
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Statistiques - À implémenter'),
      ),
    );
  }

  void _showSettings() {
    // TODO: Implémenter les paramètres
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètres - À implémenter'),
      ),
    );
  }
}