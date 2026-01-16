import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/user.dart';
import 'user_service.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
UserService userService(Ref ref) {
  return UserService();
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  User? build() {
    return null;
  }
}

@riverpod
List<User> usersList(Ref ref) {
  return [];
}
