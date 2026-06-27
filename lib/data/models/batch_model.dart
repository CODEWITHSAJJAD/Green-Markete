import 'package:freezed_annotation/freezed_annotation.dart';
part 'batch_model.freezed.dart';
part 'batch_model.g.dart';

@freezed
class BatchModel with _$BatchModel {
  const factory BatchModel({
    required String id,
    required String businessId,
    required String productId,
    required String batchCode,
    String? sourceMarketId,
    String? destinationMarketId,
    required String purchaseDate,
    required double totalQuantity,
    required String quantityUnit,
    required double purchasePricePerUnit,
    required double totalPurchaseCost,
    required String status,
    String? transportPaidBy,
    String? notes,
    String? createdAt,
  }) = _BatchModel;

  factory BatchModel.fromJson(Map<String, dynamic> json) =>
      _$BatchModelFromJson(json);
}

@freezed
class BatchCreateRequest with _$BatchCreateRequest {
  const factory BatchCreateRequest({
    required String businessId,
    required String productId,
    String? sourceMarketId,
    String? destinationMarketId,
    required String purchaseDate,
    required double totalQuantity,
    required String quantityUnit,
    required double purchasePricePerUnit,
    String? transportPaidBy,
    String? notes,
    List<BatchPartnerCreate>? partners,
    List<PackingRecordCreate>? packingRecords,
    List<ExpenseCreate>? expenses,
  }) = _BatchCreateRequest;

  factory BatchCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$BatchCreateRequestFromJson(json);
}

@freezed
class BatchPartnerCreate with _$BatchPartnerCreate {
  const factory BatchPartnerCreate({
    required String partnerId,
    required String role,
    double? dailyChargeRate,
    int? daysInvolved,
  }) = _BatchPartnerCreate;

  factory BatchPartnerCreate.fromJson(Map<String, dynamic> json) =>
      _$BatchPartnerCreateFromJson(json);
}

@freezed
class PackingRecordCreate with _$PackingRecordCreate {
  const factory PackingRecordCreate({
    required String unitType,
    String? unitLabel,
    required int unitCount,
    required double costPerUnit,
  }) = _PackingRecordCreate;

  factory PackingRecordCreate.fromJson(Map<String, dynamic> json) =>
      _$PackingRecordCreateFromJson(json);
}

@freezed
class ExpenseCreate with _$ExpenseCreate {
  const factory ExpenseCreate({
    String? partnerId,
    required String expenseSide,
    required String expenseType,
    required double amount,
    String? description,
    String? paidBy,
    String? paymentMode,
    String? paymentReference,
    String? expenseDate,
  }) = _ExpenseCreate;

  factory ExpenseCreate.fromJson(Map<String, dynamic> json) =>
      _$ExpenseCreateFromJson(json);
}
