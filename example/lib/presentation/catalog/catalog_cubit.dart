import 'package:basalt_example/domain/repositories/category_repository.dart';
import 'package:basalt_example/domain/repositories/product_repository.dart';
import 'package:basalt_example/presentation/catalog/catalog_state.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the catalogue screen — loads categories once and re-queries products
/// whenever the search text or category filter changes.
class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._products, this._categories) : super(const CatalogState());

  final ProductRepository _products;
  final CategoryRepository _categories;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, error: null));
    try {
      final categories = await _categories.all();
      final products = await _products.list(
        search: state.search,
        categoryId: state.selectedCategoryId,
      );
      emit(state.copyWith(
        status: LoadStatus.success,
        categories: categories,
        products: products,
      ));
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, error: '$e'));
    }
  }

  Future<void> search(String query) async {
    emit(state.copyWith(search: query));
    await _reloadProducts();
  }

  Future<void> selectCategory(int? categoryId) async {
    emit(state.copyWith(selectedCategoryId: categoryId));
    await _reloadProducts();
  }

  Future<void> _reloadProducts() async {
    emit(state.copyWith(status: LoadStatus.loading, error: null));
    try {
      final products = await _products.list(
        search: state.search,
        categoryId: state.selectedCategoryId,
      );
      emit(state.copyWith(status: LoadStatus.success, products: products));
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, error: '$e'));
    }
  }
}
