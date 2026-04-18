import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inheritance_models.dart';
import '../providers/inheritance_provider.dart';
import '../services/legal_search_db_service.dart';

/// Inheritance Calculation Screen - حساب المواريث
class InheritanceCalculationScreen extends StatefulWidget {
  const InheritanceCalculationScreen({super.key});

  @override
  State<InheritanceCalculationScreen> createState() =>
      _InheritanceCalculationScreenState();
}

class _InheritanceCalculationScreenState
    extends State<InheritanceCalculationScreen> {
  final List<_EstateItemRow> _estateItems = [
    _EstateItemRow(),
  ];
  final List<_DebtItemRow> _debtItems = [];
  final List<_BequestItemRow> _bequestItems = [];
  final List<HeirInput> _heirs = [];

  String _selectedHeirType = 'wife';
  final TextEditingController _heirCountController = TextEditingController(text: '1');

  static const Map<String, String> _heirTypeLabels = {
    'husband': 'زوج',
    'wife': 'زوجة',
    'son': 'ابن',
    'daughter': 'بنت',
    'grandson': 'ابن ابن',
    'granddaughter': 'بنت ابن',
    'father': 'أب',
    'grandfather': 'جد',
    'mother': 'أم',
    'grandmother_maternal': 'جدة (أم الأم)',
    'grandmother_paternal': 'جدة (أم الأب)',
    'full_brother': 'أخ شقيق',
    'full_sister': 'أخت شقيقة',
    'paternal_brother': 'أخ لأب',
    'paternal_sister': 'أخت لأب',
    'maternal_brother': 'أخ لأم',
    'maternal_sister': 'أخت لأم',
    'full_nephew': 'ابن أخ شقيق',
    'paternal_nephew': 'ابن أخ لأب',
    'full_uncle': 'عم شقيق',
    'paternal_uncle': 'عم لأب',
    'full_cousin': 'ابن عم شقيق',
    'paternal_cousin': 'ابن عم لأب',
  };

  @override
  void dispose() {
    for (final i in _estateItems) {
      i.dispose();
    }
    for (final d in _debtItems) {
      d.dispose();
    }
    for (final b in _bequestItems) {
      b.dispose();
    }
    _heirCountController.dispose();
    super.dispose();
  }

  double _sumValues(Iterable<TextEditingController> ctrls) {
    double sum = 0;
    for (final c in ctrls) {
      final v = c.text.trim().replaceAll(',', '');
      final d = double.tryParse(v);
      if (d != null && d.isFinite && d > 0) sum += d;
    }
    return sum;
  }

  String _money(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InheritanceProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('حساب المواريث'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate, color: Colors.green, size: 32),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'حساب المواريث اليمنية',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'حساب المواريث استناداً لكتاب القسمة من وزارة العدل',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بيانات التركة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    initiallyExpanded: true,
                    title: const Text('عناصر التركة (تفصيلياً)'),
                    subtitle: Text('إجمالي التركة: ${_money(_sumValues(_estateItems.map((e) => e.valueController)))}'),
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    children: [
                      ..._estateItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final row = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: _buildEstateItemRow(idx, row),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _estateItems.add(_EstateItemRow()));
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة عنصر تركة'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ExpansionTile(
                    title: const Text('الديون (تفصيلياً)'),
                    subtitle: Text('إجمالي الديون: ${_money(_sumValues(_debtItems.map((d) => d.amountController)))}'),
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    children: [
                      if (_debtItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text('لا توجد ديون مضافة'),
                        ),
                      ..._debtItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final row = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: _buildDebtItemRow(idx, row),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _debtItems.add(_DebtItemRow()));
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة دين'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ExpansionTile(
                    title: const Text('الوصايا (تفصيلياً)'),
                    subtitle: Text('إجمالي الوصايا: ${_money(_sumValues(_bequestItems.map((b) => b.amountController)))}'),
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    children: [
                      if (_bequestItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text('لا توجد وصايا مضافة'),
                        ),
                      ..._bequestItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final row = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: _buildBequestItemRow(idx, row),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _bequestItems.add(_BequestItemRow()));
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة وصية'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'الورثة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedHeirType,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'نوع الوارث',
                          ),
                          items: _heirTypeLabels.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _selectedHeirType = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _heirCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'العدد',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final cnt = int.tryParse(_heirCountController.text.trim()) ?? 0;
                        if (cnt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى إدخال عدد صحيح للوارث')),
                          );
                          return;
                        }
                        setState(() {
                          _heirs.add(HeirInput(type: _selectedHeirType, count: cnt));
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة وارث'),
                    ),
                  ),
                  if (_heirs.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ..._heirs.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final h = entry.value;
                      final label = _heirTypeLabels[h.type] ?? h.type;
                      return Card(
                        elevation: 0,
                        color: Colors.grey.withOpacity(0.06),
                        child: ListTile(
                          title: Text('$label × ${h.count}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              setState(() {
                                _heirs.removeAt(idx);
                              });
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _calculateInheritance,
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.calculate),
                      label: Text(provider.isLoading ? 'جاري الحساب...' : 'حساب الميراث'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (provider.error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          if (provider.result != null) _buildResult(provider.result!),
          _buildFeatureCard(
            context,
            icon: Icons.people,
            title: 'تقسيم الورث',
            description: 'تقسيم الورث حسب المدخلات وأحكام الشريعة الإسلامية',
            color: Colors.blue,
          ),
          _buildFeatureCard(
            context,
            icon: Icons.inventory,
            title: 'جمع وحصر التركة',
            description: 'جمع وحصر جميع أموال التركة بشكل منظم',
            color: Colors.green,
          ),
          _buildFeatureCard(
            context,
            icon: Icons.book,
            title: 'كتاب القسمة',
            description: 'حساب المواريث وفق كتاب القسمة من وزارة العدل',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Future<void> _calculateInheritance() async {
    final estateTotal = _sumValues(_estateItems.map((e) => e.valueController));
    if (estateTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال عناصر التركة وقيمتها')),
      );
      return;
    }

    if (_heirs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة الورثة أولاً')),
      );
      return;
    }

    final estateItems = _estateItems
        .map(
          (e) => EstateItemInput(
            category: e.category,
            description: e.descriptionController.text.trim(),
            value: e.valueController.text.trim().isEmpty ? '0' : e.valueController.text.trim(),
          ),
        )
        .toList();

    final debtItems = _debtItems
        .map(
          (d) => DebtItemInput(
            creditor: d.creditorController.text.trim(),
            description: d.descriptionController.text.trim(),
            amount: d.amountController.text.trim().isEmpty ? '0' : d.amountController.text.trim(),
          ),
        )
        .toList();

    final bequestItems = _bequestItems
        .map(
          (b) => BequestItemInput(
            beneficiary: b.beneficiaryController.text.trim(),
            description: b.descriptionController.text.trim(),
            amount: b.amountController.text.trim().isEmpty ? '0' : b.amountController.text.trim(),
          ),
        )
        .toList();

    await context.read<InheritanceProvider>().calculate(
          estateItems: estateItems,
          debtItems: debtItems,
          bequestItems: bequestItems,
          heirs: _heirs,
        );
  }

  Widget _buildEstateItemRow(int idx, _EstateItemRow row) {
    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: row.category,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'نوع المال',
                    ),
                    items: _EstateItemRow.categories.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => row.category = v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: row.valueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'القيمة',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  onPressed: _estateItems.length <= 1
                      ? null
                      : () {
                          setState(() {
                            final removed = _estateItems.removeAt(idx);
                            removed.dispose();
                          });
                        },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: row.descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'تفاصيل/وصف',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtItemRow(int idx, _DebtItemRow row) {
    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.creditorController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'الدائن (لمن هذا الدين؟)',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: row.amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'المبلغ',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      final removed = _debtItems.removeAt(idx);
                      removed.dispose();
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: row.descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'تفاصيل الدين',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBequestItemRow(int idx, _BequestItemRow row) {
    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.beneficiaryController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'الموصى له',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: row.amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'المبلغ',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      final removed = _bequestItems.removeAt(idx);
                      removed.dispose();
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: row.descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'تفاصيل الوصية',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(InheritanceResult result) {
    final net = result.totals['net_estate']?.toString() ?? '';
    final beq = result.totals['bequest_applied']?.toString() ?? '';
    final unalloc = result.totals['unallocated_amount']?.toString() ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('النتيجة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('صافي التركة: $net'),
            Text('الوصية المطبقة: $beq'),
            if (unalloc != '0.00' && unalloc.isNotEmpty) Text('متبقّي غير موزّع: $unalloc'),
            if (result.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('ملاحظات: ${result.notes.join(' , ')}', style: TextStyle(color: Colors.grey[700])),
            ],
            const SizedBox(height: 12),
            const Divider(),
            const Text('أنصبة الورثة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...result.shares.map((s) => _shareTile(s)),
          ],
        ),
      ),
    );
  }

  Widget _shareTile(ShareItem s) {
    final label = _heirTypeLabels[s.heirType] ?? s.heirType;
    final frac = (s.fractionNumerator > 0 && s.fractionDenominator > 0)
        ? '${s.fractionNumerator}/${s.fractionDenominator}'
        : 'تعصيب';

    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(0.06),
      child: ListTile(
        title: Text('$label × ${s.count}'),
        subtitle: Text('النصيب: $frac  |  الإجمالي: ${s.totalAmount}  |  للفرد: ${s.amountPerHeir}'),
        trailing: IconButton(
          icon: const Icon(Icons.menu_book_outlined),
          onPressed: () => _openGuideForShare(s),
        ),
      ),
    );
  }

  Future<void> _openGuideForShare(ShareItem s) async {
    final query = _guideQueryForReason(s.reasonCode, s.heirType);
    if (query.isEmpty) return;

    final results = await LegalSearchDbService.searchSentences(query, limit: 15);
    if (!mounted) return;

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد نتائج في دليل القسمة لهذا التفسير')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('دليل القسمة: "$query"'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (c, i) {
              final r = results[i];
              final txt = (r['text'] as String?) ?? '';
              final pid = (r['paragraph_id'] as int?) ?? 0;
              return ListTile(
                title: Text(txt, textDirection: TextDirection.rtl),
                subtitle: Text('فقرة: $pid', textDirection: TextDirection.rtl),
                onTap: () async {
                  final lines = await LegalSearchDbService.getParagraphSentences(pid);
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (ctx2) => AlertDialog(
                      title: Text('النص الكامل (فقرة $pid)'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: SingleChildScrollView(
                          child: Text(lines.join('\n'), textDirection: TextDirection.rtl),
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('إغلاق')),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  String _guideQueryForReason(String reasonCode, String heirType) {
    switch (reasonCode) {
      case 'WIFE':
      case 'WIFE_WITH_DESCENDANTS':
      case 'WIFE_EIGHTH':
      case 'WIFE_QUARTER':
        return 'الزوجة';
      case 'HUSBAND':
      case 'HUSBAND_HALF':
      case 'HUSBAND_QUARTER':
        return 'الزوج';
      case 'MOTHER':
      case 'MOTHER_WITH_DESCENDANTS':
      case 'MOTHER_UMARIYYA':
      case 'MOTHER_SIXTH':
      case 'MOTHER_THIRD':
      case 'MOTHER_THIRD_REMAINDER':
        return 'الأم';
      case 'FATHER_WITH_DESCENDANTS':
      case 'FATHER_RESIDUARY':
      case 'FATHER_RESIDUARY_WITH_DAUGHTERS':
      case 'FATHER_SIXTH':
      case 'FATHER_SIXTH_PLUS_RESIDUARY':
        return 'الأب';
      case 'DAUGHTER_SINGLE':
      case 'DAUGHTER_MULTIPLE':
      case 'DAUGHTER_WITH_SON_RESIDUARY':
      case 'DAUGHTER_HALF':
      case 'DAUGHTERS_TWO_THIRDS':
        return 'البنت';
      case 'SON_RESIDUARY':
        return 'الابن';
      default:
        return _heirTypeLabels[heirType] ?? heirType;
    }
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('قريباً: $title')),
          );
        },
      ),
    );
  }
}

