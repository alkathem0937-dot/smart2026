import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  bool _isLoading = true;
  List<dynamic> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      // We'll use a custom logic or just group messages
      final response = await apiService.get('/api/messaging/messages/');
      List<dynamic> results = [];
      if (response is List) {
        results = response;
      } else if (response is Map) {
        if (response.containsKey('results')) {
          results = response['results'] as List;
        } else if (response.containsKey('data')) {
          final data = response['data'];
          if (data is List) {
            results = data;
          } else if (data is Map && data.containsKey('results')) {
            results = data['results'] as List;
          }
        }
      }
      
      setState(() {
        _conversations = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('المراسلات', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _conversations.isEmpty 
          ? _buildEmptyState()
          : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد رسائل حالياً',
            style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('تحدث مع محاميك أو موكلك بخصوص القضية'),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final msg = _conversations[index];
        final isMe = false; // Simplified
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    lawsuitId: msg['lawsuit'],
                    recipientId: msg['sender'] == 1 ? msg['recipient'] : msg['sender'], // Logic needs to be smarter
                    recipientName: msg['sender_name'],
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            title: Text(msg['sender_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(msg['content'], maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(
              msg['created_at'].toString().split('T')[0],
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
        );
      },
    );
  }
}
