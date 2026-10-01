// ignore_for_file: overridden_fields
import 'package:hive/hive.dart';
import '../../domain/entities/product.dart';

part 'product_model.g.dart'; // Hive generator

@HiveType(typeId: 0)
class ProductModel extends Product {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(2)
  final String barcode;
  @override
  @HiveField(3)
  final double price;
  @override
  @HiveField(4)
  final int stock;

  const ProductModel({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.stock,
  }) : super(
          id: id,
          name: name,
          barcode: barcode,
          price: price,
          stock: stock,
        );

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      barcode: product.barcode,
      price: product.price,
      stock: product.stock,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final barcode = (json['Code Barre'] ??
            json['code_barre'] ??
            json['barcode'] ??
            json['CodeBarre'] ??
            '')
        .toString()
        .trim();
    final ref = (json['Référence'] ??
            json['Reference'] ??
            json['RAcfAcrence'] ??
            json['Rfrence'] ??
            '')
        .toString()
        .trim();
    final id = (json['id'] ?? (barcode.isNotEmpty ? barcode : ref))
        .toString()
        .trim();
    final name = (json['Désignation'] ??
            json['Designation'] ??
            json['DAcsignation'] ??
            json['Dsignation'] ??
            json['name'] ??
            barcode)
        .toString()
        .trim();

    double price = _parsePrice(json['Prix de vente Min']);
    if (price <= 0) {
      price = _parsePrice(json['Prix de vente Gros']);
    }
    if (price <= 0) {
      price = _parsePrice(json['Montant prix achat']);
    }
    if (price <= 0) {
      price = _parsePrice(json['price']);
    }

    final rawStock = json['Quantité'] ??
        json['Quantite'] ??
        json['QuantitAc'] ??
        json['Quantit'] ??
        json['stock'];
    final stock = _parseStock(rawStock);

    return ProductModel(
      id: id.isNotEmpty ? id : (barcode.isNotEmpty ? barcode : 'p_${DateTime.now().microsecondsSinceEpoch}'),
      name: name.isNotEmpty ? name : (barcode.isNotEmpty ? barcode : 'Product'),
      barcode: barcode,
      price: price,
      stock: stock,
    );
  }

  static double _parsePrice(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      final clean = val.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '').trim();
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseStock(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    if (val is String) {
      final clean = val.replaceAll(',', '.').trim();
      return int.tryParse(clean) ?? (double.tryParse(clean)?.toInt() ?? 0);
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'price': price,
      'stock': stock,
    };
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      barcode: barcode,
      price: price,
      stock: stock,
    );
  }
}

