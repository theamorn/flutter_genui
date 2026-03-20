import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:confetti/confetti.dart';

// ─── Shared HUD Style Constants ─────────────────────────────────────────────
final BoxDecoration hudDecoration = BoxDecoration(
  color: const Color(
    0xFF0F172A,
  ).withValues(alpha: 0.85), // Deep dark blue/black
  borderRadius: BorderRadius.circular(16),
  border: Border.all(
    color: Colors.cyanAccent.withValues(alpha: 0.3),
    width: 1.5,
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.cyanAccent.withValues(alpha: 0.1),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ],
);

const TextStyle hudTitleStyle = TextStyle(
  color: Colors.cyanAccent,
  fontWeight: FontWeight.bold,
  fontSize: 18,
  letterSpacing: 1.2,
  fontFamily: 'monospace',
);

const TextStyle hudSubtitleStyle = TextStyle(
  color: Colors.white70,
  fontSize: 12,
  fontFamily: 'monospace',
);

const TextStyle hudValueStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 16,
  fontFamily: 'monospace',
);

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Expense Progression', style: hudTitleStyle),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _progressColor(_progress).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _progressColor(_progress)),
                boxShadow: [
                  BoxShadow(
                    color: _progressColor(_progress).withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                '฿$spent / ฿15,000',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _progressColor(_progress),
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${(_progress * 100).round()}% of budget  •  ${widget.initialDaysLeft} days left',
          style: hudSubtitleStyle,
        ),
        const SizedBox(height: 24),
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
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _progress,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _progressColor(_progress).withValues(alpha: 0.5),
                              _progressColor(_progress).withValues(alpha: 0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
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
                    Positioned(
                      left: _progress * constraints.maxWidth - 12,
                      top: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _progressColor(_progress),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _progressColor(_progress),
                              blurRadius: 10,
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
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Month Start', style: hudSubtitleStyle),
            Text('Goal Line', style: hudSubtitleStyle),
          ],
        ),
      ],
    );
  }

  Color _progressColor(double p) {
    if (p < 0.5) return Colors.greenAccent;
    if (p < 0.8) return Colors.orangeAccent;
    return Colors.redAccent;
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
        Row(
          children: [
            const Icon(Icons.track_changes, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            const Text('Daily HUD Check-in', style: hudTitleStyle),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Quota:', style: hudSubtitleStyle),
              Row(
                children: [
                  _StepperButton(
                    icon: Icons.remove_circle_outline,
                    color: Colors.redAccent,
                    onTap: () => setState(
                      () => _dailyLimit = (_dailyLimit - 50).clamp(50, 5000),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      '฿${_dailyLimit.toStringAsFixed(0)}',
                      key: ValueKey(_dailyLimit),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.cyanAccent,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StepperButton(
                    icon: Icons.add_circle_outline,
                    color: Colors.greenAccent,
                    onTap: () => setState(
                      () => _dailyLimit = (_dailyLimit + 50).clamp(50, 5000),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('System Logs Today:', style: hudSubtitleStyle),
        const SizedBox(height: 8),
        ...widget.expenses.map((exp) {
          if (exp is! Map) return const SizedBox.shrink();
          final name = exp['name']?.toString() ?? '';
          final amount = (exp['amount'] as num?)?.toDouble() ?? 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_right_alt,
                      size: 16,
                      color: Colors.cyanAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(name, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                Text('฿${amount.toStringAsFixed(0)}', style: hudValueStyle),
              ],
            ),
          );
        }),
        const Divider(color: Colors.white24, height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'REMAINING FOR DINNER:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
                fontFamily: 'monospace',
                letterSpacing: 1.0,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orangeAccent),
              ),
              child: Text(
                '฿${widget.leftForDinner.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.orangeAccent,
                  fontFamily: 'monospace',
                ),
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
      child: Icon(icon, color: color, size: 28),
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
    _glowAnim = Tween<double>(begin: 4.0, end: 15.0).animate(
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
            Colors.cyanAccent,
            Colors.greenAccent,
            Colors.purpleAccent,
            Colors.yellowAccent,
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
                    backgroundColor: Colors.greenAccent.withValues(alpha: 0.1),
                    radius: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.greenAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: 0.5),
                            blurRadius: _glowAnim.value,
                            spreadRadius: _glowAnim.value * 0.4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.generating_tokens,
                        color: Colors.greenAccent,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OBJECTIVE SECURED',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.greenAccent,
                      letterSpacing: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Budget highly optimized. You have accrued a surplus of ฿${widget.reward.toStringAsFixed(0)} for discretionary spending. Tap token to initiate reward sequence.',
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.4,
                      fontSize: 13,
                    ),
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

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20.0),
        decoration: hudDecoration,
        child: _DraggableProgressBar(
          initialProgress: progress,
          initialDaysLeft: daysLeft,
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

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20.0),
        decoration: hudDecoration.copyWith(
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: _DailyBalanceCard(
          initialLimit: dailyLimit,
          leftForDinner: leftForDinner,
          expenses: expensesList,
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

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20.0),
        decoration: hudDecoration.copyWith(
          border: Border.all(
            color: Colors.purpleAccent.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.purpleAccent),
                const SizedBox(width: 8),
                const Text(
                  'Asset Portfolio Analysis',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.purpleAccent,
                    fontFamily: 'monospace',
                  ),
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
              final Color indicatorColor = isPositive
                  ? Colors.greenAccent
                  : Colors.redAccent;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          logoUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, _, __) => Container(
                            width: 36,
                            height: 36,
                            color: Colors.black,
                            child: const Icon(
                              Icons.business,
                              color: Colors.white54,
                            ),
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
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '\$${val.toStringAsFixed(0)} USD',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: indicatorColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: indicatorColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPositive
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: indicatorColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${drop.abs()}%',
                            style: TextStyle(
                              color: indicatorColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
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
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.cyanAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontFamily: 'monospace',
                        fontSize: 12,
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

  // 4. RecommendExpenseWidget
  CatalogItem(
    name: 'RecommendExpenseWidget',
    dataSchema: S.object(properties: {'rewardAvailable': S.number()}),
    widgetBuilder: (CatalogItemContext context) {
      final data = context.data is Map ? context.data as Map : null;
      final reward = (data?['rewardAvailable'] as num?)?.toDouble() ?? 2000;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20.0),
        decoration: hudDecoration.copyWith(
          border: Border.all(
            color: Colors.greenAccent.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: _AwardCard(reward: reward),
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

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        clipBehavior: Clip.antiAlias,
        decoration: hudDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, error, stackTrace) {
                      final fallbackUrl =
                          'https://source.unsplash.com/600x400/?${Uri.encodeComponent(name)}';
                      return Image.network(
                        fallbackUrl,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 220,
                          color: const Color(0xFF1E293B),
                          child: const Icon(
                            Icons.extension,
                            size: 60,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      );
                    },
                  )
                else
                  Image.network(
                    'https://source.unsplash.com/600x400/?${Uri.encodeComponent(name)},product',
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 220,
                      color: const Color(0xFF1E293B),
                      child: const Icon(
                        Icons.extension,
                        size: 60,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ),
                // Cyberpunk overlay gradient on images
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0F172A).withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 20,
                  right: 20,
                  child: Text(
                    name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...specs.map(
                    (spec) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.memory,
                            size: 16,
                            color: Colors.cyanAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              spec,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'EST. VALUE',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          '฿${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (url.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.link, size: 14, color: Colors.white54),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Data Source: $url',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white54,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        height: 54,
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart, color: Colors.black87),
                            SizedBox(width: 10),
                            Text(
                              'AUTHORIZE PROCUREMENT',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
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
