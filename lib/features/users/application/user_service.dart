import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

import '../../../core/services/bluetooth_service.dart';

final usersProvider = StreamProvider<List<Node>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final myNodeInfoAsync = ref.watch(myNodeInfoProvider);
  final myId = myNodeInfoAsync.value?.myNodeNum;

  return db.watchAllNodes().map((nodes) {
    if (myId == null) return nodes;
    return nodes.where((n) => n.num != myId).toList();
  });
});

class UserService {
  // We might not need a class if we just use the provider, 
  // but keeping it as a namespace or for future methods is fine.
}
