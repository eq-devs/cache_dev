import 'package:cache_dev_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Product round-trips through JSON', () {
    const product = Product(
      id: 1,
      title: 'Product 1',
      category: 'Phones',
      price: 19.5,
      rating: 4.6,
      inStock: true,
    );

    final decoded = Product.fromJson(product.toJson());

    expect(decoded.id, product.id);
    expect(decoded.title, product.title);
    expect(decoded.category, product.category);
    expect(decoded.price, product.price);
    expect(decoded.rating, product.rating);
    expect(decoded.inStock, product.inStock);
  });

  test('ExamplePayloadFactory creates the documented multi JSON snapshot', () {
    final snapshot = ExamplePayloadFactory.createSnapshot();

    expect(snapshot.cacheKeys.length, 13);
    expect(snapshot.productCount, 480);
    expect(snapshot.orderCount, 180);
    expect(snapshot.priceTracking.length, 160);
  });
}
