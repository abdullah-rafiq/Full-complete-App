import 'app_locale.dart';

class L10n {
  static bool get _isUrdu => AppLocale.isUrdu();

  // Worker home/navigation

  static String workerTodayOverviewTitle() =>
      _isUrdu ? 'آج کا خلاصہ' : "Today's overview";

  static String workerTodayOverviewSubtitle() => _isUrdu
      ? 'اپنی آنے والی درخواستوں اور کمائی کو منظم کریں۔'
      : 'Manage your incoming requests and track your earnings.';

  static String workerIncomingRequestsTitle() =>
      _isUrdu ? 'آنے والی درخواستیں' : 'Incoming requests';

  static String workerIncomingRequestsSubtitle() => _isUrdu
      ? 'ڈیمو جاب کی تفصیل دیکھنے کے لئے ٹیپ کریں۔ مستقبل میں یہاں حقیقی بکنگز نظر آئیں گی۔'
      : 'Tap to view a demo job detail. In the future this will show real-time bookings assigned to you.';

  static String workerMyJobsEarningsTitle() =>
      _isUrdu ? 'میری جابس اور کمائی' : 'My jobs & earnings';

  static String workerMyJobsEarningsSubtitle() => _isUrdu
      ? 'ڈیمو کمائی کا خلاصہ دیکھنے کے لئے ٹیپ کریں۔ بعد میں یہاں مکمل شدہ جابس اور ادائیگی کی ہسٹری آئے گی۔'
      : 'Tap to view a demo earnings summary. Later this will include completed jobs and payout history.';

  static String workerNavHome() => _isUrdu ? 'ہوم' : 'Home';
  static String workerNavJobs() => _isUrdu ? 'جابز' : 'Jobs';
  static String workerNavEarnings() => _isUrdu ? 'کمائی' : 'Earnings';
  static String workerNavMessages() => _isUrdu ? 'پیغامات' : 'Messages';
  static String workerNavProfile() => _isUrdu ? 'پروفائل' : 'Profile';

  // Auth / login

  static String authWelcomeBackTitle() =>
      _isUrdu ? 'واپس آنے پر خوش آمدید،' : 'Welcome Back,';

  static String authLoginSubtitle() => _isUrdu
      ? 'اپنے اکاؤنٹ میں ای میل اور پاس ورڈ کے ساتھ لاگ اِن کریں'
      : 'Login to your account using\nEmail and password';

  static String authEmailLabel() => _isUrdu ? 'ای میل' : 'Email';
  static String authPasswordLabel() => _isUrdu ? 'پاس ورڈ' : 'Password';

  static String authLoginButton() => _isUrdu ? 'لاگ اِن' : 'Log In';

  static String authForgotPasswordQuestion() =>
      _isUrdu ? 'پاس ورڈ بھول گئے؟ ' : 'Forgot your password? ';

  static String authResetPasswordCta() =>
      _isUrdu ? 'پاس ورڈ ری سیٹ کریں' : 'Reset password';

  static String authContinueWithGoogle() =>
      _isUrdu ? 'گوگل کے ساتھ جاری رکھیں' : 'Continue with Google';

  static String authCreateAccount() =>
      _isUrdu ? 'نیا اکاؤنٹ بنائیں' : 'Create an account';

  static String authEmailRequiredError() =>
      _isUrdu ? 'ای میل ضروری ہے' : 'Email is required';

  static String authPasswordRequiredError() =>
      _isUrdu ? 'پاس ورڈ ضروری ہے' : 'Password is required';

  static String authEnterValidEmailError() =>
      _isUrdu ? 'درست ای میل درج کریں' : 'Enter a valid email';

  static String authLoginFailed() =>
      _isUrdu ? 'لاگ اِن ناکام رہا' : 'Login failed';

  static String authNoUserFound() => _isUrdu
      ? 'اس ای میل کے ساتھ کوئی صارف نہیں ملا۔'
      : 'No user found for that email.';

  static String authWrongPassword() => _isUrdu
      ? 'غلط پاس ورڈ فراہم کیا گیا۔'
      : 'Wrong password provided.';

  static String authInvalidEmail() => _isUrdu
      ? 'ای میل ایڈریس درست نہیں۔'
      : 'Invalid email address.';

  static String authSomethingWentWrong() => _isUrdu
      ? 'کچھ غلط ہو گیا، براہِ کرم بعد میں دوبارہ کوشش کریں۔'
      : 'Something went wrong, please try again later';

  static String authGoogleFailed() => _isUrdu
      ? 'گوگل لاگ اِن ناکام رہا'
      : 'Google sign-in failed';

  // Customer main page + nav

  static String customerNavHome() => _isUrdu ? 'ہوم' : 'Home';
  static String customerNavCategories() =>
      _isUrdu ? 'کیٹیگریز' : 'Categories';
  static String customerNavBookings() =>
      _isUrdu ? 'بکنگز' : 'Bookings';
  static String customerNavMessages() =>
      _isUrdu ? 'پیغامات' : 'Messages';
  static String customerNavProfile() =>
      _isUrdu ? 'پروفائل' : 'Profile';

