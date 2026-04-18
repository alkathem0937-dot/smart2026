class HeirInput {
  final String type;
  final int count;

  const HeirInput({required this.type, required this.count});

  Map<String, dynamic> toJson() => {
        'type': type,
        'count': count,
      };
}

class EstateItemInput {
  final String category;
  final String description;
  final String value;

  const EstateItemInput({
    required this.category,
    required this.description,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'description': description,
        'value': value,
      };
}

class DebtItemInput {
  final String creditor;
  final String description;
  final String amount;

  const DebtItemInput({
    required this.creditor,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'creditor': creditor,
        'description': description,
        'amount': amount,
      };
}

class BequestItemInput {
  final String beneficiary;
  final String description;
  final String amount;

  const BequestItemInput({
    required this.beneficiary,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'beneficiary': beneficiary,
        'description': description,
        'amount': amount,
      };
}

class ShareItem {
  final String heirType;
  final int count;
  final int fractionNumerator;
  final int fractionDenominator;
  final String totalAmount;
  final String amountPerHeir;
  final String basis;
  final String reasonCode;

  const ShareItem({
    required this.heirType,
    required this.count,
    required this.fractionNumerator,
    required this.fractionDenominator,
    required this.totalAmount,
    required this.amountPerHeir,
    required this.basis,
    required this.reasonCode,
  });

  factory ShareItem.fromJson(Map<String, dynamic> json) {
    return ShareItem(
      heirType: json['heir_type']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      fractionNumerator: (json['fraction_numerator'] as num?)?.toInt() ?? 0,
      fractionDenominator: (json['fraction_denominator'] as num?)?.toInt() ?? 0,
      totalAmount: json['total_amount']?.toString() ?? '0',
      amountPerHeir: json['amount_per_heir']?.toString() ?? '0',
      basis: json['basis']?.toString() ?? '',
      reasonCode: json['reason_code']?.toString() ?? '',
    );
  }
}

class InheritanceResult {
  final Map<String, dynamic> totals;
  final List<ShareItem> shares;
  final List<String> notes;

  const InheritanceResult({required this.totals, required this.shares, required this.notes});

  factory InheritanceResult.fromJson(Map<String, dynamic> json) {
    final totals = (json['totals'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final sharesRaw = (json['shares'] as List?) ?? const [];
    final notesRaw = (json['notes'] as List?) ?? const [];

    return InheritanceResult(
      totals: totals,
      shares: sharesRaw
          .whereType<Map>()
          .map((e) => ShareItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      notes: notesRaw.map((e) => e.toString()).toList(),
    );
  }
}
