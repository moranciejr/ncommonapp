class ProfileConstants {
  static const List<String> moods = [
    'Adventure',
    'Relaxation',
    'Learning',
    'Social',
    'Creative',
    'Fitness',
    'Food & Drink',
    'Entertainment'
  ];

  static const List<String> interests = [
    'Movies',
    'Music',
    'Books',
    'Sports',
    'Travel',
    'Cooking',
    'Art',
    'Technology',
    'Gaming',
    'Fashion',
    'Photography',
    'Fitness',
    'Nature',
    'Science',
    'History'
  ];

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  static const Duration submissionCooldown = Duration(seconds: 2);
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const String nameRegex = r'^[a-zA-Z\s]+$';
} 