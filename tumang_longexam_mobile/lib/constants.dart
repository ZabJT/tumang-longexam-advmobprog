// ignore_for_file: constant_identifier_names
import 'package:flutter_dotenv/flutter_dotenv.dart';

// API - Get host with safe access to dotenv
String get host {
  try {
    return dotenv.env['HOST'] ?? 'http://10.0.2.2:5000';
  } catch (e) {
    // If dotenv is not initialized, use default
    return 'http://10.0.2.2:5000';
  }
}

// Debug: Print the host value
void debugHost() {
  try {
    print('Environment HOST: ${dotenv.env['HOST']}');
  } catch (e) {
    print('Environment HOST: Not initialized');
  }
  print('Final host value: $host');
}
