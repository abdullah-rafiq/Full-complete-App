// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

    return hasMinLength && hasUppercase && hasLowercase && hasDigit && hasSpecial;
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        if (name.isEmpty) _nameError = 'Name is required';
        if (email.isEmpty) _emailError = 'Email is required';
        if (password.isEmpty) _passwordError = 'Password is required';
        if (confirmPassword.isEmpty) {
          _confirmPasswordError = 'Please confirm your password';
        }
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _emailError = 'Please enter a valid email address';
      });
      return;
    }

    if (!_isStrongPassword(password)) {
      setState(() {
        _passwordError = 'Password does not meet the required strength criteria';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final current = FirebaseAuth.instance.currentUser;
      if (current != null && name.isNotEmpty) {
        await current.updateDisplayName(name);
      }

      if (!mounted) return;

      context.go('/role');

    } on FirebaseAuthException catch (e) {
      String message = 'Sign up failed';
      if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Something went wrong, please try again later')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF29B6F6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Create account'),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/login_main.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: const Color.fromARGB(115, 0, 213, 255),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.80),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Colors.black87),
                      onChanged: (value) {
                        setState(() {
                          _nameError =
                              value.trim().isEmpty ? 'Name is required' : null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Full name',
                        labelStyle: const TextStyle(color: Colors.black54),
                        border: const OutlineInputBorder(),
                        errorText: _nameError,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.80),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.black87),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty) {
                            _emailError = 'Email is required';
                          } else if (!_isValidEmail(value.trim())) {
                            _emailError = 'Please enter a valid email address';
                          } else {
                            _emailError = null;
                          }
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.black54),
                        border: const OutlineInputBorder(),
                        errorText: _emailError,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.80),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.black87),
                          onChanged: (value) {
                            setState(() {
                              if (value.isEmpty) {
                                _passwordError = 'Password is required';
                              } else if (!_isStrongPassword(value.trim())) {
                                _passwordError =
                                    'Password does not meet the required strength criteria';
                              } else {
                                _passwordError = null;
                              }

                              if (_confirmPasswordController.text.isNotEmpty) {
                                if (_confirmPasswordController.text.trim() !=
                                    value.trim()) {
                                  _confirmPasswordError = 'Passwords do not match';
                                } else {
                                  _confirmPasswordError = null;
                                }
                              }
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.black54),
                            border: const OutlineInputBorder(),
                            errorText: _passwordError,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Password requirements:',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            final text = _passwordController.text;
                            final hasMinLength = text.length >= 8;
                            final hasUppercase =
                                text.contains(RegExp(r'[A-Z]'));
                            final hasLowercase =
                                text.contains(RegExp(r'[a-z]'));
                            final hasDigit =
                                text.contains(RegExp(r'[0-9]'));
                            final hasSpecial = text
                                .contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

                            Color colorFor(bool condition) =>
                                condition ? Colors.green : Colors.red;

                            Icon iconFor(bool condition) => Icon(
                                  condition ? Icons.check : Icons.close,
                                  size: 16,
                                  color: colorFor(condition),
                                );

                            TextStyle styleFor(bool condition) => TextStyle(
                                  fontSize: 12,
                                  color: colorFor(condition),
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    iconFor(hasMinLength),
                                    const SizedBox(width: 4),
                                    Text(
                                      'At least 8 characters',
                                      style: styleFor(hasMinLength),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    iconFor(hasUppercase),
                                    const SizedBox(width: 4),
                                    Text(
                                      'At least one uppercase letter',
                                      style: styleFor(hasUppercase),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    iconFor(hasLowercase),
                                    const SizedBox(width: 4),
                                    Text(
                                      'At least one lowercase letter',
                                      style: styleFor(hasLowercase),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    iconFor(hasDigit),
                                    const SizedBox(width: 4),
                                    Text(
                                      'At least one number',
                                      style: styleFor(hasDigit),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    iconFor(hasSpecial),
                                    const SizedBox(width: 4),
                                    Text(
                                      'At least one special character',
                                      style: styleFor(hasSpecial),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.80),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(color: Colors.black87),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty) {
                            _confirmPasswordError =
                                'Please confirm your password';
                          } else if (value.trim() !=
                              _passwordController.text.trim()) {
                            _confirmPasswordError = 'Passwords do not match';
                          } else {
                            _confirmPasswordError = null;
                          }
                        });
                      },
                      onSubmitted: (_) => _signUp(),
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        labelStyle: const TextStyle(color: Colors.black54),
                        border: const OutlineInputBorder(),
                        errorText: _confirmPasswordError,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF29B6F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Create account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                        ),
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