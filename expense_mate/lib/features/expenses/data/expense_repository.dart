import '../domain/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> listByGroup(String groupId);
  Future<Expense> create(Expense expense);
  Future<void> delete(String id);
}
