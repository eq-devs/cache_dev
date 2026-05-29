import 'dart:io';

import 'package:cache_dev/cache_dev.dart';
import 'package:cache_dev_example/main.dart';
import 'package:cache_dev_example/sample_payload.dart';
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

  test('ExamplePayloadFactory creates the documented multi-section snapshot', () {
    final snapshot = ExamplePayloadFactory.createSnapshot();

    expect(snapshot.cacheKeys.length, 14);
    expect(snapshot.productCount, 480);
    expect(snapshot.orderCount, 180);
    expect(snapshot.priceTracking.length, 160);
    expect(snapshot.apiOrders.length, 2);
  });

  test('sample payload decodes into the expected structure', () {
    final data = kSampleApiResponse['data'] as Map;
    expect((data['user'] as Map)['full_name'], 'Test User');
    expect((data['summary'] as Map)['orders_total'], 128);
    expect((data['orders'] as List).length, 2);
  });

  test('cache_dev round-trips the real payload through MessagePack', () async {
    final directory = await Directory.systemTemp.createTemp('cache_dev_real_');
    addTearDown(() => directory.delete(recursive: true));

    final cache = CacheDevStore(options: CacheOptions(directory: directory));
    await cache.setJson('orders', kSampleApiResponse);

    // Cold store: empty memory cache forces a real MessagePack disk read.
    final cold = CacheDevStore(options: CacheOptions(directory: directory));
    final read = await cold.getJson('orders') as Map;
    final data = read['data'] as Map;

    // Unicode, nested maps, nulls, and doubles must survive the round trip.
    expect(((data['orders'] as List).first as Map)['status_text'], isA<Map>());
    expect(
      (((data['orders'] as List).first as Map)['status_text'] as Map)['zh'],
      '可取件',
    );
    expect(
      (((data['summary'] as Map)['financial'] as Map)['total_delivery_fee']
          as Map)['amount'],
      183420.0,
    );
  });
}
