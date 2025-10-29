class ItemChoice {
  int? id;
  String? label;
  String? labelName;

  ItemChoice({this.id, this.label, this.labelName});

  factory ItemChoice.fromJson(Map<String, dynamic> json) {
    return ItemChoice(
      id: json['id'],
      label: json['label'],
      labelName: json['labelname'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'label': label, 'labelname': labelName};
  }

  ItemChoice clone() {
    return ItemChoice(id: id, label: label, labelName: labelName);
  }
}
