import 'package:flutter/material.dart';
import 'package:assist/user/category_search_page.dart';

class VoiceSearchCard extends StatefulWidget {
  final Color primaryLightBlue;
  final Color primaryDarkBlue;

  const VoiceSearchCard({
    super.key,
    required this.primaryLightBlue,
    required this.primaryDarkBlue,
  });

  @override
  State<VoiceSearchCard> createState() => _VoiceSearchCardState();
}

class _VoiceSearchCardState extends State<VoiceSearchCard> {
  // Local speech recognition removed. Voice search now relies only on
  // the AI-enhanced text search in CategorySearchPage.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color searchBg1 = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final Color searchBg2 = isDark ? const Color(0xFF303030) : Colors.white70;
    final Color searchTextColor = isDark ? Colors.white70 : Colors.black54;
    final Color searchIconBg = isDark
        ? Colors.white10
        : widget.primaryLightBlue.withValues(alpha: 0.12);
    final Color searchIconColor = isDark
        ? Colors.white70
        : widget.primaryDarkBlue;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CategorySearchPage()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [searchBg1, searchBg2]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: widget.primaryDarkBlue.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: searchIconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.search, color: searchIconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search services, providers or locations',
                style: TextStyle(color: searchTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
