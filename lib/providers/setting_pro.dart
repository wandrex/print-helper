import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings_models.dart';
import '../services/api_routes.dart';
import '../services/api_service.dart';
import '../widgets/toasts.dart';

class SettingsPro extends ChangeNotifier {
  bool loading = false;
  final List<SettingsSection> _sections = [];
  List<SettingsSection> get sections => _sections;

  void _setLoading(bool v) {
    loading = v;
    notifyListeners();
  }

  Future<void> loadSettings({required BuildContext ctx}) async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final url = Uri.parse("${ApiRoutes.baseUrl}${ApiRoutes.settings}");

      final res = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _sections.clear();
        final list = data["sections"] ?? [];
        _sections.addAll(
          (list as List<dynamic>)
              .map((e) => SettingsSection.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
      if (!_sections.any((s) => s.title.toLowerCase().contains("language"))) {
        _sections.add(
          SettingsSection(
            id: 999,
            title: "Languages",
            items: [],
            expanded: true,
          ),
        );
      }
      if (!_sections.any((s) => s.title.toLowerCase().contains("ranks"))) {
        _sections.add(
          SettingsSection(id: 700, title: "Ranks", items: [], expanded: true),
        );
      }
      if (!_sections.any((s) => s.title.toLowerCase().contains("account"))) {
        _sections.add(
          SettingsSection(
            id: 200,
            title: "Account Types",
            items: [],
            expanded: true,
          ),
        );
      }
      if (!_sections.any(
        (s) => s.title.toLowerCase().contains("customer ranks"),
      )) {
        _sections.add(
          SettingsSection(
            id: 400,
            title: "Customer Ranks",
            items: [],
            expanded: true,
          ),
        );
      }
      if (!_sections.any((s) => s.title.toLowerCase().contains("skills"))) {
        _sections.add(
          SettingsSection(id: 500, title: "Skills", items: [], expanded: true),
        );
      }
      if (!_sections.any(
        (s) => s.title.toLowerCase().contains("client company"),
      )) {
        _sections.add(
          SettingsSection(
            id: 600,
            title: "Client Company Types",
            items: [],
            expanded: true,
          ),
        );
      }
      if (!_sections.any(
        (s) => s.title.toLowerCase().contains("customer company"),
      )) {
        _sections.add(
          SettingsSection(
            id: 300,
            title: "Customer Company Types",
            items: [],
            expanded: true,
          ),
        );
      }
      await getLanguages();
      await getAccountTypes();
      await getCustomerCompanyTypes();
      await getCustomerRanks();
      await getSkills();
      await getClientCompanyTypes();
      await getRanks();
    } catch (e, st) {
      debugPrint("LOAD SETTINGS ERROR: $e\n$st");
      showToast(message: "Failed to load settings");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getLanguages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final res = await http.get(
        Uri.parse("${ApiRoutes.baseUrl}languages"),
        headers: {"Authorization": "Bearer $token"},
      );
      debugPrint("LANGUAGE LIST: ${res.body}");
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final idx = _sections.indexWhere(
          (s) => s.title.toLowerCase().contains("language"),
        );
        if (idx != -1) {
          _sections[idx].items = list
              .map((e) => SettingsItem.fromJson(e as Map<String, dynamic>))
              .toList();
          notifyListeners();
        }
      } else {
        debugPrint("LANG GET non-200: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("GET LANG ERROR: $e");
    }
  }

  Future<void> getAccountTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final res = await http.get(
        Uri.parse("${ApiRoutes.baseUrl}account-types"),
        headers: {"Authorization": "Bearer $token"},
      );
      debugPrint("ACCOUNT TYPES LIST: ${res.body}");
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final idx = _sections.indexWhere(
          (s) => s.title.toLowerCase().contains("account"),
        );
        if (idx != -1) {
          _sections[idx].items = list
              .map((e) => SettingsItem.fromJson(e as Map<String, dynamic>))
              .toList();
          notifyListeners();
        }
      } else {
        debugPrint("ACCTYPE GET non-200: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("GET ACCTYPES ERROR: $e");
    }
  }

