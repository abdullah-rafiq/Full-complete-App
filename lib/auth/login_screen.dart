import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_application_1/models/app_user.dart';
import 'package:flutter_application_1/controllers/current_user_controller.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/localized_strings.dart';
import 'package:flutter_application_1/app_locale.dart';
import 'package:flutter_application_1/common/ui_helpers.dart';

import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  static const String _googleServerClientId =
      '367355369302-ne1rtv1fidied34iqehu7kmhm20i1ufs.apps.googleusercontent.com';
  static Future<void>? _googleInitFuture;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _navigateByRole(AppUser? profile) {
    // Hide keyboard before navigation to reduce transition jank
    FocusScope.of(context).unfocus();

    if (profile == null) {
      context.go('/role');
      return;
    }

    switch (profile.role) {
      case UserRole.customer:
        context.go('/home');
        break;
      case UserRole.provider:
        context.go('/worker');
        break;
      case UserRole.admin:
        context.go('/admin');
        break;
      // ignore: unreachable_switch_default
      default:
        context.go('/home');
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        if (email.isEmpty) _emailError = L10n.authEmailRequiredError();
        if (password.isEmpty) _passwordError = L10n.authPasswordRequiredError();
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _emailError = L10n.authEnterValidEmailError();
      });
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      CurrentUserController.reset();

      // Simple analytics/logging
      // ignore: avoid_print
      print('LOGIN_EMAIL_SUCCESS user=${cred.user?.uid}');

      if (cred.user != null && email.toLowerCase() == 'firebase@fire.com') {
        await AuthService.instance.ensureAdminUser(cred.user!);
      }

      final profile = await AuthService.instance.getCurrentUserProfile();

      if (!mounted) return;

      final url = profile?.profileImageUrl;
      if (url != null && url.isNotEmpty) {
        try {
          precacheImage(NetworkImage(url), context);
        } catch (_) {}
      }

      _navigateByRole(profile);
    } on FirebaseAuthException catch (e) {
      debugPrint('LOGIN_EMAIL_ERROR code=${e.code} message=${e.message}');
      String message = L10n.authLoginFailed();

      if (e.code == 'user-not-found') {
        message = L10n.authNoUserFound();
      } else if (e.code == 'wrong-password') {
        message = L10n.authWrongPassword();
      } else if (e.code == 'invalid-email') {
        message = L10n.authInvalidEmail();
      } else if (e.code == 'invalid-credential' ||
          e.code == 'INVALID_LOGIN_CREDENTIALS') {
        message = L10n.authWrongPassword();
      } else if (e.code == 'network-request-failed') {
        message =
            'Network error on Android. Disable VPN/Private DNS, update Google Play services, and try again.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please wait a bit and try again.';
      }

      final raw = e.message;
      if (message == L10n.authLoginFailed() && raw != null && raw.isNotEmpty) {
        message = raw;
      }

      UIHelpers.showSnack(context, message);
    } catch (_) {
      UIHelpers.showSnack(context, L10n.authSomethingWentWrong());
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      _googleInitFuture ??= GoogleSignIn.instance.initialize(
        serverClientId: _googleServerClientId,
      );
      await _googleInitFuture;

      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;

      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google sign-in did not return an idToken');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      await FirebaseAuth.instance.signInWithCredential(credential);

      CurrentUserController.reset();

      final profile = await AuthService.instance.getCurrentUserProfile();

      if (!mounted) return;

      if (profile == null) {
        context.go('/role');
        return;
      }

      final url = profile.profileImageUrl;
      if (url != null && url.isNotEmpty) {
        try {
          precacheImage(NetworkImage(url), context);
        } catch (_) {}
      }

      _navigateByRole(profile);
    } on FirebaseAuthException catch (e) {
      debugPrint('LOGIN_GOOGLE_ERROR code=${e.code} message=${e.message}');
      UIHelpers.showSnack(context, e.message ?? L10n.authGoogleFailed());
    } catch (e) {
      debugPrint('LOGIN_GOOGLE_ERROR: $e');
      UIHelpers.showSnack(context, '${L10n.authGoogleFailed()}: $e');
    }
  }

  Future<void> _forgotPassword() async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      // Avoid full layout jump when keyboard opens; we let Scaffold handle insets
      resizeToAvoidBottomInset: true,

      /// FIXED BACKGROUND
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/login_main.png'),
            fit: BoxFit.cover,
          ),
        ),

        /// Overlay
        child: Container(
          color: const Color.fromARGB(115, 0, 213, 255),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 28,
                right: 16,
                top: 24,
                bottom: bottomInset,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final isUrdu = AppLocale.isUrdu();
                          final newLocale = isUrdu
                              ? const Locale('en')
                              : const Locale('ur');
                          await AppLocale.setLocale(newLocale);
                          if (!mounted) return;
                          setState(() {});
                        },
                        icon: const Icon(Icons.language, size: 18),
                        label: Text(
                          AppLocale.isUrdu()
                              ? L10n.languageNameEnglish()
                              : L10n.languageNameUrdu(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Text(
                    L10n.authWelcomeBackTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.15),
                          offset: Offset(0, 5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    L10n.authLoginSubtitle(),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),

                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.80),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),

                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            labelText: L10n.authEmailLabel(),
                            labelStyle: const TextStyle(color: Colors.black54),
                            errorText: _emailError,
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value.isEmpty) {
                                _emailError = L10n.authEmailRequiredError();
                              } else if (!_isValidEmail(value.trim())) {
                                _emailError = L10n.authEnterValidEmailError();
                              } else {
                                _emailError = null;
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            labelText: L10n.authPasswordLabel(),
                            labelStyle: const TextStyle(color: Colors.black54),
                            errorText: _passwordError,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _passwordError = value.isEmpty
                                  ? L10n.authPasswordRequiredError()
                                  : null;
                            });
                          },
                          onSubmitted: (_) => _login(),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF29B6F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _login,
                            child: Text(
                              L10n.authLoginButton(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        L10n.authForgotPasswordQuestion(),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      GestureDetector(
                        onTap: _forgotPassword,
                        child: Text(
                          L10n.authResetPasswordCta(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        onPressed: _signInWithGoogle,
                        icon: Image.asset("assets/icons/google.png", width: 24),
                        label: Text(
                          L10n.authContinueWithGoogle(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        L10n.authCreateAccount(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
