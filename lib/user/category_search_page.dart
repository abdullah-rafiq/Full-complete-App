import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/models/service.dart';
import 'package:flutter_application_1/services/service_catalog_service.dart';
import 'package:flutter_application_1/services/ai_backend_service.dart';
import 'category_services_page.dart';
import 'service_detail_page.dart';

class CategorySearchPage extends StatefulWidget {
  final String? initialQuery;

  const CategorySearchPage({super.key, this.initialQuery});

  @override
  State<CategorySearchPage> createState() => _CategorySearchPageState();
}

class _CategorySearchPageState extends State<CategorySearchPage> {
  String _query = '';
  late final TextEditingController _controller;
  bool _showCategories = true;
  bool _showServices = true;
  String _aiQuery = '';
  Timer? _aiDebounce;
  bool _aiEnhancing = false;
  late final stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim().toLowerCase() ?? '';
    _aiQuery = _query;
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _aiDebounce?.cancel();
    if (_isListening) {
      _speech.stop();
    }
    _controller.dispose();
    super.dispose();
  }

  void _handleQueryChanged(String value) {
    final raw = value.trim();
    setState(() {
      _query = raw.toLowerCase();
    });

    _aiDebounce?.cancel();

    if (raw.isEmpty) {
      setState(() {
        _aiQuery = '';
        _aiEnhancing = false;
      });
      return;
    }

    _aiDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() {
        _aiEnhancing = true;
      });

      try {
        final translated = await AiBackendService.instance
            .translateToEnglish(raw);
        if (!mounted) return;
        final lowered = translated.trim().toLowerCase();
        setState(() {
          _aiQuery = lowered.isNotEmpty ? lowered : _query;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _aiQuery = _query;
        });
      } finally {
        if (mounted) {
          setState(() {
            _aiEnhancing = false;
          });
        }
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {},
      onError: (error) {},
    );

    if (!available) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        _controller.text = text;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        _handleQueryChanged(text);

        if (result.finalResult) {
          _speech.stop();
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
        }
      },
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        bool tempShowCategories = _showCategories;
        bool tempShowServices = _showServices;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Show results from:',
                    style: TextStyle(fontSize: 13),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Categories'),
                    value: tempShowCategories,
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => tempShowCategories = value);
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Services'),
                    value: tempShowServices,
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => tempShowServices = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showCategories = tempShowCategories;
                            _showServices = tempShowServices;
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Search services'),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search services or categories...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_aiEnhancing)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                      ),
                      onPressed: _toggleListening,
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _openFilterSheet,
                    ),
                  ],
                ),
              ),
              onChanged: _handleQueryChanged,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CategoryModel>>(
              stream: ServiceCatalogService.instance.watchCategories(),
              builder: (context, catSnapshot) {
                if (catSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (catSnapshot.hasError) {
                  return const Center(child: Text('Could not load categories'));
                }

                var categories = catSnapshot.data ?? [];
                final String q = _query;
                final String aiQ = _aiQuery;
                if (q.isNotEmpty || aiQ.isNotEmpty) {
                  categories = categories.where((c) {
                    final name = c.name.toLowerCase();
                    final bool matchesNormal =
                        q.isNotEmpty && name.contains(q);
                    final bool matchesAi =
                        aiQ.isNotEmpty && name.contains(aiQ);
                    return matchesNormal || matchesAi;
                  }).toList();
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('services')
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, svcSnapshot) {
                    if (svcSnapshot.hasError) {
                      return const Center(
                          child: Text('Could not load services'));
                    }

                    var services = (svcSnapshot.data?.docs ?? [])
                        .map((d) => ServiceModel.fromMap(d.id, d.data()))
                        .toList();
                    final String q = _query;
                    final String aiQ = _aiQuery;
                    if (q.isNotEmpty || aiQ.isNotEmpty) {
                      services = services.where((s) {
                        final name = s.name.toLowerCase();
                        final bool matchesNormal =
                            q.isNotEmpty && name.contains(q);
                        final bool matchesAi =
                            aiQ.isNotEmpty && name.contains(aiQ);
                        return matchesNormal || matchesAi;
                      }).toList();
                    }

                    final hasCategories = _showCategories && categories.isNotEmpty;
                    final hasServices = _showServices && services.isNotEmpty;

                    if (!hasCategories && !hasServices) {
                      return const Center(
                          child: Text('No matching categories or services'));
                    }

                    return ListView(
                      children: [
                        if (hasCategories) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          ...categories.map((cat) {
                            return Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Colors.blueAccent.withOpacity(0.1),
                                    child: Text(
                                      cat.name.isNotEmpty
                                          ? cat.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(cat.name),
                                  subtitle: Text(
                                    cat.isActive
                                        ? 'Available'
                                        : 'Currently unavailable',
                                    style: TextStyle(
                                      color: cat.isActive
                                          ? Colors.green
                                          : Colors.redAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CategoryServicesPage(
                                          category: cat,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const Divider(height: 1),
                              ],
                            );
                          }),
                        ],
                        if (hasServices) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: const Text(
                              'Services',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          ...services.map((svc) {
                            return Column(
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.cleaning_services_rounded,
                                    color: Colors.blueAccent,
                                  ),
                                  title: Text(svc.name),
                                  subtitle: Text(
                                    'From PKR ${svc.basePrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ServiceDetailPage(
                                          service: svc,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const Divider(height: 1),
                              ],
                            );
                          }),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

