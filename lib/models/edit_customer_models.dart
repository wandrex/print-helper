class EditCustomerModel {
  int id;
  int clientId;
  String companyName;
  String? imageUrl;
  String? companyCategoryName;
  String? companyTypeName;
  String? customerRankName;
  int? categoryTypeId;
  int? customerRankId;
  List<EditCustomerContact> contacts;

  EditCustomerModel({
    required this.id,
    required this.clientId,
    required this.companyName,
    this.companyTypeName,
    this.imageUrl,
    this.companyCategoryName,
    this.customerRankName,
    this.categoryTypeId,
    this.customerRankId,
    required this.contacts,
  });

  factory EditCustomerModel.fromJson(Map<String, dynamic> json) {
    return EditCustomerModel(
      id: json["id"],
      clientId: json["client_id"],
      companyName: json["company_name"] ?? "",
      companyTypeName: json["company_type"],
      imageUrl: json["image_url"],
      companyCategoryName: json["company_category_name"],
      customerRankName: json["customer_rank_name"],
      categoryTypeId: null,
      customerRankId: null,
      contacts: (json["contacts"] as List)
          .map((c) => EditCustomerContact.fromJson(c))
          .toList(),
    );
  }
}

class EditCustomerContact {
  int contactId;
  bool isPrimary;

  String name;
  String lastName;
  String email;
  String username;
  String? imageUrl;

  List<EditPhoneModel> phones;
  List<String> emails;
  List<int> languageIds;

  EditCustomerContact({
    required this.contactId,
    required this.isPrimary,
    required this.name,
    required this.lastName,
    required this.email,
    required this.username,
    this.imageUrl,
    required this.phones,
    required this.emails,
    required this.languageIds,
  });

  factory EditCustomerContact.fromJson(Map<String, dynamic> json) {
    final d = json["contact_details"];

    return EditCustomerContact(
      contactId: json["id"],
      isPrimary: json["is_primary"] == 1,

      name: json["name"] ?? "",
      lastName: json["last_name"] ?? "",
      email: json["email"] ?? "",
      username: json["username"] ?? "",
      imageUrl: json["image_url"],

      phones: d == null
          ? []
          : (d["phones"] as List)
                .map((p) => EditPhoneModel.fromJson(p))
                .toList(),

      emails: d == null ? [] : List<String>.from(d["emails"] ?? []),

      languageIds: d == null
          ? []
          : (d["languages"] as List).map((l) => l["id"] as int).toList(),
    );
  }
}

class EditPhoneModel {
  String type;
  String number;

  EditPhoneModel({required this.type, required this.number});

  factory EditPhoneModel.fromJson(Map<String, dynamic> json) {
    return EditPhoneModel(type: json["type"], number: json["number"]);
  }
}
