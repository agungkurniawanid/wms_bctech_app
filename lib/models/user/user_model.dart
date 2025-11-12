class NewUserModel {
  final String username;
  final String active;
  final String email;
  final List<dynamic> inList;
  final String updated;
  final String updatedby;
  String? photoUrl;

  NewUserModel({
    required this.username,
    required this.active,
    required this.email,
    required this.inList,
    required this.updated,
    required this.updatedby,
    this.photoUrl,
  });

  factory NewUserModel.fromMap(Map<String, dynamic> map) {
    return NewUserModel(
      username: map['username'] ?? '',
      active: map['active']?.toString() ?? '',
      email: map['email'] ?? '',
      inList: (map['in'] is List) ? List<String>.from(map['in']) : [],
      updated: map['updated'] ?? '',
      updatedby: map['updatedby'] ?? '',
      photoUrl: map['photo_url'], // <-- PERBAIKAN DI SINI
    );
  }
}
