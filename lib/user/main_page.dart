import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:assist/models/app_user.dart';
import 'package:assist/models/category.dart';
import 'package:assist/services/service_catalog_service.dart';
import 'package:assist/controllers/profile_controller.dart';
import 'package:assist/controllers/current_user_controller.dart';
import 'package:assist/common/section_card.dart';
import 'package:assist/common/ui_helpers.dart';
import 'package:assist/user/category_services_page.dart';
import 'package:assist/user/my_bookings_page.dart';
import 'package:assist/common/profile_page.dart';
import 'package:assist/common/messages_page.dart';
import 'package:assist/common/notifications_page.dart';
import 'package:assist/common/app_bottom_nav.dart';
import 'package:assist/user/top_workers_section.dart';
import 'package:assist/user/featured_providers_section.dart';
import 'package:assist/user/voice_search_card.dart';
import 'package:assist/localized_strings.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final Color primaryLightBlue = const Color(0xFF4FC3F7);
  final Color primaryBlue = const Color(0xFF29B6F6);
  final Color primaryDarkBlue = const Color(0xFF0288D1);
  late final Color surfaceWhite = Colors.white.withValues(alpha: 0.95);
  int _currentIndex = 0;
  String? _displayName;
  String? _currentCity;
  late final List<Widget?> _pages;
  static const List<String> _promoImagePaths = [
    'assets/carsoual/1.jpg',
    'assets/carsoual/2.jpg',
    'assets/carsoual/3.jpg',
    'assets/carsoual/4.jpg',
  ];

  // Speech-to-text
  final PageController _promoController = PageController(viewportFraction: 0.9);
  Timer? _promoAutoScrollTimer;
  int _promoCurrentPage = 0;

  @override
  void initState() {
    super.initState();
    _pages = List<Widget?>.filled(5, null);

    _promoAutoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_promoController.hasClients) return;

      final pageCount = _promoImagePaths.length;
      if (pageCount <= 1) return;

      final nextPage = (_promoCurrentPage + 1) % pageCount;
      _promoController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });

    // After the first home frame, warm up other tabs so their Firestore
    // streams start in the background before the user taps them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _pages[1] ??= _buildCategoriesTab(context);
        _pages[2] ??= const MyBookingsPage();
        _pages[3] ??= const MessagesPage();
      });
    });
  }

  @override
  void dispose() {
    _promoAutoScrollTimer?.cancel();
    _promoController.dispose();
    super.dispose();
  }

  Widget _buildPromoCarousel() {
    return SizedBox(
      height: 180,
      child: PageView(
        controller: _promoController,
        onPageChanged: (index) {
          _promoCurrentPage = index;
        },
        children: _promoImagePaths.map(_buildPromoCard).toList(),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      UIHelpers.showSnack(context, 'You must be logged in to update location.');
      return;
    }
    final result = await ProfileController.updateLocationFromCurrentPosition(
      context,
      current.uid,
    );

    if (!mounted || result == null) return;

    if (result.city != null && result.city != _currentCity) {
      setState(() {
        _currentCity = result.city;
      });
    }
  }

  Widget _buildPromoCard(String assetPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          assetPath,
          fit: BoxFit.fitWidth,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: primaryLightBlue.withValues(alpha: 0.2),
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGradientAppBar(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final double appBarHeight = topPadding + 52;
    final current = FirebaseAuth.instance.currentUser;
    return Container(
      height: appBarHeight,
      padding: EdgeInsets.only(top: topPadding, left: 12, right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryLightBlue, primaryDarkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDarkBlue.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L10n.mainWelcomePrefix(),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (current == null)
                    const Text(
                      'User',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    )
                  else
                    StreamBuilder<AppUser?>(
                      stream: CurrentUserController.watchCurrentUser(),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        String effectiveName = _displayName ?? 'User';

                        // Prefer Firestore profile name; then auth displayName; then email prefix
                        String? rawName = user?.name?.trim();
                        if (rawName == null || rawName.isEmpty) {
                          final authName = current.displayName?.trim();
                          if (authName != null && authName.isNotEmpty) {
                            rawName = authName;
                          }
                        }
                        if (rawName == null || rawName.isEmpty) {
                          final email = current.email?.trim();
                          if (email != null && email.isNotEmpty) {
                            rawName = email.split('@').first;
                          }
                        }

                        if (rawName != null && rawName.isNotEmpty) {
                          final formatted =
                              rawName[0].toUpperCase() +
                              (rawName.length > 1 ? rawName.substring(1) : '');
                          effectiveName = formatted;
                        }

                        if (effectiveName != _displayName) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            setState(() {
                              _displayName = effectiveName;
                            });
                          });
                        }

                        return Text(
                          effectiveName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (_currentCity != null && _currentCity!.isNotEmpty)
                TextButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    _currentCity!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  onPressed: _useCurrentLocation,
                ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return StreamBuilder<List<CategoryModel>>(
      stream: ServiceCatalogService.instance.watchCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Could not load categories.'));
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return const Center(child: Text('No categories available.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemBuilder: (context, index) {
            final cat = categories[index];
            return ListTile(
              leading: (cat.iconUrl != null && cat.iconUrl!.isNotEmpty)
                  ? CircleAvatar(backgroundImage: AssetImage(cat.iconUrl!))
                  : CircleAvatar(
                      backgroundColor: primaryLightBlue.withValues(alpha: 0.2),
                      child: Text(
                        cat.name.isNotEmpty ? cat.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
              title: Text(cat.name),
              subtitle: Text(
                cat.isActive
                    ? L10n.statusAvailable()
                    : L10n.statusUnavailable(),
                style: TextStyle(
                  color: cat.isActive ? Colors.green : Colors.redAccent,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CategoryServicesPage(category: cat),
                  ),
                );
              },
            );
          },
          separatorBuilder: (_, index) => const Divider(height: 1),
          itemCount: categories.length,
        );
      },
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    return VoiceSearchCard(
      primaryLightBlue: primaryLightBlue,
      primaryDarkBlue: primaryDarkBlue,
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 140,
      child: StreamBuilder<List<CategoryModel>>(
        stream: ServiceCatalogService.instance.watchCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Could not load categories.'));
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return const Center(child: Text('No categories available.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoryServicesPage(category: cat),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryLightBlue.withValues(
                              alpha: 0.9 - index * 0.08,
                            ),
                            primaryBlue.withValues(alpha: 0.85 - index * 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: primaryDarkBlue.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: (cat.iconUrl != null && cat.iconUrl!.isNotEmpty)
                            ? Image.asset(
                                cat.iconUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      cat.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  cat.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (_, index) => const SizedBox(width: 14),
            itemCount: categories.length,
          );
        },
      ),
    );
  }

  Widget _buildUpcomingBookingsCard() {
    return SectionCard(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          const ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'),
            ),
            title: Text('Plumbing - Kitchen sink'),
            subtitle: Text('Tomorrow • 10:00 AM'),
            trailing: Chip(
              label: Text('Requested', style: TextStyle(color: Colors.orange)),
              backgroundColor: Color(0x22FFA726),
            ),
          ),
          const Divider(),
          const ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'),
            ),
            title: Text('Home Cleaning'),
            subtitle: Text('2025-11-25 • 2:00 PM'),
            trailing: Chip(
              label: Text('Confirmed', style: TextStyle(color: Colors.green)),
              backgroundColor: Color(0x2232CD32),
            ),
          ),
        ],
      ),
    );
  }

  // Simple shared section header for this page only
  Widget _buildSectionHeader(String title) {
    final textStyle =
        Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ) ??
        const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
      child: Text(title, style: textStyle),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return ScrollConfiguration(
      behavior: const ScrollBehavior(),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGradientAppBar(context),
              _buildPromoCarousel(),
              _buildSearchCard(context),
              const SizedBox(height: 6),
              _buildSectionHeader(L10n.mainCategoriesTitle()),
              _buildCategories(),
              const SizedBox(height: 12),
              _buildSectionHeader(L10n.mainFeaturedProvidersTitle()),
              const FeaturedProvidersSection(),
              const SizedBox(height: 16),
              const TopWorkersSection(),
              const SizedBox(height: 16),
              _buildSectionHeader(L10n.mainUpcomingBookingsTitle()),
              _buildUpcomingBookingsCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesTab(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 4,
        title: Text(L10n.mainCategoriesTitle()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: primaryDarkBlue.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18.0,
                  vertical: 12,
                ),
                child: Text(
                  L10n.mainAllCategoriesTitle(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _buildCategoriesList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createPageForIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        return _buildHomeTab(context);
      case 1:
        return _buildCategoriesTab(context);
      case 2:
        return const MyBookingsPage();
      case 3:
        return const MessagesPage();
      case 4:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  List<Widget> _buildIndexedStackChildren(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < _pages.length; i++) {
      final cached = _pages[i];
      if (cached != null) {
        children.add(cached);
        continue;
      }
      if (i != _currentIndex) {
        children.add(const SizedBox.shrink());
        continue;
      }
      final page = _createPageForIndex(context, i);
      _pages[i] = page;
      children.add(page);
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildIndexedStackChildren(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: L10n.customerNavHome(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.category_outlined),
            label: L10n.customerNavCategories(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            label: L10n.customerNavBookings(),
          ),
          BottomNavigationBarItem(
            icon: _MessagesIconWithBadge(),
            label: L10n.customerNavMessages(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: L10n.customerNavProfile(),
          ),
        ],
      ),
    );
  }
}

class _MessagesIconWithBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Icon(Icons.message_outlined);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final hasUnread = docs.any((doc) {
          final data = doc.data();
          final lastSender = data['lastMessageSenderId'] as String?;
          return lastSender != null && lastSender != user.uid;
        });

        if (!hasUnread) {
          return const Icon(Icons.message_outlined);
        }

        return Stack(
          clipBehavior: Clip.none,
          children: const [
            Icon(Icons.message_outlined),
            Positioned(
              right: -2,
              top: -2,
              child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }
}
