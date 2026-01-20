import 'dart:convert';

User userFromJson(dynamic data, String token) => User.fromJson(data, token);

class User {
  final String id;
  final String fname;
  final String lname;
  final String email;
  final String phone;
  final String image;
  final String token;

  User({
    this.id = '',
    this.fname = '',
    this.lname = '',
    this.email = '',
    this.phone = '',
    this.image = '',
    this.token = '',
  });

  factory User.fromJson(dynamic data, String token) {
    final String name = data['name'] ?? '';
    return User(
      id: '${data['userId']}',
      fname: name.split(' ')[0],
      lname: name.split(' ')[1],
      email: data['email'] ?? '',
      phone: '${data['phone']}',
      image: data['image'] ?? '',
      token: token,
    );
  }

  bool get isLoggedIn => token.isNotEmpty;
  String get fullName => '$fname $lname'.trim();
}

//UpdatedUser
UpdatedUser updatedUserFromJson(dynamic data) =>
    UpdatedUser.fromJson(data['user'] ?? data);

// not encoded as its multipart
dynamic updateUserToJson(UpdatedUser data) => json.encode(data.toJson());

class UpdatedUser {
  final String id;
  final String fname;
  final String lname;
  final String email;
  final String phone;
  final String? image;
  final String password;

  UpdatedUser({
    this.id = '',
    this.fname = '',
    this.lname = '',
    this.email = '',
    this.phone = '',
    this.image,
    this.password = '',
  });

  factory UpdatedUser.fromJson(Map<String, dynamic> json) {
    // final avatar = '${json["avatar"]}';
    final phone = json['phone'];
    return UpdatedUser(
      id: '${json['id']}',
      fname: json['fName'] ?? '',
      lname: json['lName'] ?? '',
      email: json['email'] ?? '',
      phone: phone != null ? '$phone' : '',
      image: '', // TODO: fetaure not implemented
      // image: avatar.isEmpty ? null : avatar,
      // to ensure image is not passed as empty string
      // which results in redundant data being sent to the server
    );
  }

  Map<String, String> toJson() => {
    'id': id,
    if (fname.isNotEmpty) 'fName': fname,
    if (lname.isNotEmpty) 'lName': lname,
    if (email.isNotEmpty) 'email': email,
    if (phone.isNotEmpty) 'phone': phone,
    // image is added as empty string to remove the image from the server
    if (image != null && image!.isEmpty) 'image': '',
    if (password.isNotEmpty) 'password': password,
  };

  UpdatedUser copyWith({
    String? id,
    String? fname,
    String? lname,
    String? email,
    String? phone,
    String? image,
    String? password,
  }) {
    return UpdatedUser(
      id: id ?? this.id,
      fname: fname ?? this.fname,
      lname: lname ?? this.lname,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      password: password ?? this.password,
    );
  }
}
