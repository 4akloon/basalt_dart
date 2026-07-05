import 'package:basalt_example/domain/entities/category.dart';
import 'package:basalt_example/domain/entities/product.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:equatable/equatable.dart';

/// State for the catalogue screen: the product list plus the active filters.
class CatalogState extends Equatable {
  const CatalogState({
    this.status = LoadStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.search = '',
    this.error,
  });

  final LoadStatus status;
  final List<Product> products;
  final List<Category> categories;
  final int? selectedCategoryId;
  final String search;
  final String? error;

  static const Object _keep = Object();

  CatalogState copyWith({
    LoadStatus? status,
    List<Product>? products,
    List<Category>? categories,
    Object? selectedCategoryId = _keep,
    String? search,
    String? error,
  }) {
    return CatalogState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategoryId: identical(selectedCategoryId, _keep)
          ? this.selectedCategoryId
          : selectedCategoryId as int?,
      search: search ?? this.search,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props =>
      [status, products, categories, selectedCategoryId, search, error];
}
