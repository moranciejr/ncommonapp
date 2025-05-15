import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlatformConfig {
  static bool get isWeb => kIsWeb;
  
  static bool get isMobile => !isWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  
  static bool get isDesktop => !isWeb && (defaultTargetPlatform == TargetPlatform.windows || 
                                        defaultTargetPlatform == TargetPlatform.macOS || 
                                        defaultTargetPlatform == TargetPlatform.linux);

  // Platform-specific configurations
  static final Map<String, dynamic> platformConfig = {
    if (kIsWeb) {
      'platform': 'web',
      'imagePickerSource': 'file_picker',
      'streamApiKey': dotenv.env['STREAM_API_KEY'] ?? '',
    } else if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      'platform': 'mobile',
      'imagePickerSource': 'image_picker',
      'streamApiKey': dotenv.env['STREAM_API_KEY'] ?? '',
    } else {
      'platform': 'desktop',
      'imagePickerSource': 'image_picker',
      'streamApiKey': dotenv.env['STREAM_API_KEY'] ?? '',
    }
  };
} 