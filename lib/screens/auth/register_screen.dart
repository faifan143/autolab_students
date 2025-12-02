import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Get.offAllNamed(AppRoutes.home);
    } else if (mounted && authProvider.error != null) {
      Get.snackbar(
        'error'.tr,
        authProvider.error!,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.darkBackgroundPrimary, AppColors.darkBackgroundSurface]
                : [AppColors.darkBackgroundPrimary, AppColors.darkBackgroundSurface],
          ),
        ),
        child: SafeArea(
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Hero section
                          Column(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryDark,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.science_outlined,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'app_title'.tr,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'register_subtitle_students'.tr,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Card with form
                          Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ).borderRadius,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'create_account_title'.tr,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'create_account_subtitle'.tr,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        labelText: 'name'.tr,
                                        prefixIcon: const Icon(Icons.person_outline),
                                      ),
                                      enabled: !authProvider.isLoading,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'name_required'.tr;
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        labelText: 'email'.tr,
                                        prefixIcon: const Icon(Icons.alternate_email),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      enabled: !authProvider.isLoading,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'email_required'.tr;
                                        }
                                        if (!GetUtils.isEmail(value.trim())) {
                                          return 'email_invalid'.tr;
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _passwordController,
                                      decoration: InputDecoration(
                                        labelText: 'password'.tr,
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                      ),
                                      obscureText: _obscurePassword,
                                      enabled: !authProvider.isLoading,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'password_required'.tr;
                                        }
                                        if (value.length < 6) {
                                          return 'password_too_short'.tr;
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: authProvider.isLoading
                                            ? null
                                            : _handleRegister,
                                        child: authProvider.isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text('register'.tr),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: TextButton(
                                        onPressed: authProvider.isLoading
                                            ? null
                                            : () => Get.offNamed(AppRoutes.login),
                                        child: Text('already_have_account_login'.tr),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
