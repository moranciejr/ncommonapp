import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  final SupabaseClient _supabase;
  final ImagePicker _picker = ImagePicker();

  ProfileService(this._supabase);

  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required DateTime dob,
    required String mood,
    required List<String> interests,
    File? profilePicture,
  }) async {
    String? profilePictureUrl;
    
    if (profilePicture != null) {
      final bytes = await profilePicture.readAsBytes();
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(profilePicture.path)}';
      
      await _supabase.storage
          .from('profile_pictures')
          .uploadBinary(fileName, bytes);
          
      profilePictureUrl = _supabase.storage
          .from('profile_pictures')
          .getPublicUrl(fileName);
    }

    await _supabase.from('users').update({
      'full_name': fullName,
      'dob': dob.toIso8601String(),
      'mood': mood,
      'interests': interests,
      'profile_picture_url': profilePictureUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_complete', true);
  }

  Future<File?> pickProfilePicture() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image == null) return null;

    final tempDir = await getTemporaryDirectory();
    final tempPath = path.join(tempDir.path, 'profile_picture.jpg');
    final File tempFile = File(tempPath);
    await tempFile.writeAsBytes(await image.readAsBytes());
    
    return tempFile;
  }

  Future<void> saveFormDraft({
    required String userId,
    required String fullName,
    required DateTime? dob,
    required String? mood,
    required List<String> interests,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_draft_$userId', {
      'fullName': fullName,
      'dob': dob?.toIso8601String(),
      'mood': mood,
      'interests': interests,
      'timestamp': DateTime.now().toIso8601String(),
    }.toString());
  }

  Future<Map<String, dynamic>?> loadFormDraft(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString('profile_draft_$userId');
    if (draft == null) return null;

    // Parse the draft string back into a map
    // This is a simplified version - you might want to use proper JSON parsing
    final Map<String, dynamic> draftMap = {};
    draft
        .replaceAll('{', '')
        .replaceAll('}', '')
        .split(',')
        .forEach((pair) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        draftMap[parts[0].trim()] = parts[1].trim();
      }
    });

    return draftMap;
  }

  Future<void> clearFormDraft(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_draft_$userId');
  }
} 