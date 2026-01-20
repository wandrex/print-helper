class LoginData {
  String emailPhone;
  String password;
  String role = "";

  LoginData({required this.emailPhone, required this.password, this.role = ""});

  Map<String, dynamic> toJson() => {'email': emailPhone, 'password': password};
}

class LoginResponseModel {
  final bool success;
  final String message;
  final UserModel user;
  final String token;
  final String tokenType;

  LoginResponseModel({
    required this.success,
    required this.message,
    required this.user,
    required this.token,
    required this.tokenType,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      user: UserModel.fromJson(json["data"]["user"]),
      token: json["data"]["token"] ?? "",
      tokenType: json["data"]["token_type"] ?? "",
    );
  }
}

class UserModel {
  final int id;
  final String name;
  final String lastName;
  final String email;
  final String username;
  final String phone;
  final String personalPhone;
  final String? image;
  final String language;
  final int role;
  final String roleName;
  final String accountType;
  final bool status;
  final int isPrimary;
  final int customerId;
  final int custClientId;
  final dynamic clientId;
  final String createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.username,
    required this.phone,
    required this.personalPhone,
    required this.image,
    required this.language,
    required this.role,
    required this.roleName,
    required this.accountType,
    required this.status,
    required this.customerId,
    required this.custClientId,
    required this.isPrimary,
    required this.clientId,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["id"],
      name: json["name"] ?? "",
      lastName: json["last_name"] ?? "",
      email: json["email"] ?? "",
      username: json["username"] ?? "",
      phone: json["phone"] ?? "",
      personalPhone: json["personal_phone"] ?? "",
      image: json["image"] == null || json["image"].toString().isEmpty
          ? null
          : json["image"],
      language: json["language"] ?? "en",
      role: json["role"] ?? 0,
      roleName: json["role_name"] ?? "",
      accountType: json["account_type"] ?? "",
      status: json["status"] ?? false,
      isPrimary: json["is_primary"] ?? 0,
      clientId: json["client_id"],
      customerId: json["customer_id"] ?? 0,
      custClientId: json["customer_client_id"] ?? 0,
      createdAt: json["created_at"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "last_name": lastName,
    "email": email,
    "username": username,
    "phone": phone,
    "personal_phone": personalPhone,
    "image": image,
    "language": language,
    "role": role,
    "role_name": roleName,
    "account_type": accountType,
    "status": status,
    "is_primary": isPrimary,
    "client_id": clientId,
    "created_at": createdAt,
  };
}
