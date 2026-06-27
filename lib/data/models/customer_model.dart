class CustomerModel {
  final String id;
  final String businessId;
  final String fullName;
  final String? phone;
  final String? city;
  final String? shopName;
  final double totalPurchased;
  final double totalPaid;
  final double outstandingBalance;

  CustomerModel({
    required this.id,
    required this.businessId,
    required this.fullName,
    this.phone,
    this.city,
    this.shopName,
    this.totalPurchased = 0,
    this.totalPaid = 0,
    this.outstandingBalance = 0,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      shopName: json['shop_name'] as String?,
      totalPurchased: (json['total_purchased'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0,
      outstandingBalance: (json['outstanding_balance'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'business_id': businessId,
    'full_name': fullName,
    'phone': phone,
    'city': city,
    'shop_name': shopName,
  };
}

class CustomerLedgerEntry {
  final String date;
  final String description;
  final double amount;
  final double runningBalance;
  final String type;

  CustomerLedgerEntry({
    required this.date,
    required this.description,
    required this.amount,
    required this.runningBalance,
    required this.type,
  });

  factory CustomerLedgerEntry.fromJson(Map<String, dynamic> json) {
    return CustomerLedgerEntry(
      date: json['date'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      runningBalance: (json['running_balance'] as num).toDouble(),
      type: json['type'] as String? ?? 'sale',
    );
  }
}
