// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'batch_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BatchModel _$BatchModelFromJson(Map<String, dynamic> json) {
  return _BatchModel.fromJson(json);
}

/// @nodoc
mixin _$BatchModel {
  String get id => throw _privateConstructorUsedError;
  String get businessId => throw _privateConstructorUsedError;
  String get productId => throw _privateConstructorUsedError;
  String get batchCode => throw _privateConstructorUsedError;
  String? get sourceMarketId => throw _privateConstructorUsedError;
  String? get destinationMarketId => throw _privateConstructorUsedError;
  String get purchaseDate => throw _privateConstructorUsedError;
  double get totalQuantity => throw _privateConstructorUsedError;
  String get quantityUnit => throw _privateConstructorUsedError;
  double get purchasePricePerUnit => throw _privateConstructorUsedError;
  double get totalPurchaseCost => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get transportPaidBy => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BatchModelCopyWith<BatchModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BatchModelCopyWith<$Res> {
  factory $BatchModelCopyWith(
          BatchModel value, $Res Function(BatchModel) then) =
      _$BatchModelCopyWithImpl<$Res, BatchModel>;
  @useResult
  $Res call(
      {String id,
      String businessId,
      String productId,
      String batchCode,
      String? sourceMarketId,
      String? destinationMarketId,
      String purchaseDate,
      double totalQuantity,
      String quantityUnit,
      double purchasePricePerUnit,
      double totalPurchaseCost,
      String status,
      String? transportPaidBy,
      String? notes,
      String? createdAt});
}

/// @nodoc
class _$BatchModelCopyWithImpl<$Res, $Val extends BatchModel>
    implements $BatchModelCopyWith<$Res> {
  _$BatchModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = null,
    Object? productId = null,
    Object? batchCode = null,
    Object? sourceMarketId = freezed,
    Object? destinationMarketId = freezed,
    Object? purchaseDate = null,
    Object? totalQuantity = null,
    Object? quantityUnit = null,
    Object? purchasePricePerUnit = null,
    Object? totalPurchaseCost = null,
    Object? status = null,
    Object? transportPaidBy = freezed,
    Object? notes = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      batchCode: null == batchCode
          ? _value.batchCode
          : batchCode // ignore: cast_nullable_to_non_nullable
              as String,
      sourceMarketId: freezed == sourceMarketId
          ? _value.sourceMarketId
          : sourceMarketId // ignore: cast_nullable_to_non_nullable
              as String?,
      destinationMarketId: freezed == destinationMarketId
          ? _value.destinationMarketId
          : destinationMarketId // ignore: cast_nullable_to_non_nullable
              as String?,
      purchaseDate: null == purchaseDate
          ? _value.purchaseDate
          : purchaseDate // ignore: cast_nullable_to_non_nullable
              as String,
      totalQuantity: null == totalQuantity
          ? _value.totalQuantity
          : totalQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      quantityUnit: null == quantityUnit
          ? _value.quantityUnit
          : quantityUnit // ignore: cast_nullable_to_non_nullable
              as String,
      purchasePricePerUnit: null == purchasePricePerUnit
          ? _value.purchasePricePerUnit
          : purchasePricePerUnit // ignore: cast_nullable_to_non_nullable
              as double,
      totalPurchaseCost: null == totalPurchaseCost
          ? _value.totalPurchaseCost
          : totalPurchaseCost // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      transportPaidBy: freezed == transportPaidBy
          ? _value.transportPaidBy
          : transportPaidBy // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BatchModelImplCopyWith<$Res>
    implements $BatchModelCopyWith<$Res> {
  factory _$$BatchModelImplCopyWith(
          _$BatchModelImpl value, $Res Function(_$BatchModelImpl) then) =
      __$$BatchModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String businessId,
      String productId,
      String batchCode,
      String? sourceMarketId,
      String? destinationMarketId,
      String purchaseDate,
      double totalQuantity,
      String quantityUnit,
      double purchasePricePerUnit,
      double totalPurchaseCost,
      String status,
      String? transportPaidBy,
      String? notes,
      String? createdAt});
}

