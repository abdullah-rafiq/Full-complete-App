class CategoryModel {
  final String id;
  final String name;
  final String? iconUrl;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
    this.isActive = true,
  });

  factory CategoryModel.fromMap(String id, Map<String, dynamic> data) {
    return CategoryModel(
      id: id,
      name: data['name'] as String? ?? '',
      iconUrl: data['iconUrl'] as String?,
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconUrl': iconUrl,
      'isActive': isActive,
    };
  }
}
