import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:flutter/material.dart';
import 'package:naturafit/utilities/color_scheme.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final TextEditingController _searchController = TextEditingController();
  List<FAQItem> _filteredFAQs = [];
  final Set<int> _expandedIndices = {};
  
  // Sample FAQ data - you can replace this with your actual FAQ data
  final List<FAQItem> _allFAQs = [
    FAQItem(
      question: "How do I schedule a session?",
      answer: "You can schedule a session by going to your trainer's profile, selecting an available time slot, and confirming the booking.",
    ),
    FAQItem(
      question: "How do I cancel a session?",
      answer: "To cancel a session, go to your upcoming sessions, select the session you want to cancel, and tap the cancel button. Please note our cancellation policy.",
    ),
    FAQItem(
      question: "What is the payment process?",
      answer: "We accept various payment methods including credit cards and digital wallets. Payments are processed securely through our platform.",
    ),
    FAQItem(
      question: "How do I change my trainer?",
      answer: "You can browse other trainers' profiles and book sessions with them. There's no need to formally switch trainers.",
    ),
    // Add more FAQ items as needed
  ];

  @override
  void initState() {
    super.initState();
    _filteredFAQs = _allFAQs;
  }

  void _filterFAQs(String query) {
    setState(() {
      _filteredFAQs = _allFAQs
          .where((faq) =>
              faq.question.toLowerCase().contains(query.toLowerCase()) ||
              faq.answer.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.chevron_left,
              color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'FAQs',
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
            child: CustomFocusTextField(
              controller: _searchController,
              onChanged: _filterFAQs,
              hintText: 'Search FAQs...',
              prefixIcon: Icons.search,
              label: '',
            ),
            
            
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredFAQs.length,
              itemBuilder: (context, index) {
                return _buildFAQCard(_filteredFAQs[index], theme, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq, ThemeData theme, int index) {
    final isExpanded = _expandedIndices.contains(index);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedIndices.remove(index);
          } else {
            _expandedIndices.add(index);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isExpanded ? myBlue30 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          //duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isExpanded ? myBlue60 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        faq.question,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isExpanded ? Colors.white : myGrey90,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isExpanded ? 0.5 : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isExpanded ? myBlue60 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isExpanded ? Colors.white : myGrey90,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isExpanded ? Colors.white : myGrey90,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Container(
                    height: isExpanded ? null : 0,
                    child: Container(
                      //duration: const Duration(milliseconds: 200),
                      //curve: Curves.easeInOut,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: isExpanded ? myBlue60 : Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        faq.answer,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isExpanded ? Colors.white : myGrey90,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
} 