class _EstateItemRow {
  static const Map<String, String> categories = {
    'cash': 'نقود',
    'real_estate': 'عقار/أرض',
    'vehicle': 'مركبة',
    'jewelry': 'ذهب/مجوهرات',
    'business': 'مشروع/تجارة',
    'other': 'أخرى',
  };

  String category;
  final TextEditingController descriptionController;
  final TextEditingController valueController;

  _EstateItemRow({
    this.category = 'cash',
    TextEditingController? descriptionController,
    TextEditingController? valueController,
  })  : descriptionController = descriptionController ?? TextEditingController(),
        valueController = valueController ?? TextEditingController();

  void dispose() {
    descriptionController.dispose();
    valueController.dispose();
  }
}

class _DebtItemRow {
  final TextEditingController creditorController;
  final TextEditingController descriptionController;
  final TextEditingController amountController;

  _DebtItemRow({
    TextEditingController? creditorController,
    TextEditingController? descriptionController,
    TextEditingController? amountController,
  })  : creditorController = creditorController ?? TextEditingController(),
        descriptionController = descriptionController ?? TextEditingController(),
        amountController = amountController ?? TextEditingController();

  void dispose() {
    creditorController.dispose();
    descriptionController.dispose();
    amountController.dispose();
  }
}

class _BequestItemRow {
  final TextEditingController beneficiaryController;
  final TextEditingController descriptionController;
  final TextEditingController amountController;

  _BequestItemRow({
    TextEditingController? beneficiaryController,
    TextEditingController? descriptionController,
    TextEditingController? amountController,
  })  : beneficiaryController = beneficiaryController ?? TextEditingController(),
        descriptionController = descriptionController ?? TextEditingController(),
        amountController = amountController ?? TextEditingController();

  void dispose() {
    beneficiaryController.dispose();
    descriptionController.dispose();
    amountController.dispose();
  }
}
