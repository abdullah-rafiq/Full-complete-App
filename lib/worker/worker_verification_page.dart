import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/controllers/worker_verification_controller.dart';
import 'package:flutter_application_1/common/ui_helpers.dart';

const bool _showDebugTokenButton =
    bool.fromEnvironment('SHOW_DEBUG_TOKEN', defaultValue: false);
const bool _logIdToken = bool.fromEnvironment('LOG_ID_TOKEN', defaultValue: false);

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

  Future<void> _showDebugToken() async {
    final token = await WorkerVerificationController.getIdTokenForDebug(
      forceRefresh: true,
    );
    debugPrint('DEBUG TOKEN: $token');
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      UIHelpers.showSnack(context, 'Could not get token (not logged in).');
      return;
    }

    if (_logIdToken) {
      debugPrint('FIREBASE_ID_TOKEN=$token');
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Firebase ID Token'),
          content: SizedBox(
            width: 520,
            child: SelectableText(token),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: token));
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                if (mounted) {
                  UIHelpers.showSnack(context, 'Token copied to clipboard.');
                }
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showImagePreview({
    required String title,
    required String url,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: Center(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  right: 56,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

      final String? cnicFrontUrl = data['cnicFrontImageUrl'] as String?;
      final String? cnicBackUrl = data['cnicBackImageUrl'] as String?;
      final String? selfieUrl = data['selfieImageUrl'] as String?;
      final String? shopUrl = data['shopImageUrl'] as String?;

      final Map<String, dynamic>? verification =
          data['verification'] as Map<String, dynamic>?;
      final Timestamp? verificationUpdatedAt =
          verification?['updatedAt'] as Timestamp?;
      final Map<String, dynamic>? verificationInputs =
          verification?['inputs'] as Map<String, dynamic>?;

      setState(() {
        _cnicFrontUrl = cnicFrontUrl;
        _cnicBackUrl = cnicBackUrl;
        _selfieUrl = selfieUrl;
        _shopUrl = shopUrl;
        _cnicFrontStatus = (data['cnicFrontStatus'] as String?) ?? 'none';
        _cnicBackStatus = (data['cnicBackStatus'] as String?) ?? 'none';
        _selfieStatus = (data['selfieStatus'] as String?) ?? 'none';
        _shopStatus = (data['shopStatus'] as String?) ?? 'none';
        _overallStatus = (data['verificationStatus'] as String?) ?? 'none';
      });

      final bool hasAnyImage =
          cnicFrontUrl != null || cnicBackUrl != null || selfieUrl != null || shopUrl != null;

      bool inputsChanged() {
        if (verificationInputs == null) return true;
        if ((verificationInputs['cnicFrontImageUrl'] as String?) != cnicFrontUrl) {
          return true;
        }
        if ((verificationInputs['cnicBackImageUrl'] as String?) != cnicBackUrl) {
          return true;
        }
        if ((verificationInputs['selfieImageUrl'] as String?) != selfieUrl) {
          return true;
        }
        if ((verificationInputs['shopImageUrl'] as String?) != shopUrl) {
          return true;
        }
        return false;
      }

      bool cnicUrduAddressMissing() {
        final dynamic cnic = verification?['cnic'];
        if (cnic is! Map<String, dynamic>) return true;
        final dynamic extracted = cnic['extracted'];
        if (extracted is! Map<String, dynamic>) return true;
        final dynamic addressUrdu = extracted['addressUrdu'];
        if (addressUrdu is! Map<String, dynamic>) return true;
        final dynamic line1 = addressUrdu['line1'];
        final String line = (line1 ?? '').toString().trim();
        return line.isEmpty;
      }

      final bool missingCnicResult = cnicFrontUrl != null &&
          cnicBackUrl != null &&
          (verification?['cnic'] == null || cnicUrduAddressMissing());
      final bool missingFaceResult =
          cnicFrontUrl != null && selfieUrl != null && verification?['face'] == null;
      final bool missingShopResult =
          shopUrl != null && verification?['shop'] == null;

      final bool shouldRunAi = hasAnyImage &&
          (verificationUpdatedAt == null ||
              inputsChanged() ||
              missingCnicResult ||
              missingFaceResult ||
              missingShopResult);

      if (shouldRunAi && mounted) {
        await WorkerVerificationController.ensureAiVerificationForCurrentUser();
      }
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showSnack(context, 'Could not load existing verification: $e');
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
    final Color titleColor = isDark
        ? Colors.white
        : theme.colorScheme.onSurface;
    // ignore: unused_local_variable
    final Color descColor = isDark
        ? Colors.white70
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);
    const totalSteps = 4;
    final bool cnicFrontOk =
        _cnicFrontUrl != null && _cnicFrontStatus != 'rejected';
    final bool cnicBackOk = _cnicBackUrl != null && _cnicBackStatus != 'rejected';
    final bool selfieOk = _selfieUrl != null && _selfieStatus != 'rejected';
    final bool shopOk = _shopUrl != null && _shopStatus != 'rejected';

    // Compute progress in the expected sequence. If an earlier step is rejected,
    // later steps shouldn't count toward progress/current step.
    var sequentialCompletedSteps = 0;
    if (cnicFrontOk) {
      sequentialCompletedSteps = 1;
      if (cnicBackOk) {
        sequentialCompletedSteps = 2;
        if (selfieOk) {
          sequentialCompletedSteps = 3;
          if (shopOk) {
            sequentialCompletedSteps = 4;
          }
        }
      }
    }

    final progress = sequentialCompletedSteps / totalSteps;
    final currentStep = sequentialCompletedSteps < totalSteps
        ? sequentialCompletedSteps + 1
        : totalSteps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker verification'),
        
        actions: [
          if (kDebugMode || _showDebugTokenButton)
            IconButton(
              tooltip: 'Debug: Copy token',
              icon: const Icon(Icons.vpn_key_outlined),
              onPressed: _showDebugToken,
              
            ),
        ],
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
                      ? Colors.green.withValues(alpha: 0.12)
                      : _overallStatus == 'rejected'
                      ? Colors.redAccent.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
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
                    color: theme.shadowColor.withValues(alpha: 0.08),
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
                  final int maxStep = sequentialCompletedSteps.clamp(0, 3);

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
                    description:
                        'Take a clear picture of the front of your CNIC.',
                    uploaded: _cnicFrontUrl != null,
                    imageUrl: _cnicFrontUrl,
                    status: _cnicFrontStatus,
                    overallStatus: _overallStatus,
                    onTap: () => _pickAndUpload('cnicFrontImageUrl'),
                    onView: _cnicFrontUrl == null
                        ? null
                        : () => _showImagePreview(
                              title: 'CNIC front picture',
                              url: _cnicFrontUrl!,
                            ),
                  ),
                  _VerificationTile(
                    title: 'CNIC back picture',
                    description:
                        'Take a clear picture of the back side of your CNIC.',
                    uploaded: _cnicBackUrl != null,
                    enabled: cnicFrontOk,
                    imageUrl: _cnicBackUrl,
                    status: _cnicBackStatus,
                    overallStatus: _overallStatus,
                    onTap: () => _pickAndUpload('cnicBackImageUrl'),
                    onView: _cnicBackUrl == null
                        ? null
                        : () => _showImagePreview(
                              title: 'CNIC back picture',
                              url: _cnicBackUrl!,
                            ),
                  ),
                  _VerificationTile(
                    title: 'Live picture',
                    description:
                        'Take a live picture of yourself matching your CNIC.',
                    uploaded: _selfieUrl != null,
                    enabled: cnicFrontOk && cnicBackOk,
                    imageUrl: _selfieUrl,
                    status: _selfieStatus,
                    overallStatus: _overallStatus,
                    onTap: () => _pickAndUpload('selfieImageUrl'),
                    onView: _selfieUrl == null
                        ? null
                        : () => _showImagePreview(
                              title: 'Live picture',
                              url: _selfieUrl!,
                            ),
                  ),
                  _VerificationTile(
                    title: 'Shop / tools picture',
                    description: 'Take a picture of your shop or tools.',
                    uploaded: _shopUrl != null,
                    enabled: cnicFrontOk && cnicBackOk && selfieOk,
                    imageUrl: _shopUrl,
                    status: _shopStatus,
                    overallStatus: _overallStatus,
                    onTap: () => _pickAndUpload('shopImageUrl'),
                    onView: _shopUrl == null
                        ? null
                        : () => _showImagePreview(
                              title: 'Shop / tools picture',
                              url: _shopUrl!,
                            ),
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
  final String? imageUrl;
  final VoidCallback? onView;

  const _VerificationTile({
    required this.title,
    required this.description,
    required this.uploaded,
    required this.status,
    required this.overallStatus,
    required this.onTap,
    this.imageUrl,
    this.onView,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color titleColor = isDark
        ? Colors.white
        : theme.colorScheme.onSurface;
    final Color descColor = isDark
        ? Colors.white70
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    void showPreview() {
      final url = imageUrl;
      if (url == null) return;
      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        builder: (context) {
          return Dialog(
            insetPadding: EdgeInsets.zero,
            backgroundColor: Colors.black,
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 5,
                      child: Center(
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 56,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    Color statusColor(String s) {
      switch (s) {
        case 'approved':
          return Colors.green;
        case 'rejected':
          return Colors.redAccent;
        case 'pending':
          return Colors.orange;
        default:
          return theme.colorScheme.onSurface.withValues(alpha: 0.4);
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

    final bool canTap =
        enabled &&
        ((overallStatus == 'none' || overallStatus == 'pending')
            ? true
            : status == 'rejected');

    final bool canView = uploaded && imageUrl != null;

    VoidCallback? resolveAction() {
      if (uploaded) {
        if (status == 'rejected') {
          return canTap ? onTap : null;
        }
        if (!canView) return null;
        return onView ?? showPreview;
      }

      return canTap ? onTap : null;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
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
                  style: TextStyle(fontSize: 12, color: descColor),
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
                        color: statusColor(status).withValues(alpha: 0.12),
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
                    onPressed: resolveAction(),
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
