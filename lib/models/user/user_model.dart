class NewUserModel {
  final String username;
  final String active;
  final List<dynamic> inList;
  final String updated;
  final String updatedby;

  NewUserModel({
    required this.username,
    required this.active,
    required this.inList,
    required this.updated,
    required this.updatedby,
  });

  factory NewUserModel.fromMap(Map<String, dynamic> map) {
    return NewUserModel(
      username: map['username'] ?? '',
      active: map['active']?.toString() ?? '',
      inList: (map['in'] is List) ? List<String>.from(map['in']) : [],
      updated: map['updated'] ?? '',
      updatedby: map['updatedby'] ?? '',
    );
  }
}
