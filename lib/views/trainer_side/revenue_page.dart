import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RevenuePage extends StatelessWidget {
  const RevenuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myGrey10,
      appBar: AppBar(
        backgroundColor: myGrey10,
        title: Text(
          'Revenue',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: myGrey80,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'This Month',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.arrow_upward,
                                color: myGreen40,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '12% vs last month',
                                style: GoogleFonts.plusJakartaSans(
                                  color: myGreen40,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$3,250',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),


          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRevenueSection(
                    'Revenue Overview',
                    [
                      _RevenueItem(
                        icon: Icons.person,
                        color: myBlue60,
                        title: 'Active Clients',
                        value: '18',
                        subtitle: '+3 this month',
                      ),
                      _RevenueItem(
                        icon: Icons.calendar_today,
                        color: myGreen50,
                        title: 'Sessions',
                        value: '45',
                        subtitle: 'This month',
                      ),
                      _RevenueItem(
                        icon: Icons.attach_money,
                        color: myRed50,
                        title: 'Avg. Session',
                        value: '\$72',
                        subtitle: 'Per session',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recent Transactions',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: myGrey90,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTransactionList(),
                  const SizedBox(height: 24),
                  Text(
                    'Monthly Summary',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: myGrey90,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Total Revenue', '\$3,250'),
                        const Divider(height: 24),
                        _buildSummaryRow('Personal Training', '\$2,400'),
                        _buildSummaryRow('Group Sessions', '\$450'),
                        _buildSummaryRow('Meal Plans', '\$250'),
                        _buildSummaryRow('Workout Plans', '\$150'),
                        const Divider(height: 24),
                        _buildSummaryRow('Platform Fee', '-\$162.50'),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: myGreen50.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Net Earnings',
                                style: GoogleFonts.plusJakartaSans(
                                  color: myGreen50,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '\$3,087.50',
                                style: GoogleFonts.plusJakartaSans(
                                  color: myGreen50,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSection(String title, List<_RevenueItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: myGrey90,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: items.map((item) => _buildRevenueCard(item)).toList(),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(_RevenueItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                color: item.color,
                size: 20,
              ),
            ),
            const Spacer(),
            Text(
              item.value,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: myGrey90,
              ),
            ),
            Text(
              item.subtitle,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions = [
      _Transaction(
        name: 'Sarah Johnson',
        date: 'Today',
        amount: 80,
        type: 'Personal Training',
      ),
      _Transaction(
        name: 'Group Session',
        date: 'Yesterday',
        amount: 150,
        type: 'Group Training',
      ),
      _Transaction(
        name: 'Mike Peters',
        date: '2 days ago',
        amount: 60,
        type: 'Meal Plan',
      ),
    ];

    return Column(
      children: transactions.map((transaction) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: myBlue60.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.payment,
                    color: myBlue60,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      transaction.type,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${transaction.amount}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    transaction.date,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: myGrey90,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: myGrey90,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueItem {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  _RevenueItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });
}

class _Transaction {
  final String name;
  final String date;
  final double amount;
  final String type;

  _Transaction({
    required this.name,
    required this.date,
    required this.amount,
    required this.type,
  });
}
