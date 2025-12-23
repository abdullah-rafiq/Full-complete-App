import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/models/booking.dart';
import 'package:flutter_application_1/models/review.dart';
import 'package:flutter_application_1/common/sentiment_utils.dart';
import 'package:flutter_application_1/controllers/admin_worker_controller.dart';
import 'package:flutter_application_1/common/section_card.dart';

class AdminWorkerDetailPage extends StatelessWidget {
  final AppUser worker;

  const AdminWorkerDetailPage({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          worker.name?.isNotEmpty == true ? worker.name! : 'Worker details',
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 16),
            _buildVerificationSection(context),
            const SizedBox(height: 16),
            _buildEarningsSection(context),
            const SizedBox(height: 16),
            _buildRiskSection(context),
            const SizedBox(height: 16),
            _buildReviewsSection(context),
          ],
        ),
      ),
    );
  }

  String _prettyJson(Object? value) {
    if (value == null) return '';
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  void _showImagePreview(
    BuildContext context, {
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

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            worker.name?.isNotEmpty == true ? worker.name! : 'Worker',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('ID: ${worker.id}', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          if (worker.phone != null)
            Text(
              'Phone: ${worker.phone}',
              style: const TextStyle(fontSize: 13),
            ),
          if (worker.email != null)
            Text(
              'Email: ${worker.email}',
              style: const TextStyle(fontSize: 13),
            ),
          const SizedBox(height: 4),
          Text(
            'Status: ${worker.status}',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(worker.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _sectionCard(
            context,
            title: 'Verification documents',
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _sectionCard(
            context,
            title: 'Verification documents',
            child: Text('Error loading verification: ${snapshot.error}'),
          );
        }

        final doc = snapshot.data;
        final data = doc?.data();
        if (doc == null || !doc.exists || data == null) {
          return _sectionCard(
            context,
            title: 'Verification documents',
            child: const Text('No verification data found for this worker.'),
          );
        }

        final String? cnicFrontUrl = data['cnicFrontImageUrl'] as String?;
        final String? cnicBackUrl = data['cnicBackImageUrl'] as String?;
        final String? selfieUrl = data['selfieImageUrl'] as String?;
        final String? shopUrl = data['shopImageUrl'] as String?;

        final String cnicFrontStatus =
            (data['cnicFrontStatus'] as String?) ?? 'pending';
        final String cnicBackStatus =
            (data['cnicBackStatus'] as String?) ?? 'pending';
        final String selfieStatus =
            (data['selfieStatus'] as String?) ?? 'pending';
        final String shopStatus = (data['shopStatus'] as String?) ?? 'pending';

        final Map<String, dynamic>? verification =
            data['verification'] as Map<String, dynamic>?;
        final Map<String, dynamic>? cnicVerification =
            verification?['cnic'] as Map<String, dynamic>?;
        final Map<String, dynamic>? cnicExtracted =
            cnicVerification?['extracted'] as Map<String, dynamic>?;
        final Map<String, dynamic>? expectedMatches =
            cnicVerification?['expectedMatches'] as Map<String, dynamic>?;
        final Map<String, dynamic>? addressUrdu =
            cnicExtracted?['addressUrdu'] as Map<String, dynamic>?;

        final String? addressUrduText = _joinNonEmpty([
          addressUrdu?['line1'] as String?,
          addressUrdu?['line2'] as String?,
          addressUrdu?['district'] as String?,
          addressUrdu?['tehsil'] as String?,
        ]);

        final bool hasAnyCnicDetails = cnicExtracted != null &&
            <String?>[
              cnicExtracted['fullName'] as String?,
              cnicExtracted['fatherName'] as String?,
              cnicExtracted['cnicNumber'] as String?,
              cnicExtracted['dateOfBirth'] as String?,
              cnicExtracted['dateOfIssue'] as String?,
              cnicExtracted['dateOfExpiry'] as String?,
              addressUrduText,
            ].any((v) => v != null && v.trim().isNotEmpty);

        final Timestamp? verificationUpdatedAt =
            verification?['updatedAt'] as Timestamp?;
        final String? verificationLastError = verification?['lastError'] as String?;
        final String? cnicError = verification?['cnicError'] as String?;
        final String? faceError = verification?['faceError'] as String?;
        final String? shopError = verification?['shopError'] as String?;

        final bool hasAnyImage =
            cnicFrontUrl != null ||
            cnicBackUrl != null ||
            selfieUrl != null ||
            shopUrl != null;

        if (!hasAnyImage) {
          return _sectionCard(
            context,
            title: 'Verification documents',
            child: const Text(
              'Worker has not submitted verification photos yet.',
            ),
          );
        }

        Color statusColor(String status) {
          switch (status) {
            case 'approved':
              return Colors.green;
            case 'rejected':
              return Colors.redAccent;
            case 'pending':
            default:
              return Colors.orange;
          }
        }

        String statusLabel(String status) {
          switch (status) {
            case 'approved':
              return 'Approved';
            case 'rejected':
              return 'Needs resubmit';
            case 'pending':
            default:
              return 'Pending';
          }
        }

        Widget buildDocRow({
          required String title,
          required String fieldStatusKey,
          required String status,
          required String? url,
        }) {
          if (url == null) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('$title: Not uploaded'),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showImagePreview(
                      context,
                      title: title,
                      url: url,
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(url, fit: BoxFit.cover),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Icon(
                                Icons.zoom_in,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Pass'),
                      onPressed: status == 'rejected'
                          ? null
                          : () async {
                              await AdminWorkerController.updateDocumentStatus(
                                context,
                                workerId: worker.id,
                                currentData: data,
                                statusField: fieldStatusKey,
                                newStatus: 'approved',
                              );
                            },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, color: Colors.redAccent),
                      label: const Text('Resubmit'),
                      onPressed: () async {
                        await AdminWorkerController.updateDocumentStatus(
                          context,
                          workerId: worker.id,
                          currentData: data,
                          statusField: fieldStatusKey,
                          newStatus: 'rejected',
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          );
        }

        return _sectionCard(
          context,
          title: 'Verification documents',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (verificationUpdatedAt != null ||
                  (verificationLastError != null &&
                      verificationLastError.trim().isNotEmpty) ||
                  (cnicError != null && cnicError.trim().isNotEmpty) ||
                  (faceError != null && faceError.trim().isNotEmpty) ||
                  (shopError != null && shopError.trim().isNotEmpty)) ...[
                Text(
                  'AI status',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (verificationUpdatedAt != null)
                  Text(
                    'Last run: ${verificationUpdatedAt.toDate().toLocal()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (verificationLastError != null &&
                    verificationLastError.trim().isNotEmpty)
                  Text(
                    'Error: $verificationLastError',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.redAccent),
                  ),
                if (cnicError != null && cnicError.trim().isNotEmpty)
                  Text(
                    'CNIC error: $cnicError',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.redAccent),
                  ),
                if (faceError != null && faceError.trim().isNotEmpty)
                  Text(
                    'Face error: $faceError',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.redAccent),
                  ),
                if (shopError != null && shopError.trim().isNotEmpty)
                  Text(
                    'Shop error: $shopError',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.redAccent),
                  ),
                const SizedBox(height: 12),
              ],
              buildDocRow(
                title: 'CNIC front picture',
                fieldStatusKey: 'cnicFrontStatus',
                status: cnicFrontStatus,
                url: cnicFrontUrl,
              ),
              buildDocRow(
                title: 'CNIC back picture',
                fieldStatusKey: 'cnicBackStatus',
                status: cnicBackStatus,
                url: cnicBackUrl,
              ),
              buildDocRow(
                title: 'Live picture',
                fieldStatusKey: 'selfieStatus',
                status: selfieStatus,
                url: selfieUrl,
              ),
              buildDocRow(
                title: 'Shop / tools picture',
                fieldStatusKey: 'shopStatus',
                status: shopStatus,
                url: shopUrl,
              ),
              if (hasAnyCnicDetails) ...[
                const SizedBox(height: 8),
                Text(
                  'Smart CNIC details',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                _buildCnicDetailsRow(
                  label: 'Name',
                  value: cnicExtracted['fullName'] as String?,
                ),
                _buildCnicDetailsRow(
                  label: 'Father name',
                  value: cnicExtracted['fatherName'] as String?,
                ),
                _buildCnicDetailsRow(
                  label: 'CNIC number',
                  value: cnicExtracted['cnicNumber'] as String?,
                ),
                _buildCnicDetailsRow(
                  label: 'Date of birth',
                  value: cnicExtracted['dateOfBirth'] as String?,
                ),
                _buildCnicDetailsRow(
                  label: 'Date of issue',
                  value: cnicExtracted['dateOfIssue'] as String?,
                ),
                _buildCnicDetailsRow(
                  label: 'Date of expiry',
                  value: cnicExtracted['dateOfExpiry'] as String?,
                ),
                _buildCnicDetailsRow(
                  label: 'Address (Urdu)',
                  value: addressUrduText,
                ),
                if (expectedMatches != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Match scores (0–1)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  _buildCnicDetailsRow(
                    label: 'Name match',
                    value: (expectedMatches['nameMatchesLikely'] as num?)
                        ?.toStringAsFixed(2),
                  ),
                  _buildCnicDetailsRow(
                    label: 'Father name match',
                    value: (expectedMatches['fatherNameMatchesLikely'] as num?)
                        ?.toStringAsFixed(2),
                  ),
                  _buildCnicDetailsRow(
                    label: 'DOB match',
                    value: (expectedMatches['dobMatchesLikely'] as num?)
                        ?.toStringAsFixed(2),
                  ),
                ],
              ],

              if (!hasAnyCnicDetails && cnicVerification != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Smart CNIC details',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'No CNIC details extracted yet. Below is the raw OCR payload.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],

              if (cnicVerification != null && !hasAnyCnicDetails) ...[
                const SizedBox(height: 12),
                Text(
                  'AI CNIC verification (raw)',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  _prettyJson(cnicVerification),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],

              if ((verification?['face'] as Map<String, dynamic>?) != null) ...[
                const SizedBox(height: 12),
                Text(
                  'AI face verification',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  _prettyJson(verification?['face']),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],

              if ((verification?['shop'] as Map<String, dynamic>?) != null) ...[
                const SizedBox(height: 12),
                Text(
                  'AI shop/tools verification',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  _prettyJson(verification?['shop']),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarningsSection(BuildContext context) {
    final bookingsQuery = FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: worker.id)
        .where('status', isEqualTo: BookingStatus.completed);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: bookingsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _sectionCard(
            context,
            title: 'Earnings',
            child: Text('Error loading earnings: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final bookings = docs
            .map((d) => BookingModel.fromMap(d.id, d.data()))
            .toList();

        final total = bookings.fold<num>(
          0,
          (totalSoFar, booking) => totalSoFar + booking.price,
        );

        return _sectionCard(
          context,
          title: 'Earnings',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total: PKR ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                bookings.isEmpty
                    ? 'No completed jobs yet.'
                    : 'Based on ${bookings.length} completed job(s).',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskSection(BuildContext context) {
    final bookingsQuery = FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: worker.id);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: bookingsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _sectionCard(
            context,
            title: 'Risk & quality signals',
            child: Text('Error loading risk indicators: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _sectionCard(
            context,
            title: 'Risk & quality signals',
            child: const Text('No booking history yet for this worker.'),
          );
        }

        final bookings = docs
            .map((d) => BookingModel.fromMap(d.id, d.data()))
            .toList();

        final totalCompleted = bookings
            .where((b) => b.status == BookingStatus.completed)
            .length;
        final totalCancelled = bookings
            .where((b) => b.status == BookingStatus.cancelled)
            .length;
        final totalNoShows = bookings
            .where((b) => (b.isNoShow ?? false))
            .length;
        final totalDisputes = bookings
            .where((b) => (b.hasDispute ?? false))
            .length;

        final totalRelevant = totalCompleted + totalCancelled;
        double cancelRate = 0;
        if (totalRelevant > 0) {
          cancelRate = (totalCancelled / totalRelevant) * 100.0;
        }

        double disputeRate = 0;
        if (totalCompleted > 0) {
          disputeRate = (totalDisputes / totalCompleted) * 100.0;
        }

        final List<Widget> bullets = [];

        bullets.add(
          Text(
            'Completed jobs: $totalCompleted, Cancelled: $totalCancelled',
            style: const TextStyle(fontSize: 13),
          ),
        );

        bullets.add(
          Text(
            'Cancellation rate: ${cancelRate.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 13),
          ),
        );

        bullets.add(
          Text(
            'Disputes on completed jobs: $totalDisputes (${disputeRate.toStringAsFixed(1)}%)',
            style: const TextStyle(fontSize: 13),
          ),
        );

        if (totalNoShows > 0) {
          bullets.add(
            Text(
              'No-shows recorded: $totalNoShows',
              style: const TextStyle(fontSize: 13),
            ),
          );
        }

        return _sectionCard(
          context,
          title: 'Risk & quality signals',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final w in bullets) ...[w, const SizedBox(height: 2)],
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    final reviewsQuery = FirebaseFirestore.instance
        .collection('reviews')
        .where('providerId', isEqualTo: worker.id)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: reviewsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _sectionCard(
            context,
            title: 'Customer reviews',
            child: Text('Error loading reviews: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _sectionCard(
            context,
            title: 'Customer reviews',
            child: const Text('No reviews yet.'),
          );
        }

        final reviews = docs
            .map((d) => ReviewModel.fromMap(d.id, d.data()))
            .toList();

        final avgRating = reviews.isEmpty
            ? 0.0
            : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                  reviews.length;

        final Map<String, int> strengthCounts = <String, int>{};
        final Map<String, int> issueCounts = <String, int>{};

        void addCount(Map<String, int> map, String key) {
          map[key] = (map[key] ?? 0) + 1;
        }

        for (final r in reviews) {
          final text = r.comment?.toLowerCase() ?? '';
          if (text.isEmpty) continue;

          if (text.contains('on time') ||
              text.contains('ontime') ||
              text.contains('punctual')) {
            addCount(strengthCounts, 'Punctual');
          }
          if (text.contains('friendly') ||
              text.contains('polite') ||
              text.contains('kind')) {
            addCount(strengthCounts, 'Friendly');
          }
          if (text.contains('clean') ||
              text.contains('neat') ||
              text.contains('tidy')) {
            addCount(strengthCounts, 'Clean');
          }
          if (text.contains('professional')) {
            addCount(strengthCounts, 'Professional');
          }
          if (text.contains('communicat')) {
            addCount(strengthCounts, 'Good communication');
          }
          if (text.contains('quick') || text.contains('fast')) {
            addCount(strengthCounts, 'Fast service');
          }

          if (text.contains('late') || text.contains('delay')) {
            addCount(issueCounts, 'Often late');
          }
          if (text.contains('cancel')) {
            addCount(issueCounts, 'Cancels bookings');
          }
          if (text.contains('no show') || text.contains('no-show')) {
            addCount(issueCounts, 'No-show');
          }
          if (text.contains('rude') || text.contains('bad behavior')) {
            addCount(issueCounts, 'Rude behavior');
          }
          if (text.contains('dirty') || text.contains('mess')) {
            addCount(issueCounts, 'Leaves place dirty');
          }
          if (text.contains('slow') || text.contains('took too long')) {
            addCount(issueCounts, 'Slow service');
          }
        }

        final List<MapEntry<String, int>> strengths =
            strengthCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
        final List<MapEntry<String, int>> issues = issueCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final topStrengths = strengths.length > 3
            ? strengths.sublist(0, 3)
            : strengths;
        final topIssues = issues.length > 3 ? issues.sublist(0, 3) : issues;

        return _sectionCard(
          context,
          title: 'Customer reviews',
          child: FutureBuilder<SentimentStats>(
            future: SentimentUtils.computeWithAi(reviews),
            builder: (context, snapshot) {
              final SentimentStats sentiment =
                  snapshot.data ?? SentimentUtils.compute(reviews);
              final sentimentPercent =
                  ((sentiment.avgScore + 1.0) / 2.0 * 100.0).clamp(0.0, 100.0);
              String sentimentLabel;
              if (sentiment.avgScore > 0.25) {
                sentimentLabel = 'Sentiment: Positive';
              } else if (sentiment.avgScore < -0.25) {
                sentimentLabel = 'Sentiment: Negative';
              } else {
                sentimentLabel = 'Sentiment: Neutral';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${reviews.length} review(s))',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$sentimentLabel | Sentiment score: ${sentimentPercent.toStringAsFixed(0)} / 100'
                    '  (Pos: ${sentiment.positiveCount}, Neu: ${sentiment.neutralCount}, Neg: ${sentiment.negativeCount})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (topStrengths.isNotEmpty) ...[
                    const Text(
                      'Top strengths',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: topStrengths
                          .map(
                            (e) => Chip(
                              label: Text(e.key),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (topIssues.isNotEmpty) ...[
                    const Text(
                      'Common issues',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: topIssues
                          .map(
                            (e) => Chip(
                              label: Text(e.key),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    separatorBuilder: (separatorContext, separatorIndex) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final r = reviews[index];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withValues(alpha: 0.07),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < r.rating ? Icons.star : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                            if (r.comment != null &&
                                r.comment!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  r.comment!,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              'Booking: ${r.bookingId}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCnicDetailsRow({required String label, String? value}) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  String? _joinNonEmpty(List<String?> parts) {
    final List<String> filtered = parts
        .where((p) => p != null && p.trim().isNotEmpty)
        .map((p) => p!.trim())
        .toList();
    if (filtered.isEmpty) {
      return null;
    }
    return filtered.join(', ');
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
