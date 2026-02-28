import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/payment_order_model.dart';
import 'dart:developer' as developer;

/// Payment Order Screen - أمر الأداء
/// Uses same format as lawsuit_detail_screen with legal templates
class PaymentOrderScreen extends StatefulWidget {
  final int? paymentOrderId;
  final int? lawsuitId; // Optional: pre-fill lawsuit

  const PaymentOrderScreen({super.key, this.paymentOrderId, this.lawsuitId});

  @override
  State<PaymentOrderScreen> createState() => _PaymentOrderScreenState();
}

class _PaymentOrderScreenState extends State<PaymentOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _orderNumberController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  
  // Legal text controllers (for payment order templates)
  final Map<String, TextEditingController> _legalTextControllers = {};
  
  String? _selectedLawsuitNumber;
  int? _selectedLawsuitId;
  String? _selectedStatus;
  DateTime? _selectedOrderDate;
  
  bool _isLoadingTemplates = false;
  bool _isSaving = false;
  Map<String, dynamic>? _templates;
  List<String> _templateKeys = [];
  
  bool get _isEditMode => widget.paymentOrderId != null;

  @override
  void initState() {
    super.initState();
    _orderNumberController = TextEditingController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedStatus = 'pending';
    _selectedOrderDate = DateTime.now();
    _selectedLawsuitId = widget.lawsuitId;

    // Load templates for payment order
    _loadTemplates('امر_اداء');
    
    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPaymentOrder();
      });
    }
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    for (var controller in _legalTextControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPaymentOrder() async {
    // TODO: Implement loading payment order
  }

  Future<void> _loadTemplates(String caseType) async {
    setState(() {
      _isLoadingTemplates = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.apiService.getLawsuitTemplates(caseType);
      
      setState(() {
        _templates = response;
        _templateKeys = (response['templates'] as List)
            .map((t) => t['section_key'] as String)
            .toList();
        
        // Create controllers for each template
        for (var template in response['templates']) {
          final key = template['section_key'] as String;
          if (!_legalTextControllers.containsKey(key)) {
            _legalTextControllers[key] = TextEditingController(
              text: template['default_text'] as String? ?? '',
            );
          }
        }
      });
    } catch (e) {
      developer.log('Error loading templates: $e', name: 'PaymentOrderScreen');
    } finally {
      setState(() {
        _isLoadingTemplates = false;
      });
    }
  }

  Future<void> _savePaymentOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLawsuitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الدعوى')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final amount = double.tryParse(_amountController.text.trim()) ?? 0;
      
      final paymentOrder = PaymentOrderModel(
        id: widget.paymentOrderId,
        lawsuitId: _selectedLawsuitId!,
        amount: amount,
        orderNumber: _orderNumberController.text.trim().isEmpty 
            ? null 
            : _orderNumberController.text.trim(),
        orderDate: _selectedOrderDate ?? DateTime.now(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        status: _selectedStatus ?? 'pending',
      );

      // Save payment order
      if (_isEditMode) {
        await authProvider.apiService.updatePaymentOrder(
          widget.paymentOrderId!,
          paymentOrder.toJson(),
        );
      } else {
        await authProvider.apiService.createPaymentOrder(paymentOrder.toJson());
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'تم تحديث أمر الأداء بنجاح' : 'تم إنشاء أمر الأداء بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      developer.log('Error saving payment order: $e', name: 'PaymentOrderScreen');
      if (mounted) {
        final errorStr = e.toString();
        String errorMessage = 'خطأ في حفظ أمر الأداء';
        IconData errorIcon = Icons.error_outline;
        Color errorColor = Colors.red;
        
        if (errorStr.contains('SocketException') || 
            errorStr.contains('Failed host lookup') ||
            errorStr.contains('Network is unreachable')) {
          errorMessage = 'لا يوجد اتصال بالإنترنت\nيرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى';
          errorIcon = Icons.wifi_off;
          errorColor = Colors.orange.shade700;
        } else if (errorStr.contains('TimeoutException') || 
                   errorStr.contains('timeout')) {
          errorMessage = 'انتهت مهلة الاتصال\nيرجى المحاولة مرة أخرى';
          errorIcon = Icons.wifi_off;
          errorColor = Colors.orange.shade700;
        } else if (errorStr.contains('Connection refused') ||
                   errorStr.contains('Network') || 
                   errorStr.contains('Connection')) {
          errorMessage = 'لا يمكن الاتصال بالخادم\nيرجى التحقق من اتصال الإنترنت';
          errorIcon = Icons.wifi_off;
          errorColor = Colors.orange.shade700;
        } else if (errorStr.contains('400') || 
                   errorStr.contains('Bad Request')) {
          errorMessage = 'البيانات المدخلة غير صحيحة\nيرجى التحقق من جميع الحقول';
          errorIcon = Icons.warning_amber_rounded;
        } else {
          String cleanError = errorStr.replaceAll('Exception: ', '');
          if (cleanError.length > 100) {
            errorMessage = 'خطأ في حفظ أمر الأداء\nيرجى المحاولة مرة أخرى';
          } else {
            errorMessage = 'خطأ في حفظ أمر الأداء: $cleanError';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(errorIcon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'حسناً',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل أمر الأداء' : 'إضافة أمر أداء جديد'),
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Lawsuit Selection
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'معلومات الدعوى',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: TextEditingController(text: _selectedLawsuitNumber ?? ''),
                      decoration: const InputDecoration(
                        labelText: 'رقم الدعوى',
                        prefixIcon: Icon(Icons.gavel),
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () {
                        // TODO: Open lawsuit selection dialog
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order Number
            TextFormField(
              controller: _orderNumberController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: 'رقم الأمر (اختياري)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال المبلغ';
                }
                if (double.tryParse(value) == null) {
                  return 'يرجى إدخال رقم صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Order Date
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedOrderDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    _selectedOrderDate = date;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ الأمر *',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedOrderDate != null
                      ? DateFormat('yyyy-MM-dd').format(_selectedOrderDate!)
                      : 'اختر التاريخ',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'حالة الدفع',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
                DropdownMenuItem(value: 'paid', child: Text('مدفوع')),
                DropdownMenuItem(value: 'partial', child: Text('مدفوع جزئياً')),
                DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: 'الوصف (اختياري)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Legal Templates Section
            if (_isLoadingTemplates)
              const Center(child: CircularProgressIndicator())
            else if (_templates != null && _templateKeys.isNotEmpty)
              ..._buildLegalTextFields()
            else
              const SizedBox.shrink(),

            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: (_isSaving || _isLoadingTemplates) ? null : _savePaymentOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _isEditMode ? 'حفظ التغييرات' : 'إنشاء أمر الأداء',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLegalTextFields() {
    if (_templates == null) return [];
    
    final templates = _templates!['templates'] as List;
    final widgets = <Widget>[];
    
    widgets.add(const Divider());
    widgets.add(
      const Text(
        'النصوص القانونية',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
    widgets.add(const SizedBox(height: 16));
    
    for (var template in templates) {
      final key = template['section_key'] as String;
      final title = template['section_title'] as String;
      final isRequired = template['is_required'] as bool? ?? false;
      
      if (!_legalTextControllers.containsKey(key)) {
        _legalTextControllers[key] = TextEditingController(
          text: template['default_text'] as String? ?? '',
        );
      }
      
      widgets.add(
        TextFormField(
          controller: _legalTextControllers[key],
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            labelText: title + (isRequired ? ' *' : ''),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.gavel),
            helperText: 'يمكنك تعديل النص الافتراضي',
          ),
          maxLines: 8,
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'هذا الحقل إجباري';
                  }
                  return null;
                }
              : null,
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }
    
    return widgets;
  }
}

