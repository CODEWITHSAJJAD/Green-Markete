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
    this.customPermissions,
  });

  final String accessLevel;
  final String sideRole;
  final bool manageOtherSide;
  final Map<String, bool>? customPermissions;

  bool get isOwner => accessLevel == 'owner' || sideRole == 'owner';
  bool get isEditor => accessLevel == 'editor' || isOwner;
  bool get isViewer => accessLevel == 'viewer';
  bool get isAccountant => (accessLevel == 'accountant' || sideRole == 'accountant') && !isOwner;

  bool get canEditPurchaserSide {
    if (isOwner) return true;
    if (customPermissions?.containsKey('can_purchase') == true) {
      return customPermissions!['can_purchase']!;
    }
    return manageOtherSide || sideRole == 'purchaser' || sideRole == 'both';
  }

  bool get canEditSellerSide {
    if (isOwner) return true;
    if (customPermissions?.containsKey('can_sell') == true) {
      return customPermissions!['can_sell']!;
    }
    return manageOtherSide || sideRole == 'seller' || sideRole == 'both';
  }

  bool canEditSide(String side) {
    if (isOwner) return true;
    if (side == 'purchaser') return canEditPurchaserSide;
    if (side == 'seller') return canEditSellerSide;
    return false;
  }

  bool can(Capability c) {
    if (isOwner) return true;

    switch (c) {
      case Capability.createBatch:
      case Capability.recordPurchase:
      case Capability.addPacking:
        if (customPermissions?.containsKey('can_purchase') == true) {
          return customPermissions!['can_purchase']!;
        }
        if (isAccountant && !manageOtherSide) return false;
        return canEditPurchaserSide;

      case Capability.createProduct:
        if (customPermissions?.containsKey('can_purchase') == true) {
          return customPermissions!['can_purchase']!;
        }
        if (isAccountant && !manageOtherSide) return false;
        return isEditor || canEditPurchaserSide;

      case Capability.editBatch:
        if (customPermissions?.containsKey('can_close_batch') == true) {
          return customPermissions!['can_close_batch']!;
        }
        return isEditor || canEditPurchaserSide || canEditSellerSide;

      case Capability.closeBatch:
        if (customPermissions?.containsKey('can_close_batch') == true) {
          return customPermissions!['can_close_batch']!;
        }
        return isOwner || (isEditor && canEditSellerSide);

      case Capability.voidExpense:
      case Capability.archiveCustomer:
      case Capability.manageAccess:
      case Capability.viewAuditLog:
      case Capability.createPartner:
      case Capability.createMarket:
        return isOwner;

      case Capability.manageTransport:
        if (customPermissions?.containsKey('can_transport') == true) {
          return customPermissions!['can_transport']!;
        }
        if (isAccountant && !manageOtherSide) return false;
        return canEditPurchaserSide;

      case Capability.addPurchaserExpense:
      case Capability.addSellerExpense:
      case Capability.addExpense:
        if (customPermissions?.containsKey('can_expense') == true) {
          return customPermissions!['can_expense']!;
        }
        return isAccountant || canEditPurchaserSide || canEditSellerSide || isEditor;

      case Capability.recordSale:
      case Capability.createCustomer:
      case Capability.recordPayment:
        if (customPermissions?.containsKey('can_sell') == true) {
          return customPermissions!['can_sell']!;
        }
        if (isAccountant && !manageOtherSide) return false;
        return canEditSellerSide;

      case Capability.createSettlement:
        if (customPermissions?.containsKey('can_expense') == true) {
          return customPermissions!['can_expense']!;
        }
        return isAccountant || canEditSellerSide || isEditor;

      case Capability.manageSupplier:
        if (customPermissions?.containsKey('can_purchase') == true) {
          return customPermissions!['can_purchase']!;
        }
        return isAccountant || canEditPurchaserSide || isEditor;
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
