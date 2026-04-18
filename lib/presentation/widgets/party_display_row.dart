import 'package:flutter/material.dart';
import '../../models/party_model.dart';

class PartyDisplayRow extends StatelessWidget {
  final PartyModel party;
  final bool isPlaintiff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PartyDisplayRow({
    super.key,
    required this.party,
    required this.isPlaintiff,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 150, child: Text(party.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            SizedBox(width: 80, child: Text(party.nationality, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            SizedBox(width: 80, child: Text(party.genderDisplay, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10), maxLines: 1)),
            const SizedBox(width: 8),
            SizedBox(width: 80, child: Text(party.occupation ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            SizedBox(width: 100, child: Text(party.phone ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            SizedBox(width: 150, child: Text(party.address, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            SizedBox(width: 150, child: Text(party.attorneyName ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
