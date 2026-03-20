import 'package:flutter/material.dart';
import 'package:gen_ui/main.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:confetti/confetti.dart';

// ─── 1. ExpenseProgressLineGraph ─────────────────────────────────────────────

class _DraggableProgressBar extends StatefulWidget {
  final double initialProgress;
  final int initialDaysLeft;
  const _DraggableProgressBar({
    required this.initialProgress,
    required this.initialDaysLeft,
  });

  @override
  State<_DraggableProgressBar> createState() => _DraggableProgressBarState();
}

class _DraggableProgressBarState extends State<_DraggableProgressBar> {
  late double _progress;

  @override
  void initState() {
    super.initState();
    _progress = widget.initialProgress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final spent = (_progress * 15000).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Expense Progression',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _progressColor(_progress).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _progressColor(_progress)),
              ),
              child: Text(
                '฿$spent / ฿15,000',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _progressColor(_progress),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${(_progress * 100).round()}% of monthly budget  •  ${widget.initialDaysLeft} days left',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                final newVal =
                    (_progress + details.delta.dx / constraints.maxWidth).clamp(
                      0.0,
                      1.0,
                    );
                setState(() => _progress = newVal);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _progress,
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _progressColor(_progress).withValues(alpha: 0.7),
                              _progressColor(_progress),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Positioned(
                      left: _progress * constraints.maxWidth - 14,
                      top: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _progressColor(_progress),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _progressColor(
                                _progress,
                              ).withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Month Start',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
            Text(
              'End of Month Goal',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _progressColor(double p) {
    if (p < 0.5) return Colors.green;
    if (p < 0.8) return Colors.orange;
    return Colors.red;
  }
}

// ─── 2. DailyBalanceWidget ────────────────────────────────────────────────────

class _DailyBalanceCard extends StatefulWidget {
  final double initialLimit;
  final double leftForDinner;
  final List<Object?> expenses;
  const _DailyBalanceCard({
    required this.initialLimit,
    required this.leftForDinner,
    required this.expenses,
  });

  @override
  State<_DailyBalanceCard> createState() => _DailyBalanceCardState();
}

class _DailyBalanceCardState extends State<_DailyBalanceCard> {
  late double _dailyLimit;

  @override
  void initState() {
    super.initState();
    _dailyLimit = widget.initialLimit;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Check-in',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Goal:',
                style: TextStyle(color: Colors.black54),
              ),
              Row(
                children: [
                  _StepperButton(
                    icon: Icons.remove_circle_outline,
                    color: Colors.red,
                    onTap: () => setState(
                      () => _dailyLimit = (_dailyLimit - 50).clamp(50, 5000),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      '฿${_dailyLimit.toStringAsFixed(0)}',
                      key: ValueKey(_dailyLimit),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StepperButton(
                    icon: Icons.add_circle_outline,
                    color: Colors.green,
                    onTap: () => setState(
                      () => _dailyLimit = (_dailyLimit + 50).clamp(50, 5000),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Spent Today:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...widget.expenses.map((exp) {
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
                    const Icon(
                      Icons.receipt_long,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(name),
                  ],
                ),
                Text('฿${amount.toStringAsFixed(0)}'),
              ],
            ),
          );
        }),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Left for Dinner:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            Text(
              '฿${widget.leftForDinner.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.deepOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StepperButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 30),
    );
  }
}

// ─── 4. RecommendExpenseWidget ────────────────────────────────────────────────

class _AwardCard extends StatefulWidget {
  final double reward;
  const _AwardCard({required this.reward});

  @override
  State<_AwardCard> createState() => _AwardCardState();
}

class _AwardCardState extends State<_AwardCard>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 4.0, end: 20.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            Colors.green,
            Colors.yellow,
            Colors.orange,
            Colors.pink,
            Colors.blue,
            Colors.purple,
          ],
          numberOfParticles: 40,
          gravity: 0.3,
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => _confettiController.play(),
              child: AnimatedBuilder(
                animation: _glowAnim,
                builder: (context, child) {
                  return CircleAvatar(
                    backgroundColor: Colors.green.shade200,
                    radius: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: 0.8),
                            blurRadius: _glowAnim.value,
                            spreadRadius: _glowAnim.value * 0.4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎉 Great Job!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You are far under your spending goal! You have ฿${widget.reward.toStringAsFixed(0)} to reward yourself. Tap the icon to celebrate! 🎊',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Catalog definition ───────────────────────────────────────────────────────

/// The catalog defining the specific 5 widgets for the 13-step Financial Story demo
final catalogItemsList = <CatalogItem>[
  // 1. ExpenseProgressLineGraph
  CatalogItem(
    name: 'ExpenseProgressLineGraph',
    dataSchema: S.object(
      properties: {
        'progressPercentage': S.number(
          description: '0 to 1 progress of expense',
        ),
        'daysLeft': S.number(description: 'Days left in month'),
      },
      required: ['progressPercentage', 'daysLeft'],
    ),
    widgetBuilder: (CatalogItemContext context) {
      final data = context.data is Map ? context.data as Map : null;
      final progress =
          (data?['progressPercentage'] as num?)?.toDouble() ?? 0.65;
      final daysLeft = (data?['daysLeft'] as num?)?.toInt() ?? 10;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _DraggableProgressBar(
            initialProgress: progress,
            initialDaysLeft: daysLeft,
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
            properties: {'name': S.string(), 'amount': S.number()},
          ),
        ),
      },
      required: ['dailyLimit', 'leftForDinner', 'expenses'],
    ),
    widgetBuilder: (CatalogItemContext context) {
      final data = context.data is Map ? context.data as Map : null;
      final dailyLimit = (data?['dailyLimit'] as num?)?.toDouble() ?? 500;
      final leftForDinner = (data?['leftForDinner'] as num?)?.toDouble() ?? 100;
      final expensesList = data?['expenses'] as List<Object?>? ?? [];

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 3,
        color: Theme.of(
          context.buildContext,
        ).colorScheme.primaryContainer.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _DailyBalanceCard(
            initialLimit: dailyLimit,
            leftForDinner: leftForDinner,
            expenses: expensesList,
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
              'ticker': S.string(description: 'Stock ticker symbol'),
              'dropPercent': S.number(),
              'value': S.number(),
              'logoUrl': S.string(description: 'URL to the brand logo image'),
            },
          ),
        ),
        'reassuranceMessage': S.string(),
      },
      required: ['stocks', 'reassuranceMessage'],
    ),
    widgetBuilder: (CatalogItemContext context) {
      final data = context.data is Map ? context.data as Map : null;
      final stocks = data?['stocks'] as List<Object?>? ?? [];
      final message = data?['reassuranceMessage'] as String? ?? '';

      // Fallback logos by brand name
      const brandLogos = <String, String>{
        'google': 'https://logo.clearbit.com/google.com',
        'alphabet': 'https://logo.clearbit.com/abc.xyz',
        'apple': 'https://logo.clearbit.com/apple.com',
        'microsoft': 'https://logo.clearbit.com/microsoft.com',
        'amazon': 'https://logo.clearbit.com/amazon.com',
        'tesla': 'https://logo.clearbit.com/tesla.com',
        'meta': 'https://logo.clearbit.com/meta.com',
        'nvidia': 'https://logo.clearbit.com/nvidia.com',
      };

      String getLogoUrl(Map stock) {
        final fromData = stock['logoUrl']?.toString() ?? '';
        if (fromData.isNotEmpty) return fromData;
        final name = (stock['name']?.toString() ?? '').toLowerCase();
        for (final entry in brandLogos.entries) {
          if (name.contains(entry.key)) return entry.value;
        }
        final ticker = (stock['ticker']?.toString() ?? '').toLowerCase();
        return 'https://logo.clearbit.com/$ticker.com';
      }

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.shade200, width: 2),
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
                  const Text(
                    'Passive Income & Stocks',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...stocks.map((stock) {
                if (stock is! Map) return const SizedBox.shrink();
                final name = stock['name']?.toString() ?? 'Stock';
                final drop = (stock['dropPercent'] as num?)?.toDouble() ?? 0.0;
                final val = (stock['value'] as num?)?.toDouble() ?? 0.0;
                final logoUrl = getLogoUrl(stock);
                final isPositive = drop <= 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          logoUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, _, __) => Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.business,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '\$${val.toStringAsFixed(0)} USD',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPositive ? '▲ $drop%' : '▼ $drop%',
                          style: TextStyle(
                            color: isPositive
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),

  // 4. RecommendExpenseWidget
  CatalogItem(
    name: 'RecommendExpenseWidget',
    dataSchema: S.object(properties: {'rewardAvailable': S.number()}),
    widgetBuilder: (CatalogItemContext context) {
      final data = context.data is Map ? context.data as Map : null;
      final reward = (data?['rewardAvailable'] as num?)?.toDouble() ?? 2000;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 2,
        color: Colors.green.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _AwardCard(reward: reward),
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
        'url': S.string(description: 'URL to the product page'),
      },
      required: ['id', 'name', 'price', 'imageUrl', 'url'],
    ),
    widgetBuilder: (CatalogItemContext itemContext) {
      final data = itemContext.data is Map ? itemContext.data as Map : null;
      final name = (data?['name'] as String?) ?? 'Product';
      final price = (data?['price'] as num?)?.toDouble() ?? 0.0;
      final imageUrl = (data?['imageUrl'] as String?) ?? '';
      final url = (data?['url'] as String?) ?? '';
      final specs =
          (data?['specs'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final id = (data?['id'] as String?) ?? 'unknown';

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
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, stackTrace) {
                  // Fallback: search via Google Images for the item
                  final fallbackUrl =
                      'https://source.unsplash.com/600x400/?${Uri.encodeComponent(name)}';
                  return Image.network(
                    fallbackUrl,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.shopping_bag,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              )
            else
              Image.network(
                'https://source.unsplash.com/600x400/?${Uri.encodeComponent(name)},product',
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.shopping_bag,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...specs.map(
                    (spec) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              spec,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '฿${price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(
                        itemContext.buildContext,
                      ).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Source $url',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(
                        itemContext.buildContext,
                      ).colorScheme.primary,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        itemContext.buildContext,
                      ).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () async {
                      itemContext.dispatchEvent(
                        UserActionEvent(
                          name: 'buy_now',
                          sourceComponentId: itemContext.id,
                          context: {
                            'id': id,
                            'name': name,
                            'price': price,
                            'url': url,
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_checkout),
                    label: const Text(
                      'Confirm Purchase',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  ),
];

final catalog = Catalog(catalogItemsList, catalogId: 'story_catalog');
