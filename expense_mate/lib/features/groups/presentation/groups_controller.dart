import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../groups/data/group_repository.dart';
import '../../groups/domain/group.dart';
import '../../../shared/providers/repositories.dart';

final groupsProvider = StateNotifierProvider<GroupsController, AsyncValue<List<Group>>>((ref) {
  final repo = ref.watch(groupRepositoryProvider);
  return GroupsController(repo)..load();
});

class GroupsController extends StateNotifier<AsyncValue<List<Group>>> {
  GroupsController(this._repo) : super(const AsyncValue.loading());
  final GroupRepository _repo;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("email");
      if (email == null) {
        state = const AsyncValue.data([]);
        return;
      }

      final groups = await _repo.listByEmail(email);
      state = AsyncValue.data(groups);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGroup(String name, List<Member> members) async {
    final g = Group(id: '', name: name, members: members);
    await _repo.create(g);
    await load();
  }

  Future<void> removeGroup(String id) async {
    await _repo.delete(id);
    await load();
  }
}
