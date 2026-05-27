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

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _birthday ?? DateTime(today.year - 18, today.month, today.day),
      firstDate: DateTime(today.year - 120),
      lastDate: today,
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
    final canSubmit = _canSubmit(authState);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Back',
                onPressed: () => context.go(AppRoutes.login),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            const SizedBox(height: 20),
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
                color: AppTheme.midnight.withValues(alpha: 0.72),
              ),
            ),
            if (authState.errorMessage != null) ...[
              const SizedBox(height: 18),
              _AuthMessage(message: authState.errorMessage!, isError: true),
            ],
            if (authState.infoMessage != null) ...[
              const SizedBox(height: 18),
              _AuthMessage(message: authState.infoMessage!),
            ],
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
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
                  const SizedBox(height: 14),
                  _GenderDropdown(
                    value: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                    validator: _validateGender,
                  ),
                  const SizedBox(height: 14),
                  _SignupField(
                    controller: _birthdayController,
                    label: 'Birthday (required)',
                    hintText: 'Select your birthday',
                    icon: Icons.cake_outlined,
                    suffixIcon: Icons.calendar_today_outlined,
                    readOnly: true,
                    onTap: _pickBirthday,
                    validator: (_) => _validateBirthday(_birthday),
                  ),
                  const SizedBox(height: 14),
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
                    onSuffixPressed:
                        authNotifier.toggleSignupPasswordVisibility,
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
                    onSuffixPressed:
                        authNotifier.toggleSignupConfirmPasswordVisibility,
                    validator: _validateConfirmPassword,
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
                ],
              ),
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
            const SizedBox(height: 18),
            _GradientButton(
              label: 'Create account',
              isLoading: authState.isLoading,
              onPressed: canSubmit ? _submit : null,
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
    );
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

  bool _canSubmit(AuthUiState authState) {
    return authState.acceptsTerms &&
        !authState.isLoading &&
        _validateFirstName(_firstNameController.text) == null &&
        _validateMiddleInitial(_middleInitialController.text) == null &&
        _validateLastName(_lastNameController.text) == null &&
        _validateSuffix(_suffixController.text) == null &&
        _validateGender(_gender) == null &&
        _validateBirthday(_birthday) == null &&
        _validateUsername(_usernameController.text) == null &&
        _validateEmail(_emailController.text) == null &&
        _validateNewPassword(_passwordController.text) == null &&
        _validateConfirmPassword(_confirmPasswordController.text) == null;
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
      ),
    );
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
          borderRadius: BorderRadius.circular(8),
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
              borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(8),
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
