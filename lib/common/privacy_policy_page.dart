// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../localized_strings.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
        title: Text(L10n.privacyTitle()),
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
                    'This Privacy Policy explains how the Assist app collects, uses, and protects your information. '
                    'It is a generic example based on common practice in similar apps. You should review and adapt it with a qualified lawyer before going live.\n\n'
                    '1. Information we collect\n'
                    '- Account information: name, email address, phone number, profile photo, and role (customer or provider).\n'
                    '- Usage information: bookings you create or accept, services viewed, ratings and reviews, and in-app interactions.\n'
                    '- Location information: approximate or precise location when you allow location access (e.g. for finding nearby providers or tracking jobs).\n'
                    '- Device information: basic device identifiers, app version, and technical logs used for performance and security.\n\n'
                    '2. How we use your information\n'
                    '- To create and manage your account and profile.\n'
                    '- To process bookings, payments, and wallet transactions.\n'
                    '- To match customers with nearby service providers and show relevant services.\n'
                    '- To send notifications about booking status, promotions, and important updates (you can control some notifications in Settings).\n'
                    '- To monitor service quality, prevent fraud, and improve the app.\n\n'
                    '3. Sharing of information\n'
                    '- With service providers: we share necessary details (name, address, contact number, booking details) so they can complete a job.\n'
                    '- With payment partners: when you make a payment, required data is shared securely with payment gateways or banks.\n'
                    '- With third-party tools: we may use analytics, crash reporting, or push notification services that process limited technical data.\n'
                    '- When required by law: we may disclose information to comply with legal obligations or to protect our rights and the safety of users.\n\n'
                    '4. Data retention\n'
                    '- We keep your information for as long as necessary to provide the service and for a reasonable period afterward, as allowed by law (for example, for accounting or dispute resolution).\n\n'
                    '5. Your choices and rights\n'
                    '- You can access and update basic profile information from within the app.\n'
                    '- You may request deletion of your account; some information may be retained where required by law or for legitimate business purposes.\n'
                    '- You can control certain permissions (such as location or notifications) via your device settings.\n\n'
                    '6. Security\n'
                    '- We use reasonable technical and organisational measures to help protect your information.\n'
                    '- No system is 100% secure; you should keep your login details confidential and alert us if you suspect unauthorised access.\n\n'
                    '7. Children\n'
                    '- The service is not directed to children under the age of 13 (or local minimum age); they should not create an account or use the app.\n\n'
                    '8. Changes to this Policy\n'
                    '- We may update this Privacy Policy from time to time. When we do, we will update the "Last updated" date above.\n'
                    '- Your continued use of the app after changes become effective means you accept the revised Policy.\n\n'
                    '9. Contact\n'
                    '- If you have questions about this Privacy Policy or your data, please use the Contact us section in the app.',
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
