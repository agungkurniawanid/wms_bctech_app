import 'dart:convert';

class RequestWorkflow {
  int? userid;
  final String? email;
  final String? password;
  String? role;
  String? documentno;
  final String? group;
  final String? token;
  final String? username;
  final String? lGORT;

  RequestWorkflow({
    this.userid,
    this.email,
    this.password,
    this.role,
    this.documentno,
    this.group,
    this.token,
    this.username,
    this.lGORT,
  });

  RequestWorkflow copyWith({
    int? userid,
    String? email,
    String? password,
    String? role,
    String? documentno,
    String? group,
    String? token,
    String? username,
    String? lGORT,
  }) {
    return RequestWorkflow(
      userid: userid ?? this.userid,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      documentno: documentno ?? this.documentno,
      group: group ?? this.group,
      token: token ?? this.token,
      username: username ?? this.username,
      lGORT: lGORT ?? this.lGORT,
    );
  }

  Map<String, dynamic> toJsonLogin() => {"email": email, "password": password};
  Map<String, dynamic> toJsonEmail() => {"documentno": documentno};

  Map<String, dynamic> toJsonApproveIn() => {
    "group": group,
    "ebeln": documentno,
    "all": role,
  };

  Map<String, dynamic> toJsonSaveNoDocument() => {
    "username": username,
    "ebeln": documentno,
  };

  Map<String, dynamic> toJsonGetDocument() => {"ebeln": documentno};
  Map<String, dynamic> toJsonGetStock() => {"LGORT": lGORT};

  Map<String, dynamic> toJsonApproveSR() => {
    "documentno": documentno,
    "group": group,
  };

  Map<String, dynamic> toJsonRefreshStock() => {
    "werks": group,
    "lgort": documentno,
    "username": username,
  };

  Map<String, dynamic> toAuth() => {"Authorization": token};
  Map<String, dynamic> toJsonCategory() => {"userid": userid, "role": role};

  factory RequestWorkflow.fromJson(Map<String, dynamic> json) =>
      RequestWorkflow(
        userid: json['userid'],
        email: json['email'],
        password: json['password'],
        role: json['role'],
        documentno: json['documentno'],
        group: json['group'],
        token: json['token'],
        username: json['username'],
        lGORT: json['LGORT'],
      );
}

String toJsonLogin(RequestWorkflow data) => json.encode(data.toJsonLogin());
String toJsonEmail(RequestWorkflow data) => json.encode(data.toJsonEmail());
String toJsonApproveSR(RequestWorkflow data) =>
    json.encode(data.toJsonApproveSR());

String toJsonRefreshStock(RequestWorkflow data) =>
    json.encode(data.toJsonRefreshStock());

String toJsonApproveIn(RequestWorkflow data) =>
    json.encode(data.toJsonApproveIn());

String toJsonSaveNoDocument(RequestWorkflow data) =>
    json.encode(data.toJsonSaveNoDocument());

String toJsonGetStock(RequestWorkflow data) =>
    json.encode(data.toJsonGetStock());

String toJsonGetDocument(RequestWorkflow data) =>
    json.encode(data.toJsonGetDocument());

String toJsonCategory(RequestWorkflow data) =>
    json.encode(data.toJsonCategory());

Map<String, dynamic> toAuth(RequestWorkflow data) => data.toAuth();
