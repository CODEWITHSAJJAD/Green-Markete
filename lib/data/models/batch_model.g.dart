// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BatchModelImpl _$$BatchModelImplFromJson(Map<String, dynamic> json) =>
    _$BatchModelImpl(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      productId: json['productId'] as String,
      batchCode: json['batchCode'] as String,
      sourceMarketId: json['sourceMarketId'] as String?,
      destinationMarketId: json['destinationMarketId'] as String?,
      purchaseDate: json['purchaseDate'] as String,
      totalQuantity: (json['totalQuantity'] as num).toDouble(),
      quantityUnit: json['quantityUnit'] as String,
      purchasePricePerUnit: (json['purchasePricePerUnit'] as num).toDouble(),
      totalPurchaseCost: (json['totalPurchaseCost'] as num).toDouble(),
      status: json['status'] as String,
      transportPaidBy: json['transportPaidBy'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$$BatchModelImplToJson(_$BatchModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessId': instance.businessId,
      'productId': instance.productId,
      'batchCode': instance.batchCode,
      'sourceMarketId': instance.sourceMarketId,
      'destinationMarketId': instance.destinationMarketId,
      'purchaseDate': instance.purchaseDate,
      'totalQuantity': instance.totalQuantity,
      'quantityUnit': instance.quantityUnit,
      'purchasePricePerUnit': instance.purchasePricePerUnit,
      'totalPurchaseCost': instance.totalPurchaseCost,
      'status': instance.status,
      'transportPaidBy': instance.transportPaidBy,
      'notes': instance.notes,
      'createdAt': instance.createdAt,
    };

_$BatchCreateRequestImpl _$$BatchCreateRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$BatchCreateRequestImpl(
      businessId: json['businessId'] as String,
      productId: json['productId'] as String,
      sourceMarketId: json['sourceMarketId'] as String?,
      destinationMarketId: json['destinationMarketId'] as String?,
      purchaseDate: json['purchaseDate'] as String,
      totalQuantity: (json['totalQuantity'] as num).toDouble(),
      quantityUnit: json['quantityUnit'] as String,
      purchasePricePerUnit: (json['purchasePricePerUnit'] as num).toDouble(),
      transportPaidBy: json['transportPaidBy'] as String?,
      notes: json['notes'] as String?,
      partners: (json['partners'] as List<dynamic>?)
          ?.map((e) => BatchPartnerCreate.fromJson(e as Map<String, dynamic>))
          .toList(),
      packingRecords: (json['packingRecords'] as List<dynamic>?)
          ?.map((e) => PackingRecordCreate.fromJson(e as Map<String, dynamic>))
          .toList(),
      expenses: (json['expenses'] as List<dynamic>?)
          ?.map((e) => ExpenseCreate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$BatchCreateRequestImplToJson(
        _$BatchCreateRequestImpl instance) =>
    <String, dynamic>{
      'businessId': instance.businessId,
      'productId': instance.productId,
      'sourceMarketId': instance.sourceMarketId,
      'destinationMarketId': instance.destinationMarketId,
      'purchaseDate': instance.purchaseDate,
      'totalQuantity': instance.totalQuantity,
      'quantityUnit': instance.quantityUnit,
      'purchasePricePerUnit': instance.purchasePricePerUnit,
      'transportPaidBy': instance.transportPaidBy,
      'notes': instance.notes,
      'partners': instance.partners,
      'packingRecords': instance.packingRecords,
      'expenses': instance.expenses,
    };

_$BatchPartnerCreateImpl _$$BatchPartnerCreateImplFromJson(
        Map<String, dynamic> json) =>
    _$BatchPartnerCreateImpl(
      partnerId: json['partnerId'] as String,
      role: json['role'] as String,
      dailyChargeRate: (json['dailyChargeRate'] as num?)?.toDouble(),
      daysInvolved: (json['daysInvolved'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$BatchPartnerCreateImplToJson(
        _$BatchPartnerCreateImpl instance) =>
    <String, dynamic>{
      'partnerId': instance.partnerId,
      'role': instance.role,
      'dailyChargeRate': instance.dailyChargeRate,
      'daysInvolved': instance.daysInvolved,
    };

_$PackingRecordCreateImpl _$$PackingRecordCreateImplFromJson(
        Map<String, dynamic> json) =>
    _$PackingRecordCreateImpl(
      unitType: json['unitType'] as String,
      unitLabel: json['unitLabel'] as String?,
      unitCount: (json['unitCount'] as num).toInt(),
      costPerUnit: (json['costPerUnit'] as num).toDouble(),
    );

Map<String, dynamic> _$$PackingRecordCreateImplToJson(
        _$PackingRecordCreateImpl instance) =>
    <String, dynamic>{
      'unitType': instance.unitType,
      'unitLabel': instance.unitLabel,
      'unitCount': instance.unitCount,
      'costPerUnit': instance.costPerUnit,
    };

_$ExpenseCreateImpl _$$ExpenseCreateImplFromJson(Map<String, dynamic> json) =>
    _$ExpenseCreateImpl(
      partnerId: json['partnerId'] as String?,
      expenseSide: json['expenseSide'] as String,
      expenseType: json['expenseType'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      paidBy: json['paidBy'] as String?,
      paymentMode: json['paymentMode'] as String?,
      paymentReference: json['paymentReference'] as String?,
      expenseDate: json['expenseDate'] as String?,
    );

Map<String, dynamic> _$$ExpenseCreateImplToJson(_$ExpenseCreateImpl instance) =>
    <String, dynamic>{
      'partnerId': instance.partnerId,
      'expenseSide': instance.expenseSide,
      'expenseType': instance.expenseType,
      'amount': instance.amount,
      'description': instance.description,
      'paidBy': instance.paidBy,
      'paymentMode': instance.paymentMode,
      'paymentReference': instance.paymentReference,
      'expenseDate': instance.expenseDate,
    };
