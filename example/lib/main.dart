import 'dart:io';
import 'dart:math';

import 'package:cache_dev/cache_dev.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'sample_payload.dart';

void main() {
  runApp(const CacheDevExampleApp());
}

class CacheDevExampleApp extends StatelessWidget {
  const CacheDevExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'cache_dev example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: const CacheExamplePage(),
    );
  }
}

class CacheExamplePage extends StatefulWidget {
  const CacheExamplePage({super.key});

  @override
  State<CacheExamplePage> createState() => _CacheExamplePageState();
}

class _CacheExamplePageState extends State<CacheExamplePage> {
  CacheDevStore? _cache;
  Directory? _cacheDirectory;
  Box<Object?>? _hiveBox;
  ExampleSnapshot? _snapshot;
  BenchmarkResult? _benchmark;
  HiveComparisonResult? _comparison;
  String _status = 'Preparing mobile cache directory...';
  bool _busy = true;
  int _diskFiles = 0;
  int _hiveEntries = 0;
  int _selectedPreview = 0;

  static const _previewKeys = <String>[
    'home',
    'profile_user_1',
    'product_page_1',
    'order_page_1',
    'price_tracking',
    'orders_api',
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final docs = await getApplicationDocumentsDirectory();
    final directory = Directory('${docs.path}/cache_dev_example');
    Hive.init('${docs.path}/cache_dev_example_hive');
    final hiveBox = await Hive.openBox<Object?>('payloads');
    final cache = CacheDevStore(
      options: CacheOptions(
        directory: directory,
        memoryMaxEntries: 32,
        isolateThresholdBytes: 12 * 1024,
        defaultTtl: const Duration(minutes: 10),
        flushWrites: false,
        bulkConcurrency: 6,
      ),
    );

    await cache.warmUp(_previewKeys);
    final files = await _countCacheFiles(directory);

    if (!mounted) {
      return;
    }
    setState(() {
      _cache = cache;
      _cacheDirectory = directory;
      _hiveBox = hiveBox;
      _diskFiles = files;
      _hiveEntries = hiveBox.length;
      _busy = false;
      _status = 'Ready for cache_dev MessagePack files and Hive comparison.';
    });
  }

