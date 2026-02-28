import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../providers/lawsuit_provider.dart';
import '../providers/auth_provider.dart';
import '../models/lawsuit_model.dart';
import '../models/party_model.dart';
import '../config/api_config.dart';
import 'dart:developer' as developer;
import 'dart:io';

/// Lawsuit Detail Screen - Updated to support legal templates
class LawsuitDetailScreen extends StatefulWidget {
  final int? lawsuitId;

  const LawsuitDetailScreen({super.key, this.lawsuitId});

  @override
  State<LawsuitDetailScreen> createState() => _LawsuitDetailScreenState();
}

class _LawsuitDetailScreenState extends State<LawsuitDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _caseNumberController;
  late TextEditingController _subjectController;
  late TextEditingController _descriptionController;
  
  // Legal text controllers (dynamic based on case type)
  final Map<String, TextEditingController> _legalTextControllers = {};
  
  String? _selectedCaseType;
  String? _selectedCaseStatus;
  String? _selectedGovernorate;
  int? _selectedCourtId;
  
  bool _isLoadingTemplates = false;
  Map<String, dynamic>? _templates;
  List<String> _templateKeys = [];
  
  // Parties data
  List<PlaintiffModel> _plaintiffs = [];
  List<DefendantModel> _defendants = [];
  bool _isLoadingParties = false;
  
  // Attachments data
  List<Map<String, dynamic>> _attachments = [];
  bool _isLoadingAttachments = false;
  bool _isUploadingAttachment = false;
  
  bool get _isEditMode => widget.lawsuitId != null;

  @override
  void initState() {
    super.initState();
    _caseNumberController = TextEditingController();
    _subjectController = TextEditingController();
    _descriptionController = TextEditingController();
    
    // Default case type
    _selectedCaseType = 'دعوى';
    _selectedCaseStatus = 'جديد';

    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadLawsuit();
        _loadParties();
        _loadAttachments();
      });
    } else {
      // Load templates for default case type
      _loadTemplates(_selectedCaseType!);
    }
  }

  @override
  void dispose() {
    _caseNumberController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    for (var controller in _legalTextControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLawsuit() async {
    final provider = Provider.of<LawsuitProvider>(context, listen: false);
    await provider.loadLawsuit(widget.lawsuitId!);
    final lawsuit = provider.selectedLawsuit;
    if (lawsuit != null) {
      _caseNumberController.text = lawsuit.caseNumber;
      _subjectController.text = lawsuit.subject ?? '';
      _descriptionController.text = lawsuit.description ?? '';
      _selectedCaseType = lawsuit.caseType;
      _selectedCaseStatus = lawsuit.caseStatus ?? 'جديد';
      _selectedGovernorate = lawsuit.governorate;
      
      // Load templates and populate legal text fields
      await _loadTemplates(_selectedCaseType!);
      
      // Populate legal text fields from lawsuit
      if (lawsuit.facts != null && _legalTextControllers.containsKey('facts')) {
        _legalTextControllers['facts']!.text = lawsuit.facts!;
      }
      if (lawsuit.legalBasis != null && _legalTextControllers.containsKey('legal')) {
        _legalTextControllers['legal']!.text = lawsuit.legalBasis!;
      }
      if (lawsuit.requests != null && _legalTextControllers.containsKey('requests')) {
        _legalTextControllers['requests']!.text = lawsuit.requests!;
      }
    }
  }

  Future<void> _loadParties() async {
    if (widget.lawsuitId == null || !mounted) return;
    
    if (mounted) {
      setState(() {
        _isLoadingParties = true;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final plaintiffsResponse = await authProvider.apiService.getPlaintiffs(
        lawsuitId: widget.lawsuitId,
      );
      final defendantsResponse = await authProvider.apiService.getDefendants(
        lawsuitId: widget.lawsuitId,
      );

      developer.log('Plaintiffs response: $plaintiffsResponse', name: 'LawsuitDetailScreen');
      developer.log('Defendants response: $defendantsResponse', name: 'LawsuitDetailScreen');

      if (mounted) {
        // Handle different response structures: could be {'results': [...]} or {'data': {'results': [...]}}
        List<dynamic>? plaintiffsData;
        if (plaintiffsResponse['results'] != null) {
          plaintiffsData = plaintiffsResponse['results'] as List?;
        } else if (plaintiffsResponse['data'] != null && plaintiffsResponse['data'] is Map) {
          plaintiffsData = (plaintiffsResponse['data'] as Map<String, dynamic>)['results'] as List?;
        }
        
        final plaintiffsList = (plaintiffsData ?? [])
            .map((json) {
              try {
                return PlaintiffModel.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                developer.log('Error parsing plaintiff: $e, json: $json', name: 'LawsuitDetailScreen');
                return null;
              }
            })
            .whereType<PlaintiffModel>()
            .toList();
        
        // Handle different response structures for defendants
        List<dynamic>? defendantsData;
        if (defendantsResponse['results'] != null) {
          defendantsData = defendantsResponse['results'] as List?;
        } else if (defendantsResponse['data'] != null && defendantsResponse['data'] is Map) {
          defendantsData = (defendantsResponse['data'] as Map<String, dynamic>)['results'] as List?;
        }
        
        final defendantsList = (defendantsData ?? [])
            .map((json) {
              try {
                return DefendantModel.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                developer.log('Error parsing defendant: $e, json: $json', name: 'LawsuitDetailScreen');
                return null;
              }
            })
            .whereType<DefendantModel>()
            .toList();
        
        developer.log('Parsed ${plaintiffsList.length} plaintiffs and ${defendantsList.length} defendants from server', name: 'LawsuitDetailScreen');

        setState(() {
          // Merge server data with local data to avoid losing newly added parties
          // On initial load (_plaintiffs and _defendants are empty), use server data directly
          // On subsequent loads (after adding parties), merge to preserve newly added ones
          
          final isInitialLoad = _plaintiffs.isEmpty && _defendants.isEmpty;
          
          if (isInitialLoad) {
            // Initial load: use server data directly
            developer.log('Initial load: using server data directly', name: 'LawsuitDetailScreen');
            _plaintiffs = plaintiffsList;
            _defendants = defendantsList;
          } else {
            // Subsequent load: merge server data with local data
            // If server returned empty lists but we have local data, don't overwrite
            if (plaintiffsList.isEmpty && _plaintiffs.isNotEmpty) {
              developer.log('Server returned empty plaintiffs but we have local data, keeping local', name: 'LawsuitDetailScreen');
              // Keep local data, don't overwrite
            } else {
              // For plaintiffs: merge by ID, keeping local ones that aren't in server response
              final serverPlaintiffIds = plaintiffsList.map((p) => p.id).whereType<int>().toSet();
              final serverPlaintiffNames = plaintiffsList.map((p) => p.name.toLowerCase().trim()).toSet();
              
              // Start with server data (most up-to-date)
              final mergedPlaintiffs = <PlaintiffModel>[...plaintiffsList];
              
              // Add local parties that aren't in server response yet (newly added, pending sync)
              for (var localPlaintiff in _plaintiffs) {
                final hasId = localPlaintiff.id != null;
                final idNotInServer = hasId && !serverPlaintiffIds.contains(localPlaintiff.id);
                final nameNotInServer = !serverPlaintiffNames.contains(localPlaintiff.name.toLowerCase().trim());
                
                // Keep if: has ID but not in server, OR no ID and name not in server (newly added, pending)
                if (idNotInServer || (!hasId && nameNotInServer)) {
                  mergedPlaintiffs.add(localPlaintiff);
                }
              }
              
              _plaintiffs = mergedPlaintiffs;
            }
            
            // Same for defendants
            if (defendantsList.isEmpty && _defendants.isNotEmpty) {
              developer.log('Server returned empty defendants but we have local data, keeping local', name: 'LawsuitDetailScreen');
              // Keep local data, don't overwrite
            } else {
              final serverDefendantIds = defendantsList.map((d) => d.id).whereType<int>().toSet();
              final serverDefendantNames = defendantsList.map((d) => d.name.toLowerCase().trim()).toSet();
              
              final mergedDefendants = <DefendantModel>[...defendantsList];
              
              for (var localDefendant in _defendants) {
                final hasId = localDefendant.id != null;
                final idNotInServer = hasId && !serverDefendantIds.contains(localDefendant.id);
                final nameNotInServer = !serverDefendantNames.contains(localDefendant.name.toLowerCase().trim());
                
                if (idNotInServer || (!hasId && nameNotInServer)) {
                  mergedDefendants.add(localDefendant);
                }
              }
              
              _defendants = mergedDefendants;
            }
          }
          
          _isLoadingParties = false;
        });
        
        developer.log('Loaded ${_plaintiffs.length} plaintiffs and ${_defendants.length} defendants', name: 'LawsuitDetailScreen');
      }
    } catch (e, stackTrace) {
      developer.log('Error loading parties: $e', name: 'LawsuitDetailScreen');
      developer.log('Stack trace: $stackTrace', name: 'LawsuitDetailScreen');
      if (mounted) {
        setState(() {
          // Don't clear existing lists on error - keep what we have
          _isLoadingParties = false;
        });
        
        // Extract error message
        String errorMessage = e.toString();
        // Remove "Exception: " prefix if present
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        
        // Only show error if lists are empty (initial load failed)
        // If we have local data, the error might be from a background sync
        if (_plaintiffs.isEmpty && _defendants.isEmpty) {
          final errorStr = errorMessage.toLowerCase();
          IconData errorIcon = Icons.error_outline;
          Color errorColor = Colors.red;
          String displayMessage = 'خطأ في تحميل الأطراف';
          
          if (errorStr.contains('socket') || 
              errorStr.contains('network') ||
              errorStr.contains('connection')) {
            displayMessage = 'لا يوجد اتصال بالإنترنت\nيرجى التحقق من اتصال الإنترنت';
            errorIcon = Icons.wifi_off;
            errorColor = Colors.orange.shade700;
          } else if (errorStr.contains('timeout')) {
            displayMessage = 'انتهت مهلة الاتصال\nيرجى المحاولة مرة أخرى';
            errorIcon = Icons.wifi_off;
            errorColor = Colors.orange.shade700;
          } else {
            displayMessage = 'خطأ في تحميل الأطراف\n$errorMessage';
            if (displayMessage.length > 150) {
              displayMessage = 'خطأ في تحميل الأطراف\nيرجى المحاولة مرة أخرى';
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
                      displayMessage,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: errorColor,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              action: SnackBarAction(
                label: 'إعادة المحاولة',
                textColor: Colors.white,
                onPressed: () {
                  _loadParties();
                },
              ),
            ),
          );
        } else {
          // We have local data, so this might be a background sync error
          // Show a less intrusive message
          developer.log('Background sync failed but we have local data', name: 'LawsuitDetailScreen');
        }
      }
    }
  }

  Future<void> _loadTemplates(String caseType) async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingTemplates = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.apiService.getLawsuitTemplates(caseType);
      
      if (mounted) {
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
      }
    } catch (e) {
      developer.log('Error loading templates: $e', name: 'LawsuitDetailScreen');
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        String errorMessage = 'خطأ في تحميل النصوص القانونية';
        IconData errorIcon = Icons.warning_amber_rounded;
        Color errorColor = Colors.orange.shade700;
        
        if (errorStr.contains('socket') || 
            errorStr.contains('network') ||
            errorStr.contains('connection')) {
          errorMessage = 'لا يوجد اتصال بالإنترنت\nلا يمكن تحميل النصوص القانونية';
          errorIcon = Icons.wifi_off;
        } else if (errorStr.contains('timeout')) {
          errorMessage = 'انتهت مهلة الاتصال\nيرجى المحاولة مرة أخرى';
          errorIcon = Icons.wifi_off;
        } else {
          String cleanError = e.toString().replaceAll('Exception: ', '');
          if (cleanError.length > 100) {
            errorMessage = 'خطأ في تحميل النصوص القانونية\nيرجى المحاولة مرة أخرى';
          } else {
            errorMessage = 'خطأ في تحميل النصوص القانونية: $cleanError';
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
      if (mounted) {
        setState(() {
          _isLoadingTemplates = false;
        });
      }
    }
  }

  void _onCaseTypeChanged(String? newType) {
    if (newType != null && newType != _selectedCaseType) {
      setState(() {
        _selectedCaseType = newType;
        // Clear existing legal text controllers
        for (var controller in _legalTextControllers.values) {
      controller.dispose();
    }
        _legalTextControllers.clear();
        _templateKeys.clear();
      });
      // Load new templates
      _loadTemplates(newType);
    }
  }

  Future<void> _saveLawsuit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<LawsuitProvider>(context, listen: false);
    
    // Build legal texts from controllers
    String? facts;
    String? legalBasis;
    String? requests;
    
    if (_legalTextControllers.containsKey('facts')) {
      facts = _legalTextControllers['facts']!.text.trim();
    }
    if (_legalTextControllers.containsKey('legal')) {
      legalBasis = _legalTextControllers['legal']!.text.trim();
    }
    if (_legalTextControllers.containsKey('requests')) {
      requests = _legalTextControllers['requests']!.text.trim();
    }
    
    final lawsuit = LawsuitModel(
      id: widget.lawsuitId,
      caseNumber: _caseNumberController.text.trim(),
      caseType: _selectedCaseType!,
      caseStatus: _selectedCaseStatus,
      subject: _subjectController.text.trim().isEmpty 
          ? null 
          : _subjectController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      facts: facts?.isEmpty ?? true ? null : facts,
      legalBasis: legalBasis?.isEmpty ?? true ? null : legalBasis,
      requests: requests?.isEmpty ?? true ? null : requests,
      governorate: _selectedGovernorate,
      filingDate: DateTime.now(),
    );

    if (_isEditMode) {
      final success = await provider.updateLawsuit(widget.lawsuitId!, lawsuit);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الدعوى بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        final errorMessage = provider.errorMessage ?? 'حدث خطأ في تحديث الدعوى';
        final errorStr = errorMessage.toLowerCase();
        IconData errorIcon = Icons.error_outline;
        Color errorColor = Colors.red;
        String displayMessage = errorMessage;
        
        if (errorStr.contains('لا يوجد اتصال') || 
            errorStr.contains('network') ||
            errorStr.contains('connection')) {
          displayMessage = 'لا يوجد اتصال بالإنترنت\nيرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى';
          errorIcon = Icons.wifi_off;
          errorColor = Colors.orange.shade700;
        } else if (errorStr.contains('انتهت مهلة') || 
                   errorStr.contains('timeout')) {
          displayMessage = 'انتهت مهلة الاتصال\nيرجى المحاولة مرة أخرى';
          errorIcon = Icons.wifi_off;
          errorColor = Colors.orange.shade700;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(errorIcon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayMessage,
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
    } else {
      // Create new lawsuit
      final createdLawsuit = await provider.createLawsuit(lawsuit);
      if (createdLawsuit != null && createdLawsuit.id != null && mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LawsuitDetailScreen(lawsuitId: createdLawsuit.id!),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الدعوى بنجاح. يمكنك الآن إضافة المستندات'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        Navigator.pop(context);
        final errorMessage = provider.errorMessage ?? 'حدث خطأ في إنشاء الدعوى';
        final errorStr = errorMessage.toLowerCase();
        IconData errorIcon = Icons.error_outline;
        Color errorColor = Colors.red;
        String displayMessage = errorMessage;
        
        if (errorStr.contains('لا يوجد اتصال') || 
            errorStr.contains('network') ||
            errorStr.contains('connection')) {
          displayMessage = 'لا يوجد اتصال بالإنترنت\nيرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى';
          errorIcon = Icons.wifi_off;
          errorColor = Colors.orange.shade700;
        } else if (errorStr.contains('انتهت مهلة') || 
                   errorStr.contains('timeout')) {
          displayMessage = 'انتهت مهلة الاتصال\nيرجى المحاولة مرة أخرى';
          errorIcon = Icons.wifi_off;
          errorColor = Colors.orange.shade700;
        } else if (errorStr.contains('400') || 
                   errorStr.contains('bad request')) {
          displayMessage = 'البيانات المدخلة غير صحيحة\nيرجى التحقق من جميع الحقول';
          errorIcon = Icons.warning_amber_rounded;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(errorIcon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayMessage,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'تعديل الدعوى' : 'إضافة دعوى جديدة'),
      ),
      body: _isEditMode
          ? Consumer<LawsuitProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.selectedLawsuit == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildForm();
              },
            )
          : _buildForm(),
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
            // Case Type (triggers template loading)
            DropdownButtonFormField<String>(
              value: _selectedCaseType,
              decoration: const InputDecoration(
                labelText: 'نوع القضية',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'امر_اداء', child: Text('أمر أداء')),
                DropdownMenuItem(value: 'دعوى', child: Text('دعوى')),
                DropdownMenuItem(value: 'رد_على_دعوى', child: Text('رد على دعوى')),
                DropdownMenuItem(value: 'استئناف', child: Text('استئناف')),
                DropdownMenuItem(value: 'طعن', child: Text('طعن')),
              ],
              onChanged: _onCaseTypeChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى اختيار نوع القضية';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Case Number
            TextFormField(
              controller: _caseNumberController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: 'رقم الدعوى',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال رقم الدعوى';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Subject
            TextFormField(
              controller: _subjectController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: 'موضوع الدعوى',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subject),
              ),
              maxLength: 150,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال موضوع الدعوى';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Case Status
            DropdownButtonFormField<String>(
              value: _selectedCaseStatus,
              decoration: const InputDecoration(
                labelText: 'حالة القضية',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              items: const [
                DropdownMenuItem(value: 'جديد', child: Text('جديد')),
                DropdownMenuItem(value: 'قيد_النظر', child: Text('قيد النظر')),
                DropdownMenuItem(value: 'مكتمل', child: Text('مكتمل')),
                DropdownMenuItem(value: 'مغلق', child: Text('مغلق')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCaseStatus = value;
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

            // Parties Section (only in edit mode)
            if (_isEditMode && widget.lawsuitId != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              _buildPartiesSection(),
              const SizedBox(height: 16),
            ],

            // Attachments Section (only in edit mode)
            if (_isEditMode && widget.lawsuitId != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              _buildAttachmentsSection(),
              const SizedBox(height: 16),
            ],

            // Save button
            Consumer<LawsuitProvider>(
              builder: (context, provider, child) {
                return ElevatedButton(
                  onPressed: (provider.isLoading || _isLoadingTemplates) ? null : _saveLawsuit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isEditMode ? 'حفظ التغييرات' : 'إنشاء الدعوى',
                          style: const TextStyle(fontSize: 16),
                        ),
                );
              },
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
    
    widgets.add(
      const Divider(),
    );
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

  Widget _buildPartiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'أطراف الدعوى',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.green),
                  onPressed: () => _showAddPartyDialog(isPlaintiff: true),
                  tooltip: 'إضافة مدعي',
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_outlined, color: Colors.orange),
                  onPressed: () => _showAddPartyDialog(isPlaintiff: false),
                  tooltip: 'إضافة مدعى عليه',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Plaintiffs
        Card(
          color: Colors.green.shade50,
          child: ExpansionTile(
            key: ValueKey('plaintiffs_${_plaintiffs.length}'),
            leading: const Icon(Icons.person, color: Colors.green),
            title: Text('المدعون (${_plaintiffs.length})'),
            initiallyExpanded: _plaintiffs.isNotEmpty,
            children: _isLoadingParties && _plaintiffs.isEmpty
                ? [const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ))]
                : _plaintiffs.isEmpty
                    ? [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('لا يوجد مدعون', style: TextStyle(color: Colors.grey)),
                        ),
                      ]
                    : _plaintiffs.map((plaintiff) => _buildPartyCard(plaintiff, isPlaintiff: true)).toList(),
          ),
        ),
        const SizedBox(height: 8),
        
        // Defendants
        Card(
          color: Colors.orange.shade50,
          child: ExpansionTile(
            key: ValueKey('defendants_${_defendants.length}'),
            leading: const Icon(Icons.person_outline, color: Colors.orange),
            title: Text('المدعى عليهم (${_defendants.length})'),
            initiallyExpanded: _defendants.isNotEmpty,
            children: _isLoadingParties && _defendants.isEmpty
                ? [const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ))]
                : _defendants.isEmpty
                    ? [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('لا يوجد مدعى عليهم', style: TextStyle(color: Colors.grey)),
                        ),
                      ]
                    : _defendants.map((defendant) => _buildPartyCard(defendant, isPlaintiff: false)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPartyCard(PartyModel party, {required bool isPlaintiff}) {
    return ListTile(
      title: Text(party.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الجنس: ${party.genderDisplay}'),
          Text('الجنسية: ${party.nationality}'),
          if (party.occupation != null) Text('المهنة: ${party.occupation}'),
          Text('العنوان: ${party.address}'),
          if (party.phone != null) Text('الهاتف: ${party.phone}'),
          if (party.attorneyName != null) Text('الوكيل: ${party.attorneyName}'),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showAddPartyDialog(
              isPlaintiff: isPlaintiff,
              party: party,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteParty(party, isPlaintiff: isPlaintiff),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPartyDialog({
    required bool isPlaintiff,
    PartyModel? party,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: party?.name ?? '');
    final nationalityController = TextEditingController(text: party?.nationality ?? '');
    final occupationController = TextEditingController(text: party?.occupation ?? '');
    final addressController = TextEditingController(text: party?.address ?? '');
    final phoneController = TextEditingController(text: party?.phone ?? '');
    final attorneyNameController = TextEditingController(text: party?.attorneyName ?? '');
    final attorneyPhoneController = TextEditingController(text: party?.attorneyPhone ?? '');
    String? selectedGender = party?.gender ?? 'male';

    bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(party == null 
              ? (isPlaintiff ? 'إضافة مدعي' : 'إضافة مدعى عليه')
              : (isPlaintiff ? 'تعديل مدعي' : 'تعديل مدعى عليه')),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'الاسم *'),
                    validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(labelText: 'الجنس *'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('ذكر')),
                      DropdownMenuItem(value: 'female', child: Text('أنثى')),
                    ],
                    onChanged: (v) {
                      setDialogState(() {
                        selectedGender = v;
                      });
                    },
                  ),
                TextFormField(
                  controller: nationalityController,
                  decoration: const InputDecoration(labelText: 'الجنسية *'),
                  validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: occupationController,
                  decoration: const InputDecoration(labelText: 'المهنة'),
                ),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'العنوان *'),
                  maxLines: 2,
                  validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'الهاتف'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: attorneyNameController,
                  decoration: const InputDecoration(labelText: 'اسم الوكيل'),
                ),
                TextFormField(
                  controller: attorneyPhoneController,
                  decoration: const InputDecoration(labelText: 'هاتف الوكيل'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(party == null ? 'إضافة' : 'حفظ'),
          ),
        ],
        ),
      ),
    );
    
    // Save party data before disposing controllers
    final partyName = nameController.text;
    final partyGender = selectedGender!;
    final partyNationality = nationalityController.text;
    final partyOccupation = occupationController.text.isEmpty ? null : occupationController.text;
    final partyAddress = addressController.text;
    final partyPhone = phoneController.text.isEmpty ? null : phoneController.text;
    final partyAttorneyName = attorneyNameController.text.isEmpty ? null : attorneyNameController.text;
    final partyAttorneyPhone = attorneyPhoneController.text.isEmpty ? null : attorneyPhoneController.text;
    
    // Dispose controllers after dialog is fully closed
    // Use post-frame callback to ensure dialog widgets are completely disposed before disposing controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait one more frame to ensure all dialog widgets are fully disposed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameController.dispose();
        nationalityController.dispose();
        occupationController.dispose();
        addressController.dispose();
        phoneController.dispose();
        attorneyNameController.dispose();
        attorneyPhoneController.dispose();
      });
    });
    
    // Save party if dialog returned true and widget is still mounted
    if (shouldSave == true && mounted) {
      await _saveParty(
        isPlaintiff: isPlaintiff,
        party: party,
        name: partyName,
        gender: partyGender,
        nationality: partyNationality,
        occupation: partyOccupation,
        address: partyAddress,
        phone: partyPhone,
        attorneyName: partyAttorneyName,
        attorneyPhone: partyAttorneyPhone,
      );
    }
  }

  Future<void> _saveParty({
    required bool isPlaintiff,
    PartyModel? party,
    required String name,
    required String gender,
    required String nationality,
    String? occupation,
    required String address,
    String? phone,
    String? attorneyName,
    String? attorneyPhone,
  }) async {
    if (!mounted) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final lawsuitId = widget.lawsuitId!;
      
      final partyData = {
        'lawsuit_id': lawsuitId,
        'name': name,
        'gender': gender,
        'nationality': nationality,
        if (occupation != null && occupation.isNotEmpty) 'occupation': occupation,
        'address': address,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (attorneyName != null && attorneyName.isNotEmpty) 'attorney_name': attorneyName,
        if (attorneyPhone != null && attorneyPhone.isNotEmpty) 'attorney_phone': attorneyPhone,
      };

      developer.log('Saving party: $partyData', name: 'LawsuitDetailScreen');

      Map<String, dynamic>? responseData;
      
      if (party == null) {
        // Create new party
        if (isPlaintiff) {
          final response = await authProvider.apiService.createPlaintiff(partyData);
          developer.log('Create plaintiff response: $response', name: 'LawsuitDetailScreen');
          responseData = response;
          
          // Add to local list immediately for better UX
          if (mounted && responseData != null) {
            try {
              final newPlaintiff = PlaintiffModel.fromJson(responseData);
              setState(() {
                _plaintiffs.add(newPlaintiff);
              });
            } catch (e) {
              developer.log('Error parsing new plaintiff: $e', name: 'LawsuitDetailScreen');
            }
          }
        } else {
          final response = await authProvider.apiService.createDefendant(partyData);
          developer.log('Create defendant response: $response', name: 'LawsuitDetailScreen');
          responseData = response;
          
          // Add to local list immediately for better UX
          if (mounted && responseData != null) {
            try {
              final newDefendant = DefendantModel.fromJson(responseData);
              setState(() {
                _defendants.add(newDefendant);
              });
            } catch (e) {
              developer.log('Error parsing new defendant: $e', name: 'LawsuitDetailScreen');
            }
          }
        }
      } else {
        // Update existing party
        if (isPlaintiff) {
          final response = await authProvider.apiService.updatePlaintiff(party.id!, partyData);
          developer.log('Update plaintiff response: $response', name: 'LawsuitDetailScreen');
          responseData = response;
          
          // Update local list immediately
          if (mounted && responseData != null) {
            try {
              final updatedPlaintiff = PlaintiffModel.fromJson(responseData);
              setState(() {
                final index = _plaintiffs.indexWhere((p) => p.id == party.id);
                if (index != -1) {
                  _plaintiffs[index] = updatedPlaintiff;
                }
              });
            } catch (e) {
              developer.log('Error parsing updated plaintiff: $e', name: 'LawsuitDetailScreen');
            }
          }
        } else {
          final response = await authProvider.apiService.updateDefendant(party.id!, partyData);
          developer.log('Update defendant response: $response', name: 'LawsuitDetailScreen');
          responseData = response;
          
          // Update local list immediately
          if (mounted && responseData != null) {
            try {
              final updatedDefendant = DefendantModel.fromJson(responseData);
              setState(() {
                final index = _defendants.indexWhere((d) => d.id == party.id);
                if (index != -1) {
                  _defendants[index] = updatedDefendant;
                }
              });
            } catch (e) {
              developer.log('Error parsing updated defendant: $e', name: 'LawsuitDetailScreen');
            }
          }
        }
      }

      // Show success message first
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(party == null 
                ? (isPlaintiff ? 'تم إضافة المدعي بنجاح' : 'تم إضافة المدعى عليه بنجاح')
                : 'تم التحديث بنجاح'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // For new parties: we already added them locally with the server response,
      // so no need to reload immediately. Only reload for updates to ensure sync.
      // We'll do a background sync after a longer delay to catch any edge cases.
      if (mounted) {
        if (party == null) {
          // New party: do a background sync after delay, but merging will preserve local data
          // This is just to ensure we're in sync with server, not to replace local data
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _loadParties().catchError((e) {
                developer.log('Error syncing parties: $e', name: 'LawsuitDetailScreen');
              });
            }
          });
        } else {
          // Updated party: reload after short delay to get latest data
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _loadParties().catchError((e) {
                developer.log('Error reloading parties: $e', name: 'LawsuitDetailScreen');
              });
            }
          });
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error saving party: $e', name: 'LawsuitDetailScreen');
      developer.log('Stack trace: $stackTrace', name: 'LawsuitDetailScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ الطرف: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _deleteParty(PartyModel party, {required bool isPlaintiff}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف ${party.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (isPlaintiff) {
        await authProvider.apiService.deletePlaintiff(party.id!);
      } else {
        await authProvider.apiService.deleteDefendant(party.id!);
      }

      // Reload parties only if still mounted
      if (mounted) {
        await _loadParties();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحذف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('Error deleting party: $e', name: 'LawsuitDetailScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'مستندات الدعوى',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isUploadingAttachment)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.blue),
                  onPressed: _isUploadingAttachment ? null : _showAddAttachmentDialog,
                  tooltip: 'إضافة مستند',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_isLoadingAttachments)
          const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ))
        else if (_attachments.isEmpty && !_isUploadingAttachment)
          Card(
            color: Colors.grey.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'لا توجد مستندات مرفقة',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          ..._attachments.map((attachment) => _buildAttachmentCard(attachment)),
        if (_isUploadingAttachment && _attachments.isEmpty)
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('جاري رفع المستند...'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAttachmentCard(Map<String, dynamic> attachment) {
    final docTypeDisplay = attachment['document_type_display'] ?? attachment['document_type'] ?? 'غير محدد';
    final fileName = attachment['original_filename'] ?? attachment['file'] ?? 'ملف';
    final content = attachment['content'] ?? '';
    final evidenceBasis = attachment['evidence_basis'] ?? '';
    final pageCount = attachment['page_count'] ?? 0;
    final fileSize = attachment['file_size_display'] ?? '';
    final createdAt = attachment['created_at'] != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(attachment['created_at']))
        : '';
    final fileUrl = attachment['file_url'] ?? attachment['file'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.blue),
        title: Text(
          docTypeDisplay,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fileName.isNotEmpty) Text('الملف: $fileName'),
            if (content.isNotEmpty) 
              Text(
                'المضمون: ${content.length > 50 ? content.substring(0, 50) + "..." : content}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (pageCount > 0) Text('عدد الصفحات: $pageCount'),
            if (fileSize.isNotEmpty) Text('الحجم: $fileSize'),
            if (createdAt.isNotEmpty) Text('تاريخ الإضافة: $createdAt'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fileUrl.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.download, color: Colors.blue),
                onPressed: () => _downloadOrOpenAttachment(fileUrl, fileName),
                tooltip: 'تحميل/فتح المستند',
              ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _showEditAttachmentDialog(attachment),
              tooltip: 'تعديل المستند',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteAttachment(attachment['id']),
              tooltip: 'حذف المستند',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _deleteAttachment(int? attachmentId) async {
    if (attachmentId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المستند؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.apiService.deleteAttachment(attachmentId);
      
      await _loadAttachments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المستند بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('Error deleting attachment: $e', name: 'LawsuitDetailScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف المستند: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAttachments() async {
    if (widget.lawsuitId == null || !mounted) return;
    
    setState(() {
      _isLoadingAttachments = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await authProvider.apiService.getAttachments(lawsuitId: widget.lawsuitId);
      
      if (mounted) {
        List<dynamic>? attachmentsData;
        if (response['results'] != null) {
          attachmentsData = response['results'] as List?;
        } else if (response['data'] != null && response['data'] is Map) {
          attachmentsData = (response['data'] as Map<String, dynamic>)['results'] as List?;
        } else if (response is List) {
          attachmentsData = response as List<dynamic>;
        } else {
          attachmentsData = null;
        }
        
        setState(() {
          _attachments = (attachmentsData ?? []).cast<Map<String, dynamic>>();
          _isLoadingAttachments = false;
        });
      }
    } catch (e) {
      developer.log('Error loading attachments: $e', name: 'LawsuitDetailScreen');
      if (mounted) {
        setState(() {
          _isLoadingAttachments = false;
        });
      }
    }
  }

  Future<void> _showAddAttachmentDialog() async {
    if (widget.lawsuitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب حفظ الدعوى أولاً قبل إضافة المستندات'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final contentController = TextEditingController();
    final evidenceBasisController = TextEditingController();
    final pageCountController = TextEditingController(text: '1');
    String? selectedDocType = 'other';
    DateTime? selectedDate = DateTime.now();
    File? selectedFile;

    final docTypes = [
      {'value': 'identity', 'label': 'هوية/جواز سفر'},
      {'value': 'contract', 'label': 'عقد'},
      {'value': 'certificate', 'label': 'شهادة'},
      {'value': 'evidence', 'label': 'دليل'},
      {'value': 'statement', 'label': 'بيان'},
      {'value': 'receipt', 'label': 'إيصال'},
      {'value': 'other', 'label': 'أخرى'},
    ];

    bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('إضافة مستند جديد'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedDocType,
                    decoration: const InputDecoration(labelText: 'نوع المستند *'),
                    items: docTypes.map((t) => DropdownMenuItem(
                      value: t['value'] as String,
                      child: Text(t['label'] as String),
                    )).toList(),
                    onChanged: (v) {
                      setDialogState(() {
                        selectedDocType = v;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'مضمون المستند *',
                      hintText: 'وصف محتوى المستند',
                    ),
                    maxLines: 3,
                    validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: evidenceBasisController,
                    decoration: const InputDecoration(
                      labelText: 'وجه الاستدلال *',
                      hintText: 'كيف يستدل بهذا المستند',
                    ),
                    maxLines: 2,
                    validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: pageCountController,
                    decoration: const InputDecoration(labelText: 'عدد الصفحات *'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'مطلوب';
                      if (int.tryParse(v!) == null || int.parse(v) < 1) {
                        return 'يجب أن يكون رقماً أكبر من 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text('التاريخ الميلادي: ${selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : 'غير محدد'}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.any,
                        allowMultiple: false,
                      );
                      if (result != null && result.files.single.path != null) {
                        setDialogState(() {
                          selectedFile = File(result!.files.single.path!);
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(selectedFile != null 
                        ? 'تم اختيار: ${selectedFile!.path.split('/').last}'
                        : 'اختر ملف *'),
                  ),
                  if (selectedFile != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedFile!.path.split('/').last,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                Text(
                                  'الحجم: ${_formatFileSize(selectedFile!.lengthSync())}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setDialogState(() {
                                selectedFile = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: _isUploadingAttachment ? null : () {
                if (formKey.currentState!.validate() && selectedDate != null && selectedFile != null) {
                  Navigator.pop(dialogContext, true);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى ملء جميع الحقول المطلوبة واختيار ملف'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: _isUploadingAttachment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    if (shouldSave == true && selectedFile != null && selectedDate != null) {
      await _uploadAttachment(
        file: selectedFile!,
        documentType: selectedDocType!,
        content: contentController.text,
        evidenceBasis: evidenceBasisController.text,
        pageCount: int.parse(pageCountController.text),
        gregorianDate: selectedDate!,
      );
    }

    contentController.dispose();
    evidenceBasisController.dispose();
    pageCountController.dispose();
  }

  Future<void> _showEditAttachmentDialog(Map<String, dynamic> attachment) async {
    if (widget.lawsuitId == null) return;

    final formKey = GlobalKey<FormState>();
    final contentController = TextEditingController(text: attachment['content'] ?? '');
    final evidenceBasisController = TextEditingController(text: attachment['evidence_basis'] ?? '');
    final pageCountController = TextEditingController(text: (attachment['page_count'] ?? 1).toString());
    String? selectedDocType = attachment['document_type'] ?? 'other';
    DateTime? selectedDate = attachment['gregorian_date'] != null
        ? DateTime.parse(attachment['gregorian_date'])
        : DateTime.now();
    File? selectedFile;

    final docTypes = [
      {'value': 'identity', 'label': 'هوية/جواز سفر'},
      {'value': 'contract', 'label': 'عقد'},
      {'value': 'certificate', 'label': 'شهادة'},
      {'value': 'evidence', 'label': 'دليل'},
      {'value': 'statement', 'label': 'بيان'},
      {'value': 'receipt', 'label': 'إيصال'},
      {'value': 'other', 'label': 'أخرى'},
    ];

    bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('تعديل المستند'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedDocType,
                    decoration: const InputDecoration(labelText: 'نوع المستند *'),
                    items: docTypes.map((t) => DropdownMenuItem(
                      value: t['value'] as String,
                      child: Text(t['label'] as String),
                    )).toList(),
                    onChanged: (v) {
                      setDialogState(() {
                        selectedDocType = v;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'مضمون المستند *',
                      hintText: 'وصف محتوى المستند',
                    ),
                    maxLines: 3,
                    validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: evidenceBasisController,
                    decoration: const InputDecoration(
                      labelText: 'وجه الاستدلال *',
                      hintText: 'كيف يستدل بهذا المستند',
                    ),
                    maxLines: 2,
                    validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: pageCountController,
                    decoration: const InputDecoration(labelText: 'عدد الصفحات *'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'مطلوب';
                      if (int.tryParse(v!) == null || int.parse(v) < 1) {
                        return 'يجب أن يكون رقماً أكبر من 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text('التاريخ الميلادي: ${selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : 'غير محدد'}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ملف جديد (اختياري - اتركه فارغاً للاحتفاظ بالملف الحالي)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.any,
                        allowMultiple: false,
                      );
                      if (result != null && result.files.single.path != null) {
                        setDialogState(() {
                          selectedFile = File(result!.files.single.path!);
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(selectedFile != null 
                        ? 'تم اختيار: ${selectedFile!.path.split('/').last}'
                        : 'اختر ملف جديد (اختياري)'),
                  ),
                  if (selectedFile != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedFile!.path.split('/').last,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                Text(
                                  'الحجم: ${_formatFileSize(selectedFile!.lengthSync())}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setDialogState(() {
                                selectedFile = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: _isUploadingAttachment ? null : () {
                if (formKey.currentState!.validate() && selectedDate != null) {
                  Navigator.pop(dialogContext, true);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى ملء جميع الحقول المطلوبة'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: _isUploadingAttachment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (shouldSave == true && selectedDate != null) {
      await _updateAttachment(
        attachmentId: attachment['id'],
        documentType: selectedDocType!,
        content: contentController.text,
        evidenceBasis: evidenceBasisController.text,
        pageCount: int.parse(pageCountController.text),
        gregorianDate: selectedDate!,
        newFile: selectedFile,
      );
    }

    contentController.dispose();
    evidenceBasisController.dispose();
    pageCountController.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _downloadOrOpenAttachment(String fileUrl, String fileName) async {
    try {
      final uri = Uri.parse(fileUrl);
      
      // If it's a full URL, try to open it directly
      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('لا يمكن فتح الملف'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        // If it's a relative URL, construct full URL
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final fullUrl = '${ApiConfig.baseUrl}$fileUrl';
        final fullUri = Uri.parse(fullUrl);
        
        if (await canLaunchUrl(fullUri)) {
          await launchUrl(fullUri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('لا يمكن فتح الملف'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      developer.log('Error opening attachment: $e', name: 'LawsuitDetailScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في فتح الملف: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadAttachment({
    required File file,
    required String documentType,
    required String content,
    required String evidenceBasis,
    required int pageCount,
    required DateTime gregorianDate,
  }) async {
    if (widget.lawsuitId == null) return;

    setState(() {
      _isUploadingAttachment = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Convert gregorian date to hijri
      final hijriDate = HijriCalendar.fromDate(gregorianDate);
      final hijriDateString = '${hijriDate.hYear}/${hijriDate.hMonth}/${hijriDate.hDay}';

      // Upload file
      await authProvider.apiService.uploadAttachment(
        lawsuitId: widget.lawsuitId!,
        filePath: file.path,
        documentType: documentType,
        gregorianDate: DateFormat('yyyy-MM-dd').format(gregorianDate),
        hijriDate: hijriDateString,
        pageCount: pageCount,
        content: content,
        evidenceBasis: evidenceBasis,
      );

      // Reload attachments
      await _loadAttachments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع المستند بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('Error uploading attachment: $e', name: 'LawsuitDetailScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع المستند: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAttachment = false;
        });
      }
    }
  }

  Future<void> _updateAttachment({
    required int attachmentId,
    required String documentType,
    required String content,
    required String evidenceBasis,
    required int pageCount,
    required DateTime gregorianDate,
    File? newFile,
  }) async {
    if (widget.lawsuitId == null) return;

    setState(() {
      _isUploadingAttachment = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Convert gregorian date to hijri
      final hijriDate = HijriCalendar.fromDate(gregorianDate);
      final hijriDateString = '${hijriDate.hYear}/${hijriDate.hMonth}/${hijriDate.hDay}';

      // Update attachment
      await authProvider.apiService.updateAttachment(
        id: attachmentId,
        documentType: documentType,
        gregorianDate: DateFormat('yyyy-MM-dd').format(gregorianDate),
        hijriDate: hijriDateString,
        pageCount: pageCount,
        content: content,
        evidenceBasis: evidenceBasis,
        filePath: newFile?.path,
      );

      // Reload attachments
      await _loadAttachments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث المستند بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('Error updating attachment: $e', name: 'LawsuitDetailScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث المستند: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAttachment = false;
        });
      }
    }
  }
}
