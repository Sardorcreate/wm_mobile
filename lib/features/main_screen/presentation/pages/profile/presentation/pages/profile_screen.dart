import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wm_mobile/features/auth/controller/auth_service.dart';
import 'package:wm_mobile/features/auth/presentation/pages/login_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  static const String _changeCredentialsUrl =
      'http://172.31.20.171:8080/user/change_credentials';

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.clearAuth();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final token = await AuthService.instance.getToken();

      if (token == null) {
        _showSnackBar("Sessiya tugagan, qaytadan kiring", isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      final uri = Uri.parse(_changeCredentialsUrl).replace(
        queryParameters: {
          'password': _newPasswordController.text,
        },
      );

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showSnackBar("Parol muvaffaqiyatli o'zgartirildi");
      } else {
        _showSnackBar(
          "Xatolik yuz berdi (${response.body})",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Internet aloqasi bilan xatolik yuz berdi", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  InputDecoration _passwordDecoration({
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white30),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: Colors.white70,
        ),
        onPressed: onToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 48,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Foydalanuvchi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Parolni o'zgartirish",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500
              ),
            ),
          ),
          const SizedBox(height: 16),

          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _passwordDecoration(
                    label: 'Yangi parol',
                    obscure: _obscureNewPassword,
                    onToggle: () => setState(
                          () => _obscureNewPassword = !_obscureNewPassword,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Yangi parolni kiriting";
                    }
                    if (value.length < 6) {
                      return "Parol kamida 6 ta belgidan iborat bo'lishi kerak";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _passwordDecoration(
                    label: 'Parolni tasdiqlang',
                    obscure: _obscureConfirmPassword,
                    onToggle: () => setState(
                          () =>
                      _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Parolni tasdiqlang";
                    }
                    if (value != _newPasswordController.text) {
                      return "Parollar mos kelmadi";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.55),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white30),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Saqlash',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Chiqish',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}