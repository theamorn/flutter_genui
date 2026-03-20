import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'catalog.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:genui_firebase_ai/genui_firebase_ai.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';

class CustomA2uiMessageProcessor extends A2uiMessageProcessor {
  CustomA2uiMessageProcessor({required super.catalogs});

  @override
  void handleUiEvent(UiEvent event) async {
    super.handleUiEvent(event);
    // Host intercepts the 'buy_now' action and handles the launch externally
    if (event is UserActionEvent && event.name == 'buy_now') {
      final url = event.context['url'] as String;
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SmartAssistantApp());
}

class SmartAssistantApp extends StatelessWidget {
  const SmartAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HUD',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyan,
          secondary: Colors.cyanAccent,
          surface: Colors.black,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Colors.cyanAccent,
            fontFamily: 'monospace',
          ),
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final ContentGenerator _contentGenerator;
  late final GenUiConversation _conversation;
  final _surfaceIds = <String>[];

  @override
  void initState() {
    super.initState();

    // Create the custom message processor with our 5 new story widgets
    final a2uiMessageProcessor = CustomA2uiMessageProcessor(
      catalogs: [catalog],
    );
    const systemInstruction = '''
You are an expert in financial assistant. Every time I ask you a question,
        you should generate UI that displays one financial answer related to that word if it's not relate
        you just send the text back. Use my information to help answer the questions
      
      <Information>
      Name: Amorn 
      Nickname: Bank
      Company: KBTG
      Salary: 30,000 Baht
      Target spend per day: 500 Baht
      Transaction Today:
        - Coffee: 50 Baht
        - Lunch: 80 Baht
        - MRT to work: 40 Baht
      Stocks:
        - Google: 10 stock at 150 Dolalrs
        - Apple: 5 stock at 300 Dolalrs
      Expense Status: Good progress towards end of month. Now spend 12,000 Baht.
      </Information>
''';

    _contentGenerator = FirebaseAiContentGenerator(
      catalog: catalog,
      systemInstruction: systemInstruction,
      modelCreator:
          ({required configuration, systemInstruction, toolConfig, tools}) {
            return GeminiGenerativeModel(
              FirebaseAI.googleAI().generativeModel(
                model: 'gemini-3-flash-preview',
                systemInstruction: systemInstruction,
                tools: tools,
                toolConfig: toolConfig,
              ),
            );
          },
    );

    _conversation = GenUiConversation(
      a2uiMessageProcessor: a2uiMessageProcessor,
      contentGenerator: _contentGenerator,
      onSurfaceAdded: _onSurfaceAdded,
      onSurfaceDeleted: _onSurfaceDeleted,
      onError: (exception) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${exception.error}')));
      },
    );
  }

  @override
  void dispose() {
    _conversation.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSurfaceAdded(SurfaceAdded update) {
    print("surface added ${update.surfaceId}");
    setState(() {
      _surfaceIds.add(update.surfaceId);
    });
  }

  void _onSurfaceDeleted(SurfaceRemoved update) {
    print("surface deleted ${update.surfaceId}");
    setState(() {
      _surfaceIds.remove(update.surfaceId);
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _scrollToBottom();

    // Trigger the A2UI conversation
    _conversation.sendRequest(UserMessage.text(text));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCatalogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.cyan),
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Catalog Widgets',
            style: TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace'),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: catalogItemsList.length,
              itemBuilder: (context, index) {
                final item = catalogItemsList[index];
                return ListTile(
                  leading: const Icon(Icons.extension, color: Colors.cyan),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();

                    showDialog(
                      context: context,
                      builder: (childContext) {
                        final dataModel = DataModel();
                        final dataContext = DataContext(dataModel, '/');
                        final itemContext = CatalogItemContext(
                          data: {},
                          id: item.name,
                          buildChild: (id, [ctx]) => const SizedBox.shrink(),
                          dispatchEvent: (event) {},
                          buildContext: childContext,
                          dataContext: dataContext,
                          getComponent: (id) => null,
                          surfaceId: 'preview_${item.name}',
                        );

                        return AlertDialog(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.cyan),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontFamily: 'monospace',
                            ),
                          ),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: SingleChildScrollView(
                              child: item.widgetBuilder(itemContext),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(childContext).pop(),
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  color: Colors.cyan,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.cyan, fontFamily: 'monospace'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HUD',
          style: TextStyle(
            fontFamily: 'monospace',
            letterSpacing: 2,
            color: Colors.cyan,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.widgets, color: Colors.cyan),
            onPressed: () => _showCatalogDialog(context),
            tooltip: 'Catalog Widgets',
          ),
        ],
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.cyan),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.cyan, height: 1.0),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage(
              'https://transparenttextures.com/patterns/cubes.png',
            ), // A subtle grid texture
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.cyan.withOpacity(0.05),
              BlendMode.dstIn,
            ),
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ValueListenableBuilder<List<ChatMessage>>(
                    valueListenable: _conversation.conversation,
                    builder: (context, messages, _) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _scrollToBottom(),
                      );
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          if (message is UserMessage) {
                            return MessageBubble(
                              text: message.text,
                              isUser: true,
                            );
                          } else if (message is AiTextMessage) {
                            return MessageBubble(
                              text: message.text,
                              isUser: false,
                            );
                          } else if (message is AiUiMessage) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.cyan.withOpacity(0.5),
                                ),
                                color: Colors.cyan.withOpacity(0.05),
                              ),
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "SYSTEM_WIDGET_RENDER // ${message.surfaceId}",
                                    style: const TextStyle(
                                      color: Colors.cyan,
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GenUiSurface(
                                    host: _conversation.host,
                                    surfaceId: message.surfaceId,
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                ),
                // Input Section
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.cyan, width: 1),
                      ),
                      color: Colors.black,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontFamily: 'monospace',
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter command override...",
                              hintStyle: TextStyle(
                                color: Colors.cyan.withOpacity(0.5),
                                fontFamily: 'monospace',
                              ),
                              filled: true,
                              fillColor: Colors.black,
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.cyan),
                                borderRadius: BorderRadius.zero,
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.cyanAccent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.zero,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 15,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ValueListenableBuilder<bool>(
                          valueListenable: _conversation.isProcessing,
                          builder: (context, isProcessing, _) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.cyan),
                              ),
                              child: IconButton(
                                icon: isProcessing
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.cyanAccent,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send,
                                        color: Colors.cyanAccent,
                                      ),
                                onPressed: isProcessing ? null : _sendMessage,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Opacity(
              opacity: 0.1,
              child: const Positioned(
                top: 16,
                left: 16,
                child: IgnorePointer(child: AnimatedJarvisDate()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const MessageBubble({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? Colors.cyan.withOpacity(0.1) : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isUser ? Colors.transparent : Colors.cyan,
                  width: 2,
                ),
                right: BorderSide(
                  color: isUser ? Colors.cyan : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  isUser ? "USER_INPUT >" : "AI >",
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  textAlign: isUser ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    color: isUser ? Colors.cyanAccent : Colors.white,
                    fontSize: 15,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AnimatedJarvisDate extends StatefulWidget {
  const AnimatedJarvisDate({super.key});
  @override
  State<AnimatedJarvisDate> createState() => _AnimatedJarvisDateState();
}

class _AnimatedJarvisDateState extends State<AnimatedJarvisDate>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildDateRing(),
        const SizedBox(height: 12),
        _buildTickingTime(),
        const SizedBox(height: 16),
        _buildBatteryRing(),
      ],
    );
  }

  Widget _buildDateRing() {
    final now = DateTime.now();
    final month = _monthString(now.month);
    final day = now.day.toString().padLeft(2, '0');

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * 3.1415926535,
                child: CustomPaint(
                  size: const Size(120, 120),
                  painter: JarvisArcPainter(),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle:
                    -_controller.value * 2 * 3.1415926535, // Reverse rotation
                child: CustomPaint(
                  size: const Size(100, 100),
                  painter: JarvisInnerArcPainter(),
                ),
              );
            },
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 1),
              color: Colors.cyan.withOpacity(0.1),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                month,
                style: TextStyle(
                  color: Colors.cyanAccent.withOpacity(0.9),
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              Text(
                day,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontFamily: 'monospace',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTickingTime() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final now = DateTime.now();
        final hours = now.hour.toString().padLeft(2, '0');
        final minutes = now.minute.toString().padLeft(2, '0');
        final seconds = now.second.toString().padLeft(2, '0');
        return Text(
          "$hours:$minutes:$seconds",
          style: TextStyle(
            color: Colors.cyanAccent.withOpacity(0.85),
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            shadows: [
              Shadow(color: Colors.cyanAccent.withOpacity(0.6), blurRadius: 6),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBatteryRing() {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * 3.1415926535,
                child: CustomPaint(
                  size: const Size(80, 80),
                  painter: JarvisBatteryPainter(),
                ),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "PWR",
                style: TextStyle(
                  color: Colors.cyanAccent.withOpacity(0.8),
                  fontFamily: 'monospace',
                  fontSize: 8,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent.withOpacity(0.4),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              Text(
                "98%",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 5),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthString(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }
}

class JarvisBatteryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Inner battery solid arc
    final solidPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawArc(rect, 0, 3.1415 * 2 * 0.98, false, solidPaint); // 98% full

    // Outer rotating decorative arcs
    canvas.drawArc(rect, 0.5, 1.0, false, paint);
    canvas.drawArc(rect, 2.5, 1.0, false, paint);
    canvas.drawArc(rect, 4.5, 0.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class JarvisArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw thick outer arcs
    canvas.drawArc(rect, 0, 1.5, false, paint);
    canvas.drawArc(rect, 2.5, 0.5, false, paint);
    canvas.drawArc(rect, 3.5, 1.2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class JarvisInnerArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw thinner internal tracker arcs
    canvas.drawArc(rect, 1.0, 2.0, false, paint);
    canvas.drawArc(rect, 4.0, 1.0, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
