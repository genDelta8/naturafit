import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:intl/intl.dart';

class MonthlyRevenuePage extends StatefulWidget {
  const MonthlyRevenuePage({super.key});

  @override
  State<MonthlyRevenuePage> createState() => _MonthlyRevenuePageState();
}

class _MonthlyRevenuePageState extends State<MonthlyRevenuePage> {
  final currentMonth = DateTime.now();
  
  // Dummy data - replace with real data from your backend
  final Map<String, double> monthlyRevenue = {
    'January': 2500,
    'February': 2800,
    'March': 3200,
    'April': 3100,
    'May': 3500,
    'June': 3300,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Revenue Overview',
          style: GoogleFonts.plusJakartaSans(
            color: myGrey90,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: myBlue60,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Month',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$3,300',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatItem('Sessions', '24'),
                      const SizedBox(width: 24),
                      _buildStatItem('Clients', '12'),
                      const SizedBox(width: 24),
                      _buildStatItem('Avg/Session', '\$137'),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Monthly Breakdown
            Text(
              'Monthly Breakdown',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...monthlyRevenue.entries.map((entry) => _buildMonthlyRevenueItem(
              entry.key,
              entry.value,
            )).toList(),
            
            const SizedBox(height: 24),
            
            // Revenue Sources
            Text(
              'Revenue Sources',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildRevenueSourceItem('Personal Training', 2200, myBlue60),
            _buildRevenueSourceItem('Group Sessions', 600, myPurple60),
            _buildRevenueSourceItem('Meal Plans', 300, myGreen50),
            _buildRevenueSourceItem('Workout Plans', 200, myTeal30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyRevenueItem(String month, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            month,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: myGrey90,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSourceItem(String source, double amount, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              source,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: myGrey90,
            ),
          ),
        ],
      ),
    );
  }
} 