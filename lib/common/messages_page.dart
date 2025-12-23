import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:assist/models/app_user.dart';
import 'package:assist/services/user_service.dart';
import '../common/chat_page.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: theme.colorScheme.primary.withAlpha(204),
            ),
            const SizedBox(height: 12),
            Text(
              'No conversations yet',
              style:
                  theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ) ??
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Your chats with providers will appear here once you start messaging.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your messages.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _withInitialTimeout(
          FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: user.uid)
              .snapshots(),
          const Duration(seconds: 15),
          debugName: 'chats',
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Could not load messages: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = (snapshot.data?.docs ?? []).toList()
            ..sort((a, b) {
              final aTs = a.data()['updatedAt'] as Timestamp?;
              final bTs = b.data()['updatedAt'] as Timestamp?;
              final aMs = aTs?.millisecondsSinceEpoch ?? 0;
              final bMs = bTs?.millisecondsSinceEpoch ?? 0;
              return bMs.compareTo(aMs);
            });

          if (docs.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (separatorContext, separatorIndex) =>
                const Divider(height: 1),
            itemBuilder: (context, index) {
              final chatDoc = docs[index];
              final data = chatDoc.data();
              final participants =
                  (data['participants'] as List?)?.whereType<String>().toList() ??
                  const <String>[];
              final otherId = participants.firstWhere(
                (id) => id != user.uid,
                orElse: () => user.uid,
              );
              final lastMessage = data['lastMessage'] as String? ?? '';
              final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

              return FutureBuilder<AppUser?>(
                future: UserService.instance.getById(otherId),
                builder: (context, userSnap) {
                  final other = userSnap.data;
                  final displayName = (other?.name?.trim().isNotEmpty ?? false)
                      ? other!.name!.trim()
                      : 'User';

                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(displayName),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: updatedAt == null
                        ? null
                        : Text(
                            '${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 11),
                          ),
                    onTap: () {
                      if (other == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatPage(chatId: chatDoc.id, otherUser: other),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

Stream<T> _withInitialTimeout<T>(
  Stream<T> source,
  Duration timeout, {
  String? debugName,
}) {
  late final StreamController<T> controller;
  StreamSubscription<T>? sub;
  Timer? timer;
  var gotFirst = false;

  controller = StreamController<T>(
    onListen: () {
      timer = Timer(timeout, () {
        if (gotFirst || controller.isClosed) return;
        controller.addError(
          TimeoutException(
            'Timed out waiting for initial data${debugName == null ? '' : ' ($debugName)'}',
          ),
        );
      });

      sub = source.listen(
        (event) {
          if (!gotFirst) {
            gotFirst = true;
            timer?.cancel();
          }
          controller.add(event);
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          controller.close();
        },
      );
    },
    onCancel: () async {
      timer?.cancel();
      await sub?.cancel();
    },
  );

  return controller.stream;
}
