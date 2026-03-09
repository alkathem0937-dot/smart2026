// lib/screens/smart_assistant_screen.dart
// شاشة المساعد الذكي - واجهة الدردشة مع الذكاء الاصطناعي

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'dart:developer' as developer;

/// Smart Assistant Screen - المساعد الذكي
class SmartAssistantScreen extends StatefulWidget {
  const SmartAssistantScreen({super.key});

  @override
  State<SmartAssistantScreen> createState() => _SmartAssistantScreenState();
}

class _SmartAssistantScreenState extends State<SmartAssistantScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _apiService = authProvider.apiService;
      // Note: ChatProvider doesn't need token setup as it uses AIApiService directly
      // ملاحظة: ChatProvider لا يحتاج إعداد token لأنه يستخدم AIApiService مباشرة
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    _questionController.clear();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    await chatProvider.sendMessage(question);

    // حفظ سجل الدردشة بعد الحصول على الاستجابة
    // Wait for response then save log
    try {
      final messages = chatProvider.messages;
      if (messages.length >= 2) {
        final lastMessage = messages.last;
        if (lastMessage['role'] == 'assistant') {
          final content = lastMessage['content'];
          if (content != null) {
            final contentStr = content.toString();
            await _apiService.createAIChatLog(
              question,
              contentStr,
              modelVersion: 'groq-openrouter',
            );
          }
        }
      }
    } catch (e) {
      developer.log('Error saving chat log: $e', name: 'SmartAssistantScreen');
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعد القانوني الذكي'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              Provider.of<ChatProvider>(context, listen: false).clearMessages();
            },
            tooltip: 'مسح الدردشة',
          ),
        ],
      ),
      body: Column(
        children: [
          // منطقة الرسائل
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12.0),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    final isUser = message['role'] == 'user';
                    return _buildMessageBubble(
                      {'role': message['role'] as String, 'content': message['content'] as String},
                      isUser
                    );
                  },
                );
              },
            ),
          ),
          // مؤشر التحميل
          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'جاري التفكير...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Note: ChatProvider doesn't have errorMessage, errors are shown in messages
          // ملاحظة: ChatProvider لا يحتوي على errorMessage، الأخطاء تظهر في الرسائل
          // حقل الإدخال
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      decoration: InputDecoration(
                        hintText: 'اكتب استفسارك القانوني...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 12.0,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendQuestion(),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Consumer<ChatProvider>(
                    builder: (context, provider, child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: provider.isLoading
                              ? Colors.grey
                              : const Color(0xFFD4AF37),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: provider.isLoading ? null : _sendQuestion,
                          icon: const Icon(Icons.send, color: Colors.white),
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
    );
  }

  Widget _buildMessageBubble(Map<String, String> message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.all(14.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFD4AF37).withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: Border.all(
            color: isUser
                ? const Color(0xFFD4AF37).withOpacity(0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUser ? Icons.person : Icons.smart_toy,
                  size: 16,
                  color: isUser ? const Color(0xFFD4AF37) : const Color(0xFF1A1A1A),
                ),
                const SizedBox(width: 6),
                Text(
                  isUser ? 'أنت' : 'المساعد الذكي',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isUser ? const Color(0xFFD4AF37) : const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              message['content'] ?? '',
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