/// @nodoc
class __$$BatchModelImplCopyWithImpl<$Res>
    extends _$BatchModelCopyWithImpl<$Res, _$BatchModelImpl>
    implements _$$BatchModelImplCopyWith<$Res> {
  __$$BatchModelImplCopyWithImpl(
      _$BatchModelImpl _value, $Res Function(_$BatchModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? businessId = null,
    Object? productId = null,
    Object? batchCode = null,
    Object? sourceMarketId = freezed,
    Object? destinationMarketId = freezed,
    Object? purchaseDate = null,
    Object? totalQuantity = null,
    Object? quantityUnit = null,
    Object? purchasePricePerUnit = null,
    Object? totalPurchaseCost = null,
    Object? status = null,
    Object? transportPaidBy = freezed,
    Object? notes = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$BatchModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      batchCode: null == batchCode
          ? _value.batchCode
          : batchCode // ignore: cast_nullable_to_non_nullable
              as String,
      sourceMarketId: freezed == sourceMarketId
          ? _value.sourceMarketId
          : sourceMarketId // ignore: cast_nullable_to_non_nullable
              as String?,
      destinationMarketId: freezed == destinationMarketId
          ? _value.destinationMarketId
          : destinationMarketId // ignore: cast_nullable_to_non_nullable
              as String?,
      purchaseDate: null == purchaseDate
          ? _value.purchaseDate
          : purchaseDate // ignore: cast_nullable_to_non_nullable
              as String,
      totalQuantity: null == totalQuantity
          ? _value.totalQuantity
          : totalQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      quantityUnit: null == quantityUnit
          ? _value.quantityUnit
          : quantityUnit // ignore: cast_nullable_to_non_nullable
              as String,
      purchasePricePerUnit: null == purchasePricePerUnit
          ? _value.purchasePricePerUnit
          : purchasePricePerUnit // ignore: cast_nullable_to_non_nullable
              as double,
      totalPurchaseCost: null == totalPurchaseCost
          ? _value.totalPurchaseCost
          : totalPurchaseCost // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      transportPaidBy: freezed == transportPaidBy
          ? _value.transportPaidBy
          : transportPaidBy // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BatchModelImpl implements _BatchModel {
  const _$BatchModelImpl(
      {required this.id,
      required this.businessId,
      required this.productId,
      required this.batchCode,
      this.sourceMarketId,
      this.destinationMarketId,
      required this.purchaseDate,
      required this.totalQuantity,
      required this.quantityUnit,
      required this.purchasePricePerUnit,
      required this.totalPurchaseCost,
      required this.status,
      this.transportPaidBy,
      this.notes,
      this.createdAt});

  factory _$BatchModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BatchModelImplFromJson(json);

  @override
  final String id;
  @override
  final String businessId;
  @override
  final String productId;
  @override
  final String batchCode;
  @override
  final String? sourceMarketId;
  @override
  final String? destinationMarketId;
  @override
  final String purchaseDate;
  @override
  final double totalQuantity;
  @override
  final String quantityUnit;
  @override
  final double purchasePricePerUnit;
  @override
  final double totalPurchaseCost;
  @override
  final String status;
  @override
  final String? transportPaidBy;
  @override
  final String? notes;
  @override
  final String? createdAt;

  @override
  String toString() {
    return 'BatchModel(id: $id, businessId: $businessId, productId: $productId, batchCode: $batchCode, sourceMarketId: $sourceMarketId, destinationMarketId: $destinationMarketId, purchaseDate: $purchaseDate, totalQuantity: $totalQuantity, quantityUnit: $quantityUnit, purchasePricePerUnit: $purchasePricePerUnit, totalPurchaseCost: $totalPurchaseCost, status: $status, transportPaidBy: $transportPaidBy, notes: $notes, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BatchModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.batchCode, batchCode) ||
                other.batchCode == batchCode) &&
            (identical(other.sourceMarketId, sourceMarketId) ||
                other.sourceMarketId == sourceMarketId) &&
            (identical(other.destinationMarketId, destinationMarketId) ||
                other.destinationMarketId == destinationMarketId) &&
            (identical(other.purchaseDate, purchaseDate) ||
                other.purchaseDate == purchaseDate) &&
            (identical(other.totalQuantity, totalQuantity) ||
                other.totalQuantity == totalQuantity) &&
            (identical(other.quantityUnit, quantityUnit) ||
                other.quantityUnit == quantityUnit) &&
            (identical(other.purchasePricePerUnit, purchasePricePerUnit) ||
                other.purchasePricePerUnit == purchasePricePerUnit) &&
            (identical(other.totalPurchaseCost, totalPurchaseCost) ||
                other.totalPurchaseCost == totalPurchaseCost) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.transportPaidBy, transportPaidBy) ||
                other.transportPaidBy == transportPaidBy) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      businessId,
      productId,
      batchCode,
      sourceMarketId,
      destinationMarketId,
      purchaseDate,
      totalQuantity,
      quantityUnit,
      purchasePricePerUnit,
      totalPurchaseCost,
      status,
      transportPaidBy,
      notes,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BatchModelImplCopyWith<_$BatchModelImpl> get copyWith =>
      __$$BatchModelImplCopyWithImpl<_$BatchModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BatchModelImplToJson(
      this,
    );
  }
}

abstract class _BatchModel implements BatchModel {
  const factory _BatchModel(
      {required final String id,
      required final String businessId,
      required final String productId,
      required final String batchCode,
      final String? sourceMarketId,
      final String? destinationMarketId,
      required final String purchaseDate,
      required final double totalQuantity,
      required final String quantityUnit,
      required final double purchasePricePerUnit,
      required final double totalPurchaseCost,
      required final String status,
      final String? transportPaidBy,
      final String? notes,
      final String? createdAt}) = _$BatchModelImpl;

  factory _BatchModel.fromJson(Map<String, dynamic> json) =
      _$BatchModelImpl.fromJson;

