enum Capability {
  createBatch,
  editBatch,
  closeBatch,
  addPacking,
  addExpense,
  voidExpense,
  recordSale,
  recordPayment,
  createCustomer,
  archiveCustomer,
  createPartner,
  createMarket,
  createProduct,
  createSettlement,
  manageAccess,
  viewAuditLog,
}

class CapabilityService {
  CapabilityService(this.role);

  final String role;

  bool _isOwner() => role == 'owner';
  bool _isEditor() => role == 'editor' || _isOwner();

  bool can(Capability c) {
    switch (c) {
      case Capability.createBatch:
      case Capability.editBatch:
      case Capability.addPacking:
      case Capability.addExpense:
      case Capability.recordSale:
      case Capability.recordPayment:
      case Capability.createPartner:
      case Capability.createMarket:
      case Capability.createProduct:
      case Capability.createSettlement:
      case Capability.createCustomer:
        return _isEditor();
      case Capability.archiveCustomer:
      case Capability.voidExpense:
      case Capability.closeBatch:
      case Capability.manageAccess:
      case Capability.viewAuditLog:
        return _isOwner();
    }
  }
}

extension RoleCapability on String {
  bool get canCreateBatch => CapabilityService(this).can(Capability.createBatch);
  bool get canEditBatch => CapabilityService(this).can(Capability.editBatch);
  bool get canCloseBatch => CapabilityService(this).can(Capability.closeBatch);
  bool get canArchiveCustomer =>
      CapabilityService(this).can(Capability.archiveCustomer);
  bool get canVoidExpense => CapabilityService(this).can(Capability.voidExpense);
  bool get canManageAccess => CapabilityService(this).can(Capability.manageAccess);
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