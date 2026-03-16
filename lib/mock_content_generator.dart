import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

/// A Mock Content Generator to safely demo GenUI without API keys or network latency.
/// This mock acts as a state machine fulfilling the 13-step "Financial Statement" story flow.
class MockContentGenerator implements ContentGenerator {
  final StreamController<A2uiMessage> _a2uiMessageController = StreamController<A2uiMessage>.broadcast();
  final StreamController<String> _textStreamController = StreamController<String>.broadcast();
  final StreamController<ContentGeneratorError> _errorStreamController = StreamController<ContentGeneratorError>.broadcast();
  final ValueNotifier<bool> _isProcessing = ValueNotifier<bool>(false);

  @override
  Stream<A2uiMessage> get a2uiMessageStream => _a2uiMessageController.stream;

  @override
  Stream<String> get textResponseStream => _textStreamController.stream;

  @override
  Stream<ContentGeneratorError> get errorStream => _errorStreamController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessing;

  @override
  Future<void> sendRequest(
    ChatMessage message, {
    Iterable<ChatMessage>? history,
    A2UiClientCapabilities? clientCapabilities,
  }) async {
    _isProcessing.value = true;
    try {
      if (message is UserMessage) {
        final prompt = message.text.toLowerCase();
        
        await Future.delayed(const Duration(milliseconds: 500));

        if (prompt.contains('money') || prompt.contains('left')) {
          await _handleDailyBalance();
        } else if (prompt.contains('stock') || prompt.contains('passive')) {
          await _handleStaticStocks();
        } else if (prompt.contains('summary') || prompt.contains('shopping')) {
          await _handleExpenseSummary();
        } else if (prompt.contains('shoe') || prompt.contains('sneaker')) {
          await _handleShoppingRecommendation();
        } else if (prompt.contains('thank') || prompt.contains('done')) {
          _textStreamController.add("You're very welcome! Let me know if you need anything else. Have a great day! \n\n**(End of Demo)**");
        } else {
          // Default greeting / Step 1 & 2
          _textStreamController.add("Good morning! I've summarized your income and outcome: you are solidly in the **green** position. You don't need to worry about spending money, and you're perfectly on plan to the end of the month.");
        }
      } else if (message is UserUiInteractionMessage) {
        final text = message.text;
        if (text.isNotEmpty) {
           if (text.contains('buy_now')) {
             _textStreamController.add("🎉 Purchase Complete! I've checked out the items for you. I have automatically updated your expense summary plan to reflect this reward.");
           } else {
             _textStreamController.add("\n\n*Agent task executed: $text*");
           }
        }
      }
    } catch (e, stack) {
      _errorStreamController.add(ContentGeneratorError(e, stack));
    } finally {
      _isProcessing.value = false;
    }
  }

  Future<void> _handleDailyBalance() async {
    _textStreamController.add("Here is your daily budget breakdown:");
    await Future.delayed(const Duration(milliseconds: 600));

    final surfaceId = DateTime.now().millisecondsSinceEpoch.toString();
    _a2uiMessageController.add(A2uiMessage.fromJson({'beginRendering': {'surfaceId': surfaceId, 'root': 'root', 'catalogId': 'story_catalog'}}));
    
    await Future.delayed(const Duration(milliseconds: 400));
    _a2uiMessageController.add(A2uiMessage.fromJson({
      'surfaceUpdate': {
        'surfaceId': surfaceId,
        'components': [
          {
            'id': 'root',
            'type': 'Column',
            'properties': {
              'children': [ {'componentId': 'dailyBal'} ]
            }
          },
          {
            'id': 'dailyBal',
            'type': 'DailyBalanceWidget',
            'properties': {
              'dailyLimit': { 'literalNumber': 300 },
              'leftForDinner': { 'literalNumber': 70 },
              'expenses': [
                { 'name': { 'literalString': 'Coffee' }, 'amount': { 'literalNumber': 50 } },
                { 'name': { 'literalString': 'Lunch' }, 'amount': { 'literalNumber': 80 } },
                { 'name': { 'literalString': 'MRT to work' }, 'amount': { 'literalNumber': 40 } },
              ]
            }
          }
        ]
      }
    }));
    
    await Future.delayed(const Duration(milliseconds: 400));
    _textStreamController.add("\n\nYour total so far is around 170 Baht. Now it's time for dinner, and you can spend 70 Baht as usual to hit your goal under 300 Baht per day.");
  }

