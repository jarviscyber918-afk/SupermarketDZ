import 'dart:convert';

class SaleItem {
  final String productId;
  final String name;
  final String barcode;
  final int quantity;
  final double price;
  final double total;

  SaleItem({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.quantity,
    required this.price,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'barcode': barcode,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }

  factory SaleItem.fromMap(Map<dynamic, dynamic> map) {
    return SaleItem(
      productId: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      barcode: map['barcode']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SaleTransaction {
  final String id;
  final int receiptNumber;
  final DateTime timestamp;
  final List<SaleItem> items;
  final double totalAmount;
  final double cashReceived;
  final double changeDue;
  final String shopName;

  SaleTransaction({
    required this.id,
    required this.receiptNumber,
    required this.timestamp,
    required this.items,
    required this.totalAmount,
    required this.cashReceived,
    required this.changeDue,
    required this.shopName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiptNumber': receiptNumber,
      'timestamp': timestamp.toIso8601String(),
      'items': items.map((x) => x.toMap()).toList(),
      'totalAmount': totalAmount,
      'cashReceived': cashReceived,
      'changeDue': changeDue,
      'shopName': shopName,
    };
  }

  factory SaleTransaction.fromMap(Map<dynamic, dynamic> map) {
    return SaleTransaction(
      id: map['id']?.toString() ?? '',
      receiptNumber: (map['receiptNumber'] as num?)?.toInt() ?? 1,
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => SaleItem.fromMap(Map<dynamic, dynamic>.from(e as Map)))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      cashReceived: (map['cashReceived'] as num?)?.toDouble() ?? 0.0,
      changeDue: (map['changeDue'] as num?)?.toDouble() ?? 0.0,
      shopName: map['shopName']?.toString() ?? 'Supermarket DZ',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SaleTransaction.fromJson(String source) =>
      SaleTransaction.fromMap(jsonDecode(source));
}
