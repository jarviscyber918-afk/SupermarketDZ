import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final box = HiveDatabase.productBox;
      final products = box.values.toList();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    try {
      final box = HiveDatabase.productBox;
      final directProduct = box.get(barcode);
      if (directProduct != null && directProduct.barcode == barcode) {
        return Right(directProduct);
      }
      final product = box.values.firstWhere(
        (element) => element.barcode == barcode,
        orElse: () => throw Exception('Product not found'),
      );
      return Right(product);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct(Product product) async {
    try {
      final box = HiveDatabase.productBox;
      final model = ProductModel.fromEntity(product);
      final key = model.barcode.isNotEmpty ? model.barcode : model.id;
      await box.put(key, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    try {
      final box = HiveDatabase.productBox;
      final model = ProductModel.fromEntity(product);
      final key = model.barcode.isNotEmpty ? model.barcode : model.id;

      // Clean up any previous entries with different key for same item
      final keysToDelete = <dynamic>[];
      for (final entry in box.toMap().entries) {
        if ((entry.value.id == model.id ||
                (model.barcode.isNotEmpty &&
                    entry.value.barcode == model.barcode)) &&
            entry.key != key) {
          keysToDelete.add(entry.key);
        }
      }
      for (final k in keysToDelete) {
        await box.delete(k);
      }

      await box.put(key, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      final box = HiveDatabase.productBox;
      final keysToDelete = <dynamic>[];
      if (box.containsKey(id)) {
        keysToDelete.add(id);
      }
      for (final entry in box.toMap().entries) {
        if (entry.value.id == id || entry.value.barcode == id) {
          if (!keysToDelete.contains(entry.key)) {
            keysToDelete.add(entry.key);
          }
        }
      }
      for (final k in keysToDelete) {
        await box.delete(k);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
