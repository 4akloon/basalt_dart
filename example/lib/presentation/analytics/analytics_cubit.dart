import 'package:basalt_example/domain/repositories/analytics_repository.dart';
import 'package:basalt_example/presentation/analytics/analytics_state.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Loads the three analytics rollups for the dashboard.
class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit(this._analytics) : super(const AnalyticsState());

  final AnalyticsRepository _analytics;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final revenue = await _analytics.revenueByCategory();
      final top = await _analytics.topCustomers();
      final low = await _analytics.lowStock();
      emit(state.copyWith(
        status: LoadStatus.success,
        revenueByCategory: revenue,
        topCustomers: top,
        lowStock: low,
      ));
    } catch (e) {
      emit(state.copyWith(status: LoadStatus.failure, error: '$e'));
    }
  }
}
