import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../repositories/auth_repository.dart';
import '../repositories/members_repository.dart';
import '../repositories/news_repository.dart';
import '../repositories/notifications_repository.dart';
import '../repositories/contracts_repository.dart';
import '../repositories/events_repository.dart';
import '../repositories/suggestions_repository.dart';
import '../repositories/admin_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioClientProvider = Provider<DioClient>((ref) {
  final client = DioClient(ref.watch(tokenStorageProvider));
  // Wired by main.dart bootstrap to invalidate auth on permanent refresh failure
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioClientProvider), ref.watch(tokenStorageProvider)),
);

final membersRepositoryProvider = Provider<MembersRepository>(
  (ref) => MembersRepository(ref.watch(dioClientProvider)),
);

final newsRepositoryProvider = Provider<NewsRepository>(
  (ref) => NewsRepository(ref.watch(dioClientProvider)),
);

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(dioClientProvider)),
);

final contractsRepositoryProvider = Provider<ContractsRepository>(
  (ref) => ContractsRepository(ref.watch(dioClientProvider)),
);

final eventsRepositoryProvider = Provider<EventsRepository>(
  (ref) => EventsRepository(ref.watch(dioClientProvider)),
);

final suggestionsRepositoryProvider = Provider<SuggestionsRepository>(
  (ref) => SuggestionsRepository(ref.watch(dioClientProvider)),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(dioClientProvider)),
);
