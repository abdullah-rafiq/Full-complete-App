import 'package:assist/models/booking.dart';
import 'package:assist/models/service.dart';
import 'package:assist/models/app_user.dart';
import 'package:assist/services/service_catalog_service.dart';
import 'package:assist/services/user_service.dart';

class BookingsController {
  const BookingsController._();

  /// Preload all services referenced by the given bookings in as few
  /// Firestore queries as possible, using an in-memory cache for reuse.
  ///
  /// Returns a map from serviceId -> ServiceModel? (null if not found).
  static Future<Map<String, ServiceModel?>> loadServicesForBookings(
    List<BookingModel> bookings,
  ) async {
    if (bookings.isEmpty) return <String, ServiceModel?>{};

    final ids = bookings
        .map((b) => b.serviceId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) return <String, ServiceModel?>{};

    return ServiceCatalogService.instance.getServicesBatch(ids);
  }

  /// Preload all customers referenced by the given bookings.
  static Future<Map<String, AppUser?>> loadCustomersForBookings(
    List<BookingModel> bookings,
  ) async {
    if (bookings.isEmpty) return <String, AppUser?>{};

    final ids = bookings.map((b) => b.customerId).toSet().toList();
    if (ids.isEmpty) return <String, AppUser?>{};

    return UserService.instance.getUsersBatch(ids);
  }
}
