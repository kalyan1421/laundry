import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import 'payment_status_screen.dart';

/// Transaction History Screen - Shows all user payments
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTransactions();
  }

  void _loadTransactions() async {
    if (_isInitialized) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    
    if (authProvider.userModel?.uid != null) {
      await paymentProvider.loadCustomerTransactions(authProvider.userModel!.uid, limit: 100);
      await paymentProvider.loadTransactionStats(authProvider.userModel!.uid);
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list_alt)),
            Tab(text: 'Success', icon: Icon(Icons.check_circle)),
            Tab(text: 'Failed', icon: Icon(Icons.error)),
            Tab(text: 'Pending', icon: Icon(Icons.access_time)),
          ],
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
        ),
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          if (paymentProvider.isLoading && !_isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildSearchAndStats(paymentProvider),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionList(paymentProvider.transactions),
                    _buildTransactionList(_filterByStatus(
                      paymentProvider.transactions, 
                      TransactionStatus.success,
                    )),
                    _buildTransactionList(_filterByStatus(
                      paymentProvider.transactions, 
                      TransactionStatus.failed,
                    )),
                    _buildTransactionList(_filterByStatus(
                      paymentProvider.transactions, 
                      TransactionStatus.pending,
                    )),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadTransactions,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh Transactions',
      ),
    );
  }

  Widget _buildSearchAndStats(PaymentProvider paymentProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),
          // Stats Cards
          if (paymentProvider.transactionStats != null)
            _buildStatsCards(paymentProvider.transactionStats!),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            '₹${(stats['totalAmount'] ?? 0.0).toStringAsFixed(2)}',
            '${stats['totalTransactions'] ?? 0} transactions',
            Colors.blue,
            Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Successful',
            '₹${(stats['successfulAmount'] ?? 0.0).toStringAsFixed(2)}',
            '${stats['successfulTransactions'] ?? 0} payments',
            Colors.green,
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Pending',
            '${stats['pendingTransactions'] ?? 0}',
            'payments',
            Colors.orange,
            Icons.access_time,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<TransactionModel> transactions) {
    final filteredTransactions = _searchQuery.isEmpty
        ? transactions
        : transactions.where((transaction) {
            return transaction.id.toLowerCase().contains(_searchQuery) ||
                   transaction.orderId.toLowerCase().contains(_searchQuery) ||
                   transaction.description.toLowerCase().contains(_searchQuery) ||
                   transaction.payerName.toLowerCase().contains(_searchQuery);
          }).toList();

    if (filteredTransactions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadTransactions();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = filteredTransactions[index];
          return _buildTransactionCard(transaction);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Start making payments to see your transaction history'
                : 'No transactions match your search',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _viewTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusIcon(transaction.status),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.formattedAmount,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          transaction.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusChip(transaction.status),
                      const SizedBox(height: 4),
                      Text(
                        transaction.formattedDateTime.split(',')[0], // Just the date
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.receipt, transaction.orderId),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.person, transaction.payerName),
                  if (transaction.upiApp != null) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.payment, transaction.upiApp!),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(TransactionStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case TransactionStatus.success:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case TransactionStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        break;
      case TransactionStatus.pending:
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case TransactionStatus.cancelled:
        color = Colors.grey;
        icon = Icons.cancel;
        break;
      case TransactionStatus.timeout:
        color = Colors.deepOrange;
        icon = Icons.timer_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildStatusChip(TransactionStatus status) {
    Color color;
    String text;

    switch (status) {
      case TransactionStatus.success:
        color = Colors.green;
        text = 'Success';
        break;
      case TransactionStatus.failed:
        color = Colors.red;
        text = 'Failed';
        break;
      case TransactionStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case TransactionStatus.cancelled:
        color = Colors.grey;
        text = 'Cancelled';
        break;
      case TransactionStatus.timeout:
        color = Colors.deepOrange;
        text = 'Timeout';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: 12, 
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            text.length > 10 ? '${text.substring(0, 10)}...' : text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<TransactionModel> _filterByStatus(List<TransactionModel> transactions, TransactionStatus status) {
    return transactions.where((transaction) => transaction.status == status).toList();
  }

  void _viewTransactionDetails(TransactionModel transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentStatusScreen(
          transaction: transaction,
          isSuccess: transaction.isSuccessful,
        ),
      ),
    );
  }
} 