  @override
  String get id;
  @override
  String get businessId;
  @override
  String get productId;
  @override
  String get batchCode;
  @override
  String? get sourceMarketId;
  @override
  String? get destinationMarketId;
  @override
  String get purchaseDate;
  @override
  double get totalQuantity;
  @override
  String get quantityUnit;
  @override
  double get purchasePricePerUnit;
  @override
  double get totalPurchaseCost;
  @override
  String get status;
  @override
  String? get transportPaidBy;
  @override
  String? get notes;
  @override
  String? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$BatchModelImplCopyWith<_$BatchModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BatchCreateRequest _$BatchCreateRequestFromJson(Map<String, dynamic> json) {
  return _BatchCreateRequest.fromJson(json);
}

/// @nodoc
mixin _$BatchCreateRequest {
  String get businessId => throw _privateConstructorUsedError;
  String get productId => throw _privateConstructorUsedError;
  String? get sourceMarketId => throw _privateConstructorUsedError;
  String? get destinationMarketId => throw _privateConstructorUsedError;
  String get purchaseDate => throw _privateConstructorUsedError;
  double get totalQuantity => throw _privateConstructorUsedError;
  String get quantityUnit => throw _privateConstructorUsedError;
  double get purchasePricePerUnit => throw _privateConstructorUsedError;
  String? get transportPaidBy => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  List<BatchPartnerCreate>? get partners => throw _privateConstructorUsedError;
  List<PackingRecordCreate>? get packingRecords =>
      throw _privateConstructorUsedError;
  List<ExpenseCreate>? get expenses => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BatchCreateRequestCopyWith<BatchCreateRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BatchCreateRequestCopyWith<$Res> {
  factory $BatchCreateRequestCopyWith(
          BatchCreateRequest value, $Res Function(BatchCreateRequest) then) =
      _$BatchCreateRequestCopyWithImpl<$Res, BatchCreateRequest>;
  @useResult
  $Res call(
      {String businessId,
      String productId,
      String? sourceMarketId,
      String? destinationMarketId,
      String purchaseDate,
      double totalQuantity,
      String quantityUnit,
      double purchasePricePerUnit,
      String? transportPaidBy,
      String? notes,
      List<BatchPartnerCreate>? partners,
      List<PackingRecordCreate>? packingRecords,
      List<ExpenseCreate>? expenses});
}

/// @nodoc
class _$BatchCreateRequestCopyWithImpl<$Res, $Val extends BatchCreateRequest>
    implements $BatchCreateRequestCopyWith<$Res> {
  _$BatchCreateRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? businessId = null,
    Object? productId = null,
    Object? sourceMarketId = freezed,
    Object? destinationMarketId = freezed,
    Object? purchaseDate = null,
    Object? totalQuantity = null,
    Object? quantityUnit = null,
    Object? purchasePricePerUnit = null,
    Object? transportPaidBy = freezed,
    Object? notes = freezed,
    Object? partners = freezed,
    Object? packingRecords = freezed,
    Object? expenses = freezed,
  }) {
    return _then(_value.copyWith(
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      sourceMarketId: freezed == sourceMarketId
          ? _value.sourceMarketId
          : sourceMarketId // ignore: cast_nullable_to_non_nullable
              as String?,
      destinationMarketId: freezed == destinationMarketId
          ? _value.destinationMarketId
          : destinationMarketId // ignore: cast_nullable_to_non_nullable
              as String?,
      purchaseDate: null == purchaseDate
          ? _value.purchaseDate
          : purchaseDate // ignore: cast_nullable_to_non_nullable
              as String,
      totalQuantity: null == totalQuantity
          ? _value.totalQuantity
          : totalQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      quantityUnit: null == quantityUnit
          ? _value.quantityUnit
          : quantityUnit // ignore: cast_nullable_to_non_nullable
              as String,
      purchasePricePerUnit: null == purchasePricePerUnit
          ? _value.purchasePricePerUnit
          : purchasePricePerUnit // ignore: cast_nullable_to_non_nullable
              as double,
      transportPaidBy: freezed == transportPaidBy
          ? _value.transportPaidBy
          : transportPaidBy // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      partners: freezed == partners
          ? _value.partners
          : partners // ignore: cast_nullable_to_non_nullable
              as List<BatchPartnerCreate>?,
      packingRecords: freezed == packingRecords
          ? _value.packingRecords
          : packingRecords // ignore: cast_nullable_to_non_nullable
              as List<PackingRecordCreate>?,
      expenses: freezed == expenses
          ? _value.expenses
          : expenses // ignore: cast_nullable_to_non_nullable
              as List<ExpenseCreate>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BatchCreateRequestImplCopyWith<$Res>
    implements $BatchCreateRequestCopyWith<$Res> {
  factory _$$BatchCreateRequestImplCopyWith(_$BatchCreateRequestImpl value,
          $Res Function(_$BatchCreateRequestImpl) then) =
      __$$BatchCreateRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String businessId,
      String productId,
      String? sourceMarketId,
      String? destinationMarketId,
      String purchaseDate,
      double totalQuantity,
      String quantityUnit,
      double purchasePricePerUnit,
      String? transportPaidBy,
      String? notes,
      List<BatchPartnerCreate>? partners,
      List<PackingRecordCreate>? packingRecords,
      List<ExpenseCreate>? expenses});
}

/// @nodoc
class __$$BatchCreateRequestImplCopyWithImpl<$Res>
    extends _$BatchCreateRequestCopyWithImpl<$Res, _$BatchCreateRequestImpl>
    implements _$$BatchCreateRequestImplCopyWith<$Res> {
  __$$BatchCreateRequestImplCopyWithImpl(_$BatchCreateRequestImpl _value,
      $Res Function(_$BatchCreateRequestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? businessId = null,
    Object? productId = null,
    Object? sourceMarketId = freezed,
    Object? destinationMarketId = freezed,
    Object? purchaseDate = null,
    Object? totalQuantity = null,
    Object? quantityUnit = null,
    Object? purchasePricePerUnit = null,
    Object? transportPaidBy = freezed,
    Object? notes = freezed,
    Object? partners = freezed,
    Object? packingRecords = freezed,
    Object? expenses = freezed,
  }) {
    return _then(_$BatchCreateRequestImpl(
      businessId: null == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as String,
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      sourceMarketId: freezed == sourceMarketId
          ? _value.sourceMarketId
          : sourceMarketId // ignore: cast_nullable_to_non_nullable
              as String?,
      destinationMarketId: freezed == destinationMarketId
          ? _value.destinationMarketId
          : destinationMarketId // ignore: cast_nullable_to_non_nullable
              as String?,
      purchaseDate: null == purchaseDate
          ? _value.purchaseDate
          : purchaseDate // ignore: cast_nullable_to_non_nullable
              as String,
      totalQuantity: null == totalQuantity
          ? _value.totalQuantity
          : totalQuantity // ignore: cast_nullable_to_non_nullable
              as double,
      quantityUnit: null == quantityUnit
          ? _value.quantityUnit
          : quantityUnit // ignore: cast_nullable_to_non_nullable
              as String,
      purchasePricePerUnit: null == purchasePricePerUnit
          ? _value.purchasePricePerUnit
          : purchasePricePerUnit // ignore: cast_nullable_to_non_nullable
              as double,
      transportPaidBy: freezed == transportPaidBy
          ? _value.transportPaidBy
          : transportPaidBy // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      partners: freezed == partners
          ? _value._partners
          : partners // ignore: cast_nullable_to_non_nullable
              as List<BatchPartnerCreate>?,
      packingRecords: freezed == packingRecords
          ? _value._packingRecords
          : packingRecords // ignore: cast_nullable_to_non_nullable
              as List<PackingRecordCreate>?,
      expenses: freezed == expenses
          ? _value._expenses
          : expenses // ignore: cast_nullable_to_non_nullable
              as List<ExpenseCreate>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BatchCreateRequestImpl implements _BatchCreateRequest {
  const _$BatchCreateRequestImpl(
      {required this.businessId,
      required this.productId,
      this.sourceMarketId,
      this.destinationMarketId,
      required this.purchaseDate,
      required this.totalQuantity,
      required this.quantityUnit,
      required this.purchasePricePerUnit,
      this.transportPaidBy,
      this.notes,
      final List<BatchPartnerCreate>? partners,
      final List<PackingRecordCreate>? packingRecords,
      final List<ExpenseCreate>? expenses})
      : _partners = partners,
        _packingRecords = packingRecords,
        _expenses = expenses;

  factory _$BatchCreateRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$BatchCreateRequestImplFromJson(json);

  @override
  final String businessId;
  @override
  final String productId;
  @override
  final String? sourceMarketId;
  @override
  final String? destinationMarketId;
  @override
  final String purchaseDate;
  @override
  final double totalQuantity;
  @override
  final String quantityUnit;
  @override
  final double purchasePricePerUnit;
  @override
  final String? transportPaidBy;
  @override
  final String? notes;
  final List<BatchPartnerCreate>? _partners;
  @override
  List<BatchPartnerCreate>? get partners {
    final value = _partners;
    if (value == null) return null;
    if (_partners is EqualUnmodifiableListView) return _partners;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<PackingRecordCreate>? _packingRecords;
  @override
  List<PackingRecordCreate>? get packingRecords {
    final value = _packingRecords;
    if (value == null) return null;
    if (_packingRecords is EqualUnmodifiableListView) return _packingRecords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<ExpenseCreate>? _expenses;
  @override
  List<ExpenseCreate>? get expenses {
    final value = _expenses;
    if (value == null) return null;
    if (_expenses is EqualUnmodifiableListView) return _expenses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'BatchCreateRequest(businessId: $businessId, productId: $productId, sourceMarketId: $sourceMarketId, destinationMarketId: $destinationMarketId, purchaseDate: $purchaseDate, totalQuantity: $totalQuantity, quantityUnit: $quantityUnit, purchasePricePerUnit: $purchasePricePerUnit, transportPaidBy: $transportPaidBy, notes: $notes, partners: $partners, packingRecords: $packingRecords, expenses: $expenses)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BatchCreateRequestImpl &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.sourceMarketId, sourceMarketId) ||
                other.sourceMarketId == sourceMarketId) &&
            (identical(other.destinationMarketId, destinationMarketId) ||
                other.destinationMarketId == destinationMarketId) &&
            (identical(other.purchaseDate, purchaseDate) ||
                other.purchaseDate == purchaseDate) &&
            (identical(other.totalQuantity, totalQuantity) ||
                other.totalQuantity == totalQuantity) &&
            (identical(other.quantityUnit, quantityUnit) ||
                other.quantityUnit == quantityUnit) &&
            (identical(other.purchasePricePerUnit, purchasePricePerUnit) ||
                other.purchasePricePerUnit == purchasePricePerUnit) &&
            (identical(other.transportPaidBy, transportPaidBy) ||
                other.transportPaidBy == transportPaidBy) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality().equals(other._partners, _partners) &&
            const DeepCollectionEquality()
                .equals(other._packingRecords, _packingRecords) &&
            const DeepCollectionEquality().equals(other._expenses, _expenses));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      businessId,
      productId,
      sourceMarketId,
      destinationMarketId,
      purchaseDate,
      totalQuantity,
      quantityUnit,
      purchasePricePerUnit,
      transportPaidBy,
      notes,
      const DeepCollectionEquality().hash(_partners),
      const DeepCollectionEquality().hash(_packingRecords),
      const DeepCollectionEquality().hash(_expenses));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BatchCreateRequestImplCopyWith<_$BatchCreateRequestImpl> get copyWith =>
      __$$BatchCreateRequestImplCopyWithImpl<_$BatchCreateRequestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BatchCreateRequestImplToJson(
      this,
    );
  }
}

abstract class _BatchCreateRequest implements BatchCreateRequest {
  const factory _BatchCreateRequest(
      {required final String businessId,
      required final String productId,
      final String? sourceMarketId,
      final String? destinationMarketId,
      required final String purchaseDate,
      required final double totalQuantity,
      required final String quantityUnit,
      required final double purchasePricePerUnit,
      final String? transportPaidBy,
      final String? notes,
      final List<BatchPartnerCreate>? partners,
      final List<PackingRecordCreate>? packingRecords,
      final List<ExpenseCreate>? expenses}) = _$BatchCreateRequestImpl;

  factory _BatchCreateRequest.fromJson(Map<String, dynamic> json) =
      _$BatchCreateRequestImpl.fromJson;

  @override
  String get businessId;
  @override
  String get productId;
  @override
  String? get sourceMarketId;
  @override
  String? get destinationMarketId;
  @override
  String get purchaseDate;
  @override
  double get totalQuantity;
  @override
  String get quantityUnit;
  @override
  double get purchasePricePerUnit;
  @override
  String? get transportPaidBy;
  @override
  String? get notes;
  @override
  List<BatchPartnerCreate>? get partners;
  @override
  List<PackingRecordCreate>? get packingRecords;
  @override
  List<ExpenseCreate>? get expenses;
  @override
  @JsonKey(ignore: true)
  _$$BatchCreateRequestImplCopyWith<_$BatchCreateRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BatchPartnerCreate _$BatchPartnerCreateFromJson(Map<String, dynamic> json) {
  return _BatchPartnerCreate.fromJson(json);
}

/// @nodoc
mixin _$BatchPartnerCreate {
  String get partnerId => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  double? get dailyChargeRate => throw _privateConstructorUsedError;
  int? get daysInvolved => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BatchPartnerCreateCopyWith<BatchPartnerCreate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BatchPartnerCreateCopyWith<$Res> {
  factory $BatchPartnerCreateCopyWith(
          BatchPartnerCreate value, $Res Function(BatchPartnerCreate) then) =
      _$BatchPartnerCreateCopyWithImpl<$Res, BatchPartnerCreate>;
  @useResult
  $Res call(
      {String partnerId,
      String role,
      double? dailyChargeRate,
      int? daysInvolved});
}

/// @nodoc
class _$BatchPartnerCreateCopyWithImpl<$Res, $Val extends BatchPartnerCreate>
    implements $BatchPartnerCreateCopyWith<$Res> {
  _$BatchPartnerCreateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? partnerId = null,
    Object? role = null,
    Object? dailyChargeRate = freezed,
    Object? daysInvolved = freezed,
  }) {
    return _then(_value.copyWith(
      partnerId: null == partnerId
          ? _value.partnerId
          : partnerId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      dailyChargeRate: freezed == dailyChargeRate
          ? _value.dailyChargeRate
          : dailyChargeRate // ignore: cast_nullable_to_non_nullable
              as double?,
      daysInvolved: freezed == daysInvolved
          ? _value.daysInvolved
          : daysInvolved // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BatchPartnerCreateImplCopyWith<$Res>
    implements $BatchPartnerCreateCopyWith<$Res> {
  factory _$$BatchPartnerCreateImplCopyWith(_$BatchPartnerCreateImpl value,
          $Res Function(_$BatchPartnerCreateImpl) then) =
      __$$BatchPartnerCreateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String partnerId,
      String role,
      double? dailyChargeRate,
      int? daysInvolved});
}

/// @nodoc
class __$$BatchPartnerCreateImplCopyWithImpl<$Res>
    extends _$BatchPartnerCreateCopyWithImpl<$Res, _$BatchPartnerCreateImpl>
    implements _$$BatchPartnerCreateImplCopyWith<$Res> {
  __$$BatchPartnerCreateImplCopyWithImpl(_$BatchPartnerCreateImpl _value,
      $Res Function(_$BatchPartnerCreateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? partnerId = null,
    Object? role = null,
    Object? dailyChargeRate = freezed,
    Object? daysInvolved = freezed,
  }) {
    return _then(_$BatchPartnerCreateImpl(
      partnerId: null == partnerId
          ? _value.partnerId
          : partnerId // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      dailyChargeRate: freezed == dailyChargeRate
          ? _value.dailyChargeRate
          : dailyChargeRate // ignore: cast_nullable_to_non_nullable
              as double?,
      daysInvolved: freezed == daysInvolved
          ? _value.daysInvolved
          : daysInvolved // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BatchPartnerCreateImpl implements _BatchPartnerCreate {
  const _$BatchPartnerCreateImpl(
      {required this.partnerId,
      required this.role,
      this.dailyChargeRate,
      this.daysInvolved});

  factory _$BatchPartnerCreateImpl.fromJson(Map<String, dynamic> json) =>
      _$$BatchPartnerCreateImplFromJson(json);

  @override
  final String partnerId;
  @override
  final String role;
  @override
  final double? dailyChargeRate;
  @override
  final int? daysInvolved;

  @override
  String toString() {
    return 'BatchPartnerCreate(partnerId: $partnerId, role: $role, dailyChargeRate: $dailyChargeRate, daysInvolved: $daysInvolved)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BatchPartnerCreateImpl &&
            (identical(other.partnerId, partnerId) ||
                other.partnerId == partnerId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.dailyChargeRate, dailyChargeRate) ||
                other.dailyChargeRate == dailyChargeRate) &&
            (identical(other.daysInvolved, daysInvolved) ||
                other.daysInvolved == daysInvolved));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, partnerId, role, dailyChargeRate, daysInvolved);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BatchPartnerCreateImplCopyWith<_$BatchPartnerCreateImpl> get copyWith =>
      __$$BatchPartnerCreateImplCopyWithImpl<_$BatchPartnerCreateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BatchPartnerCreateImplToJson(
      this,
    );
  }
}

abstract class _BatchPartnerCreate implements BatchPartnerCreate {
  const factory _BatchPartnerCreate(
      {required final String partnerId,
      required final String role,
      final double? dailyChargeRate,
      final int? daysInvolved}) = _$BatchPartnerCreateImpl;

  factory _BatchPartnerCreate.fromJson(Map<String, dynamic> json) =
      _$BatchPartnerCreateImpl.fromJson;

  @override
  String get partnerId;
  @override
  String get role;
  @override
  double? get dailyChargeRate;
  @override
  int? get daysInvolved;
  @override
  @JsonKey(ignore: true)
  _$$BatchPartnerCreateImplCopyWith<_$BatchPartnerCreateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PackingRecordCreate _$PackingRecordCreateFromJson(Map<String, dynamic> json) {
  return _PackingRecordCreate.fromJson(json);
}

/// @nodoc
mixin _$PackingRecordCreate {
  String get unitType => throw _privateConstructorUsedError;
  String? get unitLabel => throw _privateConstructorUsedError;
  int get unitCount => throw _privateConstructorUsedError;
  double get costPerUnit => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PackingRecordCreateCopyWith<PackingRecordCreate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PackingRecordCreateCopyWith<$Res> {
  factory $PackingRecordCreateCopyWith(
          PackingRecordCreate value, $Res Function(PackingRecordCreate) then) =
      _$PackingRecordCreateCopyWithImpl<$Res, PackingRecordCreate>;
  @useResult
  $Res call(
      {String unitType, String? unitLabel, int unitCount, double costPerUnit});
}

/// @nodoc
class _$PackingRecordCreateCopyWithImpl<$Res, $Val extends PackingRecordCreate>
    implements $PackingRecordCreateCopyWith<$Res> {
  _$PackingRecordCreateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unitType = null,
    Object? unitLabel = freezed,
    Object? unitCount = null,
    Object? costPerUnit = null,
  }) {
    return _then(_value.copyWith(
      unitType: null == unitType
          ? _value.unitType
          : unitType // ignore: cast_nullable_to_non_nullable
              as String,
      unitLabel: freezed == unitLabel
          ? _value.unitLabel
          : unitLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      unitCount: null == unitCount
          ? _value.unitCount
          : unitCount // ignore: cast_nullable_to_non_nullable
              as int,
      costPerUnit: null == costPerUnit
          ? _value.costPerUnit
          : costPerUnit // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PackingRecordCreateImplCopyWith<$Res>
    implements $PackingRecordCreateCopyWith<$Res> {
  factory _$$PackingRecordCreateImplCopyWith(_$PackingRecordCreateImpl value,
          $Res Function(_$PackingRecordCreateImpl) then) =
      __$$PackingRecordCreateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String unitType, String? unitLabel, int unitCount, double costPerUnit});
}

/// @nodoc
class __$$PackingRecordCreateImplCopyWithImpl<$Res>
    extends _$PackingRecordCreateCopyWithImpl<$Res, _$PackingRecordCreateImpl>
    implements _$$PackingRecordCreateImplCopyWith<$Res> {
  __$$PackingRecordCreateImplCopyWithImpl(_$PackingRecordCreateImpl _value,
      $Res Function(_$PackingRecordCreateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? unitType = null,
    Object? unitLabel = freezed,
    Object? unitCount = null,
    Object? costPerUnit = null,
  }) {
    return _then(_$PackingRecordCreateImpl(
      unitType: null == unitType
          ? _value.unitType
          : unitType // ignore: cast_nullable_to_non_nullable
              as String,
      unitLabel: freezed == unitLabel
          ? _value.unitLabel
          : unitLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      unitCount: null == unitCount
          ? _value.unitCount
          : unitCount // ignore: cast_nullable_to_non_nullable
              as int,
      costPerUnit: null == costPerUnit
          ? _value.costPerUnit
          : costPerUnit // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PackingRecordCreateImpl implements _PackingRecordCreate {
  const _$PackingRecordCreateImpl(
      {required this.unitType,
      this.unitLabel,
      required this.unitCount,
      required this.costPerUnit});

  factory _$PackingRecordCreateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PackingRecordCreateImplFromJson(json);

  @override
  final String unitType;
  @override
  final String? unitLabel;
  @override
  final int unitCount;
  @override
  final double costPerUnit;

  @override
  String toString() {
    return 'PackingRecordCreate(unitType: $unitType, unitLabel: $unitLabel, unitCount: $unitCount, costPerUnit: $costPerUnit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PackingRecordCreateImpl &&
            (identical(other.unitType, unitType) ||
                other.unitType == unitType) &&
            (identical(other.unitLabel, unitLabel) ||
                other.unitLabel == unitLabel) &&
            (identical(other.unitCount, unitCount) ||
                other.unitCount == unitCount) &&
            (identical(other.costPerUnit, costPerUnit) ||
                other.costPerUnit == costPerUnit));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, unitType, unitLabel, unitCount, costPerUnit);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PackingRecordCreateImplCopyWith<_$PackingRecordCreateImpl> get copyWith =>
      __$$PackingRecordCreateImplCopyWithImpl<_$PackingRecordCreateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PackingRecordCreateImplToJson(
      this,
    );
  }
}

abstract class _PackingRecordCreate implements PackingRecordCreate {
  const factory _PackingRecordCreate(
      {required final String unitType,
      final String? unitLabel,
      required final int unitCount,
      required final double costPerUnit}) = _$PackingRecordCreateImpl;

  factory _PackingRecordCreate.fromJson(Map<String, dynamic> json) =
      _$PackingRecordCreateImpl.fromJson;

  @override
  String get unitType;
  @override
  String? get unitLabel;
  @override
  int get unitCount;
  @override
  double get costPerUnit;
  @override
  @JsonKey(ignore: true)
  _$$PackingRecordCreateImplCopyWith<_$PackingRecordCreateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExpenseCreate _$ExpenseCreateFromJson(Map<String, dynamic> json) {
  return _ExpenseCreate.fromJson(json);
}

/// @nodoc
mixin _$ExpenseCreate {
  String? get partnerId => throw _privateConstructorUsedError;
  String get expenseSide => throw _privateConstructorUsedError;
  String get expenseType => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get paidBy => throw _privateConstructorUsedError;
  String? get paymentMode => throw _privateConstructorUsedError;
  String? get paymentReference => throw _privateConstructorUsedError;
  String? get expenseDate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExpenseCreateCopyWith<ExpenseCreate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExpenseCreateCopyWith<$Res> {
  factory $ExpenseCreateCopyWith(
          ExpenseCreate value, $Res Function(ExpenseCreate) then) =
      _$ExpenseCreateCopyWithImpl<$Res, ExpenseCreate>;
  @useResult
  $Res call(
      {String? partnerId,
      String expenseSide,
      String expenseType,
      double amount,
      String? description,
      String? paidBy,
      String? paymentMode,
      String? paymentReference,
      String? expenseDate});
}

/// @nodoc
class _$ExpenseCreateCopyWithImpl<$Res, $Val extends ExpenseCreate>
    implements $ExpenseCreateCopyWith<$Res> {
  _$ExpenseCreateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? partnerId = freezed,
    Object? expenseSide = null,
    Object? expenseType = null,
    Object? amount = null,
    Object? description = freezed,
    Object? paidBy = freezed,
    Object? paymentMode = freezed,
    Object? paymentReference = freezed,
    Object? expenseDate = freezed,
  }) {
    return _then(_value.copyWith(
      partnerId: freezed == partnerId
          ? _value.partnerId
          : partnerId // ignore: cast_nullable_to_non_nullable
              as String?,
      expenseSide: null == expenseSide
          ? _value.expenseSide
          : expenseSide // ignore: cast_nullable_to_non_nullable
              as String,
      expenseType: null == expenseType
          ? _value.expenseType
          : expenseType // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      paidBy: freezed == paidBy
          ? _value.paidBy
          : paidBy // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentMode: freezed == paymentMode
          ? _value.paymentMode
          : paymentMode // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentReference: freezed == paymentReference
          ? _value.paymentReference
          : paymentReference // ignore: cast_nullable_to_non_nullable
              as String?,
      expenseDate: freezed == expenseDate
          ? _value.expenseDate
          : expenseDate // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExpenseCreateImplCopyWith<$Res>
    implements $ExpenseCreateCopyWith<$Res> {
  factory _$$ExpenseCreateImplCopyWith(
          _$ExpenseCreateImpl value, $Res Function(_$ExpenseCreateImpl) then) =
      __$$ExpenseCreateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? partnerId,
      String expenseSide,
      String expenseType,
      double amount,
      String? description,
      String? paidBy,
      String? paymentMode,
      String? paymentReference,
      String? expenseDate});
}

/// @nodoc
class __$$ExpenseCreateImplCopyWithImpl<$Res>
    extends _$ExpenseCreateCopyWithImpl<$Res, _$ExpenseCreateImpl>
    implements _$$ExpenseCreateImplCopyWith<$Res> {
  __$$ExpenseCreateImplCopyWithImpl(
      _$ExpenseCreateImpl _value, $Res Function(_$ExpenseCreateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? partnerId = freezed,
    Object? expenseSide = null,
    Object? expenseType = null,
    Object? amount = null,
    Object? description = freezed,
    Object? paidBy = freezed,
    Object? paymentMode = freezed,
    Object? paymentReference = freezed,
    Object? expenseDate = freezed,
  }) {
    return _then(_$ExpenseCreateImpl(
      partnerId: freezed == partnerId
          ? _value.partnerId
          : partnerId // ignore: cast_nullable_to_non_nullable
              as String?,
      expenseSide: null == expenseSide
          ? _value.expenseSide
          : expenseSide // ignore: cast_nullable_to_non_nullable
              as String,
      expenseType: null == expenseType
          ? _value.expenseType
          : expenseType // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      paidBy: freezed == paidBy
          ? _value.paidBy
          : paidBy // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentMode: freezed == paymentMode
          ? _value.paymentMode
          : paymentMode // ignore: cast_nullable_to_non_nullable
              as String?,
      paymentReference: freezed == paymentReference
          ? _value.paymentReference
          : paymentReference // ignore: cast_nullable_to_non_nullable
              as String?,
      expenseDate: freezed == expenseDate
          ? _value.expenseDate
          : expenseDate // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExpenseCreateImpl implements _ExpenseCreate {
  const _$ExpenseCreateImpl(
      {this.partnerId,
      required this.expenseSide,
      required this.expenseType,
      required this.amount,
      this.description,
      this.paidBy,
      this.paymentMode,
      this.paymentReference,
      this.expenseDate});

  factory _$ExpenseCreateImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExpenseCreateImplFromJson(json);

  @override
  final String? partnerId;
  @override
  final String expenseSide;
  @override
  final String expenseType;
  @override
  final double amount;
  @override
  final String? description;
  @override
  final String? paidBy;
  @override
  final String? paymentMode;
  @override
  final String? paymentReference;
  @override
  final String? expenseDate;

  @override
  String toString() {
    return 'ExpenseCreate(partnerId: $partnerId, expenseSide: $expenseSide, expenseType: $expenseType, amount: $amount, description: $description, paidBy: $paidBy, paymentMode: $paymentMode, paymentReference: $paymentReference, expenseDate: $expenseDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExpenseCreateImpl &&
            (identical(other.partnerId, partnerId) ||
                other.partnerId == partnerId) &&
            (identical(other.expenseSide, expenseSide) ||
                other.expenseSide == expenseSide) &&
            (identical(other.expenseType, expenseType) ||
                other.expenseType == expenseType) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.paidBy, paidBy) || other.paidBy == paidBy) &&
            (identical(other.paymentMode, paymentMode) ||
                other.paymentMode == paymentMode) &&
            (identical(other.paymentReference, paymentReference) ||
                other.paymentReference == paymentReference) &&
            (identical(other.expenseDate, expenseDate) ||
                other.expenseDate == expenseDate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      partnerId,
      expenseSide,
      expenseType,
      amount,
      description,
      paidBy,
      paymentMode,
      paymentReference,
      expenseDate);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExpenseCreateImplCopyWith<_$ExpenseCreateImpl> get copyWith =>
      __$$ExpenseCreateImplCopyWithImpl<_$ExpenseCreateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExpenseCreateImplToJson(
      this,
    );
  }
}

abstract class _ExpenseCreate implements ExpenseCreate {
  const factory _ExpenseCreate(
      {final String? partnerId,
      required final String expenseSide,
      required final String expenseType,
      required final double amount,
      final String? description,
      final String? paidBy,
      final String? paymentMode,
      final String? paymentReference,
      final String? expenseDate}) = _$ExpenseCreateImpl;

  factory _ExpenseCreate.fromJson(Map<String, dynamic> json) =
      _$ExpenseCreateImpl.fromJson;

  @override
  String? get partnerId;
  @override
  String get expenseSide;
  @override
  String get expenseType;
  @override
  double get amount;
  @override
  String? get description;
  @override
  String? get paidBy;
  @override
  String? get paymentMode;
  @override
  String? get paymentReference;
  @override
  String? get expenseDate;
  @override
  @JsonKey(ignore: true)
  _$$ExpenseCreateImplCopyWith<_$ExpenseCreateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
