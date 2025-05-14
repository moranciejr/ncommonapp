// Flutter Profile Completion Flow for nCommonApp
// Collects interests, mood, photos, and basic info before home screen

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_form_state.dart';
import '../services/profile_service.dart';
import '../constants/profile_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../services/supabase_browser_client.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();
  late final SupabaseBrowserClient _supabase;
  late final ProfileService _profileService;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  
  late ProfileFormState _formState;
  File? _profilePicture;
  bool _isDragging = false;
  final _analytics = FirebaseAnalytics.instance;
  bool _isNameAvailable = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _formState = ProfileFormState(nameController: _nameController);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _loadDraft();
    _animationController.forward();
  }

  Future<void> _initializeServices() async {
    _supabase = await SupabaseBrowserClient.getInstance();
    _profileService = ProfileService(_supabase.client);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkNameAvailability(String name) async {
    if (name.length < ProfileConstants.minNameLength) return;
    
    try {
      final response = await _supabase.from('users')
          .select('id')
          .eq('full_name', name)
          .single();
      
      setState(() {
        _isNameAvailable = response == null;
      });
    } catch (e) {
      // If no user found, name is available
      setState(() {
        _isNameAvailable = true;
      });
    }
  }

  Future<void> _loadDraft() async {
    final user = _supabase.currentUser;
    if (user == null) return;

    final draft = await _profileService.loadFormDraft(user.id);
    if (draft != null) {
      setState(() {
        _nameController.text = draft['fullName'] ?? '';
        if (draft['dob'] != null) {
          _formState = _formState.copyWith(
            selectedDate: DateTime.parse(draft['dob']),
          );
        }
        if (draft['mood'] != null) {
          _formState = _formState.copyWith(
            selectedMood: draft['mood'],
          );
        }
        if (draft['interests'] != null) {
          _formState = _formState.copyWith(
            selectedInterests: Set<String>.from(draft['interests']),
          );
        }
      });
    }
  }

  Future<void> _saveDraft() async {
    final user = _supabase.currentUser;
    if (user == null) return;

    await _profileService.saveFormDraft(
      userId: user.id,
      fullName: _nameController.text,
      dob: _formState.selectedDate,
      mood: _formState.selectedMood,
      interests: _formState.selectedInterests.toList(),
    );
  }

  Future<void> _pickProfilePicture() async {
    final picture = await _profileService.pickProfilePicture();
    if (picture != null) {
      setState(() {
        _profilePicture = picture;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _formState.selectedDate) {
      setState(() {
        _formState = _formState.copyWith(selectedDate: picked);
      });
      _saveDraft();
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formState.canSubmit || !_isNameAvailable) return;

    setState(() {
      _formState = _formState.copyWith(
        isLoading: true,
        errorMessage: null,
        lastSubmissionTime: DateTime.now(),
      );
    });

    try {
      final user = _supabase.currentUser;
      if (user == null) throw Exception('User not found');

      // Upload profile picture if exists
      String? profilePictureUrl;
      if (_profilePicture != null) {
        final bytes = await _profilePicture!.readAsBytes();
        final path = 'profile_pictures/${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.client.storage.from('public').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
        profilePictureUrl = _supabase.client.storage.from('public').getPublicUrl(path);
      }

      // Update user profile
      await _supabase.update('users', {
        'full_name': _nameController.text.trim(),
        'dob': _formState.selectedDate!.toIso8601String(),
        'mood': _formState.selectedMood,
        'profile_picture_url': profilePictureUrl,
        'profile_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, user.id);

      // Update interests
      await _supabase.client.from('user_interests').delete().eq('user_id', user.id);
      final dbInterests = await _supabase.from('interests');
      final Map<String, int> nameToId = {
        for (var i in dbInterests) i['name'] as String: i['id'] as int
      };
      
      final inserts = _formState.selectedInterests.map((interest) => {
        'user_id': user.id,
        'interest_id': nameToId[interest] ?? 0
      }).toList();
      
      await _supabase.client.from('user_interests').insert(inserts);

      await _profileService.clearFormDraft(user.id);

      // Track profile completion
      await _analytics.logEvent(
        name: 'profile_completed',
        parameters: {
          'user_id': user.id,
          'interests_count': _formState.selectedInterests.length,
          'has_profile_picture': _profilePicture != null,
        },
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _formState = _formState.copyWith(
          errorMessage: 'Error saving profile: $e',
          retryCount: _formState.retryCount + 1,
        );
      });

      if (_formState.retryCount < ProfileConstants.maxRetries) {
        await Future.delayed(ProfileConstants.retryDelay * _formState.retryCount);
        _handleSubmit();
      }
    } finally {
      if (mounted) {
        setState(() {
          _formState = _formState.copyWith(isLoading: false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Profile Completion Help'),
                  content: const Text(
                    'Please fill out all required fields to complete your profile. '
                    'Your profile picture is optional but recommended.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'Tell us about yourself',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: _formState.formProgress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                if (_formState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      _formState.errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                GestureDetector(
                  onTap: _pickProfilePicture,
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      image: _profilePicture != null
                          ? DecorationImage(
                              image: FileImage(_profilePicture!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _profilePicture == null
                        ? const Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    semanticLabel: 'Enter your full name',
                    errorText: !_isNameAvailable ? 'This name is already taken' : null,
                  ),
                  enabled: !_formState.isLoading,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (value) {
                    _saveDraft();
                    _checkNameAvailability(value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.length < ProfileConstants.minNameLength) {
                      return 'Name must be at least ${ProfileConstants.minNameLength} characters';
                    }
                    if (value.length > ProfileConstants.maxNameLength) {
                      return 'Name must be less than ${ProfileConstants.maxNameLength} characters';
                    }
                    if (!RegExp(ProfileConstants.nameRegex).hasMatch(value)) {
                      return 'Name can only contain letters and spaces';
                    }
                    if (!_isNameAvailable) {
                      return 'This name is already taken';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: _formState.isLoading ? null : () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _formState.selectedDate == null
                          ? 'Select Date'
                          : '${_formState.selectedDate!.day}/${_formState.selectedDate!.month}/${_formState.selectedDate!.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _formState.selectedMood,
                  decoration: const InputDecoration(
                    labelText: 'In the Mood For...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.mood),
                  ),
                  items: ProfileConstants.moods.map((String mood) {
                    return DropdownMenuItem<String>(
                      value: mood,
                      child: Text(mood),
                    );
                  }).toList(),
                  onChanged: _formState.isLoading
                      ? null
                      : (String? newValue) {
                          setState(() {
                            _formState = _formState.copyWith(selectedMood: newValue);
                          });
                          _saveDraft();
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your mood';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Your Interests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: ProfileConstants.interests.map((String interest) {
                    return FilterChip(
                      label: Text(interest),
                      selected: _formState.selectedInterests.contains(interest),
                      onSelected: _formState.isLoading
                          ? null
                          : (bool selected) {
                              setState(() {
                                final newInterests = Set<String>.from(_formState.selectedInterests);
                                if (selected) {
                                  newInterests.add(interest);
                                } else {
                                  newInterests.remove(interest);
                                }
                                _formState = _formState.copyWith(selectedInterests: newInterests);
                              });
                              _saveDraft();
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: (_formState.canSubmit && _isNameAvailable) ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _formState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Complete Profile',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 