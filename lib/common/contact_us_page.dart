// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../localized_strings.dart';
import '../services/support_service.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final TextEditingController _chatController = TextEditingController();
  final List<_ChatMessage> _messages = <_ChatMessage>[];

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        fromUser: false,
        text: L10n.contactSupportBotWelcome(),
        timestampLabel: 'now',
      ),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(fromUser: true, text: text, timestampLabel: 'now'),
      );
    });

    _chatController.clear();

    try {
      final reply = await SupportService.instance.askSupport(text);
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            fromUser: false,
            text: reply,
            timestampLabel: 'now',
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            fromUser: false,
            text: L10n.contactSupportReplyGeneric(),
            timestampLabel: 'now',
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.contactAppBarTitle()),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Theme.of(context).shadowColor.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        ListTile(
                          leading: Icon(Icons.email_outlined),
                          title: Text('Email'),
                          subtitle: Text('support@example.com'),
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.phone_outlined),
                          title: Text('Phone'),
                          subtitle: Text('+1 234 567 890 (dummy)'),
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.access_time),
                          title: Text('Support hours'),
                          subtitle:
                              Text('Mon - Fri, 9:00 AM - 6:00 PM (local time)'),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'The contact details above are dummy placeholders. Replace them with your real support email and phone when you are ready to go live.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Theme.of(context).shadowColor.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          L10n.contactLiveChatTitle(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        height: 260,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant,
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  final alignment = message.fromUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft;
                                  final color = message.fromUser
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest;
                                  final textColor = message.fromUser
                                      ? Colors.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant;

                                  return Align(
                                    alignment: alignment,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        message.text,
                                        style:
                                            TextStyle(color: textColor),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _chatController,
                                      decoration: InputDecoration(
                                        hintText: L10n.contactTypeMessageHint(),
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (_) => _sendMessage(),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send),
                                    onPressed: _sendMessage,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool fromUser;
  final String text;
  final String timestampLabel;

  const _ChatMessage({
    required this.fromUser,
    required this.text,
    required this.timestampLabel,
  });
}
