class Category {
  final String? category;
  final String? inventoryGroupId;
  final String? inventoryGroupName;

  const Category({
    this.category,
    this.inventoryGroupId,
    this.inventoryGroupName,
  });

  factory Category.fromJson(Map<String, dynamic> data) {
    return Category(
      category: data['category']?.toString(),
      inventoryGroupId: data['inventory_group_id']?.toString(),
      inventoryGroupName: data['inventory_group_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (category != null) 'category': category,
      if (inventoryGroupId != null) 'inventory_group_id': inventoryGroupId,
      if (inventoryGroupName != null)
        'inventory_group_name': inventoryGroupName,
    };
  }

  @override
  String toString() {
    return 'Category(category: $category, inventoryGroupId: $inventoryGroupId, inventoryGroupName: $inventoryGroupName)';
  }
}
