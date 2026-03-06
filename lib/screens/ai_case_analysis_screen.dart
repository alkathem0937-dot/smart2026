// lib/screens/ai_case_analysis_screen.dart
// شاشة تحليل القضايا باستخدام الذكاء الاصطناعي

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_chat_provider.dart';

/// AI-Powered Case Analysis Screen - تحليل وإعداد القضايا بالذكاء الاصطناعي
class AICaseAnalysisScreen extends StatefulWidget {
  const AICaseAnalysisScreen({super.key});

  @override
  State<AICaseAnalysisScreen> createState() => _AICaseAnalysisScreenState();
}

class _AICaseAnalysisScreenState extends State<AICaseAnalysisScreen> {
  final TextEditingController _caseDescriptionController =
      TextEditingController();
  String _analysisResult = '';
  bool _isAnalyzing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _caseDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _analyzeCase() async {
    if (_caseDescriptionController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'الرجاء إدخال تفاصيل القضية للتحليل.';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _analysisResult = '';
    });

    final query =
        "حلل القضية التالية وقدم التكييف القانوني والإجراءات المحتملة بناءً على القانون اليمني:\n"
        "${_caseDescriptionController.text}";

    try {
      final chatProvider = Provider.of<AIChatProvider>(context, listen: false);
      final response =
          await chatProvider.apiService.getChatResponse(query, []);
      setState(() {
        _analysisResult = response['response'] ?? 'لم يتم الحصول على نتائج.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحليل القضية: $e';
        _analysisResult =
            'عذرًا، حدث خطأ أثناء تحليل القضية. يرجى المحاولة مرة أخرى.';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحليل القضايا بالذكاء الاصطناعي'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بطاقة إدخال تفاصيل القضية
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'تحليل القضية',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _caseDescriptionController,
                    maxLines: 8,
                    minLines: 5,
                    decoration: InputDecoration(
                      labelText: 'تفاصيل القضية',
                      hintText:
                          'أدخل وصفاً تفصيلياً للقضية المراد تحليلها...\n'
                          'مثال: شخص قام بالاستيلاء على أرض مملوكة للدولة...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                      ),
                      alignLabelWithHint: true,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeCase,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        _isAnalyzing ? 'جاري التحليل...' : 'تحليل القضية',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // رسالة الخطأ
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // نتائج التحليل
          if (_analysisResult.isNotEmpty) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'نتائج التحليل',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    SelectableText(
                      _analysisResult,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: Colors.black87,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
          ] else if (!_isAnalyzing) ...[
            // بطاقات الميزات
            _buildFeatureCard(
              context,
              icon: Icons.description,
              title: 'إعداد الدعاوى',
              description:
                  'إعداد الدعاوى تلقائياً حسب البيانات المقدمة وأطراف التقاضي',
              color: Colors.blue,
            ),
            _buildFeatureCard(
              context,
              icon: Icons.reply,
              title: 'معالجة الردود',
              description:
                  'إعداد الردود على الدعاوى والطعون والخدمات المطلوبة',
              color: Colors.green,
            ),
            _buildFeatureCard(
              context,
              icon: Icons.gavel,
              title: 'التحليل القانوني',
              description:
                  'تحليل القضايا بناءً على القوانين والتشريعات اليمنية',
              color: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // يمكن فتح شاشة الدردشة مع سؤال مسبق
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title - استخدم صندوق التحليل أعلاه')),
          );
        },
      ),
    );
  }
}
