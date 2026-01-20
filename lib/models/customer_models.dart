class ClientModelCust {
  int id;
  String companyName;
  List<String> languagesNames;
  String? image;
  String companyType;
  String companyTypeName;
  String clientRank;

  String? brandingLogo;
  String brandingPrimaryColor;
  String brandingSecondaryColor;
  String brandingUrl;

  String address;
  String address2;
  String state;
  String city;
  String zipcode;

  bool status;
  int createdBy;
  int updatedBy;
  String createdAt;
  String updatedAt;

  ClientModelCust({
    required this.id,
    required this.companyName,
    required this.languagesNames,
    required this.image,
    required this.companyType,
    required this.companyTypeName,
    required this.clientRank,
    required this.brandingLogo,
    required this.brandingPrimaryColor,
    required this.brandingSecondaryColor,
    required this.brandingUrl,
    required this.address,
    required this.address2,
    required this.state,
    required this.city,
    required this.zipcode,
    required this.status,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  ClientModelCust copyWith({
    int? id,
    String? companyName,
    List<String>? languagesNames,
    String? image,
    String? companyType,
    String? companyTypeName,
    String? clientRank,
    String? brandingLogo,
    String? brandingPrimaryColor,
    String? brandingSecondaryColor,
    String? brandingUrl,
    String? address,
    String? address2,
    String? state,
    String? city,
    String? zipcode,
    bool? status,
    int? createdBy,
    int? updatedBy,
    String? createdAt,
    String? updatedAt,
  }) {
    return ClientModelCust(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      languagesNames: languagesNames ?? this.languagesNames,
      image: image ?? this.image,
      companyType: companyType ?? this.companyType,
      companyTypeName: companyTypeName ?? this.companyTypeName,
      clientRank: clientRank ?? this.clientRank,
      brandingLogo: brandingLogo ?? this.brandingLogo,
      brandingPrimaryColor: brandingPrimaryColor ?? this.brandingPrimaryColor,
      brandingSecondaryColor:
          brandingSecondaryColor ?? this.brandingSecondaryColor,
      brandingUrl: brandingUrl ?? this.brandingUrl,
      address: address ?? this.address,
      address2: address2 ?? this.address2,
      state: state ?? this.state,
      city: city ?? this.city,
      zipcode: zipcode ?? this.zipcode,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ClientModelCust.fromJson(Map<String, dynamic> json) {
    return ClientModelCust(
      id: json["id"],
      companyName: json["company_name"] ?? "",
      languagesNames: (json["languages_names"] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      image: json["image"],
      companyType: json["company_type"]?.toString() ?? "",
      companyTypeName: json["company_type_name"] ?? "",
      clientRank: json["client_rank"]?.toString() ?? "",
      brandingLogo: json["branding_logo"],
      brandingPrimaryColor: json["branding_primary_color"] ?? "",
      brandingSecondaryColor: json["branding_secondary_color"] ?? "",
      brandingUrl: json["branding_url"] ?? "",
      address: json["address"] ?? "",
      address2: json["address_2"] ?? "",
      state: json["state"]?.toString() ?? "",
      city: json["city"]?.toString() ?? "",
      zipcode: json["zipcode"]?.toString() ?? "",
      status: json["status"] == true,
      createdBy: json["created_by"] ?? 0,
      updatedBy: json["updated_by"] ?? 0,
      createdAt: json["created_at"] ?? "",
      updatedAt: json["updated_at"] ?? "",
    );
  }
}

class CustomerModel {
  int id;
  int clientId;
  String companyName;
  String? image;
  String? imageUrl;
  String companyCategoryName;
  String? customerRankName;
  String? brandingLogo;
  String brandingPrimaryColor;
  String brandingSecondaryColor;
  String brandingUrl;

  String address;
  String address2;
  String state;
  String city;
  String zipcode;
  bool status;
  int createdBy;
  int updatedBy;
  String createdAt;
  String updatedAt;
  List<ContactModel> contacts;

  CustomerModel({
    required this.id,
    required this.clientId,
    required this.companyName,
    required this.image,
    required this.imageUrl,
    required this.companyCategoryName,
    required this.customerRankName,
    required this.brandingLogo,
    required this.brandingPrimaryColor,
    required this.brandingSecondaryColor,
    required this.brandingUrl,
    required this.address,
    required this.address2,
    required this.state,
    required this.city,
    required this.zipcode,
    required this.status,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.contacts,
  });

  CustomerModel copyWith({
    int? id,
    int? clientId,
    String? companyName,
    String? image,
    String? imageUrl,
    String? companyCategoryName,
    String? customerRankName,
    String? brandingLogo,
    String? brandingPrimaryColor,
    String? brandingSecondaryColor,
    String? brandingUrl,
    String? address,
    String? address2,
    String? state,
    String? city,
    String? zipcode,
    bool? status,
    int? createdBy,
    int? updatedBy,
    String? createdAt,
    String? updatedAt,
    List<ContactModel>? contacts,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      companyName: companyName ?? this.companyName,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      companyCategoryName: companyCategoryName ?? this.companyCategoryName,
      customerRankName: customerRankName ?? this.customerRankName,
      brandingLogo: brandingLogo ?? this.brandingLogo,
      brandingPrimaryColor: brandingPrimaryColor ?? this.brandingPrimaryColor,
      brandingSecondaryColor:
          brandingSecondaryColor ?? this.brandingSecondaryColor,
      brandingUrl: brandingUrl ?? this.brandingUrl,
      address: address ?? this.address,
      address2: address2 ?? this.address2,
      state: state ?? this.state,
      city: city ?? this.city,
      zipcode: zipcode ?? this.zipcode,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contacts: contacts ?? this.contacts,
    );
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    final c = json["customer"];

    return CustomerModel(
      id: c["id"],
      clientId: c["client_id"],
      companyName: c["company_name"] ?? "",
      image: c["image"],
      imageUrl: c["image_url"],
      companyCategoryName: c["company_category_name"] ?? "",
      customerRankName: c["customer_rank_name"],
      brandingLogo: c["branding_logo"],
      brandingPrimaryColor: c["branding_primary_color"] ?? "",
      brandingSecondaryColor: c["branding_secondary_color"] ?? "",
      brandingUrl: c["branding_url"] ?? "",
      address: c["address"] ?? "",
      address2: c["address_2"] ?? "",
      state: c["state"]?.toString() ?? "",
      city: c["city"]?.toString() ?? "",
      zipcode: c["zipcode"]?.toString() ?? "",
      status: c["status"] == true,
      createdBy: c["created_by"] ?? 0,
      updatedBy: c["updated_by"] ?? 0,
      createdAt: c["created_at"] ?? "",
      updatedAt: c["updated_at"] ?? "",
      contacts: (c["contacts"] as List<dynamic>? ?? [])
          .map((e) => ContactModel.fromJson(e))
          .toList(),
    );
  }

  factory CustomerModel.fromClientModel(
    ClientModelCust client,
    int customerId,
  ) {
    return CustomerModel(
      id: customerId,
      clientId: client.id,
      companyName: client.companyName,
      image: client.image,
      imageUrl: client.image,
      companyCategoryName: client.companyTypeName,
      customerRankName: client.clientRank,
      brandingLogo: client.brandingLogo,
      brandingPrimaryColor: client.brandingPrimaryColor,
      brandingSecondaryColor: client.brandingSecondaryColor,
      brandingUrl: client.brandingUrl,
      address: client.address,
      address2: client.address2,
      state: client.state,
      city: client.city,
      zipcode: client.zipcode,
      status: client.status,
      createdBy: client.createdBy,
      updatedBy: client.updatedBy,
      createdAt: client.createdAt,
      updatedAt: client.updatedAt,
      contacts: const [],
    );
  }
}

class ContactModel {
  int contactId;
  int customerId;
  bool isPrimary;
  String name;
  String lastName;
  String email;
  String username;
  String? phone;
  String? personalPhone;
  String? image;
  String? imageUrl;
  int? language;
  int role;
  bool status;
  String createdAt;
  String updatedAt;
  int createdBy;
  int updatedBy;
  List<String> phones;
  List<String> emails;
  List<String> languages;

  ContactModel({
    required this.contactId,
    required this.customerId,
    required this.isPrimary,
    required this.name,
    required this.lastName,
    required this.email,
    required this.username,
    required this.phone,
    required this.personalPhone,
    required this.image,
    required this.imageUrl,
    required this.language,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.phones,
    required this.emails,
    required this.languages,
  });

  ContactModel copyWith({
    int? contactId,
    int? customerId,
    bool? isPrimary,
    String? name,
    String? lastName,
    String? email,
    String? username,
    String? phone,
    String? personalPhone,
    String? image,
    String? imageUrl,
    int? language,
    int? role,
    bool? status,
    String? createdAt,
    String? updatedAt,
    int? createdBy,
    int? updatedBy,
    List<String>? phones,
    List<String>? emails,
    List<String>? languages,
  }) {
    return ContactModel(
      contactId: contactId ?? this.contactId,
      customerId: customerId ?? this.customerId,
      isPrimary: isPrimary ?? this.isPrimary,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      personalPhone: personalPhone ?? this.personalPhone,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      language: language ?? this.language,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      phones: phones ?? this.phones,
      emails: emails ?? this.emails,
      languages: languages ?? this.languages,
    );
  }

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    final d = json["contact_details"];
    return ContactModel(
      contactId: json["id"],
      customerId: json["customer_id"],
      isPrimary: json["is_primary"] == 1,
      name: json["name"] ?? "",
      lastName: json["last_name"] ?? "",
      email: json["email"] ?? "",
      username: json["username"] ?? "",
      phone: json["phone"],
      personalPhone: json["personal_phone"],
      image: json["image"],
      imageUrl: json["image_url"],
      language: json["language"],
      role: json["role"] ?? 0,
      status: json["status"] == true,
      createdAt: json["created_at"] ?? "",
      updatedAt: json["updated_at"] ?? "",
      createdBy: json["created_by"] ?? 0,
      updatedBy: json["updated_by"] ?? 0,
      phones: d == null
          ? []
          : (d["phones"] as List).map((p) => p["number"].toString()).toList(),
      emails: d == null
          ? []
          : (d["emails"] as List).map((e) => e.toString()).toList(),
      languages: d == null
          ? []
          : (d["languages"] as List)
                .map((lang) => lang["name"]?.toString() ?? "")
                .toList(),
    );
  }
}

class ContactDetailsModel {
  int id;
  int? clientId;
  int customerId;
  int contactId;
  List<Map<String, dynamic>> phones;
  List<String> emails;
  List<String> languages;
  String createdAt;
  String updatedAt;

  ContactDetailsModel({
    required this.id,
    required this.clientId,
    required this.customerId,
    required this.contactId,
    required this.phones,
    required this.emails,
    required this.languages,
    required this.createdAt,
    required this.updatedAt,
  });

  ContactDetailsModel copyWith({
    int? id,
    int? clientId,
    int? customerId,
    int? contactId,
    List<Map<String, dynamic>>? phones,
    List<String>? emails,
    List<String>? languages,
    String? createdAt,
    String? updatedAt,
  }) {
    return ContactDetailsModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      customerId: customerId ?? this.customerId,
      contactId: contactId ?? this.contactId,
      phones: phones ?? this.phones,
      emails: emails ?? this.emails,
      languages: languages ?? this.languages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ContactDetailsModel.fromJson(Map<String, dynamic> json) {
    return ContactDetailsModel(
      id: json["id"],
      clientId: json["client_id"],
      customerId: json["customer_id"],
      contactId: json["contact_id"],
      phones: (json["phones"] as List<dynamic>? ?? [])
          .map((e) => {"type": e["type"], "number": e["number"]})
          .toList(),
      emails: (json["emails"] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      languages: (json["languages"] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      createdAt: json["created_at"] ?? "",
      updatedAt: json["updated_at"] ?? "",
    );
  }
}
