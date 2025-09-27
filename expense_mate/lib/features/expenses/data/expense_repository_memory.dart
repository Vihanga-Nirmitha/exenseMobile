import 'dart:math';
import '../domain/expense.dart';
import 'expense_repository.dart';

class ExpenseRepositoryMemory implements ExpenseRepository {
  final _byGroup = <String, List<Expense>>{};

  @override
  Future<Expense> create(Expense expense) async {
    final id = (expense.id.isEmpty) ? _randId() : expense.id;
    final e = Expense(
      id: id,
      groupId: expense.groupId,
      title: expense.title,
      amount: expense.amount,
      paidByUserId: expense.paidByUserId,
      createdAt: expense.createdAt,
      shares: List<Share>.from(expense.shares),
      note: expense.note,
      currency: expense.currency,
    );
    _byGroup.putIfAbsent(e.groupId, () => []).add(e);
    return e;
  }

  @override
  Future<void> delete(String id) async {
    for (final list in _byGroup.values) {
      list.removeWhere((e) => e.id == id);
    }
  }

  @override
  Future<List<Expense>> listByGroup(String groupId) async {
    final list = _byGroup[groupId] ?? [];
    list.sort((a,b)=>b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  String _randId() => Random().nextInt(1<<31).toString();
}