  Future<void> _handleStaticStocks() async {
    _textStreamController.add("Checking your portfolio...");
    await Future.delayed(const Duration(milliseconds: 600));

    final surfaceId = DateTime.now().millisecondsSinceEpoch.toString();
    _a2uiMessageController.add(A2uiMessage.fromJson({'beginRendering': {'surfaceId': surfaceId, 'root': 'root', 'catalogId': 'story_catalog'}}));
    
    await Future.delayed(const Duration(milliseconds: 400));
    _a2uiMessageController.add(A2uiMessage.fromJson({
      'surfaceUpdate': {
        'surfaceId': surfaceId,
        'components': [
          {
            'id': 'root',
            'type': 'Column',
            'properties': { 'children': [ {'componentId': 'stocks'} ] }
          },
          {
            'id': 'stocks',
            'type': 'StockWidget',
            'properties': {
              'reassuranceMessage': { 'literalString': 'Don\'t worry, the overall outlook for both of these still looks good. I will notify you in advance if you need to sell.' },
              'stocks': [
                { 'name': { 'literalString': 'Stock A' }, 'dropPercent': { 'literalNumber': 10.0 }, 'value': { 'literalNumber': 1250 } },
                { 'name': { 'literalString': 'Stock B' }, 'dropPercent': { 'literalNumber': 4.5 }, 'value': { 'literalNumber': 840 } },
              ]
            }
          }
        ]
      }
    }));
    await Future.delayed(const Duration(milliseconds: 400));
    _textStreamController.add("\n\nSorry, today the stock market is not going well. However, they remain solid long-term investments.");
  }

  Future<void> _handleExpenseSummary() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final surfaceId = DateTime.now().millisecondsSinceEpoch.toString();
    _a2uiMessageController.add(A2uiMessage.fromJson({'beginRendering': {'surfaceId': surfaceId, 'root': 'root', 'catalogId': 'story_catalog'}}));
    
    await Future.delayed(const Duration(milliseconds: 400));
    _a2uiMessageController.add(A2uiMessage.fromJson({
      'surfaceUpdate': {
        'surfaceId': surfaceId,
        'components': [
          {
            'id': 'root',
            'type': 'Column',
            'properties': { 'children': [ {'componentId': 'prograph'}, {'componentId': 'reward'} ] }
          },
          {
            'id': 'prograph',
            'type': 'ExpenseProgressLineGraph',
            'properties': {
              'progressPercentage': { 'literalNumber': 0.65 },
              'daysLeft': { 'literalNumber': 12 },
            }
          },
          {
            'id': 'reward',
            'type': 'RecommendExpenseWidget',
            'properties': {
              'rewardAvailable': { 'literalNumber': 2000 },
            }
          }
        ]
      }
    }));
  }

  Future<void> _handleShoppingRecommendation() async {
    _textStreamController.add("That would be nice! Your current sneakers are kind of outdated and about 6 years old now. Let me look for a new pair for you:");
    await Future.delayed(const Duration(milliseconds: 800));

    final surfaceId = DateTime.now().millisecondsSinceEpoch.toString();
    _a2uiMessageController.add(A2uiMessage.fromJson({'beginRendering': {'surfaceId': surfaceId, 'root': 'root', 'catalogId': 'story_catalog'}}));
    
    await Future.delayed(const Duration(milliseconds: 400));
    _a2uiMessageController.add(A2uiMessage.fromJson({
      'surfaceUpdate': {
        'surfaceId': surfaceId,
        'components': [
          {
            'id': 'root',
            'type': 'Column',
            'properties': { 'children': [ {'componentId': 'sneakers'} ] }
          },
          {
            'id': 'sneakers',
            'type': 'ProductShoppingWidget',
            'properties': {
              'id': { 'literalString': 'nike-air-max' },
              'name': { 'literalString': 'Nike Air Max 2026' },
              'price': { 'literalNumber': 1850 },
              'specs': [
                 { 'literalString': 'Breathable mesh upper' },
                 { 'literalString': 'Max Air cushioning' },
                 { 'literalString': 'Classic monochrome styling' }
              ],
              'imageUrl': { 'literalString': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=2070&auto=format&fit=crop' }
            }
          }
        ]
      }
    }));
    await Future.delayed(const Duration(milliseconds: 400));
    _textStreamController.add("\n\nWould you like me to buy it and checkout?");
  }

  @override
  void dispose() {
    _a2uiMessageController.close();
    _textStreamController.close();
    _errorStreamController.close();
    _isProcessing.dispose();
  }
}
