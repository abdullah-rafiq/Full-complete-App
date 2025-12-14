// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../localized_strings.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(L10n.termsTitle()),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.all(Radius.circular(18)),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last updated: 08 December 2025',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'These Terms & Conditions ("Terms") apply to your use of the Assist mobile application and related services. '
                    'They are a generic example based on common practice in similar apps. You should review them with a qualified lawyer before going live.\n\n'
                    'By creating an account or using the app, you agree to these Terms. If you do not agree, you must not use the service.\n\n'
                    '1. Service description\n'
                    '- Assist is a platform that connects customers with independent service providers for home and on-demand services (such as cleaning, plumbing, AC repair, etc.).\n'
                    '- We do not guarantee the availability, quality, or suitability of any service provider and act only as a technology intermediary.\n\n'
                    '2. Accounts and eligibility\n'
                    '- You must be at least 18 years old or the age of majority in your jurisdiction to create an account.\n'
                    '- You are responsible for keeping your login credentials secure and for all activity under your account.\n\n'
                    '3. Bookings and cancellations\n'
                    '- When you place a booking request, you authorise us to share relevant details with service providers.\n'
                    '- A booking is only confirmed when a provider accepts it in the app.\n'
                    '- Cancellation and rescheduling rules (including any fees) may apply and can vary by service or provider.\n\n'
                    '4. Pricing and payments\n'
                    '- Prices shown in the app are usually estimates. Final charges may vary based on actual work performed, time spent, or materials used.\n'
                    '- You agree to pay the total amount displayed in the app when a booking is completed, using the available payment methods (e.g. card, wallet, cash on delivery if offered).\n'
                    '- Any taxes, fees, or government charges are your responsibility where applicable.\n\n'
                    '5. Your responsibilities\n'
                    '- Provide accurate information about your address, contact details, and service requirements.\n'
                    '- Ensure safe access to the property for the service provider.\n'
                    '- Treat providers and support staff respectfully; abusive behaviour may lead to account suspension.\n\n'
                    '6. Ratings and reviews\n'
                    '- You may leave ratings and reviews after a booking. These must be fair, honest, and not defamatory or abusive.\n'
                    '- We may remove content that violates our policies or applicable law.\n\n'
                    '7. Suspension and termination\n'
                    '- We may suspend or terminate your account if we detect misuse, fraud, or violation of these Terms, including non-payment or abusive conduct.\n\n'
                    '8. Liability and disclaimers\n'
                    '- The app and services are provided on an "as is" and "as available" basis, without any express or implied warranties.\n'
                    '- To the maximum extent allowed by law, the company is not liable for indirect, incidental, or consequential damages, or for any acts or omissions of independent service providers.\n\n'
                    '9. Changes to these Terms\n'
                    '- We may update these Terms from time to time. When we do, we will update the "Last updated" date above.\n'
                    '- Continued use of the app after changes become effective means you accept the revised Terms.\n\n'
                    '10. Contact\n'
                    '- For questions about these Terms, please use the Contact us section in the app.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
