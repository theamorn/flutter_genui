import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Helper extension to safely get values from DataContext
extension DataContextHelper on DataContext {
  double getDoubleSafe(String key, {double defaultValue = 0.0}) {
    final value = getValue<Object>(DataPath(key));
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  String getStringSafe(String key, {String defaultValue = ''}) {
    final value = getValue<Object>(DataPath(key));
    if (value is String) return value;
    return defaultValue;
  }

  List<Object?> getListSafe(String key) {
    final value = getValue<Object>(DataPath(key));
    if (value is List) return value;
    return [];
  }
}

/// The catalog defining the specific 5 widgets for the 13-step Financial Story demo
final catalog = Catalog(
  [
    // 1. ExpenseProgressLineGraph
    CatalogItem(
      name: 'ExpenseProgressLineGraph',
      dataSchema: S.object(
        properties: {
          'progressPercentage': S.number(description: '0 to 1 progress of expense'),
          'daysLeft': S.number(description: 'Days left in month'),
        },
      ),
      widgetBuilder: (CatalogItemContext context) {
        final progress = context.dataContext.getDoubleSafe('progressPercentage', defaultValue: 0.65);
        final daysLeft = context.dataContext.getDoubleSafe('daysLeft', defaultValue: 10).toInt();

        // We use a mocked visual layout using Flutter framework tools.
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Expense Progression', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('$daysLeft days left in the month', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context.buildContext).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Month Start'),
                    Text('End of Month Goal', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),

    // 2. DailyBalanceWidget
    CatalogItem(
      name: 'DailyBalanceWidget',
      dataSchema: S.object(
        properties: {
          'dailyLimit': S.number(),
          'leftForDinner': S.number(),
          'expenses': S.list(
            items: S.object(
              properties: {
                'name': S.string(),
                'amount': S.number(),
              },
            ),
          ),
        },
      ),
      widgetBuilder: (CatalogItemContext context) {
        final dailyLimit = context.dataContext.getDoubleSafe('dailyLimit', defaultValue: 300);
        final leftForDinner = context.dataContext.getDoubleSafe('leftForDinner', defaultValue: 70);
        final expensesList = context.dataContext.getListSafe('expenses');

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          color: Theme.of(context.buildContext).colorScheme.primaryContainer.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Check-in', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Daily Goal:', style: TextStyle(color: Colors.black54)),
                      Text('$dailyLimit THB', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Spent Today:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...expensesList.map((exp) {
                  if (exp is! Map) return const SizedBox.shrink();
                  final name = exp['name']?.toString() ?? '';
                  final amount = (exp['amount'] as num?)?.toDouble() ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                           children: [
                             const Icon(Icons.receipt_long, size: 16, color: Colors.black54),
                             const SizedBox(width: 8),
                             Text(name),
                           ]
                        ),
                        Text('${amount.toStringAsFixed(0)} THB'),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Left for Dinner:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                    Text('${leftForDinner.toStringAsFixed(0)} THB', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),

    // 3. StockWidget
    CatalogItem(
      name: 'StockWidget',
      dataSchema: S.object(
        properties: {
          'stocks': S.list(
            items: S.object(
              properties: {
                'name': S.string(),
                'dropPercent': S.number(),
                'value': S.number(),
              },
            ),
          ),
          'reassuranceMessage': S.string(),
        },
      ),
      widgetBuilder: (CatalogItemContext context) {
        final stocks = context.dataContext.getListSafe('stocks');
        final message = context.dataContext.getStringSafe('reassuranceMessage', defaultValue: 'Don\'t panic.');

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red.shade200, width: 2)
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_down, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    const Text('Passive Income & Stocks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                ...stocks.map((stock) {
                  if (stock is! Map) return const SizedBox.shrink();
                  final name = stock['name']?.toString() ?? 'Stock';
                  final drop = (stock['dropPercent'] as num?)?.toDouble() ?? 0.0;
                  final val = (stock['value'] as num?)?.toDouble() ?? 0.0;
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Row(
                           children: [
                             Text('${val.toStringAsFixed(0)} USD', style: const TextStyle(color: Colors.black54)),
                             const SizedBox(width: 12),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                               child: Text('▼ $drop%', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                             )
                           ]
                        )
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                       const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                       const SizedBox(width: 8),
                       Expanded(child: Text(message, style: const TextStyle(color: Colors.blue))),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    ),

    // 4. RecommendExpenseWidget
    CatalogItem(
      name: 'RecommendExpenseWidget',
      dataSchema: S.object(
        properties: {
          'rewardAvailable': S.number(),
        },
      ),
      widgetBuilder: (CatalogItemContext context) {
        final reward = context.dataContext.getDoubleSafe('rewardAvailable', defaultValue: 2000);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          color: Colors.green.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade200,
                  radius: 24,
                  child: const Icon(Icons.card_giftcard, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Great Job!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        'You are far under your spending goal. You have around ${reward.toStringAsFixed(0)} THB available to reward yourself with some shopping!',
                        style: const TextStyle(color: Colors.black87),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    ),

    // 5. ProductShoppingWidget
    CatalogItem(
      name: 'ProductShoppingWidget',
      dataSchema: S.object(
        properties: {
          'id': S.string(),
          'name': S.string(),
          'specs': S.list(items: S.string()),
          'price': S.number(),
          'imageUrl': S.string(),
        },
        required: ['id', 'name', 'price', 'imageUrl'],
      ),
      widgetBuilder: (CatalogItemContext context) {
        final id = context.dataContext.getStringSafe('id', defaultValue: 'unknown');
        final name = context.dataContext.getStringSafe('name', defaultValue: 'Sneakers');
        final price = context.dataContext.getDoubleSafe('price', defaultValue: 0.0);
        final imageUrl = context.dataContext.getStringSafe('imageUrl', defaultValue: '');
        final specs = context.dataContext.getListSafe('specs').map((e) => e.toString()).toList();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 4,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, error, stackTrace) =>
                      Container(height: 200, color: Colors.grey[200], child: const Icon(Icons.shopping_bag, size: 50, color: Colors.grey)),
                ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...specs.map((spec) => Padding(
                       padding: const EdgeInsets.only(bottom: 4),
                       child: Row(
                          children: [
                             const Icon(Icons.check_circle, size: 14, color: Colors.green),
                             const SizedBox(width: 8),
                             Expanded(child: Text(spec, style: const TextStyle(color: Colors.black87))),
                          ]
                       )
                    )),
                    const SizedBox(height: 16),
                    Text(
                      '${price.toStringAsFixed(0)} THB',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context.buildContext).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context.buildContext).colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        context.dispatchEvent(
                          UiEvent.fromMap({
                            'surfaceId': context.surfaceId,
                            'isAction': true,
                            'eventType': 'buy_now',
                            'value': {'id': id, 'name': name, 'price': price},
                            'timestamp': DateTime.now().toIso8601String(),
                          }),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Confirm Purchase', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  ],
  catalogId: 'story_catalog',
);
