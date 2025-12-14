import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedDemoData() async {
  final db = FirebaseFirestore.instance;

  WriteBatch batch = db.batch();

  // USERS
  final userCustomer1 = db.collection('users').doc('user_customer_1');
  batch.set(userCustomer1, {
    'name': 'Ali Customer',
    'phone': '+92...',
    'email': 'ali.customer@example.com',
    'role': 'customer',
    'status': 'Active',
    'profileImageUrl': null,
    'verified': false,
    'walletBalance': 1500,
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 1, 10)),
    'lastSeen': Timestamp.fromDate(DateTime(2024, 11, 25, 14)),
    'city': 'Karachi',
    'addressLine1': 'House 12, Street 3',
    'town': 'DHA',
    'locationLat': 24.8607,
    'locationLng': 67.0011,
    'notificationsEnabled': true,
  });

  // Second approved provider (Lahore)
  final userProvider2 = db.collection('users').doc('user_provider_2');
  batch.set(userProvider2, {
    'name': 'Hamza Provider',
    'phone': '+92...444',
    'email': 'hamza.provider@example.com',
    'role': 'provider',
    'status': 'Active',
    'profileImageUrl': null,
    'verified': true,
    'walletBalance': 0,
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 4, 11)),
    'lastSeen': Timestamp.fromDate(DateTime(2024, 11, 25, 12, 45)),
    'verificationStatus': 'approved',
    'verificationReason': null,
    'city': 'Lahore',
    'addressLine1': 'Workshop 10, Johar Town',
    'town': 'Johar Town',
    'locationLat': 31.4676,
    'locationLng': 74.2728,
    'notificationsEnabled': true,
  });

  // Third approved provider (Islamabad)
  final userProvider3 = db.collection('users').doc('user_provider_3');
  batch.set(userProvider3, {
    'name': 'Ayesha Provider',
    'phone': '+92...555',
    'email': 'ayesha.provider@example.com',
    'role': 'provider',
    'status': 'Active',
    'profileImageUrl': null,
    'verified': true,
    'walletBalance': 0,
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 6, 16)),
    'lastSeen': Timestamp.fromDate(DateTime(2024, 11, 25, 16)),
    'verificationStatus': 'approved',
    'verificationReason': null,
    'city': 'Islamabad',
    'addressLine1': 'Shop 3, Blue Area',
    'town': 'Blue Area',
    'locationLat': 33.6938,
    'locationLng': 73.0652,
    'notificationsEnabled': true,
  });

  // Second customer (Lahore)
  final userCustomer2 = db.collection('users').doc('user_customer_2');
  batch.set(userCustomer2, {
    'name': 'Fatima Customer',
    'phone': '+92...222',
    'email': 'fatima.customer@example.com',
    'role': 'customer',
    'status': 'Active',
    'profileImageUrl': null,
    'verified': false,
    'walletBalance': 800,
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 5, 11)),
    'lastSeen': Timestamp.fromDate(DateTime(2024, 11, 25, 13)),
    'city': 'Lahore',
    'addressLine1': 'Flat 21, Gulberg',
    'town': 'Gulberg',
    'locationLat': 31.5204,
    'locationLng': 74.3587,
    'notificationsEnabled': true,
  });

  // Third customer (Islamabad)
  final userCustomer3 = db.collection('users').doc('user_customer_3');
  batch.set(userCustomer3, {
    'name': 'Usman Customer',
    'phone': '+92...333',
    'email': 'usman.customer@example.com',
    'role': 'customer',
    'status': 'Active',
    'profileImageUrl': null,
    'verified': false,
    'walletBalance': 500,
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 6, 9)),
    'lastSeen': Timestamp.fromDate(DateTime(2024, 11, 25, 11, 30)),
    'city': 'Islamabad',
    'addressLine1': 'Sector F-7, Street 8',
    'town': 'F-7',
    'locationLat': 33.6844,
    'locationLng': 73.0479,
    'notificationsEnabled': true,
  });

  // Approved provider (visible in workers list, not pending)
  final userProvider1 = db.collection('users').doc('user_provider_1');
  batch.set(userProvider1, {
    'name': 'Sara Provider',
    'phone': '+92...',
    'email': 'sara.provider@example.com',
    'role': 'provider',
    'status': 'Active',
    'profileImageUrl': null,
    'verified': true,
    'walletBalance': 0,
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 2, 10)),
    'lastSeen': Timestamp.fromDate(DateTime(2024, 11, 25, 13, 30)),
    'verificationStatus': 'approved',
    'verificationReason': null,
    'city': 'Karachi',
    'addressLine1': 'Shop 5, Main Market',
    'town': 'Gulshan',
    'locationLat': 24.8607,
    'locationLng': 67.0011,
    'notificationsEnabled': true,
  });

  // Pending provider (for AdminPendingWorkersPage)
  final userProviderPending =
      db.collection('users').doc('user_provider_pending_1');
  batch.set(userProviderPending, {
    'name': 'Pending Provider',
    'phone': '+92...123',
    'email': 'pending.provider@example.com',
    'role': 'provider',
    'status': 'Active',
    'profileImageUrl': null,
    'verified': false,
    'walletBalance': 0,
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 3, 9)),
    'lastSeen': Timestamp.fromDate(DateTime(2024, 11, 25, 12)),
    'verificationStatus': 'pending',
    'verificationReason': null,
    'city': 'Karachi',
    'addressLine1': 'Pending Market, Shop 12',
    'town': 'Gulshan',
    'locationLat': 24.8607,
    'locationLng': 67.0011,
    'notificationsEnabled': true,
  });

  // Admin user (for admin pages)
  final userAdmin1 = db.collection('users').doc('user_admin_1');
  batch.set(userAdmin1, {
    'name': 'Admin User',
    'phone': '+92...999',
    'email': 'admin@example.com',
    'role': 'admin',
    'status': 'Active',
    'profileImageUrl': null,
    'verified': true,
    'walletBalance': 0,
    'createdAt': Timestamp.fromDate(DateTime(2024, 10, 20, 10)),
    'lastSeen': Timestamp.fromDate(DateTime(2024, 11, 25, 15)),
    'city': 'Karachi',
    'addressLine1': 'Head Office',
    'town': 'Downtown',
    'locationLat': 24.8607,
    'locationLng': 67.0011,
    'notificationsEnabled': true,
  });

  final serviceDeepCleaning =
      db.collection('services').doc('deep_cleaning_3bhk');
  batch.set(serviceDeepCleaning, {
    'name': 'Deep Cleaning (3 BHK)',
    'categoryId': 'cleaner',
    'description': 'Full house deep cleaning',
    'basePrice': 3500,
    'durationEstimate': 180,
    'images': <String>[
      'https://example.com/demo/deep-cleaning.jpg',
    ],
    'isActive': true,
    // For demo: attach to an approved Karachi provider so distance logic works
    'providerId': 'user_provider_1',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 10, 9)),
  });

  final serviceAcRepair =
      db.collection('services').doc('ac_repair_split');
  batch.set(serviceAcRepair, {
    'name': 'AC Repair - Split Unit',
    'categoryId': 'ac_repair',
    'description': 'Repair and servicing of split AC units',
    'basePrice': 2500,
    'durationEstimate': 90,
    'images': <String>[
      'https://example.com/demo/ac-repair.jpg',
    ],
    'isActive': true,
    // Attach to Karachi provider for demo distance filtering
    'providerId': 'user_provider_1',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 12, 10)),
  });

  final servicePlumber = db.collection('services').doc('plumbing_leak_fix');
  batch.set(servicePlumber, {
    'name': 'Plumbing - Leak Fix',
    'categoryId': 'plumber',
    'description': 'Fixing common pipe and tap leaks',
    'basePrice': 1800,
    'durationEstimate': 60,
    'images': <String>[
      'https://example.com/demo/plumbing.jpg',
    ],
    'isActive': true,
    // Attach to Lahore provider so Lahore customers see a nearby plumber
    'providerId': 'user_provider_2',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 13, 11)),
  });

  final serviceElectrician =
      db.collection('services').doc('electrician_fault_fix');
  batch.set(serviceElectrician, {
    'name': 'Electrician - Fault Fix',
    'categoryId': 'electrician',
    'description': 'Troubleshooting and fixing electrical faults',
    'basePrice': 2000,
    'durationEstimate': 75,
    'images': <String>[
      'https://example.com/demo/electrician.jpg',
    ],
    'isActive': true,
    // Attach to Karachi provider for demo
    'providerId': 'user_provider_1',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 14, 10)),
  });

  final serviceCarpenter =
      db.collection('services').doc('carpenter_furniture_repair');
  batch.set(serviceCarpenter, {
    'name': 'Carpenter - Furniture Repair',
    'categoryId': 'carpenter',
    'description': 'Repairing doors, cupboards, and furniture',
    'basePrice': 2200,
    'durationEstimate': 120,
    'images': <String>[
      'https://example.com/demo/carpentry.jpg',
    ],
    'isActive': true,
    // Attach to Islamabad provider so Islamabad customers see a nearby carpenter
    'providerId': 'user_provider_3',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 15, 9)),
  });

  final servicePainter = db.collection('services').doc('painter_room');
  batch.set(servicePainter, {
    'name': 'Painter - Single Room',
    'categoryId': 'painter',
    'description': 'Painting a standard size room with one color',
    'basePrice': 3000,
    'durationEstimate': 180,
    'images': <String>[
      'https://example.com/demo/painting.jpg',
    ],
    'isActive': true,
    // Attach to Lahore provider for demo
    'providerId': 'user_provider_2',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 16, 9)),
  });

  final serviceBarber = db.collection('services').doc('barber_home_haircut');
  batch.set(serviceBarber, {
    'name': 'Barber - Home Haircut',
    'categoryId': 'barber',
    'description': 'At-home haircut and basic grooming',
    'basePrice': 1200,
    'durationEstimate': 45,
    'images': <String>[
      'https://example.com/demo/barber.jpg',
    ],
    'isActive': true,
    // Attach to Karachi provider for demo
    'providerId': 'user_provider_1',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 17, 10)),
  });

  final booking1 = db.collection('bookings').doc('booking_1');
  batch.set(booking1, {
    'serviceId': 'deep_cleaning_3bhk',
    'customerId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'status': 'Requested',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 11, 30, 10)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 25, 10, 30)),
    'location': const GeoPoint(24.8607, 67.0011),
    'address': 'Some address in Karachi',
    'price': 3500,
    'paymentStatus': 'Pending',
    'paymentMethod': 'card',
    'paymentProviderId': null,
    'paymentAmount': null,
    'notes': 'Please bring own supplies',
    'cancelledBy': null,
    'isNoShow': null,
    'hasDispute': null,
  });

  final booking2 = db.collection('bookings').doc('booking_2');
  batch.set(booking2, {
    'serviceId': 'deep_cleaning_3bhk',
    'customerId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'status': 'Completed',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 11, 20, 14)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 19, 16, 30)),
    'location': const GeoPoint(24.8607, 67.0011),
    'address': 'Old booking, already done',
    'price': 3500,
    'paymentStatus': 'Paid',
    'paymentMethod': 'card',
    'paymentProviderId': 'demo_gateway_456',
    'paymentAmount': 3500,
    'notes': 'Completed successfully',
    'cancelledBy': null,
    'isNoShow': false,
    'hasDispute': false,
  });

  // Additional bookings for richer analytics and worker dashboards
  final booking4 = db.collection('bookings').doc('booking_4');
  batch.set(booking4, {
    'serviceId': 'deep_cleaning_3bhk',
    'customerId': 'user_customer_2',
    'providerId': 'user_provider_2',
    'status': 'Completed',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 11, 18, 11)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 17, 14, 15)),
    'location': const GeoPoint(31.5204, 74.3587),
    'address': 'Apartment, Gulberg Lahore',
    'price': 4200,
    'paymentStatus': 'Paid',
    'paymentMethod': 'card',
    'paymentProviderId': 'demo_gateway_111',
    'paymentAmount': 4200,
    'notes': 'Include sofa cleaning',
    'cancelledBy': null,
    'isNoShow': false,
    'hasDispute': false,
  });

  final booking5 = db.collection('bookings').doc('booking_5');
  batch.set(booking5, {
    'serviceId': 'deep_cleaning_3bhk',
    'customerId': 'user_customer_2',
    'providerId': 'user_provider_2',
    'status': 'InProgress',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 11, 29, 9)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 29, 8, 30)),
    'location': const GeoPoint(31.5204, 74.3587),
    'address': 'House 8, Johar Town Lahore',
    'price': 3800,
    'paymentStatus': 'Pending',
    'paymentMethod': 'card',
    'paymentProviderId': null,
    'paymentAmount': null,
    'notes': 'Customer at home',
    'cancelledBy': null,
    'isNoShow': null,
    'hasDispute': false,
  });

  final booking6 = db.collection('bookings').doc('booking_6');
  batch.set(booking6, {
    'serviceId': 'deep_cleaning_3bhk',
    'customerId': 'user_customer_3',
    'providerId': 'user_provider_3',
    'status': 'OnTheWay',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 11, 30, 15)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 30, 14, 20)),
    'location': const GeoPoint(33.6844, 73.0479),
    'address': 'House 22, F-7 Islamabad',
    'price': 3600,
    'paymentStatus': 'Pending',
    'paymentMethod': 'card',
    'paymentProviderId': null,
    'paymentAmount': null,
    'notes': 'Bring eco-friendly products',
    'cancelledBy': null,
    'isNoShow': null,
    'hasDispute': false,
  });

  final booking7 = db.collection('bookings').doc('booking_7');
  batch.set(booking7, {
    'serviceId': 'deep_cleaning_3bhk',
    'customerId': 'user_customer_3',
    'providerId': 'user_provider_3',
    'status': 'Accepted',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 12, 1, 11)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 30, 18, 10)),
    'location': const GeoPoint(33.6938, 73.0652),
    'address': 'Flat 5, Blue Area Islamabad',
    'price': 3900,
    'paymentStatus': 'Pending',
    'paymentMethod': 'card',
    'paymentProviderId': null,
    'paymentAmount': null,
    'notes': 'Parking available in basement',
    'cancelledBy': null,
    'isNoShow': null,
    'hasDispute': false,
  });

  final booking8 = db.collection('bookings').doc('booking_8');
  batch.set(booking8, {
    'serviceId': 'deep_cleaning_3bhk',
    'customerId': 'user_customer_2',
    'providerId': 'user_provider_1',
    'status': 'Completed',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 11, 15, 9)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 14, 12, 0)),
    'location': const GeoPoint(31.5204, 74.3587),
    'address': 'Old town Lahore',
    'price': 3400,
    'paymentStatus': 'Paid',
    'paymentMethod': 'card',
    'paymentProviderId': 'demo_gateway_222',
    'paymentAmount': 3400,
    'notes': 'Customer reported minor issue',
    'cancelledBy': null,
    'isNoShow': false,
    'hasDispute': true,
  });

  // AC repair bookings
  final booking9 = db.collection('bookings').doc('booking_9');
  batch.set(booking9, {
    'serviceId': 'ac_repair_split',
    'customerId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'status': 'Completed',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 11, 22, 11)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 21, 15)),
    'location': const GeoPoint(24.8607, 67.0011),
    'address': 'Apartment in DHA, Karachi',
    'price': 2500,
    'paymentStatus': 'Paid',
    'paymentMethod': 'card',
    'paymentProviderId': 'demo_gateway_333',
    'paymentAmount': 2500,
    'notes': 'AC cooling issue resolved',
    'cancelledBy': null,
    'isNoShow': false,
    'hasDispute': false,
  });

  final booking10 = db.collection('bookings').doc('booking_10');
  batch.set(booking10, {
    'serviceId': 'ac_repair_split',
    'customerId': 'user_customer_3',
    'providerId': 'user_provider_3',
    'status': 'Requested',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 12, 2, 10)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 12, 1, 20)),
    'location': const GeoPoint(33.6938, 73.0652),
    'address': 'Office in Blue Area, Islamabad',
    'price': 2700,
    'paymentStatus': 'Pending',
    'paymentMethod': 'card',
    'paymentProviderId': null,
    'paymentAmount': null,
    'notes': 'Water leakage from indoor unit',
    'cancelledBy': null,
    'isNoShow': null,
    'hasDispute': false,
  });

  // Category-specific demo bookings for other services
  final booking11 = db.collection('bookings').doc('booking_11');
  batch.set(booking11, {
    'serviceId': 'plumbing_leak_fix',
    'customerId': 'user_customer_2',
    'providerId': 'user_provider_2',
    'status': 'Completed',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 11, 18, 15)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 17, 17, 0)),
    'location': const GeoPoint(31.5204, 74.3587),
    'address': 'Bathroom leak, Gulberg Lahore',
    'price': 2000,
    'paymentStatus': 'Paid',
    'paymentMethod': 'card',
    'paymentProviderId': 'demo_gateway_444',
    'paymentAmount': 2000,
    'notes': 'Pipe under sink was leaking',
    'cancelledBy': null,
    'isNoShow': false,
    'hasDispute': false,
  });

  final booking12 = db.collection('bookings').doc('booking_12');
  batch.set(booking12, {
    'serviceId': 'electrician_fault_fix',
    'customerId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'status': 'Completed',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 11, 21, 18)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 21, 16, 0)),
    'location': const GeoPoint(24.8607, 67.0011),
    'address': 'Living room wiring fault, Karachi',
    'price': 2300,
    'paymentStatus': 'Paid',
    'paymentMethod': 'card',
    'paymentProviderId': 'demo_gateway_555',
    'paymentAmount': 2300,
    'notes': 'Short circuit issue fixed',
    'cancelledBy': null,
    'isNoShow': false,
    'hasDispute': false,
  });

  final booking13 = db.collection('bookings').doc('booking_13');
  batch.set(booking13, {
    'serviceId': 'carpenter_furniture_repair',
    'customerId': 'user_customer_3',
    'providerId': 'user_provider_3',
    'status': 'Completed',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 11, 23, 11)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 22, 15, 30)),
    'location': const GeoPoint(33.6844, 73.0479),
    'address': 'Wardrobe door repair, Islamabad',
    'price': 2600,
    'paymentStatus': 'Paid',
    'paymentMethod': 'card',
    'paymentProviderId': 'demo_gateway_666',
    'paymentAmount': 2600,
    'notes': 'Re-aligned hinges and fixed door',
    'cancelledBy': null,
    'isNoShow': false,
    'hasDispute': false,
  });

  final booking14 = db.collection('bookings').doc('booking_14');
  batch.set(booking14, {
    'serviceId': 'painter_room',
    'customerId': 'user_customer_2',
    'providerId': 'user_provider_2',
    'status': 'Completed',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 11, 24, 9)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 23, 14, 0)),
    'location': const GeoPoint(31.5204, 74.3587),
    'address': 'Bedroom repaint, Lahore',
    'price': 3200,
    'paymentStatus': 'Paid',
    'paymentMethod': 'card',
    'paymentProviderId': 'demo_gateway_777',
    'paymentAmount': 3200,
    'notes': 'One accent wall added',
    'cancelledBy': null,
    'isNoShow': false,
    'hasDispute': false,
  });

  final booking15 = db.collection('bookings').doc('booking_15');
  batch.set(booking15, {
    'serviceId': 'barber_home_haircut',
    'customerId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'status': 'Completed',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 11, 26, 17)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 26, 15, 30)),
    'location': const GeoPoint(24.8607, 67.0011),
    'address': 'Home haircut, DHA Karachi',
    'price': 1400,
    'paymentStatus': 'Paid',
    'paymentMethod': 'card',
    'paymentProviderId': 'demo_gateway_888',
    'paymentAmount': 1400,
    'notes': 'Standard haircut and beard trim',
    'cancelledBy': null,
    'isNoShow': false,
    'hasDispute': false,
  });

  final booking3 = db.collection('bookings').doc('booking_3');
  batch.set(booking3, {
    'serviceId': 'deep_cleaning_3bhk',
    'customerId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'status': 'Cancelled',
    'scheduledTime': Timestamp.fromDate(DateTime(2024, 11, 28, 9)),
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 27, 10)),
    'location': const GeoPoint(24.8607, 67.0011),
    'address': 'Cancelled by customer',
    'price': 3500,
    'paymentStatus': 'Failed',
    'paymentMethod': 'card',
    'paymentProviderId': 'demo_gateway_789',
    'paymentAmount': 0,
    'notes': 'Customer cancelled before start',
    'cancelledBy': 'customer',
    'isNoShow': null,
    'hasDispute': false,
  });

  final payment1 = db.collection('payments').doc('payment_1');
  batch.set(payment1, {
    'bookingId': 'booking_1',
    'userId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'amount': 3500,
    'method': 'card',
    'gatewayRef': 'demo_gateway_123',
    'status': 'Pending',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 25, 10, 35)),
  });

  final payment2 = db.collection('payments').doc('payment_2');
  batch.set(payment2, {
    'bookingId': 'booking_2',
    'userId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'amount': 3500,
    'method': 'card',
    'gatewayRef': 'demo_gateway_456',
    'status': 'Success',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 20, 16)),
  });

  final payment3 = db.collection('payments').doc('payment_3');
  batch.set(payment3, {
    'bookingId': 'booking_3',
    'userId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'amount': 3500,
    'method': 'card',
    'gatewayRef': 'demo_gateway_789',
    'status': 'Failed',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 27, 10, 30)),
  });

  final payment4 = db.collection('payments').doc('payment_4');
  batch.set(payment4, {
    'bookingId': 'booking_9',
    'userId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'amount': 2500,
    'method': 'card',
    'gatewayRef': 'demo_gateway_333',
    'status': 'Success',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 22, 12)),
  });

  final payment5 = db.collection('payments').doc('payment_5');
  batch.set(payment5, {
    'bookingId': 'booking_11',
    'userId': 'user_customer_2',
    'providerId': 'user_provider_2',
    'amount': 2000,
    'method': 'card',
    'gatewayRef': 'demo_gateway_444',
    'status': 'Success',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 18, 16)),
  });

  final payment6 = db.collection('payments').doc('payment_6');
  batch.set(payment6, {
    'bookingId': 'booking_12',
    'userId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'amount': 2300,
    'method': 'card',
    'gatewayRef': 'demo_gateway_555',
    'status': 'Success',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 21, 19)),
  });

  final payment7 = db.collection('payments').doc('payment_7');
  batch.set(payment7, {
    'bookingId': 'booking_13',
    'userId': 'user_customer_3',
    'providerId': 'user_provider_3',
    'amount': 2600,
    'method': 'card',
    'gatewayRef': 'demo_gateway_666',
    'status': 'Success',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 23, 12)),
  });

  final payment8 = db.collection('payments').doc('payment_8');
  batch.set(payment8, {
    'bookingId': 'booking_14',
    'userId': 'user_customer_2',
    'providerId': 'user_provider_2',
    'amount': 3200,
    'method': 'card',
    'gatewayRef': 'demo_gateway_777',
    'status': 'Success',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 24, 13)),
  });

  final payment9 = db.collection('payments').doc('payment_9');
  batch.set(payment9, {
    'bookingId': 'booking_15',
    'userId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'amount': 1400,
    'method': 'card',
    'gatewayRef': 'demo_gateway_888',
    'status': 'Success',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 26, 18)),
  });

  final review1 = db.collection('reviews').doc('review_1');
  batch.set(review1, {
    'bookingId': 'booking_1',
    'customerId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'rating': 5,
    'comment': 'Great job!',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 30, 15)),
    'qPunctuality': 5,
    'qQuality': 5,
    'qCommunication': 4,
    'qProfessionalism': 5,
    'wouldRecommend': true,
    'hadDispute': false,
    'completionTimeMinutes': 150,
    'expectedDurationMinutes': 180,
  });

  // Additional reviews to enrich worker ranking and analytics
  final review2 = db.collection('reviews').doc('review_2');
  batch.set(review2, {
    'bookingId': 'booking_2',
    'customerId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'rating': 4,
    'comment': 'Good service, could be a bit faster.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 21, 12)),
    'qPunctuality': 4,
    'qQuality': 4,
    'qCommunication': 4,
    'qProfessionalism': 4,
    'wouldRecommend': true,
    'hadDispute': false,
    'completionTimeMinutes': 190,
    'expectedDurationMinutes': 180,
  });

  final review3 = db.collection('reviews').doc('review_3');
  batch.set(review3, {
    'bookingId': 'booking_4',
    'customerId': 'user_customer_2',
    'providerId': 'user_provider_2',
    'rating': 5,
    'comment': 'Excellent deep cleaning, highly recommended.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 19, 17)),
    'qPunctuality': 5,
    'qQuality': 5,
    'qCommunication': 5,
    'qProfessionalism': 5,
    'wouldRecommend': true,
    'hadDispute': false,
    'completionTimeMinutes': 160,
    'expectedDurationMinutes': 180,
  });

  final review4 = db.collection('reviews').doc('review_4');
  batch.set(review4, {
    'bookingId': 'booking_8',
    'customerId': 'user_customer_2',
    'providerId': 'user_provider_1',
    'rating': 2,
    'comment': 'Some areas were missed and needed rework.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 16, 13)),
    'qPunctuality': 3,
    'qQuality': 2,
    'qCommunication': 3,
    'qProfessionalism': 2,
    'wouldRecommend': false,
    'hadDispute': true,
    'completionTimeMinutes': 210,
    'expectedDurationMinutes': 180,
  });

  final review5 = db.collection('reviews').doc('review_5');
  batch.set(review5, {
    'bookingId': 'booking_9',
    'customerId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'rating': 5,
    'comment': 'AC is working perfectly now, very professional.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 22, 18)),
    'qPunctuality': 5,
    'qQuality': 5,
    'qCommunication': 5,
    'qProfessionalism': 5,
    'wouldRecommend': true,
    'hadDispute': false,
    'completionTimeMinutes': 80,
    'expectedDurationMinutes': 90,
  });

  final review6 = db.collection('reviews').doc('review_6');
  batch.set(review6, {
    'bookingId': 'booking_11',
    'customerId': 'user_customer_2',
    'providerId': 'user_provider_2',
    'rating': 5,
    'comment': 'Plumber fixed the leak quickly and cleaned up afterwards.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 18, 18)),
    'qPunctuality': 5,
    'qQuality': 5,
    'qCommunication': 5,
    'qProfessionalism': 5,
    'wouldRecommend': true,
    'hadDispute': false,
    'completionTimeMinutes': 55,
    'expectedDurationMinutes': 60,
  });

  final review7 = db.collection('reviews').doc('review_7');
  batch.set(review7, {
    'bookingId': 'booking_12',
    'customerId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'rating': 4,
    'comment': 'Electrician solved the problem, took a bit longer than expected.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 21, 20)),
    'qPunctuality': 4,
    'qQuality': 5,
    'qCommunication': 4,
    'qProfessionalism': 4,
    'wouldRecommend': true,
    'hadDispute': false,
    'completionTimeMinutes': 95,
    'expectedDurationMinutes': 75,
  });

  final review8 = db.collection('reviews').doc('review_8');
  batch.set(review8, {
    'bookingId': 'booking_13',
    'customerId': 'user_customer_3',
    'providerId': 'user_provider_3',
    'rating': 5,
    'comment': 'Wardrobe door works perfectly now, very neat work.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 23, 14)),
    'qPunctuality': 5,
    'qQuality': 5,
    'qCommunication': 5,
    'qProfessionalism': 5,
    'wouldRecommend': true,
    'hadDispute': false,
    'completionTimeMinutes': 110,
    'expectedDurationMinutes': 120,
  });

  final review9 = db.collection('reviews').doc('review_9');
  batch.set(review9, {
    'bookingId': 'booking_14',
    'customerId': 'user_customer_2',
    'providerId': 'user_provider_2',
    'rating': 5,
    'comment': 'Room looks great, paint finish is smooth.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 24, 17)),
    'qPunctuality': 5,
    'qQuality': 5,
    'qCommunication': 5,
    'qProfessionalism': 5,
    'wouldRecommend': true,
    'hadDispute': false,
    'completionTimeMinutes': 185,
    'expectedDurationMinutes': 180,
  });

  final review10 = db.collection('reviews').doc('review_10');
  batch.set(review10, {
    'bookingId': 'booking_15',
    'customerId': 'user_customer_1',
    'providerId': 'user_provider_1',
    'rating': 5,
    'comment': 'Very convenient home haircut, exactly as requested.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 26, 19)),
    'qPunctuality': 5,
    'qQuality': 5,
    'qCommunication': 5,
    'qProfessionalism': 5,
    'wouldRecommend': true,
    'hadDispute': false,
    'completionTimeMinutes': 50,
    'expectedDurationMinutes': 45,
  });

  final notif1 = db.collection('notifications').doc('notif_1');
  batch.set(notif1, {
    'userId': 'user_customer_1',
    'title': 'Booking confirmed',
    'body': 'Your booking booking_1 has been accepted.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 25, 11)),
  });

  final adminNotif1 =
      db.collection('admin_notifications').doc('admin_notif_1');
  batch.set(adminNotif1, {
    'type': 'new_user',
    'userId': 'user_customer_1',
    'role': 'customer',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 1, 10)),
  });

  // Additional admin notifications so admin panel has richer data
  final adminNotif2 =
      db.collection('admin_notifications').doc('admin_notif_2');
  batch.set(adminNotif2, {
    'type': 'new_user',
    'userId': 'user_provider_1',
    'role': 'provider',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 2, 10)),
  });

  final adminNotif3 =
      db.collection('admin_notifications').doc('admin_notif_3');
  batch.set(adminNotif3, {
    'type': 'new_user',
    'userId': 'user_provider_2',
    'role': 'provider',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 4, 11)),
  });

  final adminNotif4 =
      db.collection('admin_notifications').doc('admin_notif_4');
  batch.set(adminNotif4, {
    'type': 'info',
    'title': 'High cancellation rate detected',
    'message': 'Booking booking_3 was cancelled by the customer. Review worker and customer history if pattern continues.',
    'bookingId': 'booking_3',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 28, 10)),
  });

  final adminNotif5 =
      db.collection('admin_notifications').doc('admin_notif_5');
  batch.set(adminNotif5, {
    'type': 'info',
    'title': 'Dispute opened on booking',
    'message': 'Booking booking_8 has a dispute flag. Please review details and contact both parties if needed.',
    'bookingId': 'booking_8',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 16, 14)),
  });

  // System-level notification for admin
  final adminNotif6 =
      db.collection('admin_notifications').doc('admin_notif_6');
  batch.set(adminNotif6, {
    'type': 'system',
    'title': 'Daily summary ready',
    'message': 'Daily analytics summary for bookings, revenue and new users is ready to review.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 29, 9, 30)),
  });

  // Admin action style notifications (used like an audit log)
  final adminNotif7 =
      db.collection('admin_notifications').doc('admin_notif_7');
  batch.set(adminNotif7, {
    'type': 'info',
    'title': 'Provider verification approved',
    'message': 'Admin approved verification for provider user_provider_1.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 26, 11, 20)),
  });

  final adminNotif8 =
      db.collection('admin_notifications').doc('admin_notif_8');
  batch.set(adminNotif8, {
    'type': 'system',
    'title': 'Daily payouts processed',
    'message': 'Automated payouts for completed bookings have been processed successfully.',
    'createdAt': Timestamp.fromDate(DateTime(2024, 11, 29, 18, 0)),
  });

  // CHAT + MESSAGES (for chat/messages/worker badge)
  final chat1 = db.collection('chats').doc('chat_customer_provider1');
  batch.set(chat1, {
    'participants': ['user_customer_1', 'user_provider_1'],
    'lastMessage': 'Hello, I would like to confirm my booking.',
    'lastMessageSenderId': 'user_customer_1',
    'updatedAt': Timestamp.fromDate(DateTime(2024, 11, 25, 16)),
  });

  final chat1Msg1 =
      chat1.collection('messages').doc('msg_1');
  batch.set(chat1Msg1, {
    'senderId': 'user_customer_1',
    'text': 'Hello, I would like to confirm my booking.',
    'timestamp': Timestamp.fromDate(DateTime(2024, 11, 25, 15, 50)),
  });

  final chat1Msg2 =
      chat1.collection('messages').doc('msg_2');
  batch.set(chat1Msg2, {
    'senderId': 'user_provider_1',
    'text': 'Sure, I will be there on time.',
    'timestamp': Timestamp.fromDate(DateTime(2024, 11, 25, 15, 55)),
  });

  // Admin <> provider chat for admin chat page
  final adminChat = db.collection('chats').doc('chat_admin_provider1');
  batch.set(adminChat, {
    'participants': ['user_admin_1', 'user_provider_1'],
    'lastMessage': 'Thanks, I will review your documents today.',
    'lastMessageSenderId': 'user_admin_1',
    'updatedAt': Timestamp.fromDate(DateTime(2024, 11, 26, 11, 15)),
  });

  final adminChatMsg1 =
      adminChat.collection('messages').doc('msg_1');
  batch.set(adminChatMsg1, {
    'senderId': 'user_provider_1',
    'text': 'Hello admin, my verification is still pending. Can you please check?',
    'timestamp': Timestamp.fromDate(DateTime(2024, 11, 26, 10, 45)),
  });

  final adminChatMsg2 =
      adminChat.collection('messages').doc('msg_2');
  batch.set(adminChatMsg2, {
    'senderId': 'user_admin_1',
    'text': 'Hi, I see your profile. I will review your documents and update the status shortly.',
    'timestamp': Timestamp.fromDate(DateTime(2024, 11, 26, 11, 0)),
  });

  final adminChatMsg3 =
      adminChat.collection('messages').doc('msg_3');
  batch.set(adminChatMsg3, {
    'senderId': 'user_admin_1',
    'text': 'Thanks, I will review your documents today.',
    'timestamp': Timestamp.fromDate(DateTime(2024, 11, 26, 11, 15)),
  });

  await batch.commit();
}
