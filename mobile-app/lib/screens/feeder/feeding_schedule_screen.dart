import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as material show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/firebase_service.dart';
import '../../models/device.dart';
import '../../models/pet.dart';
import '../../models/feeding_schedule.dart';
import '../../widgets/custom_button.dart';

class FeedingScheduleScreen extends ConsumerStatefulWidget {
  const FeedingScheduleScreen({super.key});

  @override
  ConsumerState<FeedingScheduleScreen> createState() => _FeedingScheduleScreenState();
}

class _FeedingScheduleScreenState extends ConsumerState<FeedingScheduleScreen> {
  String? _selectedDeviceId;
  List<FeedingSchedule> _schedules = [];

  @override
  Widget build(BuildContext context) {
    final devicesStream = ref.watch(firebaseServiceProvider).getDevices();
    final petsStream = ref.watch(firebaseServiceProvider).getPets();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horaires de repas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddScheduleDialog(),
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
              
              return Column(
                children: [
                  // Sélecteur d'appareil
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      value: _selectedDeviceId,
                      decoration: const InputDecoration(
                        labelText: 'Sélectionner un distributeur',
                        border: OutlineInputBorder(),
                      ),
                      items: feederDevices.map((device) => DropdownMenuItem<String>(
                        value: device.id,
                        child: Row(
                          children: [
                            Icon(
                              Icons.restaurant,
                              size: 20,
                              color: device.isOnline ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(device.name),
                          ],
                        ),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDeviceId = value;
                        });
                        if (value != null) {
                          _loadSchedules(value);
                        }
                      },
                    ),
                  ),
                  
                  // Liste des horaires
                  Expanded(
                    child: _selectedDeviceId == null
                        ? _buildSelectDeviceView()
                        : _buildSchedulesList(pets),
                  ),
                ],
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
            Icons.schedule,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun distributeur disponible',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez un distributeur pour programmer des horaires',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectDeviceView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_upward,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Sélectionnez un distributeur',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez un distributeur pour voir ses horaires',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesList(List<Pet> pets) {
    if (_schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun horaire programmé',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur + pour ajouter un horaire',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Ajouter un horaire',
              icon: Icons.add,
              onPressed: () => _showAddScheduleDialog(),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        final pet = pets.firstWhere(
          (p) => p.id == schedule.petId,
          orElse: () => Pet(
            id: '',
            name: 'Animal inconnu',
            species: 'unknown',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: schedule.isActive 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              child: Icon(
                Icons.schedule,
                color: schedule.isActive ? Colors.green : Colors.grey,
              ),
            ),
            title: Text(
              schedule.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: schedule.isActive ? null : Colors.grey,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Animal: ${pet.name}'),
                Text('${schedule.feedingTimes.length} repas programmés'),
                Text('Total journalier: ${schedule.totalDailyAmount}g'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditScheduleDialog(schedule);
                    break;
                  case 'toggle':
                    _toggleSchedule(schedule);
                    break;
                  case 'delete':
                    _deleteSchedule(schedule);
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
                PopupMenuItem(
                  value: 'toggle',
                  child: ListTile(
                    leading: Icon(schedule.isActive ? Icons.pause : Icons.play_arrow),
                    title: Text(schedule.isActive ? 'Désactiver' : 'Activer'),
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
            onTap: () => _showScheduleDetails(schedule, pet),
          ),
        );
      },
    );
  }

  void _loadSchedules(String deviceId) {
    // TODO: Charger les horaires depuis Firebase
    setState(() {
      _schedules = [
        // Exemple de données
        FeedingSchedule(
          id: '1',
          deviceId: deviceId,
          petId: 'pet1',
          name: 'Repas de Minou',
          feedingTimes: [
            FeedingTime(
              id: '1',
              time: const TimeOfDay(hour: 8, minute: 0),
              amount: 50,
              daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
            ),
            FeedingTime(
              id: '2',
              time: const TimeOfDay(hour: 18, minute: 0),
              amount: 50,
              daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
            ),
          ],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });
  }

  void _showAddScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AddScheduleDialog(
        deviceId: _selectedDeviceId!,
        onScheduleAdded: (schedule) {
          setState(() {
            _schedules.add(schedule);
          });
        },
      ),
    );
  }

  void _showEditScheduleDialog(FeedingSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => EditScheduleDialog(
        schedule: schedule,
        onScheduleUpdated: (updatedSchedule) {
          setState(() {
            final index = _schedules.indexWhere((s) => s.id == updatedSchedule.id);
            if (index != -1) {
              _schedules[index] = updatedSchedule;
            }
          });
        },
      ),
    );
  }

  void _showScheduleDetails(FeedingSchedule schedule, Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schedule.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Animal: ${pet.name}'),
            const SizedBox(height: 8),
            Text('État: ${schedule.isActive ? "Actif" : "Inactif"}'),
            const SizedBox(height: 8),
            Text('Nombre de repas: ${schedule.feedingTimes.length}'),
            const SizedBox(height: 8),
            Text('Total journalier: ${schedule.totalDailyAmount}g'),
            const SizedBox(height: 16),
            const Text('Horaires:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...schedule.feedingTimes.map((time) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text('• ${time.timeDisplayText} - ${time.amountDisplayText} (${time.daysDisplayText})'),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditScheduleDialog(schedule);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _toggleSchedule(FeedingSchedule schedule) {
    setState(() {
      final index = _schedules.indexWhere((s) => s.id == schedule.id);
      if (index != -1) {
        _schedules[index] = schedule.copyWith(
          isActive: !schedule.isActive,
          updatedAt: DateTime.now(),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          schedule.isActive 
              ? 'Horaire désactivé' 
              : 'Horaire activé',
        ),
      ),
    );
  }

  void _deleteSchedule(FeedingSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'horaire'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${schedule.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _schedules.removeWhere((s) => s.id == schedule.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Horaire supprimé')),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class AddScheduleDialog extends ConsumerStatefulWidget {
  final String deviceId;
  final Function(FeedingSchedule) onScheduleAdded;

  const AddScheduleDialog({
    super.key,
    required this.deviceId,
    required this.onScheduleAdded,
  });

  @override
  ConsumerState<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends ConsumerState<AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedPetId;
  final List<FeedingTime> _feedingTimes = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petsStream = ref.watch(firebaseServiceProvider).getPets();

    return AlertDialog(
      title: const Text('Nouvel horaire'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'horaire',
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
              
              StreamBuilder<List<Pet>>(
                stream: petsStream,
                builder: (context, snapshot) {
                  final pets = snapshot.data ?? [];
                  
                  return DropdownButtonFormField<String>(
                    value: _selectedPetId,
                    decoration: const InputDecoration(
                      labelText: 'Animal',
                      border: OutlineInputBorder(),
                    ),
                    items: pets.map((pet) => DropdownMenuItem<String>(
                      value: pet.id,
                      child: Text(pet.name),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPetId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner un animal';
                      }
                      return null;
                    },
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Horaires de repas'),
                  TextButton.icon(
                    onPressed: _addFeedingTime,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              
              if (_feedingTimes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Aucun horaire ajouté',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...List.generate(_feedingTimes.length, (index) {
                  final time = _feedingTimes[index];
                  return ListTile(
                    dense: true,
                    title: Text('${time.timeDisplayText} - ${time.amountDisplayText}'),
                    subtitle: Text(time.daysDisplayText),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _feedingTimes.removeAt(index);
                        });
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _feedingTimes.isEmpty ? null : _saveSchedule,
          child: const Text('Créer'),
        ),
      ],
    );
  }

  void _addFeedingTime() {
    showDialog(
      context: context,
      builder: (context) => AddFeedingTimeDialog(
        onTimeAdded: (feedingTime) {
          setState(() {
            _feedingTimes.add(feedingTime);
          });
        },
      ),
    );
  }

  void _saveSchedule() {
    if (_formKey.currentState!.validate()) {
      final schedule = FeedingSchedule(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: widget.deviceId,
        petId: _selectedPetId!,
        name: _nameController.text.trim(),
        feedingTimes: _feedingTimes,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onScheduleAdded(schedule);
      Navigator.of(context).pop();
    }
  }
}

class EditScheduleDialog extends StatefulWidget {
  final FeedingSchedule schedule;
  final Function(FeedingSchedule) onScheduleUpdated;

  const EditScheduleDialog({
    super.key,
    required this.schedule,
    required this.onScheduleUpdated,
  });

  @override
  State<EditScheduleDialog> createState() => _EditScheduleDialogState();
}

class _EditScheduleDialogState extends State<EditScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late List<FeedingTime> _feedingTimes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.schedule.name);
    _feedingTimes = List.from(widget.schedule.feedingTimes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier l\'horaire'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'horaire',
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
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Horaires de repas'),
                  TextButton.icon(
                    onPressed: _addFeedingTime,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              
              ...List.generate(_feedingTimes.length, (index) {
                final time = _feedingTimes[index];
                return ListTile(
                  dense: true,
                  title: Text('${time.timeDisplayText} - ${time.amountDisplayText}'),
                  subtitle: Text(time.daysDisplayText),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _feedingTimes.removeAt(index);
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveSchedule,
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }

  void _addFeedingTime() {
    showDialog(
      context: context,
      builder: (context) => AddFeedingTimeDialog(
        onTimeAdded: (feedingTime) {
          setState(() {
            _feedingTimes.add(feedingTime);
          });
        },
      ),
    );
  }

  void _saveSchedule() {
    if (_formKey.currentState!.validate()) {
      final updatedSchedule = widget.schedule.copyWith(
        name: _nameController.text.trim(),
        feedingTimes: _feedingTimes,
        updatedAt: DateTime.now(),
      );

      widget.onScheduleUpdated(updatedSchedule);
      Navigator.of(context).pop();
    }
  }
}

class AddFeedingTimeDialog extends StatefulWidget {
  final Function(FeedingTime) onTimeAdded;

  const AddFeedingTimeDialog({
    super.key,
    required this.onTimeAdded,
  });

  @override
  State<AddFeedingTimeDialog> createState() => _AddFeedingTimeDialogState();
}

class _AddFeedingTimeDialogState extends State<AddFeedingTimeDialog> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _amount = 50;
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // Tous les jours par défaut

  final List<String> _dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un horaire'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sélection de l'heure
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Heure'),
            subtitle: Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
            onTap: _selectTime,
          ),
          
          const SizedBox(height: 16),
          
          // Sélection de la quantité
          Text('Quantité: ${_amount}g'),
          Slider(
            value: _amount.toDouble(),
            min: 10,
            max: 200,
            divisions: 19,
            label: '${_amount}g',
            onChanged: (value) {
              setState(() {
                _amount = value.round();
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Sélection des jours
          const Text('Jours de la semaine:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final dayIndex = index == 0 ? 7 : index; // Dimanche = 7
              final isSelected = _selectedDays.contains(dayIndex);
              
              return FilterChip(
                label: Text(_dayNames[index]),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDays.add(dayIndex);
                    } else {
                      _selectedDays.remove(dayIndex);
                    }
                  });
                },
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedDays.isEmpty ? null : _addTime,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }

  Future<void> _selectTime() async {
    final material.TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: material.TimeOfDay(hour: _selectedTime.hour, minute: _selectedTime.minute),
    );
    
    if (picked != null) {
      final newTime = TimeOfDay(hour: picked.hour, minute: picked.minute);
      if (newTime.hour != _selectedTime.hour || newTime.minute != _selectedTime.minute) {
        setState(() {
          _selectedTime = newTime;
        });
      }
    }
  }

  void _addTime() {
    final feedingTime = FeedingTime(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      time: _selectedTime,
      amount: _amount,
      daysOfWeek: _selectedDays,
      isActive: true,
    );

    widget.onTimeAdded(feedingTime);
    Navigator.of(context).pop();
  }
}