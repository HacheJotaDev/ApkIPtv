import '../utils/text_utils.dart';

class Category {
  final String id;
  final String name;
  final String parentId;
  final String type;

  Category({
    required this.id,
    required this.name,
    this.parentId = '',
    this.type = '',
  });

  factory Category.fromJson(Map<String, dynamic> json, {String type = ''}) {
    return Category(
      id: json['category_id']?.toString() ?? '',
      name: TextUtils.cleanText(json['category_name']?.toString()) ?? 'Sin nombre',
      parentId: json['parent_id']?.toString() ?? '',
      type: type,
    );
  }
}
