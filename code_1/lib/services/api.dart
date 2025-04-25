// lib/services/api.dart

import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb

/// Base URL for your backend.
/// Uses 127.0.0.1 for web builds (might work better with browser security)
/// and localhost for native builds.
final String apiUrl = kIsWeb ? 'http://127.0.0.1:8001' : 'http://localhost:8001';

// Note: Changed from 'const' to 'final' because kIsWeb is determined at runtime.
