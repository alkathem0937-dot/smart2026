import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// Screen for creating / filling a special Power of Attorney (الوكالة الخاصة).
/// Can fill a template form or upload a ready document.
class PowerOfAttorneyScreen extends StatefulWidget {
  final int? caseId;
  final String? lawyerName;
  final String? clientName;
  final String? clientPhone;

  const PowerOfAttorneyScreen({
    super.key,
    this.caseId,
    this.lawyerName,
    this.clientName,
    this.clientPhone,
  });

  @override
  State<PowerOfAttorneyScreen> createState() => _PowerOfAttorneyScreenState();
}

class _PowerOfAttorneyScreenState extends State<PowerOfAttorneyScreen> {
  // Form controllers
  final _lawyerNameCtrl = TextEditingController();
  final _lawyerIdCtrl = TextEditingController();
  final _lawyerIdIssuedCtrl = TextEditingController();
  final _lawyerIdDateCtrl = TextEditingController();
  final _lawyerLicenseCtrl = TextEditingController();
  final _lawyerAddressCtrl = TextEditingController();
  final _lawyerPhoneCtrl = TextEditingController();

  final _clientNameCtrl = TextEditingController();
  final _clientIdCtrl = TextEditingController();
  final _clientIdIssuedCtrl = TextEditingController();
  final _clientIdDateCtrl = TextEditingController();
  final _clientNationalityCtrl = TextEditingController();
  final _clientAddressCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();

  final _opponentNameCtrl = TextEditingController();
  final _caseSubjectCtrl = TextEditingController();
  final _courtNameCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();

  bool _isPdfPreview = false;

  @override
  void initState() {
    super.initState();
    _lawyerNameCtrl.text = widget.lawyerName ?? '';
    _clientNameCtrl.text = widget.clientName ?? '';
    _clientPhoneCtrl.text = widget.clientPhone ?? '';
    _dateCtrl.text = DateFormat('yyyy/MM/dd').format(DateTime.now());
  }

  @override
  void dispose() {
    for (final c in [
      _lawyerNameCtrl, _lawyerIdCtrl, _lawyerIdIssuedCtrl, _lawyerIdDateCtrl,
      _lawyerLicenseCtrl, _lawyerAddressCtrl, _lawyerPhoneCtrl,
      _clientNameCtrl, _clientIdCtrl, _clientIdIssuedCtrl, _clientIdDateCtrl,
      _clientNationalityCtrl, _clientAddressCtrl, _clientPhoneCtrl,
      _opponentNameCtrl, _caseSubjectCtrl, _courtNameCtrl, _dateCtrl, _placeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الوكالة الخاصة', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B5E3B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isPdfPreview ? Icons.edit : Icons.picture_as_pdf),
            tooltip: _isPdfPreview ? 'تعديل النموذج' : 'معاينة PDF',
            onPressed: () => setState(() => _isPdfPreview = !_isPdfPreview),
          ),
        ],
      ),
      body: _isPdfPreview ? _buildPdfPreview() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section: Lawyer info
            _sectionTitle('بيانات المحامي (الوكيل)'),
            _field(_lawyerNameCtrl, 'اسم المحامي', Icons.person),
            _field(_lawyerIdCtrl, 'رقم الهوية', Icons.badge),
            _row([
              _field(_lawyerIdIssuedCtrl, 'جهة الإصدار', Icons.location_on),
              _field(_lawyerIdDateCtrl, 'تاريخ الإصدار', Icons.date_range),
            ]),
            _field(_lawyerLicenseCtrl, 'رقم ترخيص المحاماة', Icons.card_membership),
            _field(_lawyerAddressCtrl, 'العنوان', Icons.home),
            _field(_lawyerPhoneCtrl, 'الهاتف', Icons.phone),

            const SizedBox(height: 20),
            _sectionTitle('بيانات الموكل'),
            _field(_clientNameCtrl, 'اسم الموكل', Icons.person_outline),
            _field(_clientIdCtrl, 'رقم الهوية', Icons.badge),
            _row([
              _field(_clientIdIssuedCtrl, 'جهة الإصدار', Icons.location_on),
              _field(_clientIdDateCtrl, 'تاريخ الإصدار', Icons.date_range),
            ]),
            _field(_clientNationalityCtrl, 'الجنسية', Icons.flag),
            _field(_clientAddressCtrl, 'العنوان', Icons.home),
            _field(_clientPhoneCtrl, 'الهاتف', Icons.phone),

