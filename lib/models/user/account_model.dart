import 'dart:convert';

class Account {
  final String? userid;
  final String? name;
  final String? email;
  final int? status;
  final String? hasLogin;

  Account({this.userid, this.name, this.email, this.status, this.hasLogin});

  factory Account.fromJson(Map<String, dynamic> data) {
    return Account(
      userid: data['ldapid']?.toString(),
      name: data['name']?.toString(),
      email: data['email']?.toString(),
      status: data['status'] is int
          ? data['status']
          : int.tryParse(data['status']?.toString() ?? '0'),
      hasLogin: data['hasLogin']?.toString(),
    );
  }

  Map<String, dynamic> toJsonUser() => {"username": email};

  @override
  String toString() {
    return 'Account(userid: $userid, name: $name, email: $email, status: $status, hasLogin: $hasLogin)';
  }
}

String toJsonUser(Account data) {
  final jsonData = data.toJsonUser();
  return json.encode(jsonData);
}
