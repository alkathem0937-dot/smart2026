/// Payment Order Model
class PaymentOrderModel {
  final int? id;
  final int lawsuitId;
  final String? lawsuitNumber;
  final double amount;
  final String? orderNumber;
  final DateTime orderDate;
  final String? description;
  final String status;
  final double paidAmount;
  final DateTime? paymentDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentOrderModel({
    this.id,
    required this.lawsuitId,
    this.lawsuitNumber,
    required this.amount,
    this.orderNumber,
    required this.orderDate,
    this.description,
    required this.status,
    this.paidAmount = 0,
    this.paymentDate,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentOrderModel.fromJson(Map<String, dynamic> json) {
    return PaymentOrderModel(
      id: json['id'],
      lawsuitId: json['lawsuit'] is int 
          ? json['lawsuit'] as int
          : (json['lawsuit'] is Map ? (json['lawsuit'] as Map)['id'] : null) ?? json['lawsuit_id'] ?? 0,
      lawsuitNumber: json['lawsuit'] is Map 
          ? (json['lawsuit'] as Map)['case_number'] as String?
          : null,
      amount: (json['amount'] is num) 
          ? json['amount'].toDouble() 
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      orderNumber: json['order_number'],
      orderDate: json['order_date'] != null 
          ? DateTime.parse(json['order_date']) 
          : DateTime.now(),
      description: json['description'],
      status: json['status'] ?? 'pending',
      paidAmount: (json['paid_amount'] is num) 
          ? json['paid_amount'].toDouble() 
          : double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0,
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'lawsuit': lawsuitId,
      'amount': amount,
      if (orderNumber != null) 'order_number': orderNumber,
      'order_date': orderDate.toIso8601String().split('T')[0],
      if (description != null) 'description': description,
      'status': status,
      'paid_amount': paidAmount,
      if (paymentDate != null) 'payment_date': paymentDate!.toIso8601String().split('T')[0],
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'paid':
        return 'مدفوع';
      case 'partial':
        return 'مدفوع جزئياً';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  double get remainingAmount => amount - paidAmount;
}

