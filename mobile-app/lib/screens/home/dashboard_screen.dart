import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/firebase_service.dart';
import '../../models/device.dart';
import '../../models/pet.dart';
import '../../widgets/status_card.dart';
import '../feeder/feeder_control_screen.dart';
import '../door/door_control_screen.dart';
import '../settings/pet_management_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardHomeScreen(),
    const FeederControlScreen(),
    const DoorControlScreen(),
    const PetManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_outlined),
            activeIcon: Icon(Icons.restaurant),
            label: 'Distributeur',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.door_front_door_outlined),
            activeIcon: Icon(Icons.door_front_door),
            label: 'Porte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            activeIcon: Icon(Icons.pets),
            label: 'Animaux',
          ),
        ],
      ),
    );
  }
}

class DashboardHomeScreen extends ConsumerWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesStream = ref.watch(firebaseServiceProvider).getDevices();
    final petsStream = ref.watch(firebaseServiceProvider).getPets();
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour ${user?.displayName ?? 'Utilisateur'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Text(
              'Comment vont vos animaux ?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implémenter les notifications
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(firebaseServiceProvider).signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Paramètres'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Déconnexion'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Force refresh des données
          ref.invalidate(firebaseServiceProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Aperçu rapide
              Text(
                'Aperçu rapide',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Cartes de statut
              StreamBuilder<List<Device>>(
                stream: devicesStream,
                builder: (context, deviceSnapshot) {
                  return StreamBuilder<List<Pet>>(
                    stream: petsStream,
                    builder: (context, petSnapshot) {
                      if (deviceSnapshot.connectionState == ConnectionState.waiting ||
                          petSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final devices = deviceSnapshot.data ?? [];
                      final pets = petSnapshot.data ?? [];

                      return Column(
                        children: [
                          // Statistiques générales
                          Row(
                            children: [
                              Expanded(
                                child: StatusCard(
                                  title: 'Appareils',
                                  value: '${devices.length}',
                                  subtitle: '${devices.where((d) => d.isOnline).length} en ligne',
                                  icon: Icons.devices,
                                  color: devices.any((d) => d.needsAttention) 
                                      ? Colors.orange 
                                      : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatusCard(
                                  title: 'Animaux',
                                  value: '${pets.length}',
                                  subtitle: '${pets.where((p) => p.isActive).length} actifs',
                                  icon: Icons.pets,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Appareils individuels
                          ...devices.map((device) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DeviceStatusCard(device: device),
                          )),
                        ],
                      );
                    },
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Section Activité récente
              Text(
                'Activité récente',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Liste des activités récentes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildActivityItem(
                        context,
                        icon: Icons.restaurant,
                        title: 'Distribution de nourriture',
                        subtitle: 'Minou - 50g distribués',
                        time: 'Il y a 2h',
                        color: Colors.green,
                      ),
                      const Divider(),
                      _buildActivityItem(
                        context,
                        icon: Icons.door_front_door,
                        title: 'Accès autorisé',
                        subtitle: 'Rex - Entrée par RFID',
                        time: 'Il y a 4h',
                        color: Colors.blue,
                      ),
                      const Divider(),
                      _buildActivityItem(
                        context,
                        icon: Icons.warning,
                        title: 'Niveau bas détecté',
                        subtitle: 'Distributeur cuisine - 15% restant',
                        time: 'Il y a 6h',
                        color: Colors.orange,
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
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.restaurant,
                      title: 'Nourrir maintenant',
                      onTap: () {
                        // TODO: Action rapide de distribution
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      icon: Icons.door_front_door,
                      title: 'Ouvrir la porte',
                      onTap: () {
                        // TODO: Action rapide d'ouverture
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeviceStatusCard extends StatelessWidget {
  final Device device;

  const DeviceStatusCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icône du type d'appareil
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                _getDeviceIcon(),
                color: _getStatusColor(),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Informations de l'appareil
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device.typeDisplayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        device.isOnline ? Icons.circle : Icons.circle_outlined,
                        size: 12,
                        color: _getStatusColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        device.statusDisplayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Niveau de batterie
            Column(
              children: [
                Icon(
                  _getBatteryIcon(),
                  color: _getBatteryColor(),
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  '${device.batteryLevel}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getBatteryColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon() {
    switch (device.type) {
      case DeviceType.feeder:
        return Icons.restaurant;
      case DeviceType.door:
        return Icons.door_front_door;
      case DeviceType.combo:
        return Icons.home;
    }
  }

  Color _getStatusColor() {
    switch (device.status) {
      case DeviceStatus.online:
        return Colors.green;
      case DeviceStatus.offline:
        return Colors.grey;
      case DeviceStatus.error:
        return Colors.red;
      case DeviceStatus.maintenance:
        return Colors.orange;
    }
  }

  IconData _getBatteryIcon() {
    if (device.batteryLevel > 75) return Icons.battery_full;
    if (device.batteryLevel > 50) return Icons.battery_5_bar;
    if (device.batteryLevel > 25) return Icons.battery_3_bar;
    if (device.batteryLevel > 10) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }

  Color _getBatteryColor() {
    if (device.batteryLevel > 25) return Colors.green;
    if (device.batteryLevel > 10) return Colors.orange;
    return Colors.red;
  }
}