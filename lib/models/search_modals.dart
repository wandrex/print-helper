class SearchUsers {
  final int id;
  final String name;
  final String lastName;
  final String? email;
  final String? image;
  final int role;

  SearchUsers({
    required this.id,
    required this.name,
    required this.lastName,
    this.email,
    this.image,
    required this.role,
  });

  factory SearchUsers.fromJson(Map<String, dynamic> json) {
    return SearchUsers(
      id: json['id'],
      name: json['name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      image: json['image'],
      role: json['role'] ?? 0,
    );
  }
  String get fullName => '$name $lastName'.trim();
}
