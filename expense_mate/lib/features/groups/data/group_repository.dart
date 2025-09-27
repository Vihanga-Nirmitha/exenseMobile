import '../domain/group.dart';

abstract class GroupRepository {
  Future<List<Group>> list();
  Future<Group> create(Group group);
  Future<void> delete(String id);
  Future<Group?> getById(String id);
  Future<Group> upsert(Group group);
  Future<List<Group>> listByEmail(String email);

}
