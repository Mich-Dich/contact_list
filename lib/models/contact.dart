
class Contact {
  String id;
  String firstName;
  String lastName;
  String phone;
  String email;
  String description;
  List<String> tags;

  Contact({
    String? id,
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.email = '',
    this.description = '',
    List<String>? tags,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        tags = tags ?? [];

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? '(no name)' : name;
  }

  /// Short hex id like "0x4A2F" for a memory-address vibe.
  String get hexId {
    final v = int.tryParse(id) ?? 0;
    final hex = (v & 0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0');
    return '0x$hex';
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    final s = (f + l).toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'description': description,
        'tags': tags,
      };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String?,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        description: json['description'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      );

  Contact copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? description,
    List<String>? tags,
  }) =>
      Contact(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        description: description ?? this.description,
        tags: tags ?? List<String>.from(this.tags),
      );
}
