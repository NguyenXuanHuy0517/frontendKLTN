class AppConstants {
  static const String appName = 'SmartRoomMS';
  static const String version = '1.0.0';

  // Room status
  static const String roomAvailable = 'AVAILABLE';
  static const String roomRented = 'RENTED';
  static const String roomDeposited = 'DEPOSITED';
  static const String roomMaintenance = 'MAINTENANCE';

  // Invoice status
  static const String invoiceDraft = 'DRAFT';
  static const String invoiceUnpaid = 'UNPAID';
  static const String invoicePaid = 'PAID';
  static const String invoiceOverdue = 'OVERDUE';

  // Contract status
  static const String contractActive = 'ACTIVE';
  static const String contractExpired = 'EXPIRED';
  static const String contractTerminated = 'TERMINATED_EARLY';

  // Deposit status
  static const String depositPending = 'PENDING';
  static const String depositConfirmed = 'CONFIRMED';
  static const String depositCompleted = 'COMPLETED';
  static const String depositRefunded = 'REFUNDED';
  static const String depositForfeited = 'FORFEITED';

  // Issue status
  static const String issueOpen = 'OPEN';
  static const String issueProcessing = 'PROCESSING';
  static const String issueResolved = 'RESOLVED';
  static const String issueClosed = 'CLOSED';

  // Issue priority
  static const String priorityLow = 'LOW';
  static const String priorityMedium = 'MEDIUM';
  static const String priorityHigh = 'HIGH';
  static const String priorityUrgent = 'URGENT';

  // Role
  static const String roleAdmin = 'ADMIN';
  static const String roleHost = 'HOST';
  static const String roleTenant = 'TENANT';
}
