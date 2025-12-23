import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:assist/models/app_user.dart';
import 'package:assist/models/category.dart';
import 'package:assist/controllers/current_user_controller.dart';
import 'package:assist/services/service_catalog_service.dart';

class HomeController {
  const HomeController._();

  /// Current logged-in user profile shared across home surfaces.
  static Stream<AppUser?> watchCurrentUser() {
    return CurrentUserController.watchCurrentUser();
  }

  /// Categories used across main home surfaces.
  static Stream<List<CategoryModel>> watchCategories() {
    return ServiceCatalogService.instance.watchCategories();
  }

  /// Raw stream of provider user documents for building top workers lists.
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchProviderUsers() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'provider')
        .snapshots();
  }
}
