import 'package:flutter/material.dart';

import '../dummy_json.dart';
import '../models/projects_models.dart';
import '../services/helpers.dart';
import '../utils/console_util.dart';

class ProjectPro extends ChangeNotifier {
  bool projectLoad = false;

  final List<ProjectModel> _projects = [];
  List<ProjectModel> get projects => _projects;

  bool _isSuccess(Map<String, dynamic> data) =>
      data['status'] == true && data['message'] == 'success';

  Future<void> getProjects({required BuildContext ctx}) async {
    projectLoad = true;
    notifyListeners();
    try {
      await delayed(millisec: 1000);
      final data = projectsJson;
      if (_isSuccess(data)) {
        debugPrint('0000');
        final result = data['projects'] as List<dynamic>?;
        debugPrint('111111');
        if (result != null) {
          debugPrint('2222');
          _projects.clear();
          _projects.addAll(projectsFromJson(result));
          debugPrint('3333');
          debugPrint(_projects.first.id);
        }
      }
      debugPrint('4444');
    } catch (e, st) {
      printData(title: "Project Load Error", data: "$e\n$st", e: true);
    } finally {
      projectLoad = false;
      notifyListeners();
    }
  }
}
