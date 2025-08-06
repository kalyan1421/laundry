import 'package:flutter/foundation.dart';
import 'package:upi_pay/upi_pay.dart';
import '../../data/models/transaction_model.dart';
import '../../services/upi_payment_service.dart';

/// Payment provider for managing UPI payment state and operations
class PaymentProvider with ChangeNotifier {
  final UpiPaymentService _paymentService = UpiPaymentService();

  // State variables
  bool _isLoading = false;
  bool _isInitialized = false;
  List<ApplicationMeta> _availableUpiApps = [];
  List<TransactionModel> _transactions = [];
  TransactionModel? _currentTransaction;
  String? _errorMessage;
  Map<String, dynamic>? _transactionStats;

  // Payment form state
  double _amount = 0.0;
  String _description = '';
  String _upiId = '';
  String _payerName = '';
  ApplicationMeta? _selectedUpiApp;

  // Getters
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<ApplicationMeta> get availableUpiApps => _availableUpiApps;
  List<TransactionModel> get transactions => _transactions;
  TransactionModel? get currentTransaction => _currentTransaction;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get transactionStats => _transactionStats;

  // Payment form getters
  double get amount => _amount;
  String get description => _description;
  String get upiId => _upiId;
  String get payerName => _payerName;
  ApplicationMeta? get selectedUpiApp => _selectedUpiApp;

  // Validation getters
  bool get isAmountValid => _paymentService.isValidAmount(_amount);
  bool get isUpiIdValid => _paymentService.isValidUpiId(_upiId);
  bool get isPayerNameValid => _payerName.trim().length >= 2;
  bool get isDescriptionValid => _description.trim().length >= 3;
  bool get isFormValid => isAmountValid && isUpiIdValid && isPayerNameValid && isDescriptionValid;

  // Computed properties
  bool get hasUpiApps => _availableUpiApps.isNotEmpty;
  bool get isUpiSupported => _availableUpiApps.isNotEmpty;
  String get formattedAmount => '₹${_amount.toStringAsFixed(2)}';

