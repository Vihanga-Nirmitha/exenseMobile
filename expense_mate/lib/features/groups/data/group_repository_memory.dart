import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/group.dart';
import 'group_repository.dart';

class GroupRepositoryMemory implements GroupRepository {
  final String baseUrl = "http://192.168.8.100:8085";
  final _store = <String, Group>{};

  @override
  Future<List<Group>> listByEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");
    if (email == null) return [];

    // final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/api/groups/groups?email=$email"),
      headers: {
        "Content-Type": "application/json",
        // if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      SnackBar(content: Text("Error: $data"));
      return data.map((json) => Group.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load groups: ${response.body}");
    }
  }

  @override
  Future<Group> create(Group group) async {
    final id = (group.id.isEmpty) ? _randId() : group.id;
    final g = Group(id: id, name: group.name, members: List<Member>.from(group.members), avatarUrl: group.avatarUrl);
    _store[id] = g;
    return g;
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }

  @override
  Future<Group?> getById(String id) async => _store[id];

  @override
  Future<List<Group>> list() async {
    final list = _store.values.toList();
    list.sort((a,b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<Group> upsert(Group group) async {
    _store[group.id] = group;
    return group;
  }

  String _randId() => Random().nextInt(1<<31).toString();
}