            const SizedBox(height: 20),
            _sectionTitle('بيانات القضية'),
            _field(_opponentNameCtrl, 'اسم الخصم', Icons.people),
            _field(_caseSubjectCtrl, 'موضوع القضية', Icons.subject),
            _field(_courtNameCtrl, 'المحكمة', Icons.gavel),
            _row([
              _field(_dateCtrl, 'التاريخ', Icons.calendar_today),
              _field(_placeCtrl, 'المكان', Icons.place),
            ]),

            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _isPdfPreview = true),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('معاينة وتصدير PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A940),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E3B))),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        textDirection: ui.TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1B5E3B)),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: c))).toList(),
    );
  }

  Widget _buildPdfPreview() {
    return PdfPreview(
      build: (format) => _generatePdf(format),
      canChangeOrientation: false,
      canChangePageFormat: false,
      allowPrinting: true,
      allowSharing: true,
      pdfFileName: 'وكالة_خاصة_${_clientNameCtrl.text.trim().replaceAll(' ', '_')}.pdf',
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final arabicFont = await PdfGoogleFonts.notoNaskhArabicRegular();
    final arabicFontBold = await PdfGoogleFonts.notoNaskhArabicBold();

    final pdf = pw.Document();

    final bodyStyle = pw.TextStyle(font: arabicFont, fontSize: 12);
    final boldStyle = pw.TextStyle(font: arabicFontBold, fontSize: 12, fontWeight: pw.FontWeight.bold);
    final titleStyle = pw.TextStyle(font: arabicFontBold, fontSize: 18, fontWeight: pw.FontWeight.bold);
    final subStyle = pw.TextStyle(font: arabicFontBold, fontSize: 14, fontWeight: pw.FontWeight.bold);

    String _v(TextEditingController c) => c.text.trim().isEmpty ? '..................' : c.text.trim();

    final fullText = '''
أنا الموقع أدناه: ${_v(_clientNameCtrl)}
الجنسية: ${_v(_clientNationalityCtrl)}
رقم الهوية: ${_v(_clientIdCtrl)}
صادرة من: ${_v(_clientIdIssuedCtrl)} بتاريخ: ${_v(_clientIdDateCtrl)}
العنوان: ${_v(_clientAddressCtrl)}
الهاتف: ${_v(_clientPhoneCtrl)}

أوكل عني في هذه الوكالة الخاصة المحامي / الأستاذ:
${_v(_lawyerNameCtrl)}
رقم الهوية: ${_v(_lawyerIdCtrl)} صادرة من: ${_v(_lawyerIdIssuedCtrl)} بتاريخ: ${_v(_lawyerIdDateCtrl)}
رقم ترخيص المحاماة: ${_v(_lawyerLicenseCtrl)}
العنوان: ${_v(_lawyerAddressCtrl)}
الهاتف: ${_v(_lawyerPhoneCtrl)}

لتمثيلي والنيابة عني أمام: ${_v(_courtNameCtrl)}
في مواجهة: ${_v(_opponentNameCtrl)}
في موضوع: ${_v(_caseSubjectCtrl)}

وقد خولته بموجب هذه الوكالة التصرف في كل ما يتعلق بهذه القضية من:
رفع الدعاوى والطعون والاستئنافات والمراجعات، وتقديم المذكرات والطلبات والمستندات والمرافعات، وحضور الجلسات والتوقيع على المحاضر، وتقديم طلبات التنفيذ، والحصول على صور الأحكام والقرارات، والتنازل والصلح والإبراء، وقبض المبالغ والتوقيع بالاستلام، وتوكيل الغير فيما وُكّل فيه، والقيام بكل ما يراه لازماً ومناسباً لحماية حقوقي في هذه القضية.

وهذه الوكالة سارية المفعول حتى انتهاء جميع مراحل التقاضي في هذه القضية ما لم يُبلغ بإلغائها كتابياً.

حُرر في: ${_v(_placeCtrl)}
بتاريخ: ${_v(_dateCtrl)}
''';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFontBold),
        build: (context) => [
          pw.Center(child: pw.Text('وكالة خاصة', style: titleStyle)),
          pw.SizedBox(height: 6),
          pw.Center(child: pw.Text('للتمثيل أمام القضاء', style: subStyle)),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Paragraph(text: fullText, style: bodyStyle),
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(children: [
                pw.Text('توقيع الموكل', style: boldStyle),
                pw.SizedBox(height: 30),
                pw.Text('......................', style: bodyStyle),
              ]),
              pw.Column(children: [
                pw.Text('توقيع الوكيل', style: boldStyle),
                pw.SizedBox(height: 30),
                pw.Text('......................', style: bodyStyle),
              ]),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
