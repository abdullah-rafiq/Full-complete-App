import 'package:flutter/material.dart';

import 'package:assist/models/category.dart';
import 'package:assist/services/service_catalog_service.dart';
import 'package:assist/user/category_services_page.dart';
import 'package:assist/localized_strings.dart';

class CustomerCategoriesPage extends StatelessWidget {
  const CustomerCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 4,
        title: Text(L10n.mainCategoriesTitle()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.08),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ) ??
                      const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<List<CategoryModel>>(
                  stream: ServiceCatalogService.instance.watchCategories(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Could not load categories.'),
                      );
                    }

                    final categories = snapshot.data ?? [];

                    if (categories.isEmpty) {
                      return const Center(child: Text('No categories available.'));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return ListTile(
                          leading:
                              (cat.iconUrl != null && cat.iconUrl!.isNotEmpty)
                                  ? CircleAvatar(
                                      backgroundImage: AssetImage(cat.iconUrl!),
                                    )
                                  : CircleAvatar(
                                      backgroundColor:
                                          colorScheme.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      child: Text(
                                        cat.name.isNotEmpty
                                            ? cat.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                          title: Text(cat.name),
                          subtitle: Text(
                            cat.isActive
                                ? L10n.statusAvailable()
                                : L10n.statusUnavailable(),
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
                                builder: (_) =>
                                    CategoryServicesPage(category: cat),
                              ),
                            );
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemCount: categories.length,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
