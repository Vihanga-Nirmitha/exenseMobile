import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/domain/expense.dart';
import '../../../shared/providers/repositories.dart';

final expensesProvider = FutureProvider.family<List<Expense>, String>((ref, groupId) async {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.listByGroup(groupId);
});

final addExpenseControllerProvider = Provider<AddExpenseController>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return AddExpenseController(repo);
});

class AddExpenseController {
  AddExpenseController(this._repo);
  final ExpenseRepository _repo;

  Future<void> addEqualSplit({
    required String groupId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> memberIds,
    String? currency,
    String? note,
  }) async {
    final perHead = amount / (memberIds.isEmpty ? 1 : memberIds.length);
    final shares = memberIds.map((id) => Share(userId: id, amount: perHead)).toList();

    final expense = Expense(
      id: '',
      groupId: groupId,
      title: title,
      amount: amount,
      paidByUserId: paidBy,
      createdAt: DateTime.now(),
      shares: shares,
      currency: currency ?? 'LKR',
      note: note,
    );
    await _repo.create(expense);
  }
}
