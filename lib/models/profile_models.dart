class ProfileResponse {
  final bool success;
  final ProfileData data;

  ProfileResponse({required this.success, required this.data});

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      success: json['success'] ?? false,
      data: ProfileData.fromJson(json['data']),
    );
  }
}

class ProfileData {
  final int id;
  final String name;
  final String lastName;
  final String email;
  final String phone;
  final List<String> emails;
  final List<String> phones;
  final String image;
  final int role; // New field
  final bool isOnline;
  final String? lastSeenAt;
  final DateTime createdAt; // New field
  final Customer? customer; // Updated structure
  final String companyName;
  final String companyLogo;
  final String companySegment;
  final String companyMeetingAt;
  final List<String> preferredLanguages;
  final List<String> skills; // Kept from previous request
  final int projectsCount;
  final int filesCount;
  final int contactsCount;
  final List<Recording> recordings;

  ProfileData({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.emails,
    required this.phones,
    required this.image,
    required this.role,
    required this.isOnline,
    this.lastSeenAt,
    required this.createdAt,
    this.customer,
    required this.companyName,
    required this.companyLogo,
    required this.companySegment,
    required this.companyMeetingAt,
    required this.preferredLanguages,
    required this.skills,
    required this.projectsCount,
    required this.filesCount,
    required this.contactsCount,
    required this.recordings,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      emails: List<String>.from(json['emails'] ?? []),
      phones: List<String>.from(json['phones'] ?? []),
      image: json['image'] ?? '',
      role: json['role'] ?? 0,
      isOnline: json['is_online'] ?? false,
      lastSeenAt: json['last_seen_at'],
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'])
          : null,
      companyName: json['company_name'] ?? '',
      companyLogo: json['company_logo'] ?? '',
      companySegment: json['company_segment'] ?? '',
      companyMeetingAt: json['company_meeting_at'] ?? '',
      preferredLanguages: List<String>.from(json['preferred_languages'] ?? []),
      skills: List<String>.from(json['skills'] ?? []),
      projectsCount: json['projects_count'] ?? 0,
      filesCount: json['files_count'] ?? 0,
      contactsCount: json['contacts_count'] ?? 0,
      recordings: (json['recordings'] as List<dynamic>? ?? [])
          .map((e) => Recording.fromJson(e))
          .toList(),
    );
  }
}

class Recording {
  final int id;
  final String title;
  final String duration; // Keep raw string for display/parsing
  final String voicePath;
  final String voiceUrl;
  final DateTime? recordedAt;
  final String? timeLabel;
  final int? conversationId;
  final int? messageId;

  Recording({
    required this.id,
    required this.title,
    required this.duration,
    required this.voicePath,
    required this.voiceUrl,
    required this.recordedAt,
    required this.timeLabel,
    required this.conversationId,
    required this.messageId,
  });

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Voice message',
      duration: json['duration'] ?? '00:00',
      voicePath: json['voice_path'] ?? '',
      voiceUrl: json['voice_url'] ?? '',
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at'].toString())
          : null,
      timeLabel: json['time_label'],
      conversationId: json['conversation_id'],
      messageId: json['message_id'],
    );
  }
}

class Customer {
  final int id;
  final String companyName;
  final String image;
  final String? companyType; // New
  final String? companyCategory;
  final String? customerRank;
  final String? brandingLogo; // New
  final String? brandingPrimaryColor; // New
  final String? brandingSecondaryColor; // New
  final String? brandingUrl; // New
  final String? address; // New
  final String? address2; // New
  final String? state; // New
  final String? city; // New
  final String? zipcode; // New
  final List<String>? phones; // New (Nullable list)
  final List<String>? emails; // New (Nullable list)
  final List<String>? languages; // New (Nullable list)
  final int contactsCount; // New

  Customer({
    required this.id,
    required this.companyName,
    required this.image,
    this.companyType,
    this.companyCategory,
    this.customerRank,
    this.brandingLogo,
    this.brandingPrimaryColor,
    this.brandingSecondaryColor,
    this.brandingUrl,
    this.address,
    this.address2,
    this.state,
    this.city,
    this.zipcode,
    this.phones,
    this.emails,
    this.languages,
    required this.contactsCount,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      companyName: json['company_name'] ?? '',
      image: json['image'] ?? '',
      companyType: json['company_type'],
      companyCategory: json['company_category'],
      customerRank: json['customer_rank'],
      brandingLogo: json['branding_logo'],
      brandingPrimaryColor: json['branding_primary_color'],
      brandingSecondaryColor: json['branding_secondary_color'],
      brandingUrl: json['branding_url'],
      address: json['address'],
      address2: json['address_2'],
      state: json['state'],
      city: json['city'],
      zipcode: json['zipcode'],
      phones: json['phones'] != null ? List<String>.from(json['phones']) : null,
      emails: json['emails'] != null ? List<String>.from(json['emails']) : null,
      languages: json['languages'] != null
          ? List<String>.from(json['languages'])
          : null,
      contactsCount: json['contacts_count'] ?? 0,
    );
  }
}
