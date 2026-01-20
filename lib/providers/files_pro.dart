import 'package:flutter/material.dart';

import '../dummy_json.dart';
import '../models/filefolder_models.dart';
import '../services/helpers.dart';
import '../utils/console_util.dart';

class FilesPro extends ChangeNotifier {
  bool filesLoad = false;

  final List<FolderModel> folders = [];
  final List<FileModel> files = [];

  final Set<String> selected = {};

  bool get isSelecting => selected.isNotEmpty;

  void toggleSelect(String id) {
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    selected.clear();
    notifyListeners();
  }

  bool _isSuccess(Map<String, dynamic> data) =>
      data['status'] == true && data['message'] == 'success';

  Future<void> getFiles({required BuildContext ctx}) async {
    filesLoad = true;
    notifyListeners();
    try {
      await delayed(millisec: 1000);
      final data = filesJson;
      if (_isSuccess(data)) {
        final f1 = data["folders"] as List<dynamic>?;
        final f2 = data["files"] as List<dynamic>?;
        folders.clear();
        files.clear();
        if (f1 != null) folders.addAll(foldersFromJson(f1));
        if (f2 != null) files.addAll(filesFromJson(f2));
      }
    } catch (e, st) {
      printData(title: "Files Load Error", data: "$e\n$st", e: true);
    } finally {
      filesLoad = false;
      notifyListeners();
    }
  }
}