  Future<void> _writeAll() async {
    final cache = _cache;
    final directory = _cacheDirectory;
    if (cache == null || directory == null) {
      return;
    }

    setState(() {
      _busy = true;
      _status =
          'Writing homepage, profile, product pages, orders, prices, and API...';
    });

    final snapshot = ExamplePayloadFactory.createSnapshot();
    final watch = Stopwatch()..start();
    await _writeSnapshot(cache, snapshot);
    watch.stop();
    final files = await _countCacheFiles(directory);

    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _diskFiles = files;
      _busy = false;
      _status =
          'Wrote ${snapshot.cacheKeys.length} MessagePack files in '
          '${watch.elapsedMilliseconds} ms.';
    });
  }

  Future<void> _readAll() async {
    final cache = _cache;
    if (cache == null) {
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Reading all cached payloads...';
    });

    final watch = Stopwatch()..start();
    final snapshot = await _readSnapshot(cache);
    watch.stop();

    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _busy = false;
      _status = snapshot == null
          ? 'Cache miss. Write sample data first.'
          : 'Read ${snapshot.cacheKeys.length} MessagePack files in '
                '${watch.elapsedMilliseconds} ms.';
    });
  }

  Future<void> _warmPreviewKeys() async {
    final cache = _cache;
    if (cache == null) {
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Warming first-screen cache keys...';
    });

    final watch = Stopwatch()..start();
    await cache.warmUp(_previewKeys);
    watch.stop();

    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _status =
          'Warmed ${_previewKeys.length} keys in '
          '${watch.elapsedMilliseconds} ms.';
    });
  }

  Future<void> _runBenchmark() async {
    final cache = _cache;
    final directory = _cacheDirectory;
    if (cache == null || directory == null) {
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Running write/read benchmark with large payloads...';
    });

    final result = await ExampleBenchmark(cache: cache).run();
    final files = await _countCacheFiles(directory);

    if (!mounted) {
      return;
    }
    setState(() {
      _benchmark = result;
      _diskFiles = files;
      _busy = false;
      _status =
          'Benchmark completed: ${result.payloads} payloads, '
          '${result.itemsPerPayload} items each.';
    });
  }

  Future<void> _runHiveComparison() async {
    final cache = _cache;
    final hiveBox = _hiveBox;
    final directory = _cacheDirectory;
    if (cache == null || hiveBox == null || directory == null) {
      return;
    }

    setState(() {
      _busy = true;
      _status =
          'Comparing cache_dev MessagePack files with Hive on the real payload...';
    });

    final result = await HiveComparisonBenchmark(
      cache: cache,
      directory: directory,
      hiveBox: hiveBox,
    ).run();
    final files = await _countCacheFiles(directory);

    if (!mounted) {
      return;
    }
    setState(() {
      _comparison = result;
      _diskFiles = files;
      _hiveEntries = hiveBox.length;
      _busy = false;
      _status =
          'Comparison completed with ${result.payloads} payloads. '
          'Lower milliseconds and bytes are better.';
    });
  }

  Future<void> _clearCache() async {
    final cache = _cache;
    final directory = _cacheDirectory;
    if (cache == null || directory == null) {
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Clearing cache files...';
    });

    await cache.clear();
    await _hiveBox?.clear();
    final files = await _countCacheFiles(directory);

    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = null;
      _benchmark = null;
      _comparison = null;
      _diskFiles = files;
      _hiveEntries = _hiveBox?.length ?? 0;
      _busy = false;
      _status = 'Cache cleared.';
    });
  }

  Future<void> _writeSnapshot(
    CacheDevStore cache,
    ExampleSnapshot snapshot,
  ) async {
    await cache.set<Map<String, Object?>>(
      'home',
      snapshot.home,
      encoder: (value) => value,
      ttl: const Duration(minutes: 5),
      version: 1,
    );
    await cache.set<Map<String, Object?>>(
      'profile_user_1',
      snapshot.profile,
      encoder: (value) => value,
      ttl: const Duration(hours: 2),
      version: 1,
    );

    for (final page in snapshot.productPages.entries) {
      await cache.set<List<Map<String, Object?>>>(
        'product_page_${page.key}',
        page.value,
        encoder: (value) => value,
        ttl: const Duration(minutes: 10),
        version: 1,
      );
    }

    for (final page in snapshot.orderPages.entries) {
      await cache.set<List<Map<String, Object?>>>(
        'order_page_${page.key}',
        page.value,
        encoder: (value) => value,
        ttl: const Duration(minutes: 15),
        version: 1,
      );
    }

    await cache.set<List<Map<String, Object?>>>(
      'price_tracking',
      snapshot.priceTracking,
      encoder: (value) => value,
      ttl: const Duration(minutes: 2),
      version: 1,
    );

    // The real Jana Post orders API response, cached as a single rich entry.
    await cache.setJson(
      'orders_api',
      snapshot.apiResponse,
      ttl: const Duration(minutes: 30),
      version: 4,
    );
  }

  Future<ExampleSnapshot?> _readSnapshot(CacheDevStore cache) async {
    final home = await cache.get<Map<String, Object?>>(
      'home',
      decoder: (json) => Map<String, Object?>.from(json! as Map),
    );
    final profile = await cache.get<Map<String, Object?>>(
      'profile_user_1',
      decoder: (json) => Map<String, Object?>.from(json! as Map),
    );

    if (home == null || profile == null) {
      return null;
    }

    final productPages = <int, List<Map<String, Object?>>>{};
    for (var page = 1; page <= ExamplePayloadFactory.productPageCount; page++) {
      final value = await cache.get<List<Map<String, Object?>>>(
        'product_page_$page',
        decoder: _decodeMapList,
      );
      if (value == null) {
        return null;
      }
      productPages[page] = value;
    }

    final orderPages = <int, List<Map<String, Object?>>>{};
    for (var page = 1; page <= ExamplePayloadFactory.orderPageCount; page++) {
      final value = await cache.get<List<Map<String, Object?>>>(
        'order_page_$page',
        decoder: _decodeMapList,
      );
      if (value == null) {
        return null;
      }
      orderPages[page] = value;
    }

    final priceTracking = await cache.get<List<Map<String, Object?>>>(
      'price_tracking',
      decoder: _decodeMapList,
    );
    if (priceTracking == null) {
      return null;
    }

    final apiResponse = await cache.get<Map<String, Object?>>(
      'orders_api',
      decoder: (json) => Map<String, Object?>.from(json! as Map),
    );
    if (apiResponse == null) {
      return null;
    }

    return ExampleSnapshot(
      home: home,
      profile: profile,
      productPages: productPages,
      orderPages: orderPages,
      priceTracking: priceTracking,
      apiResponse: apiResponse,
    );
  }

  List<Map<String, Object?>> _decodeMapList(Object? json) {
    return (json as List<dynamic>)
        .map((item) => Map<String, Object?>.from(item as Map))
        .toList();
  }

  Future<int> _countCacheFiles(Directory directory) async {
    try {
      if (!await directory.exists()) {
        return 0;
      }
      var count = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.msgpack')) {
          count++;
        }
      }
      return count;
    } on FileSystemException {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('cache_dev mobile cache console'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            _HeaderPanel(
              status: _status,
              busy: _busy,
              cachePath: _cacheDirectory?.path ?? 'Preparing directory',
            ),
            const SizedBox(height: 12),
            _ActionBar(
              busy: _busy,
              onWriteAll: _writeAll,
              onReadAll: _readAll,
              onWarm: _warmPreviewKeys,
              onBenchmark: _runBenchmark,
              onCompareHive: _runHiveComparison,
              onClear: _clearCache,
            ),
            const SizedBox(height: 16),
            _MetricGrid(
              diskFiles: _diskFiles,
              hiveEntries: _hiveEntries,
              snapshot: _snapshot,
              benchmark: _benchmark,
              comparison: _comparison,
            ),
            const SizedBox(height: 16),
            Text('Payload Preview', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(
                  value: 0,
                  icon: Icon(Icons.home_outlined),
                  label: Text('Home'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: Icon(Icons.inventory_2_outlined),
                  label: Text('Products'),
                ),
                ButtonSegment<int>(
                  value: 2,
                  icon: Icon(Icons.receipt_long_outlined),
                  label: Text('Orders'),
                ),
                ButtonSegment<int>(
                  value: 3,
                  icon: Icon(Icons.price_change_outlined),
                  label: Text('Prices'),
                ),
                ButtonSegment<int>(
                  value: 4,
                  icon: Icon(Icons.cloud_outlined),
                  label: Text('API'),
                ),
              ],
              selected: <int>{_selectedPreview},
              onSelectionChanged: _busy
                  ? null
                  : (selection) {
                      setState(() {
                        _selectedPreview = selection.first;
                      });
                    },
            ),
            const SizedBox(height: 12),
            _PreviewList(snapshot: _snapshot, selected: _selectedPreview),
            const SizedBox(height: 16),
            if (_benchmark != null) _BenchmarkPanel(result: _benchmark!),
            if (_comparison != null) ...<Widget>[
              const SizedBox(height: 16),
              _HiveComparisonPanel(result: _comparison!),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({
    required this.status,
    required this.busy,
    required this.cachePath,
  });

  final String status;
  final bool busy;
  final String cachePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.primaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.storage_outlined,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Split MessagePack file cache',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cachePath,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.78),
            ),
          ),
          if (busy) ...<Widget>[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              color: colorScheme.onPrimaryContainer,
              backgroundColor: colorScheme.onPrimaryContainer.withValues(
                alpha: 0.18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.busy,
    required this.onWriteAll,
    required this.onReadAll,
    required this.onWarm,
    required this.onBenchmark,
    required this.onCompareHive,
    required this.onClear,
  });

  final bool busy;
  final VoidCallback onWriteAll;
  final VoidCallback onReadAll;
  final VoidCallback onWarm;
  final VoidCallback onBenchmark;
  final VoidCallback onCompareHive;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.icon(
          onPressed: busy ? null : onWriteAll,
          icon: const Icon(Icons.save_alt),
          label: const Text('Write'),
        ),
        FilledButton.tonalIcon(
          onPressed: busy ? null : onReadAll,
          icon: const Icon(Icons.cached),
          label: const Text('Read'),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : onWarm,
          icon: const Icon(Icons.flash_on_outlined),
          label: const Text('Warm'),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : onBenchmark,
          icon: const Icon(Icons.speed_outlined),
          label: const Text('Benchmark'),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : onCompareHive,
          icon: const Icon(Icons.compare_arrows_outlined),
          label: const Text('Compare Hive'),
        ),
        IconButton.outlined(
          onPressed: busy ? null : onClear,
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Clear cache',
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.diskFiles,
    required this.hiveEntries,
    required this.snapshot,
    required this.benchmark,
    required this.comparison,
  });

  final int diskFiles;
  final int hiveEntries;
  final ExampleSnapshot? snapshot;
  final BenchmarkResult? benchmark;
  final HiveComparisonResult? comparison;

  @override
  Widget build(BuildContext context) {
    final result = benchmark;
    final compare = comparison;
    final entries = <_Metric>[
      _Metric(
        'Cache files',
        diskFiles.toString(),
        Icons.folder_copy_outlined,
      ),
      _Metric(
        'Hive entries',
        hiveEntries.toString(),
        Icons.view_in_ar_outlined,
      ),
      _Metric(
        'Cache keys',
        (snapshot?.cacheKeys.length ?? 0).toString(),
        Icons.key_outlined,
      ),
      _Metric(
        'Product rows',
        (snapshot?.productCount ?? 0).toString(),
        Icons.inventory_2_outlined,
      ),
      _Metric(
        'Order rows',
        (snapshot?.orderCount ?? 0).toString(),
        Icons.receipt_long_outlined,
      ),
      _Metric(
        'Bench write',
        result == null ? '-' : '${result.writeMs} ms',
        Icons.save_outlined,
      ),
      _Metric(
        'Bench read',
        result == null ? '-' : '${result.diskReadMs} ms',
        Icons.read_more_outlined,
      ),
      _Metric(
        'cache_dev size',
        compare == null ? '-' : _kb(compare.cacheDevDiskBytes),
        Icons.sd_storage_outlined,
      ),
      _Metric(
        'Hive size',
        compare == null ? '-' : _kb(compare.hiveDiskBytes),
        Icons.compare_arrows_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: columns == 3 ? 2.4 : 1.75,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) => _MetricTile(metric: entries[index]),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(metric.icon, size: 20, color: colorScheme.primary),
          const Spacer(),
          Text(metric.label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _PreviewList extends StatelessWidget {
  const _PreviewList({required this.snapshot, required this.selected});

  final ExampleSnapshot? snapshot;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final items = _items();
    if (items.isEmpty) {
      return const _EmptyPreview();
    }

    return Column(
      children: <Widget>[
        for (final item in items.take(10))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text(item.leading)),
            title: Text(item.title),
            subtitle: Text(item.subtitle),
            trailing: Text(item.trailing),
          ),
      ],
    );
  }

  List<_PreviewItem> _items() {
    final data = snapshot;
    if (data == null) {
      return const <_PreviewItem>[];
    }

    return switch (selected) {
      0 => <_PreviewItem>[
        _PreviewItem(
          leading: 'H',
          title: data.home['title']! as String,
          subtitle: '${data.home['sections']} sections cached',
          trailing: 'v${data.home['schemaVersion']}',
        ),
        _PreviewItem(
          leading: 'U',
          title: data.profile['name']! as String,
          subtitle: data.profile['tier']! as String,
          trailing: '${data.profile['points']} pts',
        ),
      ],
      1 =>
        data.productPages[1]!
            .take(10)
            .map(
              (item) => _PreviewItem(
                leading: '${item['id']}',
                title: item['title']! as String,
                subtitle: item['category']! as String,
                trailing: '\$${(item['price']! as num).toStringAsFixed(2)}',
              ),
            )
            .toList(),
      2 =>
        data.orderPages[1]!
            .take(10)
            .map(
              (item) => _PreviewItem(
                leading: '#',
                title: item['orderNo']! as String,
                subtitle: '${item['items']} items - ${item['status']}',
                trailing: '\$${(item['total']! as num).toStringAsFixed(2)}',
              ),
            )
            .toList(),
      3 =>
        data.priceTracking
            .take(10)
            .map(
              (item) => _PreviewItem(
                leading: '\$',
                title: item['sku']! as String,
                subtitle: '${item['source']} - ${item['movement']}',
                trailing: '\$${(item['price']! as num).toStringAsFixed(2)}',
              ),
            )
            .toList(),
      _ => data.apiOrders
          .take(10)
          .map(
            (order) => _PreviewItem(
              leading: '#',
              title: order['order_no']?.toString() ?? '-',
              subtitle:
                  '${(order['marketplace'] as Map?)?['name'] ?? '-'} - '
                  '${(order['status_text'] as Map?)?['en'] ?? order['status']}',
              trailing: order['status']?.toString() ?? '',
            ),
          )
          .toList(),
    };
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'No cached preview yet. Tap Write, then Read or Benchmark.',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

class _BenchmarkPanel extends StatelessWidget {
  const _BenchmarkPanel({required this.result});

  final BenchmarkResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Benchmark Result', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Table(
          columnWidths: const <int, TableColumnWidth>{
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(),
          },
          children: <TableRow>[
            _row('Payloads', '${result.payloads} x ${result.itemsPerPayload}'),
            _row('Write', '${result.writeMs} ms'),
            _row('Cold disk read', '${result.diskReadMs} ms'),
            _row('Hot memory read', '${result.memoryReadMs} ms'),
            _row('Warm up', '${result.warmMs} ms'),
            _row('Clear expired scan', '${result.clearExpiredMs} ms'),
          ],
        ),
      ],
    );
  }

  TableRow _row(String label, String value) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(value, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

class _HiveComparisonPanel extends StatelessWidget {
  const _HiveComparisonPanel({required this.result});

  final HiveComparisonResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('cache_dev vs Hive', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Table(
          columnWidths: const <int, TableColumnWidth>{
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
          },
          children: <TableRow>[
            _row('', 'cache_dev', 'Hive'),
            _row('Payloads', '${result.payloads}', '${result.payloads}'),
            _row(
              'Write',
              '${result.cacheDevWriteMs} ms',
              '${result.hiveWriteMs} ms',
            ),
            _row(
              'Raw read',
              '${result.cacheDevRawReadMs} ms',
              '${result.hiveRawReadMs} ms',
            ),
            _row(
              'Read + map copy',
              '${result.cacheDevDecodeReadMs} ms',
              '${result.hiveDecodeReadMs} ms',
            ),
            _row(
              'Disk size',
              _kb(result.cacheDevDiskBytes),
              _kb(result.hiveDiskBytes),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Hive is included only in the example for comparison. The package '
          'implementation stores each entry as a lightweight MessagePack file.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  TableRow _row(String label, String cacheDev, String hive) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(cacheDev, textAlign: TextAlign.end),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(hive, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

String _kb(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  return '${(kb / 1024).toStringAsFixed(2)} MB';
}

class ExamplePayloadFactory {
  const ExamplePayloadFactory._();

  static const productPageCount = 6;
  static const productItemsPerPage = 80;
  static const orderPageCount = 4;
  static const orderItemsPerPage = 45;
  static const priceTrackingItems = 160;

  static ExampleSnapshot createSnapshot() {
    return ExampleSnapshot(
      home: createHome(),
      profile: createProfile(),
      productPages: <int, List<Map<String, Object?>>>{
        for (var page = 1; page <= productPageCount; page++)
          page: createProductPage(page, productItemsPerPage),
      },
      orderPages: <int, List<Map<String, Object?>>>{
        for (var page = 1; page <= orderPageCount; page++)
          page: createOrderPage(page, orderItemsPerPage),
      },
      priceTracking: createPriceTracking(priceTrackingItems),
      apiResponse: kSampleApiResponse,
    );
  }

  static Map<String, Object?> createHome() {
    return <String, Object?>{
      'title': 'Mobile Storefront',
      'schemaVersion': 1,
      'sections': 8,
      'hero': <String, Object?>{
        'headline': 'Fast offline homepage',
        'campaign': 'spring_mobile',
      },
      'modules': List<Map<String, Object?>>.generate(
        8,
        (index) => <String, Object?>{
          'id': 'module_$index',
          'type': index.isEven ? 'products' : 'banner',
          'priority': index + 1,
          'title': 'Homepage module ${index + 1}',
        },
      ),
    };
  }

  static Map<String, Object?> createProfile() {
    return <String, Object?>{
      'id': 1,
      'name': 'Amina User',
      'tier': 'Gold loyalty member',
      'points': 4820,
      'addresses': <Map<String, Object?>>[
        <String, Object?>{
          'city': 'Almaty',
          'line': 'Dostyk Avenue',
          'default': true,
        },
      ],
      'preferences': <String, Object?>{
        'currency': 'USD',
        'language': 'en',
        'push': true,
      },
    };
  }

  static List<Map<String, Object?>> createProductPage(int page, int count) {
    final categories = <String>['Phones', 'Audio', 'Home', 'Wearables'];
    return List<Map<String, Object?>>.generate(count, (index) {
      final id = ((page - 1) * count) + index + 1;
      return Product(
        id: id,
        title: 'Product $id',
        category: categories[id % categories.length],
        price: 12.99 + (id * 1.37),
        rating: 3.8 + ((id % 12) / 10),
        inStock: id % 5 != 0,
      ).toJson();
    });
  }

  static List<Map<String, Object?>> createOrderPage(int page, int count) {
    final statuses = <String>['paid', 'packed', 'shipped', 'delivered'];
    return List<Map<String, Object?>>.generate(count, (index) {
      final id = ((page - 1) * count) + index + 1;
      return <String, Object?>{
        'id': id,
        'orderNo': 'ORD-${100000 + id}',
        'status': statuses[id % statuses.length],
        'items': 1 + (id % 6),
        'total': 28.5 + (id * 4.8),
        'updatedAt': DateTime.now().millisecondsSinceEpoch - (id * 60000),
      };
    });
  }

  static List<Map<String, Object?>> createPriceTracking(int count) {
    final random = Random(42);
    return List<Map<String, Object?>>.generate(count, (index) {
      final current = 20 + random.nextDouble() * 800;
      final previous = current + (random.nextDouble() * 80) - 40;
      return <String, Object?>{
        'sku': 'SKU-${5000 + index}',
        'source': index.isEven ? 'api' : 'webview',
        'price': current,
        'previousPrice': previous,
        'movement': current <= previous ? 'down' : 'up',
      };
    });
  }
}

class ExampleBenchmark {
  const ExampleBenchmark({required this.cache});

  final CacheDevStore cache;

  Future<BenchmarkResult> run() async {
    const payloads = 40;
    const itemsPerPayload = 120;

    final values = <String, Object?>{
      for (var i = 0; i < payloads; i++)
        'benchmark_payload_$i': ExamplePayloadFactory.createProductPage(
          i + 1,
          itemsPerPayload,
        ),
    };

    final writeWatch = Stopwatch()..start();
    await cache.setJsonAll(
      values,
      ttl: const Duration(minutes: 20),
      concurrency: 6,
    );
    writeWatch.stop();

    final diskReadWatch = Stopwatch()..start();
    for (var i = 0; i < payloads; i++) {
      await cache.get<List<Map<String, Object?>>>(
        'benchmark_payload_$i',
        decoder: _decodeMapList,
      );
    }
    diskReadWatch.stop();

    final memoryReadWatch = Stopwatch()..start();
    for (var i = 0; i < payloads; i++) {
      await cache.get<List<Map<String, Object?>>>(
        'benchmark_payload_$i',
        decoder: _decodeMapList,
      );
    }
    memoryReadWatch.stop();

    final warmWatch = Stopwatch()..start();
    await cache.warmUp(
      List<String>.generate(12, (index) => 'benchmark_payload_$index'),
    );
    warmWatch.stop();

    final clearExpiredWatch = Stopwatch()..start();
    await cache.clearExpired();
    clearExpiredWatch.stop();

    return BenchmarkResult(
      payloads: payloads,
      itemsPerPayload: itemsPerPayload,
      writeMs: writeWatch.elapsedMilliseconds,
      diskReadMs: diskReadWatch.elapsedMilliseconds,
      memoryReadMs: memoryReadWatch.elapsedMilliseconds,
      warmMs: warmWatch.elapsedMilliseconds,
      clearExpiredMs: clearExpiredWatch.elapsedMilliseconds,
    );
  }

  static List<Map<String, Object?>> _decodeMapList(Object? json) {
    return (json as List<dynamic>)
        .map((item) => Map<String, Object?>.from(item as Map))
        .toList();
  }
}

class HiveComparisonBenchmark {
  const HiveComparisonBenchmark({
    required this.cache,
    required this.directory,
    required this.hiveBox,
  });

  final CacheDevStore cache;
  final Directory directory;
  final Box<Object?> hiveBox;

  /// Copies of the real API response to cache. Each copy is stored under its
  /// own key, the way an app caches one response per page / per user.
  static const payloads = 60;

  Future<HiveComparisonResult> run() async {
    final payload = kSampleApiResponse;

    final cacheDevWriteWatch = Stopwatch()..start();
    await cache.setJsonAll(
      <String, Object?>{
        for (var i = 0; i < payloads; i++) 'compare_cache_dev_payload_$i': payload,
      },
      ttl: const Duration(minutes: 20),
      concurrency: 6,
    );
    cacheDevWriteWatch.stop();

    final cacheDevDiskBytes = await _dirBytes(directory, suffix: '.msgpack');

    final coldCache = CacheDevStore(
      options: CacheOptions(
        directory: directory,
        memoryMaxEntries: 8,
        isolateThresholdBytes: 12 * 1024,
        defaultTtl: const Duration(minutes: 10),
        flushWrites: false,
        bulkConcurrency: 6,
      ),
    );

    final cacheDevKeys = List<String>.generate(
      payloads,
      (index) => 'compare_cache_dev_payload_$index',
    );

    final cacheDevRawReadWatch = Stopwatch()..start();
    await coldCache.getJsonAll(cacheDevKeys, concurrency: 6);
    cacheDevRawReadWatch.stop();

    final cacheDevDecodeReadWatch = Stopwatch()..start();
    for (final key in cacheDevKeys) {
      await coldCache.get<Map<String, Object?>>(
        key,
        decoder: (json) => Map<String, Object?>.from(json! as Map),
      );
    }
    cacheDevDecodeReadWatch.stop();

    final hiveWriteWatch = Stopwatch()..start();
    for (var i = 0; i < payloads; i++) {
      await hiveBox.put('compare_hive_payload_$i', payload);
    }
    await hiveBox.flush();
    hiveWriteWatch.stop();

    final hiveDiskBytes = await _dirBytes(
      Directory('${directory.path}/../cache_dev_example_hive'),
    );

    final hiveRawReadWatch = Stopwatch()..start();
    for (var i = 0; i < payloads; i++) {
      if (hiveBox.get('compare_hive_payload_$i') == null) {
        throw StateError('Missing Hive benchmark payload $i');
      }
    }
    hiveRawReadWatch.stop();

    final hiveDecodeReadWatch = Stopwatch()..start();
    for (var i = 0; i < payloads; i++) {
      final value = hiveBox.get('compare_hive_payload_$i') as Map?;
      if (value == null) {
        throw StateError('Missing Hive benchmark payload $i');
      }
      Map<String, Object?>.from(value);
    }
    hiveDecodeReadWatch.stop();

    return HiveComparisonResult(
      payloads: payloads,
      cacheDevWriteMs: cacheDevWriteWatch.elapsedMilliseconds,
      cacheDevRawReadMs: cacheDevRawReadWatch.elapsedMilliseconds,
      cacheDevDecodeReadMs: cacheDevDecodeReadWatch.elapsedMilliseconds,
      cacheDevDiskBytes: cacheDevDiskBytes,
      hiveWriteMs: hiveWriteWatch.elapsedMilliseconds,
      hiveRawReadMs: hiveRawReadWatch.elapsedMilliseconds,
      hiveDecodeReadMs: hiveDecodeReadWatch.elapsedMilliseconds,
      hiveDiskBytes: hiveDiskBytes,
    );
  }

  Future<int> _dirBytes(Directory dir, {String? suffix}) async {
    if (!await dir.exists()) {
      return 0;
    }
    var total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && (suffix == null || entity.path.endsWith(suffix))) {
        total += await entity.length();
      }
    }
    return total;
  }
}

class ExampleSnapshot {
  const ExampleSnapshot({
    required this.home,
    required this.profile,
    required this.productPages,
    required this.orderPages,
    required this.priceTracking,
    required this.apiResponse,
  });

  final Map<String, Object?> home;
  final Map<String, Object?> profile;
  final Map<int, List<Map<String, Object?>>> productPages;
  final Map<int, List<Map<String, Object?>>> orderPages;
  final List<Map<String, Object?>> priceTracking;
  final Map<String, Object?> apiResponse;

  List<String> get cacheKeys {
    return <String>[
      'home',
      'profile_user_1',
      for (final page in productPages.keys) 'product_page_$page',
      for (final page in orderPages.keys) 'order_page_$page',
      'price_tracking',
      'orders_api',
    ];
  }

  /// Orders list pulled out of the real API response for the preview tab.
  List<Map<String, Object?>> get apiOrders {
    final data = apiResponse['data'];
    if (data is! Map) {
      return const <Map<String, Object?>>[];
    }
    final orders = data['orders'];
    if (orders is! List) {
      return const <Map<String, Object?>>[];
    }
    return orders
        .whereType<Map>()
        .map((order) => Map<String, Object?>.from(order))
        .toList();
  }

  int get productCount {
    return productPages.values.fold<int>(0, (sum, page) => sum + page.length);
  }

  int get orderCount {
    return orderPages.values.fold<int>(0, (sum, page) => sum + page.length);
  }
}

class BenchmarkResult {
  const BenchmarkResult({
    required this.payloads,
    required this.itemsPerPayload,
    required this.writeMs,
    required this.diskReadMs,
    required this.memoryReadMs,
    required this.warmMs,
    required this.clearExpiredMs,
  });

  final int payloads;
  final int itemsPerPayload;
  final int writeMs;
  final int diskReadMs;
  final int memoryReadMs;
  final int warmMs;
  final int clearExpiredMs;
}

class HiveComparisonResult {
  const HiveComparisonResult({
    required this.payloads,
    required this.cacheDevWriteMs,
    required this.cacheDevRawReadMs,
    required this.cacheDevDecodeReadMs,
    required this.cacheDevDiskBytes,
    required this.hiveWriteMs,
    required this.hiveRawReadMs,
    required this.hiveDecodeReadMs,
    required this.hiveDiskBytes,
  });

  final int payloads;
  final int cacheDevWriteMs;
  final int cacheDevRawReadMs;
  final int cacheDevDecodeReadMs;
  final int cacheDevDiskBytes;
  final int hiveWriteMs;
  final int hiveRawReadMs;
  final int hiveDecodeReadMs;
  final int hiveDiskBytes;
}

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.rating,
    required this.inStock,
  });

  final int id;
  final String title;
  final String category;
  final double price;
  final double rating;
  final bool inStock;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'category': category,
      'price': price,
      'rating': rating,
      'inStock': inStock,
    };
  }

  static Product fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      inStock: json['inStock'] as bool,
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _PreviewItem {
  const _PreviewItem({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String leading;
  final String title;
  final String subtitle;
  final String trailing;
}
