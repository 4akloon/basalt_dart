import 'package:basalt_example/domain/entities/views/customer_profile.dart';
import 'package:basalt_example/presentation/common/load_status.dart';
import 'package:equatable/equatable.dart';

/// State for a single customer's profile.
class CustomerProfileState extends Equatable {
  const CustomerProfileState({
    this.status = LoadStatus.initial,
    this.profile,
    this.error,
  });

  final LoadStatus status;
  final CustomerProfile? profile;
  final String? error;

  CustomerProfileState copyWith({
    LoadStatus? status,
    CustomerProfile? profile,
    String? error,
  }) {
    return CustomerProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, profile, error];
}
