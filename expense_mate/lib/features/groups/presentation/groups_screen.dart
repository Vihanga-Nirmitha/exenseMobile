import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard in dialog
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/group.dart';
import 'groups_controller.dart';
import 'package:go_router/go_router.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String? _userEmail;

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString("email");
    });
  }
  @override
  void initState() {
    super.initState();
    _loadUserEmail();
    Future.microtask(() {
      ref.read(groupsProvider.notifier).load();
    });
  }
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_userEmail ?? "User"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.92),
                Theme.of(context).colorScheme.secondary.withOpacity(0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search groups',
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: groupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (groups) {
                final filtered = _query.isEmpty
                    ? groups
                    : groups
                    .where((g) =>
                    g.name.toLowerCase().contains(_query.toLowerCase()))
                    .toList();

                if (filtered.isEmpty) {
                  return _EmptyState(
                    showHint: groups.isNotEmpty,
                    onAdd: () => _openNewGroupDialog(context, ref),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(groupsProvider.notifier).load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final g = filtered[i];
                      return Dismissible(
                        key: ValueKey(g.id),
                        direction: DismissDirection.endToStart,
                        background:
                        const _SwipeDeleteBg(color: Color(0xFFE53935)),
                        confirmDismiss: (_) async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete group?'),
                              content: Text(
                                  'Are you sure you want to delete "${g.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          return ok ?? false;
                        },
                        onDismissed: (_) async {
                          await ref
                              .read(groupsProvider.notifier)
                              .removeGroup(g.id);
                        },
                        child: InkWell(
                          onTap: () => context.go('/groups/${g.id}'),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: _cardGradient(i, context),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _GroupCard(group: g),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewGroupDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
      ),
    );
  }

  LinearGradient _cardGradient(int i, BuildContext context) {
    // pleasant rotating gradient based on index
    final base = (i * 41) % 360;
    Color c(double h, double s, double l) =>
        HSLColor.fromAHSL(1, h, s, l).toColor();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      colors: [
        c(base.toDouble(), 0.65, dark ? 0.30 : 0.70),
        c(((base + 26) % 360).toDouble(), 0.70, dark ? 0.25 : 0.80),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.1, 0.9],
    );
  }

  // ===== New Group Dialog (polished, wider, with clipboard paste) =====
  void _openNewGroupDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final memberCtrls = <TextEditingController>[TextEditingController()];
    bool isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          void addField({String initial = ''}) {
            memberCtrls.add(TextEditingController(text: initial));
            setState(() {});
          }

          void removeField(int i) {
            if (memberCtrls.length == 1) return;
            memberCtrls.removeAt(i).dispose();
            setState(() {});
          }

          final filledCount =
              memberCtrls.where((c) => c.text.trim().isNotEmpty).length;

          Widget memberField(int index) {
            final ctrl = memberCtrls[index];
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextFormField(
                controller: ctrl,
                textInputAction: index == memberCtrls.length - 1
                    ? TextInputAction.done
                    : TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Member ${index + 1}',
                  hintText: 'Display name',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: memberCtrls.length > 1
                      ? IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => removeField(index),
                  )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) {
                  if (index == memberCtrls.length - 1 &&
                      ctrl.text.trim().isNotEmpty) {
                    addField();
                  }
                },
              ),
            );
          }

          return AlertDialog(
            insetPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            title: Row(
              children: [
                const Icon(Icons.group_outlined),
                const SizedBox(width: 8),
                const Text('New group'),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child:
                  Text('$filledCount member${filledCount == 1 ? '' : 's'}'),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(MediaQuery.of(ctx).size.width * 0.95, 720),
                maxHeight: MediaQuery.of(ctx).size.height * 0.8,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Group name',
                          hintText: 'e.g. Roommates, Kandy Trip',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Group name is required'
                            : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Members',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      ...List.generate(memberCtrls.length, memberField),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => addField(),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Add member'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              final data =
                              await Clipboard.getData('text/plain');
                              final text = data?.text ?? '';
                              if (text.trim().isEmpty) return;
                              for (final token
                              in text.split(RegExp(r'[,\n;]'))) {
                                final t = token.trim();
                                if (t.isNotEmpty) addField(initial: t);
                              }
                            },
                            child: const Text('Paste list'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tip: Press Enter on the last field to add another.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isCreating ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: (!isCreating &&
                    nameCtrl.text.trim().isNotEmpty &&
                    memberCtrls.any((c) => c.text.trim().isNotEmpty))
                    ? () async {
                  if (!formKey.currentState!.validate()) return;
                  setState(() => isCreating = true);

                  final members = memberCtrls
                      .map((c) => c.text.trim())
                      .where((t) => t.isNotEmpty)
                      .toList()
                      .asMap()
                      .entries
                      .map((e) => Member(
                    userId:
                    'u${e.key}_${DateTime.now().millisecondsSinceEpoch}',
                    displayName: e.value,
                  ))
                      .toList();

                  await ref
                      .read(groupsProvider.notifier)
                      .addGroup(nameCtrl.text.trim(), members);

                  if (ctx.mounted) Navigator.pop(ctx);
                }
                    : null,
                icon: isCreating
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.check),
                label: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ======= UI helpers =======

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});
  final Group group;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    final first = parts.first[0];
    final last = (parts.length > 1 && parts.last.isNotEmpty)
        ? parts.last[0]
        : (parts.first.length > 1 ? parts.first[1] : parts.first[0]);
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(group.name);
    final count = group.members.length;

    return Ink(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white.withOpacity(0.90),
              child: Text(
                initials,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_alt_outlined,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '$count member${count == 1 ? '' : 's'}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _SwipeDeleteBg extends StatelessWidget {
  const _SwipeDeleteBg({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.showHint, required this.onAdd});
  final bool showHint;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🧮', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 12),
            Text('No groups yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              showHint
                  ? 'No results match your search.'
                  : 'Create your first group to start splitting expenses.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('New Group'),
            ),
          ],
        ),
      ),
    );
  }
}
