class AuthConstants {
  // Password requirements
  static const int minPasswordLength = 8;
  static const String passwordRegex = r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$';
  
  // Error messages
  static const Map<String, String> errorMessages = {
    'invalid_credentials': 'Invalid email or password',
    'email_not_verified': 'Please verify your email address',
    'email_already_in_use': 'This email is already registered',
    'weak_password': 'Password is too weak',
    'invalid_email': 'Please enter a valid email address',
    'user_not_found': 'No account found with this email',
    'too_many_requests': 'Too many attempts. Please try again later',
    'network_error': 'Network error. Please check your connection',
    'unknown_error': 'An unexpected error occurred',
  };

  // Social providers
  static const List<String> socialProviders = [
    'google',
    'apple',
    'github',
    'facebook',
  ];

  // Analytics events
  static const Map<String, String> analyticsEvents = {
    'login_attempt': 'login_attempt',
    'login_success': 'login_success',
    'login_failure': 'login_failure',
    'signup_attempt': 'signup_attempt',
    'signup_success': 'signup_success',
    'signup_failure': 'signup_failure',
    'social_login_attempt': 'social_login_attempt',
    'social_login_success': 'social_login_success',
    'social_login_failure': 'social_login_failure',
    'password_reset_request': 'password_reset_request',
    'password_reset_success': 'password_reset_success',
    'password_reset_failure': 'password_reset_failure',
  };
} 