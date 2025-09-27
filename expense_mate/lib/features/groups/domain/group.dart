// class Group {
//   Group({
//     required this.id,
//     required this.name,
//     required this.members,
//     this.avatarUrl,
//   });
//
//   String id;
//   String name;
//   List<Member> members;
//   String? avatarUrl;
// }
//
// class Member {
//   Member({
//     required this.userId,
//     required this.displayName,
//   });
//
//   String userId;
//   String displayName;
// }
class Group {
  Group({
    required this.id,
    required this.name,
    required this.members,
    this.avatarUrl,
  });

  String id;
  String name;
  List<Member> members;
  String? avatarUrl;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatarUrl'],
      members: (json['members'] as List<dynamic>? ?? [])
          .map((m) => Member.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'members': members.map((m) => m.toJson()).toList(),
    };
  }
}

class Member {
  Member({
    required this.userId,
    required this.displayName,
  });

  String userId;
  String displayName;

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
    };
  }
}
