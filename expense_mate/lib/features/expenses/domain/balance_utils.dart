// Returns net balance per user for a group's expenses:
// positive => user owes, negative => user is owed.
import 'expense.dart';

Map<String, double> computeBalances(List<Expense> expenses) {
  final net = <String, double>{};

  for (final e in expenses) {
    net[e.paidByUserId] = (net[e.paidByUserId] ?? 0) - e.amount;
    for (final s in e.shares) {
      net[s.userId] = (net[s.userId] ?? 0) + s.amount;
    }
  }
  // round to 2 decimals
  final rounded = <String, double>{};
  net.forEach((k, v) {
    rounded[k] = double.parse(v.toStringAsFixed(2));
  });
  return rounded;
}
