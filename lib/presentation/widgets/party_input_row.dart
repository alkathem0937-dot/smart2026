import 'package:flutter/material.dart';

class PartyInputRow extends StatefulWidget {
  final Map<String, dynamic> data;
  final int index;
  final bool isPlaintiff;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const PartyInputRow({
    super.key,
    required this.data,
    required this.index,
    required this.isPlaintiff,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<PartyInputRow> createState() => _PartyInputRowState();
}

class _PartyInputRowState extends State<PartyInputRow> {
  late TextEditingController _nameController;
  late TextEditingController _nationalityController;
  late TextEditingController _occupationController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _attorneyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data['name'] ?? '');
    _nationalityController = TextEditingController(text: widget.data['nationality'] ?? '');
    _occupationController = TextEditingController(text: widget.data['occupation'] ?? '');
    _phoneController = TextEditingController(text: widget.data['phone'] ?? '');
    _addressController = TextEditingController(text: widget.data['address'] ?? '');
    _attorneyController = TextEditingController(text: widget.data['attorney_name'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nationalityController.dispose();
    _occupationController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _attorneyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true, // For better RTL initial view
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name Field (Main focus)
            SizedBox(
              width: 150,
              child: TextFormField(
                controller: _nameController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: widget.isPlaintiff ? 'اسم المدعى' : 'اسم المدعى عليه',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                maxLength: 70,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => const SizedBox.shrink(),
                onChanged: (value) {
                  widget.data['name'] = value;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            // Nationality
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _nationalityController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'يمني',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 10),
                onChanged: (value) {
                  widget.data['nationality'] = value;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            // Gender
            SizedBox(
              width: 80,
              child: DropdownButtonFormField<String>(
                value: widget.data['gender'] ?? 'ذكر',
                decoration: const InputDecoration(
                  hintText: 'ذكر',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  isDense: true,
                ),
                dropdownColor: Colors.white,
                style: const TextStyle(fontSize: 10, color: Colors.black),
                items: const [
                  DropdownMenuItem(
                    value: 'ذكر',
                    child: Text(
                      'ذكر',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Colors.black),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'أنثى',
                    child: Text(
                      'أنثى',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Colors.black),
                    ),
                  ),
                ],
                onChanged: (value) {
                  widget.data['gender'] = value;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            // Occupation
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _occupationController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'العمل',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 10),
                maxLength: 70,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => const SizedBox.shrink(),
                onChanged: (value) {
                  widget.data['occupation'] = value;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            // Phone
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: _phoneController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: widget.isPlaintiff ? 'هاتف المدعى' : 'هاتف المدعى عليه',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  isDense: true,
                  errorText: widget.data['phone_error'],
                  errorStyle: const TextStyle(fontSize: 8),
                ),
                style: const TextStyle(fontSize: 10),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  widget.data['phone'] = value;
                  if (value.isEmpty) {
                    widget.data['phone_error'] = 'مطلوب';
                  } else {
                    widget.data['phone_error'] = null;
                  }
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            // Address
            SizedBox(
              width: 150,
              child: TextFormField(
                controller: _addressController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'عنوان المدعى',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 10),
                maxLength: 70,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => const SizedBox.shrink(),
                onChanged: (value) {
                  widget.data['address'] = value;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            // Attorney
            SizedBox(
              width: 150,
              child: TextFormField(
                controller: _attorneyController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'وكيل المدعى',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 10),
                maxLength: 70,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => const SizedBox.shrink(),
                onChanged: (value) {
                  widget.data['attorney_name'] = value;
                  widget.onChanged();
                },
              ),
            ),
            // Delete button at the end
            SizedBox(
              width: 80,
              child: IconButton(
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
