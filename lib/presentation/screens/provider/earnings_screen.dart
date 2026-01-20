import 'package:flutter/material.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _selectedFilter = 'all';

  final List<Transaction> _transactions = [
    Transaction(
      title: 'Plumbing Repair',
      subtitle: '123 Main St • Today',
      amount: 15000.0,
      type: TransactionType.completed,
      icon: Icons.check_circle,
      iconColor: Colors.green,
    ),
    Transaction(
      title: 'Faucet Install',
      subtitle: '45 Oak Ave • Yesterday',
      amount: 8000.0,
      type: TransactionType.escrow,
      icon: Icons.hourglass_top,
      iconColor: const Color(0xFFEC9213),
    ),
    Transaction(
      title: 'Payout to Bank',
      subtitle: 'Oct 24 • Completed',
      amount: -50000.0,
      type: TransactionType.payout,
      icon: Icons.arrow_outward,
      iconColor: Colors.grey,
    ),
    Transaction(
      title: 'Emergency Leak',
      subtitle: '88 Pine Rd • Oct 22',
      amount: 22000.0,
      type: TransactionType.completed,
      icon: Icons.check_circle,
      iconColor: Colors.green,
    ),
    Transaction(
      title: 'Pipe Fitting',
      subtitle: '12 Elm St • Oct 20',
      amount: 4000.0,
      type: TransactionType.escrow,
      icon: Icons.hourglass_top,
      iconColor: const Color(0xFFEC9213),
    ),
  ];

  List<Transaction> get _filteredTransactions {
    if (_selectedFilter == 'all') return _transactions;
    if (_selectedFilter == 'earnings') {
      return _transactions.where((t) => t.type != TransactionType.payout).toList();
    }
    return _transactions.where((t) => t.type == TransactionType.payout).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF181511)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Earnings',
          style: TextStyle(color: Color(0xFF181511), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Balance Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'AVAILABLE BALANCE',
                    style: TextStyle(
                      color: Color(0xFF897961),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '৳85,000.00',
                    style: TextStyle(
                      color: Color(0xFFEC9213),
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: const Color(0xFFE6E1DB),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC9213).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.lock, color: Color(0xFFEC9213), size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending in Escrow',
                              style: TextStyle(fontSize: 12, color: Color(0xFF897961), fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Releases after job completion',
                              style: TextStyle(fontSize: 10, color: Color(0xFF897961)),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '৳12,000.00',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF181511)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bank & Withdraw Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Bank Selector
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payout method selection coming soon...')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F7F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.account_balance, color: Color(0xFF897961)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Payout Method', style: TextStyle(fontSize: 10, color: Color(0xFF897961), fontWeight: FontWeight.w500)),
                              Text('Dutch-Bangla Bank •••• 4829', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF181511))),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF897961)),
                      ],
                    ),
                  ),
                ),

                // Withdraw Button
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Withdraw funds feature coming soon...')),
                    );
                  },
                  icon: const Icon(Icons.payments),
                  label: const Text('Withdraw Funds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC9213),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    shadowColor: const Color(0xFFEC9213).withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),

          // Info Text
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: Color(0xFF897961)),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Funds are transferred securely. Typical processing time is 1-3 business days depending on your bank.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF897961), height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE6E1DB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildFilterButton('All', 'all'),
                  _buildFilterButton('Earnings', 'earnings'),
                  _buildFilterButton('Payouts', 'payouts'),
                ],
              ),
            ),
          ),

          // Transaction List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECENT ACTIVITY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF897961),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ..._filteredTransactions.map((transaction) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildTransactionTile(transaction),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF181511) : const Color(0xFF897961),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    final isNegative = transaction.amount < 0;
    final absAmount = transaction.amount.abs();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E1DB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: transaction.type == TransactionType.completed
                  ? Colors.green.withOpacity(0.1)
                  : transaction.type == TransactionType.escrow
                      ? const Color(0xFFEC9213).withOpacity(0.1)
                      : const Color(0xFFF8F7F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(transaction.icon, color: transaction.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF181511)),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.subtitle,
                  style: const TextStyle(color: Color(0xFF897961), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isNegative ? '-' : '+'}৳${absAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: transaction.type == TransactionType.completed
                      ? Colors.green
                      : transaction.type == TransactionType.payout
                          ? const Color(0xFF181511)
                          : const Color(0xFF897961),
                ),
              ),
              const SizedBox(height: 4),
              if (transaction.type == TransactionType.completed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Released',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                )
              else if (transaction.type == TransactionType.escrow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC9213).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock, size: 9, color: Color(0xFFEC9213)),
                      SizedBox(width: 2),
                      Text(
                        'Escrow',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFEC9213)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum TransactionType { completed, escrow, payout }

class Transaction {
  final String title;
  final String subtitle;
  final double amount;
  final TransactionType type;
  final IconData icon;
  final Color iconColor;

  Transaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    required this.icon,
    required this.iconColor,
  });
}
