import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../groups/data/group_repository.dart';
import '../../groups/domain/group.dart';
import '../../../shared/providers/repositories.dart';
import '../../expenses/presentation/expenses_controller.dart';
import '../../expenses/domain/expense.dart';
import '../../expenses/domain/balance_utils.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupRepo = ref.watch(groupRepositoryProvider);
    return FutureBuilder<Group?>(
      future: groupRepo.getById(groupId),
      builder: (ctx, snap) {
        final group = snap.data;
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (group == null) {
          return const Scaffold(body: Center(child: Text('Group not found')));
        }

        final expensesAsync = ref.watch(expensesProvider(groupId));
        return Scaffold(
          appBar: AppBar(title: Text(group.name)),
          body: expensesAsync.when(
            data: (items) {
              final balances = computeBalances(items);
              return ListView(
                children: [
                  _BalancesCard(group: group, balances: balances),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text('Expenses', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  if (items.isEmpty)
                    const ListTile(title: Text('No expenses yet. Tap + to add.')),
                  ...items.map((e) => ListTile(
                        title: Text(e.title),
                        subtitle: Text('${e.amount.toStringAsFixed(2)} ${e.currency ?? ''} • paid by ${_nameOf(group, e.paidByUserId)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ref.read(expenseRepositoryProvider).delete(e.id);
                            ref.invalidate(expensesProvider(groupId));
                          },
                        ),
                      )),
                  const SizedBox(height: 80),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddExpenseDialog(context, ref, group),
            icon: const Icon(Icons.add),
            label: const Text('Add expense'),
          ),
        );
      },
    );
  }

  String _nameOf(Group g, String userId) =>
      g.members.firstWhere((m) => m.userId == userId, orElse: () => g.members.first).displayName;

  void _openAddExpenseDialog(BuildContext context, WidgetRef ref, Group group) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String paidBy = group.members.first.userId;
    final addCtrl = ref.read(addExpenseControllerProvider);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New expense (equal split)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', hintText: 'Dinner, Uber, Rent')),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: paidBy,
              items: group.members
                  .map((m) => DropdownMenuItem(value: m.userId, child: Text('Paid by ${m.displayName}')))
                  .toList(),
              onChanged: (v) => paidBy = v ?? paidBy,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
              if (titleCtrl.text.trim().isEmpty || amt <= 0) return;
              await addCtrl.addEqualSplit(
                groupId: group.id,
                title: titleCtrl.text.trim(),
                amount: amt,
                paidBy: paidBy,
                memberIds: group.members.map((m) => m.userId).toList(),
              );
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
              // refresh
              // ignore: use_build_context_synchronously
              final container = ProviderScope.containerOf(context);
              container.invalidate(expensesProvider(group.id));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _BalancesCard extends StatelessWidget {
  const _BalancesCard({required this.group, required this.balances});
  final Group group;
  final Map<String, double> balances;

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return const ListTile(title: Text('No balances yet'));
    }
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balances', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...group.members.map((m) {
              final v = balances[m.userId] ?? 0;
              final label = v > 0 ? 'owes' : v < 0 ? 'is owed' : 'settled';
              final amt = v.abs().toStringAsFixed(2);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(m.displayName),
                trailing: Text(v == 0 ? '0.00' : '$label $amt'),
              );
            }),
          ],
        ),
      ),
    );
  }
}
