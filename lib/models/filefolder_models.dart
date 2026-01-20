class FileModel {
  final String id; // <-- new
  final String filename;
  final String thumbnail;
  final List<String> uploadedBy;
  final String type;

  FileModel({
    required this.id,
    required this.filename,
    required this.thumbnail,
    required this.uploadedBy,
    required this.type,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id']?.toString() ?? '',
      filename: json['filename'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      uploadedBy: List<String>.from(json['uploadedBy'] ?? []),
      type: json['type'] ?? 'image',
    );
  }
}

List<FileModel> filesFromJson(List list) =>
    list.map((e) => FileModel.fromJson(e)).toList();

class FolderModel {
  final String id;
  final String title;
  final String icon;

  FolderModel({required this.title, required this.icon, required this.id});

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id']?.toString() ?? '',
      title: json["title"],
      icon: json["icon"],
    );
  }
}

List<FolderModel> foldersFromJson(List<dynamic> list) =>
    list.map((e) => FolderModel.fromJson(e as Map<String, dynamic>)).toList();