  Future<void> getCustomerCompanyTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final res = await http.get(
        Uri.parse("${ApiRoutes.baseUrl}customer-company-types"),
        headers: {"Authorization": "Bearer $token"},
      );
      debugPrint("CUSTOMER COMPANY TYPES: ${res.body}");
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final idx = _sections.indexWhere(
          (s) => s.title.toLowerCase().contains("customer company"),
        );
        if (idx != -1) {
          _sections[idx].items = list
              .map((e) => SettingsItem.fromJson(e as Map<String, dynamic>))
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("GET CUSTOMER COMPANY TYPES ERROR: $e");
    }
  }

  Future<void> getCustomerRanks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final res = await http.get(
        Uri.parse("${ApiRoutes.baseUrl}customer-ranks"),
        headers: {"Authorization": "Bearer $token"},
      );
      debugPrint("CUSTOMER RANKS: ${res.body}");
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final idx = _sections.indexWhere(
          (s) => s.title.toLowerCase().contains("customer ranks"),
        );
        if (idx != -1) {
          _sections[idx].items = list
              .map((e) => SettingsItem.fromJson(e as Map<String, dynamic>))
              .toList();

          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("GET CUSTOMER RANKS ERROR: $e");
    }
  }

  Future<void> getSkills() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final res = await http.get(
        Uri.parse("${ApiRoutes.baseUrl}skills"),
        headers: {"Authorization": "Bearer $token"},
      );
      debugPrint("SKILLS LIST: ${res.body}");
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final idx = _sections.indexWhere(
          (s) => s.title.toLowerCase().contains("skills"),
        );

        if (idx != -1) {
          _sections[idx].items = list
              .map((e) => SettingsItem.fromJson(e))
              .toList();

          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("GET SKILLS ERROR: $e");
    }
  }

  Future<void> getClientCompanyTypes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final res = await http.get(
        Uri.parse("${ApiRoutes.baseUrl}client-company-types"),
        headers: {"Authorization": "Bearer $token"},
      );
      debugPrint("CLIENT COMPANY TYPES: ${res.body}");
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final idx = _sections.indexWhere(
          (s) => s.title.toLowerCase().contains("client company"),
        );
        if (idx != -1) {
          _sections[idx].items = list
              .map((e) => SettingsItem.fromJson(e))
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("GET CLIENT COMPANY TYPES ERROR: $e");
    }
  }

  Future<void> getRanks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final res = await http.get(
        Uri.parse("${ApiRoutes.baseUrl}ranks"),
        headers: {"Authorization": "Bearer $token"},
      );
      debugPrint("RANKS LIST: ${res.body}");
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final idx = _sections.indexWhere(
          (s) => s.title.toLowerCase().contains("ranks"),
        );
        if (idx != -1) {
          _sections[idx].items = list
              .map((e) => SettingsItem.fromJson(e))
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("GET RANKS ERROR: $e");
    }
  }

  Future<void> createRank({
    required int sectionId,
    required String name,
  }) async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final response = await ApiService().postDataToApi(
        api: "ranks",
        headers: {"Authorization": "Bearer $token"},
        payload: {"name": name},
      );
      debugPrint("CREATE RANK RESPONSE: $response");
      if (response != null && response['id'] != null) {
        final idx = _sections.indexWhere((s) => s.id == sectionId);
        if (idx != -1) {
          final removed = _sections[idx].items.indexWhere((i) => i.id == 0);
          if (removed != -1) _sections[idx].items.removeAt(removed);
          _sections[idx].items.add(SettingsItem.fromJson(response));
          notifyListeners();
        }
      } else {
        showToast(message: "Create failed");
      }
    } catch (e) {
      debugPrint("CREATE RANK ERROR: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createCustomerCompanyType({
    required int sectionId,
    required String name,
  }) async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final response = await ApiService().postDataToApi(
        api: "customer-company-types",
        headers: {"Authorization": "Bearer $token"},
        payload: {"name": name},
      );
      if (response != null && response['id'] != null) {
        final idx = _sections.indexWhere((s) => s.id == sectionId);
        if (idx != -1) {
          final removed = _sections[idx].items.indexWhere((i) => i.id == 0);
          if (removed != -1) _sections[idx].items.removeAt(removed);
          _sections[idx].items.add(SettingsItem.fromJson(response));
          notifyListeners();
        }
      } else {
        showToast(message: "Create failed");
      }
    } catch (e) {
      debugPrint("CREATE CUSTOMER COMPANY TYPE ERROR: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createLanguage({
    required int sectionId,
    required String name,
  }) async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final response = await ApiService().postDataToApi(
        api: ApiRoutes.language,
        headers: {"Authorization": "Bearer $token"},
        payload: {"name": name},
      );
      debugPrint("CREATE LANGUAGE RESPONSE: $response");
      if (response != null && response['id'] != null) {
        final idx = _sections.indexWhere((s) => s.id == sectionId);
        if (idx != -1) {
          final removed = _sections[idx].items.indexWhere((i) => i.id == 0);
          if (removed != -1) _sections[idx].items.removeAt(removed);
          _sections[idx].items.add(
            SettingsItem.fromJson(response as Map<String, dynamic>),
          );
          notifyListeners();
        }
      } else if (response != null &&
          response is Map &&
          response['errors'] != null) {
        final msg =
            (response['errors']['name'] as List<dynamic>?)?.first ??
            'Validation error';
        showToast(message: msg.toString());
      } else {
        showToast(message: "Create failed");
      }
    } catch (e) {
      debugPrint("CREATE LANGUAGE ERROR: $e");
      showToast(message: "Create failed");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createAccountType({
    required int sectionId,
    required String name,
  }) async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final response = await ApiService().postDataToApi(
        api: "account-types",
        headers: {"Authorization": "Bearer $token"},
        payload: {"name": name},
      );
      debugPrint("CREATE ACCTYPE RESPONSE: $response");
      if (response != null && response['id'] != null) {
        final idx = _sections.indexWhere((s) => s.id == sectionId);
        if (idx != -1) {
          final removed = _sections[idx].items.indexWhere((i) => i.id == 0);
          if (removed != -1) _sections[idx].items.removeAt(removed);
          _sections[idx].items.add(
            SettingsItem.fromJson(response as Map<String, dynamic>),
          );
          notifyListeners();
        }
      } else if (response != null &&
          response is Map &&
          response['errors'] != null) {
        final msg =
            (response['errors']['name'] as List<dynamic>?)?.first ??
            'Validation error';
        showToast(message: msg.toString());
      } else {
        showToast(message: "Create failed");
      }
    } catch (e) {
      debugPrint("CREATE ACCTYPE ERROR: $e");
      showToast(message: "Create failed");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createCustomerRank({
    required int sectionId,
    required String name,
  }) async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final response = await ApiService().postDataToApi(
        api: "customer-ranks",
        headers: {"Authorization": "Bearer $token"},
        payload: {"name": name},
      );
      if (response != null && response['id'] != null) {
        final idx = _sections.indexWhere((s) => s.id == sectionId);
        if (idx != -1) {
          final removed = _sections[idx].items.indexWhere((i) => i.id == 0);
          if (removed != -1) _sections[idx].items.removeAt(removed);
          _sections[idx].items.add(SettingsItem.fromJson(response));
          notifyListeners();
        }
      } else {
        showToast(message: "Create failed");
      }
    } catch (e) {
      debugPrint("CREATE CUSTOMER RANK ERROR: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createClientCompanyType({
    required int sectionId,
    required String name,
  }) async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final response = await ApiService().postDataToApi(
        api: "client-company-types",
        headers: {"Authorization": "Bearer $token"},
        payload: {"name": name},
      );
      debugPrint("CREATE CLIENT COMPANY TYPE RESPONSE: $response");
      if (response != null && response['id'] != null) {
        final idx = _sections.indexWhere((s) => s.id == sectionId);
        if (idx != -1) {
          final removed = _sections[idx].items.indexWhere((i) => i.id == 0);
          if (removed != -1) _sections[idx].items.removeAt(removed);
          _sections[idx].items.add(SettingsItem.fromJson(response));
          notifyListeners();
        }
      } else {
        showToast(message: "Create failed");
      }
    } catch (e) {
      debugPrint("CREATE CLIENT COMPANY TYPE ERROR: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createSkill({
    required int sectionId,
    required String name,
  }) async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final response = await ApiService().postDataToApi(
        api: "skills",
        headers: {"Authorization": "Bearer $token"},
        payload: {"name": name},
      );
      debugPrint("CREATE SKILL RESPONSE: $response");
      if (response != null && response['id'] != null) {
        final idx = _sections.indexWhere((s) => s.id == sectionId);
        if (idx != -1) {
          final removed = _sections[idx].items.indexWhere((i) => i.id == 0);
          if (removed != -1) _sections[idx].items.removeAt(removed);
          _sections[idx].items.add(SettingsItem.fromJson(response));
          notifyListeners();
        }
      } else {
        showToast(message: "Create failed");
      }
    } catch (e) {
      debugPrint("CREATE SKILL ERROR: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateItem({
    required int sectionId,
    required int id,
    required String newName,
  }) async {
    _setLoading(true);
    try {
      final sIdx = _sections.indexWhere((s) => s.id == sectionId);
      if (sIdx == -1) return;
      final section = _sections[sIdx];
      final endpoint = section.title.toLowerCase().contains("account")
          ? ApiRoutes.accountType
          : section.title.toLowerCase().contains("customer company")
          ? ApiRoutes.custCmpnyType
          : section.title.toLowerCase().contains("customer ranks")
          ? ApiRoutes.custRank
          : section.title.toLowerCase().contains("skills")
          ? ApiRoutes.skill
          : section.title.toLowerCase().contains("client company")
          ? ApiRoutes.clientCmpnyType
          : section.title.toLowerCase().contains("ranks")
          ? ApiRoutes.rank
          : ApiRoutes.language;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final res = await ApiService().postDataToApi(
        api: "$endpoint/$id",
        isPut: true,
        headers: {"Authorization": "Bearer $token"},
        payload: {"name": newName},
      );
      debugPrint("UPDATE RESPONSE: $res");
      if (res != null && res is Map && res['errors'] != null) {
        final msg =
            (res['errors']['name'] as List<dynamic>?)?.first ??
            'Validation error';
        showToast(message: msg.toString());
        return;
      }
      final itIdx = _sections[sIdx].items.indexWhere((i) => i.id == id);
      if (itIdx != -1) {
        _sections[sIdx].items[itIdx].name = newName;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("UPDATE ITEM ERROR: $e");
      showToast(message: "Update failed");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteItem(int sectionId, int itemId) async {
    _setLoading(true);
    try {
      final sIdx = _sections.indexWhere((s) => s.id == sectionId);
      if (sIdx == -1) return;
      final section = _sections[sIdx];
      if (itemId == 0) {
        _sections[sIdx].items.removeWhere((i) => i.id == 0);
        notifyListeners();
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final endpoint = section.title.toLowerCase().contains("account")
          ? ApiRoutes.accountType
          : section.title.toLowerCase().contains("customer company")
          ? ApiRoutes.custCmpnyType
          : section.title.toLowerCase().contains("customer ranks")
          ? ApiRoutes.custRank
          : section.title.toLowerCase().contains("skills")
          ? ApiRoutes.skill
          : section.title.toLowerCase().contains("client company")
          ? ApiRoutes.clientCmpnyType
          : section.title.toLowerCase().contains("ranks")
          ? ApiRoutes.rank
          : ApiRoutes.language;

      final url = Uri.parse("${ApiRoutes.baseUrl}$endpoint/$itemId");
      final res = await http.delete(
        url,
        headers: {"Authorization": "Bearer $token"},
      );
      debugPrint("DELETE ($itemId) STATUS: ${res.statusCode}");
      if (res.statusCode == 204 || res.statusCode == 200) {
        _sections[sIdx].items.removeWhere((i) => i.id == itemId);
        notifyListeners();
      } else {
        debugPrint("DELETE failed body: ${res.body}");
        showToast(message: "Delete failed");
      }
    } catch (e) {
      debugPrint("DELETE ERROR: $e");
      showToast(message: "Delete failed");
    } finally {
      _setLoading(false);
    }
  }

  void toggleSection(int sectionId) {
    final idx = _sections.indexWhere((s) => s.id == sectionId);
    if (idx != -1) {
      _sections[idx].expanded = !_sections[idx].expanded;
      notifyListeners();
    }
  }

  void addItem(int sectionId) {
    final idx = _sections.indexWhere((s) => s.id == sectionId);
    if (idx == -1) return;
    final newItem = SettingsItem(id: 0, name: "", createdAt: "", updatedAt: "");
    _sections[idx].items.add(newItem);
  }

  void updateItemName(int sectionId, int itemId, String name) {
    final sIdx = _sections.indexWhere((s) => s.id == sectionId);
    if (sIdx == -1) return;
    final itIdx = _sections[sIdx].items.indexWhere((i) => i.id == itemId);
    if (itIdx == -1) return;
    _sections[sIdx].items[itIdx].name = name;
    notifyListeners();
  }
}
