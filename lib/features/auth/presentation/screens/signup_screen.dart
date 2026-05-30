import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/constants/app_constants.dart';
import 'package:pulso/core/routing/app_routes.dart';
import 'package:pulso/core/theme/app_theme.dart';
import 'package:pulso/features/auth/presentation/widgets/password_validation_hint.dart';
import 'package:pulso/features/auth/providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  static const int _stepCount = 4;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleInitialController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _suffixController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _birthday;
  String? _gender;
  int _currentStep = 0;
  bool _confirmPasswordAutovalidate = false;
  Timer? _confirmPasswordDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authUiProvider.notifier).showSignup();
      }
    });

    for (final controller in [
      _firstNameController,
      _middleInitialController,
      _lastNameController,
      _suffixController,
      _birthdayController,
      _usernameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.addListener(_handleFormChanged);
    }

    _passwordController.addListener(_scheduleConfirmPasswordValidation);
    _confirmPasswordController.addListener(_scheduleConfirmPasswordValidation);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_scheduleConfirmPasswordValidation);
    _confirmPasswordController.removeListener(
      _scheduleConfirmPasswordValidation,
    );
    _confirmPasswordDebounce?.cancel();

    for (final controller in [
      _firstNameController,
      _middleInitialController,
      _lastNameController,
      _suffixController,
      _birthdayController,
      _usernameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.removeListener(_handleFormChanged);
      controller.dispose();
    }

    super.dispose();
  }

  void _handleFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickBirthday() async {
    final today = DateTime.now();
    final initialDate =
        _birthday ?? DateTime(today.year - 18, today.month, today.day);
    final minimumDate = DateTime(today.year - 120);
    DateTime selectedDate = initialDate;

    final pickedDate = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) {
        return Container(
          height: 320,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            Navigator.of(context).pop(selectedDate),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumDate: minimumDate,
                    maximumDate: today,
                    onDateTimeChanged: (date) {
                      selectedDate = date;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _birthday = pickedDate;
      _birthdayController.text = _formatDate(pickedDate);
    });
  }

  Future<void> _submit() async {
    final firstInvalidStep = _firstInvalidStep();
    if (firstInvalidStep != -1) {
      setState(() {
        _currentStep = firstInvalidStep;
      });
      _formKey.currentState?.validate();
      return;
    }

    final authNotifier = ref.read(authUiProvider.notifier);
    final authState = ref.read(authUiProvider);
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (!authState.acceptsTerms) {
      authNotifier.showValidationError(
        'You need to accept the Terms and Privacy Policy.',
      );
      return;
    }

    try {
      await authNotifier.signUp(
        firstName: _firstNameController.text,
        middleInitial: _middleInitialController.text,
        lastName: _lastNameController.text,
        suffix: _suffixController.text,
        gender: _gender ?? '',
        birthday: _birthday == null ? '' : _formatDate(_birthday!),
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    } finally {
      // Don't clear password here to not inconvenience the user if it fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authUiProvider);
    final authNotifier = ref.read(authUiProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                tooltip: 'Back',
                                onPressed: () {
                                  authNotifier.showLogin();
                                  context.go(AppRoutes.login);
                                },
                                icon: const Icon(Icons.arrow_back),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Create account',
                              style: TextStyle(
                                color: AppTheme.midnight,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join PULSO and start connecting with your community.',
                              style: TextStyle(
                                color: AppTheme.midnight.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _SignupStepHeader(currentStep: _currentStep),
                            if (authState.errorMessage != null) ...[
                              const SizedBox(height: 20),
                              _AuthMessage(
                                message: authState.errorMessage!,
                                isError: true,
                              ),
                            ],
                            if (authState.infoMessage != null) ...[
                              const SizedBox(height: 18),
                              _AuthMessage(message: authState.infoMessage!),
                            ],
                            const SizedBox(height: 18),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: KeyedSubtree(
                                key: ValueKey(_currentStep),
                                child: _buildStepContent(
                                  authState,
                                  authNotifier,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final hasPrevious = _currentStep > 0;
                                final buttonWidth = hasPrevious
                                    ? math.min(
                                        140.0,
                                        (constraints.maxWidth - 12) / 2,
                                      )
                                    : math.min(140.0, constraints.maxWidth);

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    if (hasPrevious) ...[
                                      SizedBox(
                                        width: buttonWidth,
                                        height: 54,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(32),
                                            ),
                                            side: const BorderSide(
                                              color: AppTheme.royalBlue,
                                            ),
                                          ),
                                          onPressed: authState.isLoading
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _currentStep -= 1;
                                                  });
                                                },
                                          child: const Text('Previous'),
                                        ),
                                      ),
                                      const Spacer(),
                                      const SizedBox(width: 12),
                                    ] else ...[
                                      const Spacer(),
                                    ],
                                    SizedBox(
                                      width: buttonWidth,
                                      child: _GradientButton(
                                        label: _currentStep == _stepCount - 1
                                            ? 'Create account'
                                            : 'Next',
                                        isLoading: authState.isLoading,
                                        onPressed: authState.isLoading
                                            ? null
                                            : () async {
                                                final isValid =
                                                    _formKey.currentState
                                                        ?.validate() ??
                                                    false;
                                                if (!isValid) {
                                                  return;
                                                }

                                                if (_currentStep <
                                                    _stepCount - 1) {
                                                  setState(() {
                                                    _currentStep += 1;
                                                  });
                                                  return;
                                                }

                                                await _submit();
                                              },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account? '),
                                TextButton(
                                  onPressed: () {
                                    authNotifier.showLogin();
                                    context.go(AppRoutes.login);
                                  },
                                  child: const Text('Sign in'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepContent(AuthUiState authState, AuthUiNotifier authNotifier) {
    return switch (_currentStep) {
      0 => _buildPersonalInfoStep(),
      1 => _buildBirthdayStep(),
      2 => _buildGenderStep(),
      3 => _buildCredentialsStep(authState, authNotifier),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SignupField(
          controller: _firstNameController,
          label: 'First name (required)',
          hintText: 'Juan',
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          validator: _validateFirstName,
        ),
        const SizedBox(height: 14),
        _SignupField(
          controller: _middleInitialController,
          label: 'Middle initial (optional)',
          hintText: 'D',
          icon: Icons.badge_outlined,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          validator: _validateMiddleInitial,
        ),
        const SizedBox(height: 14),
        _SignupField(
          controller: _lastNameController,
          label: 'Last name (required)',
          hintText: 'Dela Cruz',
          icon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.next,
          validator: _validateLastName,
        ),
        const SizedBox(height: 14),
        _SignupField(
          controller: _suffixController,
          label: 'Suffix (optional)',
          hintText: 'Jr., Sr., III',
          icon: Icons.workspace_premium_outlined,
          textInputAction: TextInputAction.next,
          validator: _validateSuffix,
        ),
      ],
    );
  }

  Widget _buildBirthdayStep() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _SignupField(
        controller: _birthdayController,
        label: 'Birthday (required)',
        hintText: 'Select your birthday',
        icon: Icons.cake_outlined,
        suffixIcon: Icons.calendar_today_outlined,
        readOnly: true,
        onTap: _pickBirthday,
        validator: (_) => _validateBirthday(_birthday),
      ),
    );
  }

  Widget _buildGenderStep() {
    return _GenderDropdown(
      value: _gender,
      onChanged: (value) {
        setState(() {
          _gender = value;
        });
      },
      validator: _validateGender,
    );
  }

  Widget _buildCredentialsStep(
    AuthUiState authState,
    AuthUiNotifier authNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SignupField(
          controller: _usernameController,
          label: 'Username',
          hintText: 'juan_delacruz',
          icon: Icons.alternate_email_rounded,
          textInputAction: TextInputAction.next,
          onChanged: _normalizeUsernameInput,
          validator: _validateUsername,
        ),
        const SizedBox(height: 14),
        _SignupField(
          controller: _emailController,
          label: 'Email address',
          hintText: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: _validateEmail,
        ),
        const SizedBox(height: 14),
        _SignupField(
          controller: _passwordController,
          label: 'Password',
          hintText: 'Create a password',
          icon: Icons.lock_outline_rounded,
          obscureText: !authState.isSignupPasswordVisible,
          suffixIcon: authState.isSignupPasswordVisible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixPressed: authNotifier.toggleSignupPasswordVisibility,
          textInputAction: TextInputAction.next,
          validator: _validateNewPassword,
        ),
        const SizedBox(height: 10),
        PasswordValidationHint(password: _passwordController.text),
        const SizedBox(height: 14),
        _SignupField(
          controller: _confirmPasswordController,
          label: 'Confirm password',
          hintText: 'Re-enter your password',
          icon: Icons.verified_user_outlined,
          obscureText: !authState.isSignupConfirmPasswordVisible,
          suffixIcon: authState.isSignupConfirmPasswordVisible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixPressed: authNotifier.toggleSignupConfirmPasswordVisibility,
          validator: _validateConfirmPassword,
          autovalidateMode: _confirmPasswordAutovalidate
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
        ),
        const SizedBox(height: 14),
        _AccountTypeDropdown(
          value: authState.accountType,
          onChanged: (value) {
            if (value != null) {
              authNotifier.selectAccountType(value);
            }
          },
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: authState.acceptsTerms,
              onChanged: (_) => authNotifier.toggleAcceptsTerms(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'I agree to the Terms and Privacy Policy.',
                  style: TextStyle(
                    color: AppTheme.midnight.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _scheduleConfirmPasswordValidation() {
    _confirmPasswordDebounce?.cancel();

    if (_confirmPasswordController.text.isEmpty) {
      if (_confirmPasswordAutovalidate) {
        setState(() {
          _confirmPasswordAutovalidate = false;
        });
      }
      return;
    }

    if (_confirmPasswordAutovalidate) {
      setState(() {
        _confirmPasswordAutovalidate = false;
      });
    }

    _confirmPasswordDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _confirmPasswordAutovalidate = true;
      });
    });
  }

  int _firstInvalidStep() {
    if (_validateFirstName(_firstNameController.text) != null ||
        _validateMiddleInitial(_middleInitialController.text) != null ||
        _validateLastName(_lastNameController.text) != null ||
        _validateSuffix(_suffixController.text) != null) {
      return 0;
    }

    if (_validateBirthday(_birthday) != null) {
      return 1;
    }

    if (_validateGender(_gender) != null) {
      return 2;
    }

    if (_validateUsername(_usernameController.text) != null ||
        _validateEmail(_emailController.text) != null ||
        _validateNewPassword(_passwordController.text) != null ||
        _validateConfirmPassword(_confirmPasswordController.text) != null) {
      return 3;
    }

    return -1;
  }

  void _normalizeUsernameInput(String value) {
    final normalized = value.trim().toLowerCase();
    if (value != normalized) {
      _usernameController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
  }

  String? _validateFirstName(String? value) {
    final firstName = value?.trim() ?? '';
    if (firstName.isEmpty) {
      return 'First name is required.';
    }
    if (firstName.length > AppConstants.maxNameLength) {
      return 'First name must be ${AppConstants.maxNameLength} characters or less.';
    }
    return null;
  }

  String? _validateMiddleInitial(String? value) {
    final middleInitial = (value ?? '').trim().replaceAll('.', '');
    if (middleInitial.isEmpty) {
      return null;
    }
    if (!RegExp(r'^[A-Za-z]$').hasMatch(middleInitial)) {
      return 'Use one letter only, like D.';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    final lastName = value?.trim() ?? '';
    if (lastName.isEmpty) {
      return 'Last name is required.';
    }
    if (lastName.length > AppConstants.maxNameLength) {
      return 'Last name must be ${AppConstants.maxNameLength} characters or less.';
    }
    return null;
  }

  String? _validateSuffix(String? value) {
    final suffix = value?.trim() ?? '';
    if (suffix.isEmpty) {
      return null;
    }
    if (suffix.length > 12) {
      return 'Suffix must be 12 characters or less.';
    }
    if (!RegExp(r'^[A-Za-z0-9 .]+$').hasMatch(suffix)) {
      return 'Use letters, numbers, spaces, or periods only.';
    }
    return null;
  }

  String? _validateGender(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Gender is required.';
    }
    return null;
  }

  String? _validateBirthday(DateTime? birthday) {
    if (birthday == null) {
      return 'Birthday is required.';
    }
    final today = DateTime.now();
    final birthdayOnly = DateTime(birthday.year, birthday.month, birthday.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (birthdayOnly.isAfter(todayOnly)) {
      return 'Birthday cannot be in the future.';
    }
    if (birthdayOnly.isBefore(
      DateTime(today.year - 120, today.month, today.day),
    )) {
      return 'Enter a realistic birthday.';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    final username = value?.trim().toLowerCase() ?? '';
    if (username.isEmpty) {
      return 'Username is required.';
    }
    if (username.length < 3) {
      return 'Username must be at least 3 characters.';
    }
    if (username.length > 24) {
      return 'Username must be 24 characters or less.';
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      return 'Use only lowercase letters, numbers, and underscores.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';
    final validationState = PasswordPolicy.evaluate(password);

    if (password.isEmpty) {
      return 'Password is required.';
    }

    if (!validationState.hasMinLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters.';
    }

    if (!validationState.hasUppercase ||
        !validationState.hasLowercase ||
        !validationState.hasDigits ||
        !validationState.hasSpecialChar) {
      return 'Use uppercase, lowercase, number, and special character.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value ?? '';
    if (confirmPassword.isEmpty) {
      return 'Confirm your password.';
    }
    if (confirmPassword != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _SignupField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool readOnly;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final AutovalidateMode? autovalidateMode;

  const _SignupField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.suffixIcon,
    this.onSuffixPressed,
    this.onTap,
    this.onChanged,
    this.validator,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.autovalidateMode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon == null
            ? null
            : IconButton(
                onPressed: onSuffixPressed ?? onTap,
                icon: Icon(suffixIcon),
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

class _SignupStepHeader extends StatelessWidget {
  final int currentStep;

  const _SignupStepHeader({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const stepLabels = ['Personal info', 'Birthday', 'Gender', 'Credentials'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${currentStep + 1} of 4',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.midnight.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              stepLabels[currentStep],
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.midnight,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        MagicProgressBar(progress: (currentStep + 1) / 4),
      ],
    );
  }
}

class MagicProgressBar extends StatefulWidget {
  final double progress;

  const MagicProgressBar({super.key, required this.progress});

  @override
  State<MagicProgressBar> createState() => _MagicProgressBarState();
}

class _MagicProgressBarState extends State<MagicProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress.clamp(0.0, 1.0);

    return SizedBox(
      height: 44,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final barHeight = 10.0;
          final tipX = width * progress;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 17,
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.midnight.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 17,
                child: Container(
                  width: tipX,
                  height: barHeight,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.coral, AppTheme.royalBlue],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.royalBlue,
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: math.max(0.0, tipX - 26),
                top: 4,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(52, 38),
                      painter: _MagicDustPainter(progress: _controller.value),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MagicDustPainter extends CustomPainter {
  final double progress;

  _MagicDustPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(10);

    final glowPaint = Paint()
      ..color = AppTheme.royalBlue.withValues(alpha: 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(center, 6, glowPaint);

    final tipPaint = Paint()
      ..shader = const RadialGradient(
        colors: [AppTheme.royalBlue, AppTheme.royalBlue],
        stops: [0.15, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 4.5));

    canvas.drawCircle(center, 3.5, tipPaint);

    for (var i = 0; i < 16; i++) {
      final localProgress = (progress + i * 0.09) % 1.0;
      final angle = (i * 0.65) + (progress * math.pi * 2);
      final ringRadius = 3.8 + (1 - localProgress) * 2.1;
      final edgeJitter = random.nextDouble() * 0.8;
      final dx = math.cos(angle) * (ringRadius + edgeJitter);
      final dy =
          -math.sin(angle).abs() * (1.2 + localProgress * 2.0) -
          random.nextDouble() * 0.7;
      final opacity = (1 - localProgress).clamp(0.0, 1.0);
      final radius = 0.8 + random.nextDouble() * 1.1;
      final useBlue = i.isEven;

      final particlePaint = Paint()
        ..color = (useBlue ? AppTheme.royalBlue : AppTheme.coral).withValues(
          alpha: opacity,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(center + Offset(dx, dy), radius, particlePaint);

      final rayPaint = Paint()
        ..color = (useBlue ? AppTheme.coral : AppTheme.royalBlue).withValues(
          alpha: opacity,
        )
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        center + Offset(dx - 3, dy),
        center + Offset(dx + 3, dy),
        rayPaint,
      );

      canvas.drawLine(
        center + Offset(dx, dy - 3),
        center + Offset(dx, dy + 3),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MagicDustPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _GenderDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const _GenderDropdown({
    required this.value,
    required this.onChanged,
    this.validator,
  });

  static const _options = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      validator: validator,
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Gender (required)',
        hintText: 'Select your gender',
        prefixIcon: Icon(Icons.wc_outlined),
      ),
      items: _options
          .map(
            (option) =>
                DropdownMenuItem<String>(value: option, child: Text(option)),
          )
          .toList(),
    );
  }
}

class _AccountTypeDropdown extends StatelessWidget {
  final AuthAccountType value;
  final ValueChanged<AuthAccountType?> onChanged;

  const _AccountTypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<AuthAccountType>(
      initialValue: value,
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Account type',
        prefixIcon: Icon(Icons.manage_accounts_outlined),
      ),
      items: const [
        DropdownMenuItem(
          value: AuthAccountType.personal,
          child: Text('Personal'),
        ),
        DropdownMenuItem(
          value: AuthAccountType.business,
          child: Text('Business'),
        ),
        DropdownMenuItem(
          value: AuthAccountType.organization,
          child: Text('Organization'),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = isLoading || onPressed == null;

    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: isDisabled
                ? [
                    AppTheme.coral.withValues(alpha: 0.34),
                    AppTheme.royalBlue.withValues(alpha: 0.34),
                  ]
                : const [AppTheme.coral, AppTheme.royalBlue],
          ),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          onPressed: isDisabled ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
        ),
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _AuthMessage({required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? colorScheme.errorContainer
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError
              ? colorScheme.onErrorContainer
              : colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
