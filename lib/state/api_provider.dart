import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_service.dart';

final apiServiceProvider = Provider<BackendApiService>((ref) {
  return BackendApiService();
});
