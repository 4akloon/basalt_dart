import 'package:basalt_example/data/mappers/address_mapper.dart';
import 'package:basalt_example/data/mappers/customer_mapper.dart';
import 'package:basalt_example/data/models/order_row.dart';
import 'package:basalt_example/domain/entities/order.dart';
import 'package:basalt_example/domain/entities/order_status.dart';

/// Converts an [OrderRow] into a domain [Order], decoding the status enum and
/// timestamp and mapping the nested customer / shipping address.
extension OrderRowMapper on OrderRow {
  Order toDomain() => Order(
        id: id,
        customerId: customerId,
        status: OrderStatus.values.byName(status),
        placedAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        shippingAddressId: shippingAddressId,
        customer: customer?.toDomain(),
        shippingAddress: shippingAddress?.toDomain(),
      );
}
