class AppConstants {
  AppConstants._();

  static const String appName = 'GaweFlutter';
  
  // URL API Backend (Laravel presensigpsv2)
  // Untuk emulator Android, gunakan 10.0.2.2 jika backend dijalankan di localhost
  static const String baseUrl = 'http://192.168.1.117:8000/api/mobile';
  
  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  
  // Secure Storage keys
  static const String keyToken = 'auth_token';
  static const String keyDeviceId = 'user_device_id';
  static const String keyUser = 'user_data';
  static const String keyServerUrl = 'custom_server_base_url';
}
