import 'package:basalt_example/data/models/category_revenue_row.dart';
import 'package:basalt_example/data/models/top_customer_row.dart';
import 'package:basalt_example/domain/entities/customer.dart';
import 'package:basalt_example/domain/entities/loyalty_tier.dart';
import 'package:basalt_example/domain/entities/views/analytics.dart';

extension CategoryRevenueRowMapper on CategoryRevenueRow {
  CategoryRevenue toDomain() => CategoryRevenue(
        categoryName: categoryName,
        revenue: revenue,
        unitsSold: unitsSold,
      );
}

extension TopCustomerRowMapper on TopCustomerRow {
  TopCustomer toDomain() => TopCustomer(
        customer: Customer(
          id: id,
          name: name,
          email: email,
          tier: LoyaltyTier.values.byName(loyaltyTier),
          joinedAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        ),
        totalSpent: totalSpent,
        orderCount: orderCount,
      );
}
