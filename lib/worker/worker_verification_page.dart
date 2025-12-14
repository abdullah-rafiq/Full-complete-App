// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/controllers/worker_verification_controller.dart';
import 'package:flutter_application_1/common/ui_helpers.dart';

class WorkerVerificationPage extends StatefulWidget {
  const WorkerVerificationPage({super.key});

  @override
  State<WorkerVerificationPage> createState() => _WorkerVerificationPageState();
}

class _WorkerVerificationPageState extends State<WorkerVerificationPage> {
  // ignore: unused_field
  bool _submitting = false;
  String? _cnicFrontUrl;
  String? _cnicBackUrl;
  String? _selfieUrl;
  String? _shopUrl;
  String _cnicFrontStatus = 'none';
  String _cnicBackStatus = 'none';
  String _selfieStatus = 'none';
  String _shopStatus = 'none';
  String _overallStatus = 'none';

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadExistingVerification();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data == null) return;

      setState(() {
        _cnicFrontUrl = data['cnicFrontImageUrl'] as String?;
        _cnicBackUrl = data['cnicBackImageUrl'] as String?;
        _selfieUrl = data['selfieImageUrl'] as String?;
        _shopUrl = data['shopImageUrl'] as String?;
        _cnicFrontStatus = (data['cnicFrontStatus'] as String?) ?? 'none';
        _cnicBackStatus = (data['cnicBackStatus'] as String?) ?? 'none';
        _selfieStatus = (data['selfieStatus'] as String?) ?? 'none';
        _shopStatus = (data['shopStatus'] as String?) ?? 'none';
        _overallStatus =
            (data['verificationStatus'] as String?) ?? 'none';
      });
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showSnack(
        context,
        'Could not load existing verification: $e',
      );
    }
  }

  Future<void> _pickAndUpload(String field) async {
    final url = await WorkerVerificationController.pickAndUpload(
      context,
      field,
    );

    if (url == null) return;

    setState(() {
      if (field == 'cnicFrontImageUrl') {
        _cnicFrontUrl = url;
        _cnicFrontStatus = 'pending';
      } else if (field == 'cnicBackImageUrl') {
        _cnicBackUrl = url;
        _cnicBackStatus = 'pending';
      } else if (field == 'selfieImageUrl') {
        _selfieUrl = url;
        _selfieStatus = 'pending';
      } else if (field == 'shopImageUrl') {
        _shopUrl = url;
        _shopStatus = 'pending';
      }
      _overallStatus = 'pending';
    });

    if (mounted) {
      if (field == 'cnicFrontImageUrl') {
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else if (field == 'cnicBackImageUrl') {
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else if (field == 'selfieImageUrl') {
        _pageController.animateToPage(
          3,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else if (field == 'shopImageUrl') {
        // Last step completed: auto-submit verification
        _submitVerification();
      }
    }
  }

  Future<void> _submitVerification() async {
    setState(() {
      _submitting = true;
    });

    try {
      final success = await WorkerVerificationController.submitVerification(
        context,
        cnicFrontUrl: _cnicFrontUrl,
        cnicBackUrl: _cnicBackUrl,
        selfieUrl: _selfieUrl,
        shopUrl: _shopUrl,
      );

      if (mounted && success) {
        setState(() {
          _overallStatus = 'pending';
          _cnicFrontStatus = 'pending';
          _cnicBackStatus = 'pending';
          _selfieStatus = 'pending';
          _shopStatus = 'pending';
        });
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnack(context, 'Could not submit verification: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    // ignore: unused_local_variable
    final Color titleColor =
        isDark ? Colors.white : theme.colorScheme.onSurface;
    // ignore: unused_local_variable
    final Color descColor = isDark
        ? Colors.white70
        : theme.colorScheme.onSurface.withOpacity(0.7);
    const totalSteps = 4;
    final completedSteps =
        (_cnicFrontUrl != null ? 1 : 0) +
        (_cnicBackUrl != null ? 1 : 0) +
        (_selfieUrl != null ? 1 : 0) +
        (_shopUrl != null ? 1 : 0);
    final progress = completedSteps / totalSteps;
    final currentStep =
        completedSteps < totalSteps ? completedSteps + 1 : totalSteps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker verification'),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'To start taking jobs, please upload the following live photos:',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (_overallStatus == 'rejected' ||
                _overallStatus == 'pending' ||
                _overallStatus == 'approved')
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _overallStatus == 'approved'
                      ? Colors.green.withOpacity(0.12)
                      : _overallStatus == 'rejected'
                          ? Colors.redAccent.withOpacity(0.12)
                          : Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _overallStatus == 'approved'
                          ? Icons.check_circle
                          : _overallStatus == 'rejected'
                              ? Icons.error_outline
                              : Icons.hourglass_bottom,
                      color: _overallStatus == 'approved'
                          ? Colors.green
                          : _overallStatus == 'rejected'
                              ? Colors.redAccent
                              : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _overallStatus == 'approved'
                            ? 'Your verification has been approved. Thank you.'
                            : _overallStatus == 'rejected'
                                ? 'Some of your documents were rejected. Please retake the ones marked "Needs resubmit".'
                                : 'Your verification is under review. You will be notified once it is approved or if changes are needed.',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step $currentStep of $totalSteps',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 210,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  // Prevent swiping ahead of the current completed step.
                  int maxStep = 0;
                  if (_cnicFrontUrl != null) maxStep = 1;
                  if (_cnicBackUrl != null) maxStep = 2;
                  if (_selfieUrl != null) maxStep = 3;

                  if (index > maxStep) {
                    _pageController.animateToPage(
                      maxStep,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                },
                children: [
                  _VerificationTile(
                    title: 'CNIC front picture',
                    description: 'Take a clear picture of the front of your CNIC.',
                    uploaded: _cnicFrontUrl != null,
                    status: _cnicFrontStatus,
                    overallStatus: _overallStatus,
                    onTap: () => _pickAndUpload('cnicFrontImageUrl'),
                  ),
                  _VerificationTile(
                    title: 'CNIC back picture',
                    description:
                        'Take a clear picture of the back side of your CNIC.',
                    uploaded: _cnicBackUrl != null,
                    enabled: _cnicFrontUrl != null,
                    status: _cnicBackStatus,
                    overallStatus: _overallStatus,
                    onTap: () => _pickAndUpload('cnicBackImageUrl'),
                  ),
                  _VerificationTile(
                    title: 'Live picture',
                    description: 'Take a live picture of yourself matching your CNIC.',
                    uploaded: _selfieUrl != null,
                    enabled:
                        _cnicFrontUrl != null && _cnicBackUrl != null,
                    status: _selfieStatus,
                    overallStatus: _overallStatus,
                    onTap: () => _pickAndUpload('selfieImageUrl'),
                  ),
                  _VerificationTile(
                    title: 'Shop / tools picture',
                    description: 'Take a picture of your shop or tools.',
                    uploaded: _shopUrl != null,
                    enabled: _selfieUrl != null,
                    status: _shopStatus,
                    overallStatus: _overallStatus,
                    onTap: () => _pickAndUpload('shopImageUrl'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  final String title;
  final String description;
  final bool uploaded;
  final bool enabled;
  final String status;
  final String overallStatus;
  final VoidCallback onTap;

  const _VerificationTile({
    required this.title,
    required this.description,
    required this.uploaded,
    required this.status,
    required this.overallStatus,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color titleColor =
        isDark ? Colors.white : theme.colorScheme.onSurface;
    final Color descColor = isDark
        ? Colors.white70
        : theme.colorScheme.onSurface.withOpacity(0.7);

    Color statusColor(String s) {
      switch (s) {
        case 'approved':
          return Colors.green;
        case 'rejected':
          return Colors.redAccent;
        case 'pending':
          return Colors.orange;
        default:
          return theme.colorScheme.onSurface.withOpacity(0.4);
      }
    }

    String statusLabel(String s) {
      switch (s) {
        case 'approved':
          return 'Approved';
        case 'rejected':
          return 'Needs resubmit';
        case 'pending':
          return 'Pending review';
        default:
          return uploaded ? 'Uploaded' : 'Not uploaded';
      }
    }

    final bool canTap = enabled &&
        ((overallStatus == 'none' || overallStatus == 'pending')
            ? true
            : status == 'rejected');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            uploaded ? Icons.check_circle : Icons.photo_camera_outlined,
            color: uploaded ? Colors.green : Colors.blueAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: descColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel(status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: canTap ? onTap : null,
                    child: Text(
                      uploaded
                          ? (status == 'rejected'
                              ? 'Retake photo'
                              : 'View photo')
                          : 'Take photo',
                    ),
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
