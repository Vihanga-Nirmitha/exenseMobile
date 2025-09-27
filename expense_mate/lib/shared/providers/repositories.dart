import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/expenses/data/expense_repository.dart';
import '../../features/expenses/data/expense_repository_memory.dart';
import '../../features/groups/data/group_repository.dart';
import '../../features/groups/data/group_repository_memory.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepositoryMemory();
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryMemory();
});
