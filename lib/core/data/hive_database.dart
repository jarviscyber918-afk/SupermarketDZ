import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/shop/data/models/shop_model.dart';

class HiveDatabase {
  static const String productBoxName = 'products';
  static const String shopBoxName = 'shop';
  static const String settingsBoxName = 'settings';
  static const String salesBoxName = 'sales';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProductModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ShopModelAdapter());
    }

    // Open Boxes
    final pBox = await Hive.openBox<ProductModel>(productBoxName);
    await Hive.openBox<ShopModel>(shopBoxName);
    final sBox = await Hive.openBox(settingsBoxName);
    await Hive.openBox(salesBoxName);

    // Initialize currency setting strictly DA
    if (sBox.get('currency') == null) {
      await sBox.put('currency', 'DA');
    }
    if (sBox.get('currency_symbol') == null) {
      await sBox.put('currency_symbol', 'DA');
    }

    // Reset / clear legacy dummy products so store starts completely fresh and empty
    if (sBox.get('empty_store_initialized_v2', defaultValue: false) != true) {
      await pBox.clear();
      await sBox.put('empty_store_initialized_v2', true);
      debugPrint('Initialized empty store successfully. Database is now clean with 0 items.');
    }
  }

  static Box<ProductModel> get productBox =>
      Hive.box<ProductModel>(productBoxName);
  static Box<ShopModel> get shopBox => Hive.box<ShopModel>(shopBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
  static Box get salesBox => Hive.box(salesBoxName);

  static bool get isLoggedIn =>
      settingsBox.get('isLoggedIn', defaultValue: false) == true;

  static Future<void> setLoggedIn(bool value) async {
    await settingsBox.put('isLoggedIn', value);
  }

  static Future<void> logout() async {
    await settingsBox.put('isLoggedIn', false);
  }

  static Future<void> clearAllProducts() async {
    await productBox.clear();
  }

  static int getNextReceiptNumber() {
    final current = (settingsBox.get('last_receipt_number', defaultValue: 0) as num).toInt();
    final next = current + 1;
    settingsBox.put('last_receipt_number', next);
    return next;
  }

  static Future<void> recordSale(Map<String, dynamic> saleMap) async {
    final id = saleMap['id']?.toString() ?? 'REC-${DateTime.now().millisecondsSinceEpoch}';
    await salesBox.put(id, saleMap);
  }

  static List<Map<String, dynamic>> getAllSales() {
    final List<Map<String, dynamic>> list = [];
    for (final val in salesBox.values) {
      if (val is Map) {
        list.add(Map<String, dynamic>.from(val));
      }
    }
    // Sort descending by timestamp
    list.sort((a, b) {
      final tA = DateTime.tryParse(a['timestamp']?.toString() ?? '') ?? DateTime(2000);
      final tB = DateTime.tryParse(b['timestamp']?.toString() ?? '') ?? DateTime(2000);
      return tB.compareTo(tA);
    });
    return list;
  }
}

