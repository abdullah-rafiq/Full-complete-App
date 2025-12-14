// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../localized_strings.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = <Map<String, String>>[
      {
        'q': 'I forgot my password. What should I do?',
        'a':
            'On the login screen, tap "Forgot password" and enter your email. You will receive a password reset link. ',
      },
      {
        'q': 'Why can\'t I log in?',
        'a':
            'Check that your email is correct and that you are using the same login method (email / Google). If the problem continues, try resetting your password.',
      },
      {
        'q': 'How do I update my profile information?',
        'a':
            'Go to your Profile page. From there you can update your name and other basic details.',
      },
      {
        'q': 'Where can I see my payments or wallet balance?',
        'a':
            'Open the Wallet or Payment section from your profile to see transactions and payment methods.',
      },
      {
        'q': 'My booking/order is not updating.',
        'a':
            'Pull down to refresh the page. If it still does not update after some time, contact support with your order ID.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(L10n.faqTitle()),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final item = faqs[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(
                    item['q'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(item['a'] ?? ''),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
