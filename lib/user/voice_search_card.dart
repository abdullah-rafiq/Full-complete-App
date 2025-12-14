import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:flutter_application_1/common/ui_helpers.dart';
import 'package:flutter_application_1/user/category_search_page.dart';

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
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  Future<void> _startVoiceSearch() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {},
        onError: (error) {
          UIHelpers.showSnack(
            context,
            'Speech error: ${error.errorMsg}',
          );
        },
      );

      if (!available) {
        UIHelpers.showSnack(context, 'Speech recognition not available');
        return;
      }

      setState(() => _isListening = true);

      _speech.listen(
        onResult: (result) {
          if (!result.finalResult) return;
          final text = result.recognizedWords.trim();
          setState(() {
            _isListening = false;
          });

          if (text.isEmpty) return;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CategorySearchPage(initialQuery: text),
            ),
          );
        },
      );
    } catch (e) {
      setState(() => _isListening = false);
      UIHelpers.showSnack(context, 'Could not start voice search: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color searchBg1 =
        isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final Color searchBg2 =
        isDark ? const Color(0xFF303030) : Colors.white70;
    final Color searchTextColor =
        isDark ? Colors.white70 : Colors.black54;
    final Color searchIconBg =
        isDark ? Colors.white10 : widget.primaryLightBlue.withOpacity(0.12);
    final Color searchIconColor =
        isDark ? Colors.white70 : widget.primaryDarkBlue;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CategorySearchPage(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [searchBg1, searchBg2],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: widget.primaryDarkBlue.withOpacity(0.08),
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
            GestureDetector(
              onTap: _startVoiceSearch,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.primaryLightBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: widget.primaryDarkBlue,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
