import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/platform_config.dart';

class ImagePickerService {
  static final ImagePickerService _instance = ImagePickerService._internal();
  factory ImagePickerService() => _instance;
  ImagePickerService._internal();

  final _imagePicker = ImagePicker();
  late final FirebaseAnalytics _analytics;

  void initialize({required FirebaseAnalytics analytics}) {
    _analytics = analytics;
  }

  Future<File?> pickImage() async {
    try {
      if (PlatformConfig.isWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          _analytics.logEvent(
            name: 'image_picked',
            parameters: {
              'platform': 'web',
              'file_name': result.files.first.name,
            },
          );
          // For web, we return null as we'll handle the file differently
          return null;
        }
      } else {
        final result = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );

        if (result != null) {
          _analytics.logEvent(
            name: 'image_picked',
            parameters: {
              'platform': 'mobile',
              'file_name': result.name,
            },
          );
          return File(result.path);
        }
      }
    } catch (e) {
      _analytics.logEvent(
        name: 'image_pick_error',
        parameters: {'error': e.toString()},
      );
      debugPrint('Error picking image: $e');
      rethrow;
    }
    return null;
  }

  Future<List<File>> pickMultipleImages() async {
    try {
      if (PlatformConfig.isWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
        );

        if (result != null && result.files.isNotEmpty) {
          _analytics.logEvent(
            name: 'multiple_images_picked',
            parameters: {
              'platform': 'web',
              'count': result.files.length,
            },
          );
          // For web, we return empty list as we'll handle the files differently
          return [];
        }
      } else {
        final result = await _imagePicker.pickMultiImage(
          imageQuality: 80,
        );

        if (result != null && result.isNotEmpty) {
          _analytics.logEvent(
            name: 'multiple_images_picked',
            parameters: {
              'platform': 'mobile',
              'count': result.length,
            },
          );
          return result.map((xFile) => File(xFile.path)).toList();
        }
      }
    } catch (e) {
      _analytics.logEvent(
        name: 'multiple_images_pick_error',
        parameters: {'error': e.toString()},
      );
      debugPrint('Error picking multiple images: $e');
      rethrow;
    }
    return [];
  }

  Future<File?> takePicture() async {
    try {
      if (PlatformConfig.isWeb) {
        // Web doesn't support camera directly, use file picker instead
        return pickImage();
      } else {
        final result = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );

        if (result != null) {
          _analytics.logEvent(
            name: 'camera_image_captured',
            parameters: {
              'platform': 'mobile',
              'file_name': result.name,
            },
          );
          return File(result.path);
        }
      }
    } catch (e) {
      _analytics.logEvent(
        name: 'camera_capture_error',
        parameters: {'error': e.toString()},
      );
      debugPrint('Error capturing image: $e');
      rethrow;
    }
    return null;
  }
} 