class ProjectModel {
  final String id;
  final String name;
  final int comments;
  final int files;
  final String date;
  final String company;
  final int progress;
  final String status;
  final List<String> avatars;

  ProjectModel({
    required this.id,
    required this.name,
    required this.comments,
    required this.files,
    required this.date,
    required this.company,
    required this.progress,
    required this.status,
    required this.avatars,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json["id"],
      name: json["name"],
      comments: json["comments"],
      files: json["files"],
      date: json["date"],
      company: json["company"],
      progress: json["progress"],
      status: json["status"],
      avatars: List<String>.from(json["avatars"] ?? []),
    );
  }
}

List<ProjectModel> projectsFromJson(List list) =>
    list.map((e) => ProjectModel.fromJson(e)).toList();