  static String mainWelcomePrefix() =>
      _isUrdu ? 'خوش آمدید،' : 'Welcome,';

  static String mainCategoriesTitle() =>
      _isUrdu ? 'کیٹیگریز' : 'Categories';

  static String mainFeaturedProvidersTitle() =>
      _isUrdu ? 'نمایاں فراہم کنندگان' : 'Featured Providers';

  static String mainUpcomingBookingsTitle() =>
      _isUrdu ? 'آنے والی بکنگز' : 'Upcoming Bookings';

  static String mainAllCategoriesTitle() =>
      _isUrdu ? 'تمام کیٹیگریز' : 'All Categories';

  static String statusAvailable() =>
      _isUrdu ? 'دستیاب' : 'Available';

  static String statusUnavailable() => _isUrdu
      ? 'اس وقت دستیاب نہیں'
      : 'Currently unavailable';

  // Settings
 
  static String settingsAppBarTitle() =>
      _isUrdu ? 'ایپ سیٹنگز' : 'App settings';

  static String settingsPushNotificationsTitle() =>
      _isUrdu ? 'پش نوٹیفیکیشنز' : 'Push notifications';

  static String settingsPushNotificationsSubtitle() => _isUrdu
      ? 'اپنی بکنگز اور آفرز کے بارے میں اپ ڈیٹس حاصل کریں۔'
      : 'Receive updates about your bookings and offers.';

  static String settingsDarkModeTitle() =>
      _isUrdu ? 'ڈارک موڈ' : 'Dark mode';

  static String settingsDarkModeSubtitle() => _isUrdu
      ? 'ایپ کے لئے ڈارک تھیم استعمال کریں۔'
      : 'Use a dark theme for the application.';

  static String settingsLanguageTitle() =>
      _isUrdu ? 'زبان' : 'Language';

  static String languageNameEnglish() =>
      _isUrdu ? 'انگلش' : 'English';

  static String languageNameUrdu() =>
      _isUrdu ? 'اردو' : 'Urdu';

  // Contact us

  static String contactAppBarTitle() =>
      _isUrdu ? 'رابطہ کریں' : 'Contact us';

  static String contactInfoTitle() =>
      _isUrdu ? 'رابطہ معلومات' : 'Contact information';

  static String contactLiveChatTitle() =>
      _isUrdu ? 'لائیو چیٹ' : 'Live chat';

  static String contactTypeMessageHint() =>
      _isUrdu ? 'اپنا پیغام لکھیں...' : 'Type your message...';

  static String contactSupportBotWelcome() => _isUrdu
      ? 'ہیلو! میں Assist سپورٹ بوٹ ہوں۔ اپنے اکاؤنٹ یا آرڈرز کے بارے میں جو چاہیں پوچھیں۔'
      : 'Hi! I\'m Assist Support Bot. Ask me anything about your account or orders.';

  static String contactSupportReplyGeneric() => _isUrdu
      ? 'آپ کے پیغام کا شکریہ۔ ہماری سپورٹ ٹیم جلد آپ سے رابطہ کرے گی۔'
      : 'Thanks for your message. Our support team will contact you soon.';

  static String contactSupportReplyPassword() => _isUrdu
      ? 'پاس ورڈ کے مسئلے کے لئے: لاگ اِن اسکرین پر "Forgot password" کا آپشن استعمال کریں۔'
      : 'For password issues: you can use "Forgot password" on the login screen to reset it.';

  static String contactSupportReplyPayment() => _isUrdu
      ? 'ادائیگی سے متعلق سوالات کے لیے: براہ کرم ایپ میں Payment سیکشن دیکھیں یا support@example.com پر رابطہ کریں۔'
      : 'Payment questions: please check your Payment section in the app or contact us at support@example.com.';

  static String contactSupportReplyBooking() => _isUrdu
      ? 'آرڈر یا بکنگ سے متعلق سوالات کے لیے: آپ Booking / Tracking سیکشن سے اسٹیٹس دیکھ سکتے ہیں۔'
      : 'Order / booking questions: you can track status from the Booking / Tracking section of the app.';

  static String contactDemoChatInfo() => _isUrdu
      ? 'یہ ڈیمو لائیو چیٹ ہے۔ پروڈکشن میں اسے حقیقی سپورٹ بیک اینڈ سے جوڑا جائے گا۔'
      : 'This is a demo live chat. In production you would connect this to a real support backend.';

  // Simple titles for static pages

  static String faqTitle() => _isUrdu ? 'عمومی سوالات' : 'FAQ';

  static String termsTitle() =>
      _isUrdu ? 'شرائط و ضوابط' : 'Terms & conditions';

  static String privacyTitle() =>
      _isUrdu ? 'پرائیویسی پالیسی' : 'Privacy policy';

