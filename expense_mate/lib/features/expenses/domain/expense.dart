class Expense {
  Expense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.paidByUserId,
    required this.createdAt,
    required this.shares,
    this.note,
    this.currency,
  });

  String id;
  String groupId;
  String title;
  double amount;
  String paidByUserId;
  DateTime createdAt;
  List<Share> shares;
  String? note;
  String? currency; // e.g., 'LKR'
}

class Share {
  Share({
    required this.userId,
    required this.amount,
  });

  String userId;
  double amount; // positive => owes
}