  /// Initialize the payment provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      await _paymentService.initialize();
      await _loadAvailableUpiApps();
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize payment service: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load available UPI apps
  Future<void> _loadAvailableUpiApps() async {
    try {
      _availableUpiApps = await _paymentService.getAvailableUpiApps();
      
      // Auto-select first app if available
      if (_availableUpiApps.isNotEmpty && _selectedUpiApp == null) {
        _selectedUpiApp = _availableUpiApps.first;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load UPI apps: $e');
    }
  }

  /// Set payment amount
  void setAmount(double amount) {
    _amount = amount;
    _clearError();
    notifyListeners();
  }

  /// Set payment description
  void setDescription(String description) {
    _description = description;
    _clearError();
    notifyListeners();
  }

  /// Set UPI ID
  void setUpiId(String upiId) {
    _upiId = upiId.trim();
    _clearError();
    notifyListeners();
  }

  /// Set payer name
  void setPayerName(String name) {
    _payerName = name.trim();
    _clearError();
    notifyListeners();
  }

  /// Select UPI app
  void selectUpiApp(ApplicationMeta app) {
    _selectedUpiApp = app;
    _clearError();
    notifyListeners();
  }

  /// Clear form data
  void clearForm() {
    _amount = 0.0;
    _description = '';
    _upiId = '';
    _payerName = '';
    _selectedUpiApp = _availableUpiApps.isNotEmpty ? _availableUpiApps.first : null;
    _clearError();
    notifyListeners();
  }

  /// Create and initiate payment
  Future<bool> initiatePayment({
    required String orderId,
    required String customerId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!isFormValid) {
      _setError('Please fill all required fields correctly');
      return false;
    }

    if (_selectedUpiApp == null) {
      _setError('Please select a UPI app');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Create transaction
      final transaction = await _paymentService.createTransaction(
        orderId: orderId,
        customerId: customerId,
        amount: _amount,
        description: _description,
        upiId: _upiId,
        payerName: _payerName,
        metadata: metadata,
      );

      _currentTransaction = transaction;
      notifyListeners();

      // Initiate payment
      final response = await _paymentService.initiatePayment(
        transaction: transaction,
        appMeta: _selectedUpiApp!,
      );

      // Refresh transaction to get updated status
      await _refreshCurrentTransaction();

      return _currentTransaction?.isSuccessful ?? false;
    } catch (e) {
      _setError('Payment failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh current transaction status
  Future<void> _refreshCurrentTransaction() async {
    if (_currentTransaction == null) return;

    try {
      final updatedTransaction = await _paymentService.getTransaction(_currentTransaction!.id);
      if (updatedTransaction != null) {
        _currentTransaction = updatedTransaction;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing transaction: $e');
    }
  }

  /// Load transactions for a customer
  Future<void> loadCustomerTransactions(String customerId, {int? limit}) async {
    _setLoading(true);
    _clearError();

    try {
      _transactions = await _paymentService.getTransactionsByCustomerId(
        customerId,
        limit: limit,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to load transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load transactions for an order
  Future<void> loadOrderTransactions(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      _transactions = await _paymentService.getTransactionsByOrderId(orderId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load order transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load transaction statistics
  Future<void> loadTransactionStats(String customerId) async {
    try {
      _transactionStats = await _paymentService.getTransactionStats(customerId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading transaction stats: $e');
    }
  }

  /// Get a specific transaction
  Future<TransactionModel?> getTransaction(String transactionId) async {
    try {
      return await _paymentService.getTransaction(transactionId);
    } catch (e) {
      _setError('Failed to get transaction: $e');
      return null;
    }
  }

  /// Retry a failed transaction
  Future<bool> retryTransaction(String transactionId) async {
    if (_selectedUpiApp == null) {
      _setError('Please select a UPI app');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _paymentService.retryTransaction(
        transactionId: transactionId,
        appMeta: _selectedUpiApp!,
      );

      // Refresh transactions
      if (_currentTransaction != null) {
        await _refreshCurrentTransaction();
      }

      return response.status == UpiTransactionStatus.success;
    } catch (e) {
      _setError('Retry failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if UPI is supported on device
  Future<bool> checkUpiSupport() async {
    try {
      return await _paymentService.isUpiSupported();
    } catch (e) {
      _setError('Failed to check UPI support: $e');
      return false;
    }
  }

  /// Get payment summary for display
  Map<String, dynamic> getPaymentSummary() {
    return {
      'amount': _amount,
      'formattedAmount': formattedAmount,
      'description': _description,
      'upiId': _upiId,
      'payerName': _payerName,
      'selectedApp': _selectedUpiApp?.upiApplication.getAppName(),
      'isValid': isFormValid,
    };
  }

  /// Validate UPI ID format
  String? validateUpiId(String? value) {
    if (value == null || value.isEmpty) {
      return 'UPI ID is required';
    }
    if (!_paymentService.isValidUpiId(value)) {
      return 'Please enter a valid UPI ID (e.g., user@paytm)';
    }
    return null;
  }

  /// Validate amount
  String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (!_paymentService.isValidAmount(amount)) {
      return 'Amount must be between ₹1 and ₹1,00,000';
    }
    
    return null;
  }

  /// Validate payer name
  String? validatePayerName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Payer name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validate description
  String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length < 3) {
      return 'Description must be at least 3 characters';
    }
    return null;
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh UPI apps
  Future<void> refreshUpiApps() async {
    await _loadAvailableUpiApps();
  }

  /// Clean up old transactions
  Future<void> cleanupOldTransactions({int daysOld = 365}) async {
    try {
      await _paymentService.cleanupOldTransactions(daysOld: daysOld);
    } catch (e) {
      debugPrint('Error cleaning up old transactions: $e');
    }
  }

  /// Get formatted transaction amount
  String formatTransactionAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Check if transaction is recent (within last 24 hours)
  bool isRecentTransaction(TransactionModel transaction) {
    final dayAgo = DateTime.now().subtract(const Duration(hours: 24));
    return transaction.createdAt.isAfter(dayAgo);
  }

  /// Get transactions grouped by status
  Map<TransactionStatus, List<TransactionModel>> getTransactionsByStatus() {
    final grouped = <TransactionStatus, List<TransactionModel>>{};
    
    for (final transaction in _transactions) {
      grouped[transaction.status] ??= [];
      grouped[transaction.status]!.add(transaction);
    }
    
    return grouped;
  }

  /// Get device information for transaction metadata
  Future<Map<String, dynamic>> getDeviceInfo() async {
    return await _paymentService.getDeviceInfo();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }
} 