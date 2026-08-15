enum Capability {
  createBatch,
  editBatch,
  closeBatch,
  addPacking,
  addExpense,
  voidExpense,
  recordSale,
  recordPayment,
  recordPurchase,
  manageTransport,
  addPurchaserExpense,
  addSellerExpense,
  createCustomer,
  archiveCustomer,
  createPartner,
  createMarket,
  createProduct,
  createSettlement,
  manageSupplier,
  manageAccess,
  viewAuditLog,
}

/// Side-scoped capability service (multi-user RBAC).
///
/// [accessLevel] is `owner` | `editor` | `viewer` | `accountant`.
/// [sideRole] is `purchaser` | `seller` | `both` | `accountant`.
///
/// Rules (see `05_MultiUser_RBAC_Plan.md` §3.3):
/// - Owner: everything, both sides.
/// - Editor + side role: write own-side domains, read the other side.
/// - Viewer + side role: same own-side domain writes as editor, but no
///   cross-cutting writes (create batch, close, void, partner management).
/// - Accountant: read-only except financial management — expenses on both
///   sides and supplier/bill management (manageSupplier); no purchases,
///   sales, packing, transport, batch or partner operations.
/// - Cross-side write requires [manageOtherSide] (owner-set grant).
class CapabilityService {
  CapabilityService(
    this.accessLevel, {
    this.sideRole = 'both',
    this.manageOtherSide = false,
  });

  final String accessLevel;
  final String sideRole;
  final bool manageOtherSide;

  bool get isOwner => accessLevel == 'owner' || sideRole == 'owner';
  bool get isEditor => accessLevel == 'editor' || isOwner;
  bool get isViewer => accessLevel == 'viewer';
  bool get isAccountant => accessLevel == 'accountant' || sideRole == 'accountant';

  bool get canEditPurchaserSide =>
      isOwner || manageOtherSide || sideRole == 'purchaser' || sideRole == 'both';

  bool get canEditSellerSide =>
      isOwner || manageOtherSide || sideRole == 'seller' || sideRole == 'both';

  bool canEditSide(String side) {
    if (isOwner) return true;
    if (side == 'purchaser') return canEditPurchaserSide;
    if (side == 'seller') return canEditSellerSide;
    return false;
  }

  bool can(Capability c) {
    switch (c) {
      case Capability.createBatch:
      case Capability.createProduct:
        return isEditor || (canEditPurchaserSide && !isAccountant);
      case Capability.editBatch:
        return isEditor || canEditPurchaserSide || canEditSellerSide;
      case Capability.closeBatch:
        return isOwner || canEditSellerSide;
      case Capability.voidExpense:
      case Capability.archiveCustomer:
      case Capability.manageAccess:
      case Capability.viewAuditLog:
      case Capability.createPartner:
      case Capability.createMarket:
        return isOwner;
      case Capability.addPacking:
      case Capability.recordPurchase:
      case Capability.manageTransport:
        return isEditor || (canEditPurchaserSide && !isAccountant);
      case Capability.addPurchaserExpense:
        return canEditPurchaserSide || isAccountant;
      case Capability.recordSale:
        return isEditor || (canEditSellerSide && !isAccountant);
      case Capability.recordPayment:
        return canEditSellerSide || isAccountant || isEditor;
      case Capability.addSellerExpense:
        return canEditSellerSide || isAccountant;
      case Capability.addExpense:
        return canEditPurchaserSide || canEditSellerSide || isAccountant || isEditor;
      case Capability.createCustomer:
        return isEditor || canEditSellerSide;
      case Capability.createSettlement:
        return isOwner || isEditor || isAccountant || canEditSellerSide;
      case Capability.manageSupplier:
        return isOwner || isEditor || isAccountant || canEditPurchaserSide;
    }
  }
}

/// Backward-compatible role-string API. A bare role string assumes access to
/// both sides, preserving the behaviour of existing call sites.
extension RoleCapability on String {
  CapabilityService _svc() => CapabilityService(this, sideRole: 'both');

  bool get canCreateBatch => _svc().can(Capability.createBatch);
  bool get canEditBatch => _svc().can(Capability.editBatch);
  bool get canCloseBatch => _svc().can(Capability.closeBatch);
  bool get canArchiveCustomer =>
      _svc().can(Capability.archiveCustomer);
  bool get canVoidExpense => _svc().can(Capability.voidExpense);
  bool get canManageAccess => _svc().can(Capability.manageAccess);
  bool get isReadOnlyRole => this == 'viewer' || this == 'accountant';
}

String describeRole(String role) {
  switch (role) {
    case 'owner':
      return 'Owner';
    case 'editor':
      return 'Editor';
    case 'viewer':
      return 'Viewer';
    case 'accountant':
      return 'Accountant';
    default:
      return 'Member';
  }
}

String describeAccess(String? accessLevel) {
  switch (accessLevel) {
    case 'owner':
      return 'Owner';
    case 'editor':
      return 'Editor';
    case 'viewer':
      return 'Viewer';
    case 'accountant':
      return 'Accountant';
    default:
      return 'Viewer';
  }
}

String describeSide(String sideRole) {
  switch (sideRole) {
    case 'purchaser':
      return 'Purchaser';
    case 'seller':
      return 'Seller';
    case 'both':
      return 'Both sides';
    case 'accountant':
      return 'Accountant';
    default:
      return 'Member';
  }
}
