import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/case_model.dart';
import '../models/lawsuit_model.dart';
import '../services/api_service.dart';
import '../providers/lawsuit_provider.dart';
import 'appeal_screen.dart';
import 'payment_order_screen.dart';
import 'lawsuit_detail_screen.dart';
import 'power_of_attorney_screen.dart';

class CaseDetailScreen extends StatefulWidget {
  final int caseId;

  const CaseDetailScreen({super.key, required this.caseId});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  bool _isLoading = true;
  bool _isCreatingLawsuit = false;
  String? _error;
  CaseModel? _case;
  List<LawsuitModel> _lawsuits = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final c = await api.getCase(widget.caseId);
      final resp = await api.getLawsuits(queryParams: {'case': widget.caseId.toString()});
      final List<dynamic> items = resp is List
          ? resp
          : ((resp['results'] as List?) ?? (resp['data'] as List?) ?? (resp['items'] as List?) ?? []);
      final lawsuits = items.map((e) => LawsuitModel.fromJson(e as Map<String, dynamic>)).toList();

      if (!mounted) return;
      setState(() {
        _case = c;
        _lawsuits = lawsuits;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createLawsuitForCase(String caseType) async {
    setState(() => _isCreatingLawsuit = true);

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final lawsuitProvider = Provider.of<LawsuitProvider>(context, listen: false);

      final newLawsuit = LawsuitModel(
        caseNumber: 'L-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        caseType: caseType,
        caseStatus: 'جديد',
        subject: _case?.subject ?? 'إجراء جديد',
        filingDate: DateTime.now(),
        caseId: widget.caseId,
      );

      final created = await lawsuitProvider.createLawsuit(newLawsuit);
      if (created == null || created.id == null) {
        throw Exception('فشل إنشاء الدعوى');
      }

      if (!mounted) return;

      Navigator.pop(context);

      switch (caseType) {
        case 'طعن':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AppealScreen(lawsuitId: created.id)),
          );
          break;
        case 'امر_اداء':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PaymentOrderScreen(lawsuitId: created.id)),
          );
          break;
        default:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LawsuitDetailScreen(lawsuitId: created.id)),
          );
          break;
      }

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingLawsuit = false);
      }
    }
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('إضافة إجراء جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('اختر نوع الإجراء لإضافته إلى هذه القضية', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionIcon(Icons.gavel_rounded, 'دعوى', Colors.green, 'دعوى'),
                _buildOptionIcon(Icons.history_edu_rounded, 'طعن', Colors.red, 'طعن'),
                _buildOptionIcon(Icons.request_page_rounded, 'أمر أداء', Colors.amber, 'امر_اداء'),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PowerOfAttorneyScreen(
                      caseId: widget.caseId,
                      clientName: _case?.parties?.where((p) => p.role == 'client').firstOrNull?.name,
                      clientPhone: _case?.parties?.where((p) => p.role == 'client').firstOrNull?.phone,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.description_rounded, color: Colors.deepPurple, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('إنشاء وكالة خاصة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionIcon(IconData icon, String label, Color color, String caseType) {
    return InkWell(
      onTap: () => _createLawsuitForCase(caseType),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_case?.caseNumber ?? 'ملف قضية'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreatingLawsuit ? null : _showActionMenu,
        icon: _isCreatingLawsuit
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add_rounded),
        label: const Text('إضافة إجراء'),
      ),
    );
  }

  Widget _buildBody() {
    final c = _case;
    if (c == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(c.subject ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('نوع القضية: ${c.caseType ?? '-'}${c.caseSubtype != null ? ' / ${c.caseSubtype}' : ''}'),
                Text('المحافظة: ${c.governorate ?? '-'}'),
                Text('المحكمة: ${c.courtName ?? '-'}'),
                Text('سنة القضية: ${c.caseYearHijri?.toString() ?? '-'}'),
                if (c.description != null && c.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(c.description!),
                ],
              ],
            ),
          ),
        ),
        // Parties section
        if (c.parties != null && c.parties!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('أطراف القضية', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...c.parties!.map((p) => Card(
            color: p.role == 'client' ? const Color(0xFFE8F5E9) : const Color(0xFFFCE4EC),
            child: ListTile(
              leading: Icon(
                p.entityType == 'organization' ? Icons.business : Icons.person,
                color: p.role == 'client' ? Colors.green : Colors.red,
              ),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${p.roleDisplay ?? (p.role == "client" ? "موكل" : "خصم")}${p.phone != null && p.phone!.isNotEmpty ? " • ${p.phone}" : ""}',
              ),
            ),
          )),
        ],
        const SizedBox(height: 16),
        const Text('الإجراءات / الدعاوى', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_lawsuits.isEmpty)
          const Text('لا توجد دعاوى مرتبطة بهذه القضية بعد.')
        else
          ..._lawsuits.map(
            (l) => Card(
              child: ListTile(
                title: Text(l.subject ?? l.caseNumber),
                subtitle: Text('${l.caseTypeDisplay} • ${l.caseStatusDisplay}'),
              ),
            ),
          ),
      ],
    );
  }
}
