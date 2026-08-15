import 'batch_model.dart';

class PLSummaryModel {
  final String businessId;
  final String? dateFrom;
  final String? dateTo;
  final int totalBatches;
  final double totalCost;
  final double totalRevenue;
  final double totalProfitLoss;
  final List<BatchPLSummaryModel> batchSummaries;

  PLSummaryModel({
    required this.businessId,
    this.dateFrom,
    this.dateTo,
    this.totalBatches = 0,
    this.totalCost = 0,
    this.totalRevenue = 0,
    this.totalProfitLoss = 0,
    this.batchSummaries = const [],
  });

  factory PLSummaryModel.fromJson(Map<String, dynamic> json) {
    return PLSummaryModel(
      businessId: json['business_id'] as String,
      dateFrom: json['date_from'] as String?,
      dateTo: json['date_to'] as String?,
      totalBatches: json['total_batches'] as int? ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      totalProfitLoss: (json['total_profit_loss'] as num?)?.toDouble() ?? 0,
      batchSummaries: (json['batch_summaries'] as List<dynamic>?)
              ?.map((e) => BatchPLSummaryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BatchPLSummaryModel {
  final String batchId;
  final String? batchCode;
  final CostBreakdownModel costBreakdown;
  final RevenueModel revenue;
  final double netProfitLoss;

  BatchPLSummaryModel({
    required this.batchId,
    this.batchCode,
    required this.costBreakdown,
    required this.revenue,
    required this.netProfitLoss,
  });

  factory BatchPLSummaryModel.fromJson(Map<String, dynamic> json) {
    return BatchPLSummaryModel(
      batchId: json['batch_id'] as String,
      batchCode: json['batch_code'] as String?,
      costBreakdown: CostBreakdownModel.fromJson(
        json['cost_breakdown'] as Map<String, dynamic>? ?? json,
      ),
      revenue: RevenueModel.fromJson(
        json['revenue'] as Map<String, dynamic>? ?? json,
      ),
      netProfitLoss: (json['net_profit_loss'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CostBreakdownModel {
  final double purchaseCost;
  final double purchaserDailyCharges;
  final double purchaserExpenses;
  final double packingCost;
  final double transportCost;
  final double sellerDailyCharges;
  final double sellerExpenses;
  final double totalCost;

  const CostBreakdownModel({
    this.purchaseCost = 0,
    this.purchaserDailyCharges = 0,
    this.purchaserExpenses = 0,
    this.packingCost = 0,
    this.transportCost = 0,
    this.sellerDailyCharges = 0,
    this.sellerExpenses = 0,
    this.totalCost = 0,
  });

  factory CostBreakdownModel.fromJson(Map<String, dynamic> json) {
    return CostBreakdownModel(
      purchaseCost: (json['purchase_cost'] as num?)?.toDouble() ?? 0,
      purchaserDailyCharges: (json['purchaser_daily_charges'] as num?)?.toDouble() ?? 0,
      purchaserExpenses: (json['purchaser_expenses'] as num?)?.toDouble() ?? 0,
      packingCost: (json['packing_cost'] as num?)?.toDouble() ?? 0,
      transportCost: (json['transport_cost'] as num?)?.toDouble() ?? 0,
      sellerDailyCharges: (json['seller_daily_charges'] as num?)?.toDouble() ?? 0,
      sellerExpenses: (json['seller_expenses'] as num?)?.toDouble() ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RevenueModel {
  final double totalRevenue;
  final double cashReceived;
  final double creditOutstanding;

  const RevenueModel({
    this.totalRevenue = 0,
    this.cashReceived = 0,
    this.creditOutstanding = 0,
  });

  factory RevenueModel.fromJson(Map<String, dynamic> json) {
    return RevenueModel(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      cashReceived: (json['cash_received'] as num?)?.toDouble() ?? 0,
      creditOutstanding: (json['credit_outstanding'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CreditReportModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? city;
  final double outstandingBalance;

  CreditReportModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.city,
    required this.outstandingBalance,
  });

  factory CreditReportModel.fromJson(Map<String, dynamic> json) {
    return CreditReportModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      outstandingBalance: (json['outstanding_balance'] as num).toDouble(),
    );
  }
}

class DashboardSummaryModel {
  final double todaySales;
  final double todayRevenue;
  final int todaySalesCount;
  final double totalRevenue;
  final double totalCost;
  final double totalProfitLoss;
  final int activeBatches;
  final int sellingBatches;
  final int totalBatches;
  final int totalProducts;
  final int totalCustomers;
  final int customersWithCreditCount;
  final double outstandingCredit;
  final double supplierPayables;
  final List<BatchModel> recentBatches;

  DashboardSummaryModel({
    this.todaySales = 0,
    this.todayRevenue = 0,
    this.todaySalesCount = 0,
    this.totalRevenue = 0,
    this.totalCost = 0,
    this.totalProfitLoss = 0,
    this.activeBatches = 0,
    this.sellingBatches = 0,
    this.totalBatches = 0,
    this.totalProducts = 0,
    this.totalCustomers = 0,
    this.customersWithCreditCount = 0,
    this.outstandingCredit = 0,
    this.supplierPayables = 0,
    this.recentBatches = const [],
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final recentRaw = json['recent_batches'] as List<dynamic>? ?? const <dynamic>[];
    return DashboardSummaryModel(
      todaySales: (json['today_sales'] as num?)?.toDouble() ?? 0,
      todayRevenue: (json['today_revenue'] as num?)?.toDouble() ??
          (json['today_sales'] as num?)?.toDouble() ??
          0,
      todaySalesCount: (json['today_sales_count'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      totalProfitLoss: (json['total_profit_loss'] as num?)?.toDouble() ?? 0,
      activeBatches: json['active_batches'] as int? ?? 0,
      sellingBatches: json['selling_batches'] as int? ?? 0,
      totalBatches: json['total_batches'] as int? ?? 0,
      totalProducts: json['total_products'] as int? ?? 0,
      totalCustomers: json['total_customers'] as int? ?? 0,
      customersWithCreditCount: json['customers_with_credit_count'] as int? ?? 0,
      outstandingCredit: (json['outstanding_credit'] as num?)?.toDouble() ?? 0,
      supplierPayables: (json['supplier_payables'] as num?)?.toDouble() ?? 0,
      recentBatches: recentRaw
          .map((e) => BatchModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PartnerPLModel {
  final String partnerId;
  final String batchId;
  final double dailyCharges;
  final double expensesLogged;
  final double salesMade;
  final double netShare;

  PartnerPLModel({
    required this.partnerId,
    required this.batchId,
    this.dailyCharges = 0,
    this.expensesLogged = 0,
    this.salesMade = 0,
    this.netShare = 0,
  });

  factory PartnerPLModel.fromJson(Map<String, dynamic> json) {
    return PartnerPLModel(
      partnerId: json['partner_id'] as String,
      batchId: json['batch_id'] as String,
      dailyCharges: (json['daily_charges'] as num?)?.toDouble() ?? 0,
      expensesLogged: (json['expenses_logged'] as num?)?.toDouble() ?? 0,
      salesMade: (json['sales_made'] as num?)?.toDouble() ?? 0,
      netShare: (json['net_share'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MarketPerformanceModel {
  final String marketId;
  final String marketName;
  final String city;
  final int batchCount;
  final double totalRevenue;
  final double totalCost;
  final double profitLoss;

  MarketPerformanceModel({
    required this.marketId,
    required this.marketName,
    required this.city,
    this.batchCount = 0,
    this.totalRevenue = 0,
    this.totalCost = 0,
    this.profitLoss = 0,
  });

  factory MarketPerformanceModel.fromJson(Map<String, dynamic> json) {
    return MarketPerformanceModel(
      marketId: json['market_id'] as String? ?? '',
      marketName: json['market_name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      batchCount: json['batch_count'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      profitLoss: (json['profit_loss'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BatchPLDetailModel {
  final String batchId;
  final String? batchCode;
  final CostBreakdownModel costBreakdown;
  final RevenueModel revenue;
  final double netProfitLoss;
  final double? soldQuantity;
  final double? remainingQuantity;
  final double? avgSalePrice;
  final List<PartnerShareModel> partnerShares;

  const BatchPLDetailModel({
    required this.batchId,
    this.batchCode,
    this.costBreakdown = const CostBreakdownModel(),
    this.revenue = const RevenueModel(),
    this.netProfitLoss = 0,
    this.soldQuantity,
    this.remainingQuantity,
    this.avgSalePrice,
    this.partnerShares = const [],
  });

  factory BatchPLDetailModel.fromJson(Map<String, dynamic> json) {
    return BatchPLDetailModel(
      batchId: json['batch_id'] as String? ?? json['id'] as String? ?? '',
      batchCode: json['batch_code'] as String?,
      costBreakdown: CostBreakdownModel.fromJson(json),
      revenue: RevenueModel.fromJson(json),
      netProfitLoss: (json['net_profit_loss'] as num?)?.toDouble() ?? 0,
      soldQuantity: (json['sold_quantity'] as num?)?.toDouble(),
      remainingQuantity: (json['remaining_quantity'] as num?)?.toDouble(),
      avgSalePrice: (json['avg_sale_price'] as num?)?.toDouble(),
      partnerShares: (json['partner_shares'] as List<dynamic>?)
              ?.map((e) => PartnerShareModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PartnerShareModel {
  final String partnerId;
  final String? fullName;
  final String role;
  final double dailyCharges;
  final double expensesLogged;
  final double salesMade;
  final double netShare;

  PartnerShareModel({
    required this.partnerId,
    this.fullName,
    this.role = 'partner',
    this.dailyCharges = 0,
    this.expensesLogged = 0,
    this.salesMade = 0,
    this.netShare = 0,
  });

  factory PartnerShareModel.fromJson(Map<String, dynamic> json) {
    return PartnerShareModel(
      partnerId: json['partner_id'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'partner',
      dailyCharges: (json['daily_charges'] as num?)?.toDouble() ?? 0,
      expensesLogged: (json['expenses_logged'] as num?)?.toDouble() ?? 0,
      salesMade: (json['sales_made'] as num?)?.toDouble() ?? 0,
      netShare: (json['net_share'] as num?)?.toDouble() ?? 0,
    );
  }
}