import 'package:flutter/material.dart';
import 'package:gg_sms_pool/adjust_pricing_smsbus.dart';
import 'package:gg_sms_pool/adjust_pricing_smspool.dart';
import 'package:gg_sms_pool/finance_history_page.dart';
import 'package:gg_sms_pool/manage_users_page.dart';
import 'package:gg_sms_pool/manual_receipts_page.dart';
import 'package:gg_sms_pool/utils.dart';

class AdminTasksPage extends StatelessWidget {
  const AdminTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Tasks'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TaskItem(
            title: 'Approve Receipts',
            onTap: () {
              // Navigate to receipt approval page
              moveToPage(context, const ReceiptReviewPage(), false);
            },
          ),
          TaskItem(
            title: 'View Financial Reports',
            onTap: () {
              // Navigate to reports page
              moveToPage(context, const FinanceHistoryPage(), false);
            },
          ),
          TaskItem(
            title: 'Manage Users',
            onTap: () {
              // Navigate to reports page
              moveToPage(context, const ManageUsersPage(), false);
            },
          ),
          TaskItem(
            title: 'Adjust Number Pricing (Sms Pool)',
            onTap: () {
              // Navigate to reports page
              moveToPage(context, const PricingAdjustmentPageSmsPool(), false);
            },
          ),
          TaskItem(
            title: 'Adjust Number Pricing (Sms Bus)',
            onTap: () {
              // Navigate to reports page
              moveToPage(context, const PricingAdjustmentPageSmsBus(), false);
            },
          ),
           TaskItem(
            title: 'Adjust Number Pricing (Daisy Sms)',
            onTap: () {
              // Navigate to reports page
              moveToPage(context, const PricingAdjustmentPageSmsBus(), false);
            },
          ),
          
        ],
      ),
    );
  }
}

class TaskItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const TaskItem({
    required this.title,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16.0),
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }
}
