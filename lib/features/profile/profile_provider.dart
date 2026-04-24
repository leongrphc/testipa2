import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_provider.dart';
import 'profile_repository.dart';

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) {
    return null;
  }

  return profileRepository.fetchProfile();
});