  // ----------------------
  // Profile (B-lite)
  // ----------------------

  static String profileQuickWallet() => _isUrdu ? 'والیٹ' : 'Wallet';
  static String profileQuickBooking() => _isUrdu ? 'بکنگ' : 'Booking';
  static String profileQuickPayment() => _isUrdu ? 'ادائیگی' : 'Payment';
  static String profileQuickSupport() => _isUrdu ? 'سپورٹ' : 'Support';

  static String profileEditTitle() =>
      _isUrdu ? 'پروفائل میں ترمیم کریں' : 'Edit profile';

  static String profileSettingsTitle() =>
      _isUrdu ? 'سیٹنگز' : 'Settings';

  static String profileHelpSupportTitle() =>
      _isUrdu ? 'مدد اور سپورٹ' : 'Help & Support';

  static String profileLogoutTitle() =>
      _isUrdu ? 'لاگ آؤٹ' : 'Logout';

  // ----------------------
  // Customer bookings (MyBookings)
  // ----------------------

  static String bookingsAppBarTitle() =>
      _isUrdu ? 'میری بکنگز' : 'My Bookings';

  static String bookingsLoginRequiredMessage() => _isUrdu
      ? 'براہ کرم اپنی بکنگز دیکھنے کے لئے لاگ اِن کریں۔'
      : 'Please log in to view your bookings.';

  static String bookingsLoadError() => _isUrdu
      ? 'بکنگز لوڈ نہیں ہو سکیں۔'
      : 'Could not load bookings.';

  static String bookingStatusCompleted() =>
      _isUrdu ? 'مکمل' : 'Completed';

  static String bookingStatusCancelled() =>
      _isUrdu ? 'منسوخ' : 'Cancelled';

  static String bookingStatusInProgress() =>
      _isUrdu ? 'جاری ہے' : 'In progress';

  static String bookingStatusOnTheWay() =>
      _isUrdu ? 'راستے میں' : 'On the way';

  static String bookingStatusAccepted() =>
      _isUrdu ? 'طے شدہ' : 'Scheduled';

  static String bookingStatusRequested() =>
      _isUrdu ? 'درخواست شدہ' : 'Requested';

  static String bookingPayNowCta() =>
      _isUrdu ? 'ابھی ادائیگی کریں' : 'Pay now';

  static String bookingPaidLabel() =>
      _isUrdu ? 'ادا شدہ' : 'Paid';

  static String bookingsEmptyForStatus() => _isUrdu
      ? 'ابھی تک کوئی بکنگ نہیں۔'
      : 'No bookings yet.';

  // ----------------------
  // Worker jobs & earnings
  // ----------------------

  static String workerJobsAppBarTitle() =>
      _isUrdu ? 'میری جابز' : 'My jobs';

  static String workerJobsLoginRequiredMessage() => _isUrdu
      ? 'براہ کرم اپنی جابز دیکھنے کے لئے لاگ اِن کریں۔'
      : 'Please log in to view your jobs.';

  static String workerJobsLoadError() => _isUrdu
      ? 'جابز لوڈ نہیں ہو سکیں۔'
      : 'Could not load jobs.';

  static String workerJobsEmptyMessage() => _isUrdu
      ? 'ابھی تک کوئی جاب اسائن نہیں ہوئی۔'
      : 'No jobs assigned yet.';

  static String bookingFilterAll() => _isUrdu ? 'سب' : 'All';

  static String workerJobCustomerPrefix() =>
      _isUrdu ? 'کسٹمر:' : 'Customer:';

  static String workerEarningsAppBarTitle() =>
      _isUrdu ? 'کمائی' : 'Earnings';

  static String workerEarningsLoginRequiredMessage() => _isUrdu
      ? 'براہ کرم اپنی کمائی دیکھنے کے لئے لاگ اِن کریں۔'
      : 'Please log in to view your earnings.';

  static String workerEarningsLoadError() => _isUrdu
      ? 'کمائی لوڈ نہیں ہو سکی۔'
      : 'Could not load earnings.';

  static String workerEarningsTotalTitle() =>
      _isUrdu ? 'کل کمائی' : 'Total earnings';

  static String workerEarningsNoCompletedSummary() => _isUrdu
      ? 'ابھی تک کوئی مکمل جاب نہیں۔ مکمل جابز یہاں دکھائی جائیں گی۔'
      : 'No completed jobs yet. Completed jobs will appear here.';

  static String workerEarningsBasedOnJobs() => _isUrdu
      ? 'مکمل جابز کی بنیاد پر۔'
      : 'Based on completed jobs.';

  static String workerEarningsNoCompletedList() => _isUrdu
      ? 'دکھانے کے لئے کوئی مکمل جاب نہیں۔'
      : 'No completed jobs to show.';

  // ----------------------
  // Generic
  // ----------------------

  static String commonNotSet() =>
      _isUrdu ? 'سیٹ نہیں' : 'Not set';
}
