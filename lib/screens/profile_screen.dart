import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedMood;
  final List<String> _selectedInterests = [];

  final List<String> _moods = [
    'Happy',
    'Excited',
    'Calm',
    'Focused',
    'Creative',
    'Social',
  ];

  final List<String> _interests = [
    'Music',
    'Movies',
    'Books',
    'Sports',
    'Travel',
    'Food',
    'Art',
    'Technology',
    'Gaming',
    'Fitness',
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your mood')),
      );
      return;
    }
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one interest')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = SupabaseService().currentUser;
      if (user == null) throw Exception('User not found');

      await SupabaseService().client.from('profiles').upsert({
        'id': user.id,
        'name': _nameController.text,
        'dob': _selectedDate!.toIso8601String(),
        'mood': _selectedMood,
        'interests': _selectedInterests,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await FirebaseService().logEvent(
        name: 'profile_completed',
        parameters: {
          'has_name': true,
          'has_dob': true,
          'has_mood': true,
          'interests_count': _selectedInterests.length,
        },
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Current Mood',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedMood,
                  items: _moods.map((mood) {
                    return DropdownMenuItem(
                      value: mood,
                      child: Text(mood),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMood = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select Your Interests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _interests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedInterests.add(interest);
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 