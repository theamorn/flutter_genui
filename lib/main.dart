import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import 'catalog.dart';
// import 'package:firebase_core/firebase_core.dart'; // Uncomment this once you run `flutterfire configure`
import 'package:genui_firebase_ai/genui_firebase_ai.dart';
// import 'firebase_options.dart'; // Uncomment this once you run `flutterfire configure`

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // NOTE: You must run `flutterfire configure` to generate firebase_options.dart for your Android tablet.
  // Then uncomment the import and the line below to initialize Firebase.
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(const SmartTravelPlannerApp());
}

class SmartTravelPlannerApp extends StatelessWidget {
  const SmartTravelPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A2UI & GenUI Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
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

  @override
  void initState() {
    super.initState();
    
    // Create the message processor with our 5 new story widgets
    final a2uiMessageProcessor = A2uiMessageProcessor(catalogs: [catalog]);
    
    // A system prompt designed explicitly to guide the real AI through the 13-step Tech Talk story.
    const systemInstruction = '''
    You are a highly advanced Financial Statement Assistant acting as a Jarvis-like entity.
    You are in a live tech demonstration. Your goal is to guide the user through a specific 13-step story.
    
    Here is the exact state machine you should follow. You MUST use the provided tools to generate the UI instead of just talking.
    
    1. Greeting: Acknowledge the user, state they are in the 'green' and perfectly on their spending plan to the end of the month. Use text only.
    
    2. Daily Balance: When asked "How much money do I have left?" or similar, you MUST use the `DailyBalanceWidget` tool. 
       - Set `dailyLimit` to 300.
       - Set `leftForDinner` to 70.
       - Set the `expenses` list to include Coffee (50), Lunch (80), and MRT to work (40).
       - Accompany this with a short text explaining the 170 spent and 70 left.
       
    3. Stocks / Passive Income: When asked "How about my stocks and passive income today?" or similar, you MUST use the `StockWidget` tool.
       - Generate an array of two stocks.
       - Stock A is down 10%. Stock B is down 4.5%.
       - Add a reassuring message saying they are still solid long-term.
       
    4. Expense Summary & Shopping: When asked "Give me an expense summary. Is it enough to do some shopping?", you MUST use the `ExpenseProgressLineGraph` and `RecommendExpenseWidget` tools.
       - The user has a 2000 Baht reward available for being under budget.
       
    5. Sneaker Shopping: When the user says "I haven't bought new shoes in a long time", you MUST use the `ProductShoppingWidget` tool.
       - Show the user some new sneakers costing exactly 1850 THB.
       - Provide standard sneaker specifications.
       
    6. Agent Checkout: When the user says "Awesome, buy it and checkout", acknowledge the purchase. Assume the system has already fired the 'buy_now' UiEvent. Tell the user you have updated the expense summary.
    
    Follow this structure strictly. Do NOT hallucinate other tools. Provide concise, friendly assistant responses alongside your tool calls.
    ''';

    _contentGenerator = FirebaseAiContentGenerator(
      catalog: catalog,
      systemInstruction: systemInstruction,
      // Note: FirebaseAiContentGenerator doesn't require explicitly passing additionalTools
      // as it automatically provides the A2UI surface manipulation tools.
    );
    
    _conversation = GenUiConversation(
      a2uiMessageProcessor: a2uiMessageProcessor,
      contentGenerator: _contentGenerator,
      onError: (exception) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${exception.error}')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Statement Assistant'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<List<ChatMessage>>(
              valueListenable: _conversation.conversation,
              builder: (context, messages, _) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    
                    if (message is UserMessage) {
                      return MessageBubble(text: message.text, isUser: true);
                    } else if (message is AiTextMessage) {
                      return MessageBubble(text: message.text, isUser: false);
                    } else if (message is AiUiMessage) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: GenUiSurface(
                          host: _conversation.host,
                          surfaceId: message.surfaceId,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
          
          // Where the magic happens: A2UI progressively renders here (now handled by ListView!)
          
          // Input Section
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "E.g., How much money do I have left?",
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _conversation.isProcessing,
                      builder: (context, isProcessing, _) {
                        return IconButton(
                          icon: isProcessing 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send, color: Colors.white),
                          onPressed: isProcessing ? null : _sendMessage,
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) const CircleAvatar(child: Icon(Icons.smart_toy)),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? theme.colorScheme.primary : Colors.grey[300],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) const CircleAvatar(child: Icon(Icons.person)),
        ],
      ),
    );
  }
}
