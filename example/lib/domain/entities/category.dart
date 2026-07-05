/// A product category. May have a [parent] category (a self-referential
/// belongs-to), which is `null` for top-level roots.
class Category {
  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.parent,
  });

  final int id;
  final String name;
  final int? parentId;
  final Category? parent;

  bool get isRoot => parentId == null;
}
