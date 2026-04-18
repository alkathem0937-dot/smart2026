import 'package:flutter/material.dart';
import 'chat_history_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'dart:developer' as developer;

/// شاشة المساعد الذكي - بتصميم 2025+ مع اقتراحات ذكية وحفظ السجلات
class SmartAssistantScreen extends StatefulWidget {
  const SmartAssistantScreen({super.key});

  @override
  State<SmartAssistantScreen> createState() => _SmartAssistantScreenState();
}

class _SmartAssistantScreenState extends State<SmartAssistantScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ApiService _apiService;
  final VoiceService _voiceService = VoiceService();
  bool _isRecording = false;
  final FocusNode _focusNode = FocusNode();

  final List<String> _suggestions = [
    'هل يعتبر العقد المكتوب بخط اليد قانونياً؟',
    'ما هي إجراءات رفع دعوى عمالية؟',
    'ما هي شروط الطلاق للضرر؟',
    'كيف يتم تنفيذ الشيك المرتجع؟',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _apiService = authProvider.apiService;
    });
    _voiceService.init();
  }

  @override
  void dispose() {
    _voiceService.stop();
    _questionController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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

  Future<void> _sendQuestion(String questionText) async {
    final question = questionText.trim();
    if (question.isEmpty) return;

    _questionController.clear();
    _focusNode.unfocus();
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // إرسال الرسالة إلى الـ Provider
    await chatProvider.sendMessage(question);

    // حفظ السجل في قاعدة البيانات
    try {
      final messages = chatProvider.messages;
      if (messages.length >= 2) {
        final lastMessage = messages.last;
        if (lastMessage['role'] == 'assistant') {
          final content = lastMessage['content'];
          if (content != null) {
            await _apiService.createAIChatLog(
              question,
              content.toString(),
              modelVersion: 'groq-openrouter',
            );
            // تم حفظ السجل بنجاح
          }
        }
      }
    } catch (e) {
      developer.log('Error saving chat log: $e');
    }

    _scrollToBottom();
    
    // التحدث بالرد تلقائياً
    if (chatProvider.messages.isNotEmpty) {
      final lastMsg = chatProvider.messages.last;
      if (lastMsg['role'] == 'assistant') {
        _voiceService.speak(lastMsg['content']);
      }
    }
  }

  Future<void> _toggleVoiceRecording() async {
    final available = await _voiceService.toggleListening(
      onResult: (text) {
        setState(() {
          _questionController.text = text;
        });
      },
    );

    if (available) {
      setState(() {
        _isRecording = _voiceService.isListening;
      });
      if (!_isRecording && _questionController.text.isNotEmpty) {
        _sendQuestion(_questionController.text);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تفعيل صلاحية الميكروفون')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('المساعد الذكي (AI)'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'السجلات السابقة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            color: AppColors.error,
            onPressed: () => Provider.of<ChatProvider>(context, listen: false).clearMessages(),
            tooltip: 'مسح المحادثة',
          ),
        ],
      ),
      body: Column(
        children: [
          // منطقة الرسائل
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                if (provider.messages.isEmpty) {
                  return _buildEmptyState();
                }
                
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    final isUser = message['role'] == 'user';
                    return _buildMessageBubble(
                      message['content'].toString(),
                      isUser,
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
                  },
                );
              },
            ),
          ),
          
          // مؤشر التحميل والتفكير
          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: const AlwaysStoppedAnimation(0.8),
                        child: CircularProgressIndicator(color: context.colorScheme.primary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'جاري تحليل النصوص القانونية...',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 0.5, end: 1),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // اقتراحات البحث عند الفراغ أو بعد الجواب
          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              final suggestions = provider.messages.isEmpty ? _suggestions : provider.latestSuggestions;
              if (suggestions.isEmpty || provider.isLoading) return const SizedBox.shrink();

              return Container(
                height: 45,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: ActionChip(
                        label: Text(suggestions[index], style: const TextStyle(fontSize: 12)),
                        backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                        side: BorderSide(color: context.colorScheme.primary.withOpacity(0.3)),
                        onPressed: () => _sendQuestion(suggestions[index]),
                      ).animate().fade(delay: (100 * index).ms).slideX(begin: 0.1),
                    );
                  },
                ),
              );
            },
          ),

          // منطقة إدخال النص
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              MediaQuery.of(context).padding.bottom + AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      border: Border.all(color: context.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _questionController,
                            focusNode: _focusNode,
                            textDirection: TextDirection.rtl,
                            maxLines: 5,
                            minLines: 1,
                            decoration: const InputDecoration(
                              hintText: 'اكتب استشارتك القانونية هنا...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // زر الميكروفون
                Container(
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red.withOpacity(0.1) : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      color: _isRecording ? Colors.red : (isDark ? Colors.white70 : Colors.black54),
                    ),
                    onPressed: _toggleVoiceRecording,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                // زر الإرسال
                Consumer<ChatProvider>(
                  builder: (context, provider, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.colored(AppColors.brand),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: provider.isLoading
                            ? null
                            : () => _sendQuestion(_questionController.text),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    final isDark = context.isDark;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser 
              ? context.colorScheme.primary 
              : (isDark ? AppColors.darkSurfaceVariant : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.radiusLg),
            topRight: const Radius.circular(AppSpacing.radiusLg),
            bottomLeft: Radius.circular(isUser ? AppSpacing.radiusLg : 0),
            bottomRight: Radius.circular(isUser ? 0 : AppSpacing.radiusLg),
          ),
          boxShadow: isDark ? AppShadows.darkSm : AppShadows.sm,
          border: isUser ? null : Border.all(color: context.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.start : CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
                    size: 14,
                    color: isUser ? Colors.white70 : AppColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isUser ? 'أنت' : 'المساعد الذكي',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isUser ? Colors.white70 : AppColors.gold,
                    ),
                  ),
                  if (!isUser) ...[
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, size: 16),
                      color: AppColors.gold,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _voiceService.speak(text),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              SelectableText(
                text,
                style: TextStyle(
                  color: isUser 
                      ? Colors.white 
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  fontSize: 15,
                  height: 1.6,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 80,
                color: AppColors.gold,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'كيف يمكنني مساعدتك اليوم؟',
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fade().slideY(begin: 0.2),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Text(
                'أنا مساعدك القانوني الذكي، معتمد على قاعدة بيانات القوانين اليمنية. اختر من الاقتراحات بالأسفل أو اطرح سؤالك مباشرة.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
              ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}
