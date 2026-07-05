import 'package:basalt_example/data/mappers/address_mapper.dart';
import 'package:basalt_example/data/mappers/order_item_mapper.dart';
import 'package:basalt_example/data/models/customer_profile_row.dart';
import 'package:basalt_example/data/models/customer_row.dart';
import 'package:basalt_example/data/mappers/order_mapper.dart';
import 'package:basalt_example/data/mappers/customer_mapper.dart';
import 'package:basalt_example/domain/entities/views/customer_profile.dart';
import 'package:basalt_example/domain/entities/views/order_summary.dart';

extension CustomerProfileRowMapper on CustomerProfileRow {
  CustomerProfile toDomain() => CustomerProfile(
        customer: CustomerRow(
          id: id,
          name: name,
          email: email,
          loyaltyTier: loyaltyTier,
          createdAt: createdAt,
        ).toDomain(),
        addresses: [for (final a in addresses) a.toDomain()],
        orders: [
          for (final o in orders)
            OrderSummary(
              order: o.toDomain(),
              items: [for (final i in o.items) i.toDomain()],
            ),
        ],
      );
}
