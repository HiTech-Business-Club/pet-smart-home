import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/firebase_service.dart';
import '../../models/device.dart';
import '../../models/pet.dart';
import '../../models/feeding_schedule.dart';
import '../../widgets/status_card.dart';
import '../../widgets/custom_button.dart';
import 'feeding_schedule_screen.dart';

class FeederControlScreen extends ConsumerStatefulWidget {
  const FeederControlScreen({super.key});

  @override
  ConsumerState<FeederControlScreen> createState() => _FeederControlScreenState();
}

class _FeederControlScreenState extends ConsumerState<FeederControlScreen> {
  int _selectedAmount = 50;
  String? _selectedPetId;
  bool _isFeeding = false;

  @override
  Widget build(BuildContext context) {
    final devicesStream = ref.watch(firebaseServiceProvider).getDevices();
    final petsStream = ref.watch(firebaseServiceProvider).getPets();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Distributeur de nourriture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FeedingScheduleScreen(),
                ),
              );
            },
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
          final feederDevices = devices.where((d) => 
              d.type == DeviceType.feeder || d.type == DeviceType.combo).toList();

          if (feederDevices.isEmpty) {
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
                      // Statut des distributeurs
                      Text(
                        'État des distributeurs',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      ...feederDevices.map((device) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDeviceStatusCard(device),
                      )),
                      
                      const SizedBox(height: 24),
                      
                      // Contrôle manuel
                      Text(
                        'Distribution manuelle',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sélection de l'animal
                              Text(
                                'Animal (optionnel)',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              DropdownButtonFormField<String>(
                                value: _selectedPetId,
                                decoration: const InputDecoration(
                                  hintText: 'Sélectionner un animal',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Aucun animal spécifique'),
                                  ),
                                  ...pets.map((pet) => DropdownMenuItem<String>(
                                    value: pet.id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          pet.species == 'cat' ? Icons.pets : Icons.pets,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(pet.name),
                                      ],
                                    ),
                                  )),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPetId = value;
                                  });
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Sélection de la quantité
                              Text(
                                'Quantité: ${_selectedAmount}g',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              Slider(
                                value: _selectedAmount.toDouble(),
                                min: 10,
                                max: 200,
                                divisions: 19,
                                label: '${_selectedAmount}g',
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAmount = value.round();
                                  });
                                },
                              ),
                              
                              // Boutons de quantité rapide
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildQuickAmountButton(25),
                                  _buildQuickAmountButton(50),
                                  _buildQuickAmountButton(100),
                                  _buildQuickAmountButton(150),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Bouton de distribution
                              CustomButton(
                                text: 'Distribuer maintenant',
                                icon: Icons.restaurant,
                                onPressed: _isFeeding ? null : _feedNow,
                                isLoading: _isFeeding,
                                width: double.infinity,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
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
                              title: 'Programmer',
                              subtitle: 'Horaires de repas',
                              icon: Icons.schedule,
                              color: Colors.blue,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const FeedingScheduleScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ActionCard(
                              title: 'Calibrer',
                              subtitle: 'Balance',
                              icon: Icons.tune,
                              color: Colors.orange,
                              onTap: _calibrateScale,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ActionCard(
                              title: 'Historique',
                              subtitle: 'Distributions',
                              icon: Icons.history,
                              color: Colors.green,
                              onTap: _showFeedingHistory,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ActionCard(
                              title: 'Maintenance',
                              subtitle: 'Nettoyage',
                              icon: Icons.build,
                              color: Colors.purple,
                              onTap: _performMaintenance,
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
            Icons.restaurant_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun distributeur trouvé',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez un appareil distributeur pour commencer',
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

  Widget _buildDeviceStatusCard(Device device) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (device.status) {
      case DeviceStatus.online:
        statusColor = Colors.green;
        statusText = 'En ligne';
        statusIcon = Icons.check_circle;
        break;
      case DeviceStatus.offline:
        statusColor = Colors.grey;
        statusText = 'Hors ligne';
        statusIcon = Icons.offline_bolt;
        break;
      case DeviceStatus.error:
        statusColor = Colors.red;
        statusText = 'Erreur';
        statusIcon = Icons.error;
        break;
      case DeviceStatus.maintenance:
        statusColor = Colors.orange;
        statusText = 'Maintenance';
        statusIcon = Icons.build;
        break;
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
                  Icons.restaurant,
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
                    title: 'Niveau nourriture',
                    value: '75', // TODO: Valeur réelle
                    unit: '%',
                    icon: Icons.grain,
                    color: Colors.green,
                    progress: 0.75,
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
                    title: 'Dernière distribution',
                    content: 'Il y a 2h', // TODO: Valeur réelle
                    icon: Icons.access_time,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InfoCard(
                    title: 'Signal WiFi',
                    content: '${device.lastSeenDisplayText}',
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

  Widget _buildQuickAmountButton(int amount) {
    final isSelected = _selectedAmount == amount;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAmount = amount;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${amount}g',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _feedNow() async {
    setState(() {
      _isFeeding = true;
    });

    try {
      // TODO: Envoyer la commande de distribution
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Distribution de ${_selectedAmount}g en cours...'),
            backgroundColor: Colors.green,
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
          _isFeeding = false;
        });
      }
    }
  }

  void _calibrateScale() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calibrer la balance'),
        content: const Text(
          'Cette opération va calibrer la balance du distributeur. '
          'Assurez-vous que le distributeur est vide avant de continuer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Envoyer la commande de calibration
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calibration en cours...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Calibrer'),
          ),
        ],
      ),
    );
  }

  void _showFeedingHistory() {
    // TODO: Implémenter l'historique des distributions
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Historique des distributions - À implémenter'),
      ),
    );
  }

  void _performMaintenance() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maintenance du distributeur'),
        content: const Text(
          'Cette opération va effectuer un cycle de nettoyage du distributeur. '
          'Cela peut prendre quelques minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Envoyer la commande de maintenance
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maintenance en cours...'),
                  backgroundColor: Colors.purple,
                ),
              );
            },
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );
  }
}