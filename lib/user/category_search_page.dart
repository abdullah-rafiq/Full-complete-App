// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/models/service.dart';
import 'package:flutter_application_1/services/service_catalog_service.dart';
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
  String _serviceSort = 'relevance'; // relevance, price_asc, price_desc
  bool _showCategories = true;
  bool _showServices = true;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim().toLowerCase() ?? '';
    _controller = TextEditingController(text: widget.initialQuery ?? '');
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String tempSort = _serviceSort;
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
                    'Sort by price:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: const Text('Price: Low to High'),
                    value: 'price_asc',
                    groupValue: tempSort,
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => tempSort = value);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Price: High to Low'),
                    value: 'price_desc',
                    groupValue: tempSort,
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => tempSort = value);
                    },
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
                            _serviceSort = tempSort;
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _openFilterSheet,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value.trim().toLowerCase();
                });
              },
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
                if (_query.isNotEmpty) {
                  categories = categories
                      .where((c) => c.name.toLowerCase().contains(_query))
                      .toList();
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
                    if (_query.isNotEmpty) {
                      services = services
                          .where((s) => s.name.toLowerCase().contains(_query))
                          .toList();
                    }

                    // Apply sorting for services
                    if (_serviceSort == 'price_asc') {
                      services.sort((a, b) => a.basePrice.compareTo(b.basePrice));
                    } else if (_serviceSort == 'price_desc') {
                      services.sort((a, b) => b.basePrice.compareTo(a.basePrice));
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Services',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                DropdownButton<String>(
                                  value: _serviceSort,
                                  underline: const SizedBox.shrink(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'relevance',
                                      child: Text('Relevance'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'price_asc',
                                      child: Text('Price: Low to High'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'price_desc',
                                      child: Text('Price: High to Low'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _serviceSort = value;
                                    });
                                  },
                                ),
                              ],
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

