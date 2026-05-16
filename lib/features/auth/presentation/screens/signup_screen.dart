import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/constants/app_constants.dart';
import 'package:pulso/core/routing/app_routes.dart';
import 'package:pulso/core/theme/app_theme.dart';
import 'package:pulso/features/auth/presentation/widgets/auth_widgets.dart';
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
    _firstNameController.addListener(_handleFormChanged);
    _middleInitialController.addListener(_handleFormChanged);
    _lastNameController.addListener(_handleFormChanged);
    _suffixController.addListener(_handleFormChanged);
    _birthdayController.addListener(_handleFormChanged);
    _usernameController.addListener(_handleFormChanged);
    _emailController.addListener(_handleFormChanged);
    _passwordController.addListener(_handleFormChanged);
    _confirmPasswordController.addListener(_handleFormChanged);
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_handleFormChanged);
    _middleInitialController.removeListener(_handleFormChanged);
    _lastNameController.removeListener(_handleFormChanged);
    _suffixController.removeListener(_handleFormChanged);
    _birthdayController.removeListener(_handleFormChanged);
    _usernameController.removeListener(_handleFormChanged);
    _emailController.removeListener(_handleFormChanged);
    _passwordController.removeListener(_handleFormChanged);
    _confirmPasswordController.removeListener(_handleFormChanged);
    _firstNameController.dispose();
    _middleInitialController.dispose();
    _lastNameController.dispose();
    _suffixController.dispose();
    _birthdayController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(today.year - 120),
      lastDate: today,
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _birthday = pickedDate;
      _birthdayController.text = _formatDateForDisplay(pickedDate);
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
        birthday: _formatDateForDatabase(_birthday),
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    } finally {
      _passwordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authUiProvider);
    final authNotifier = ref.read(authUiProvider.notifier);
    final canSubmit = _canSubmit(authState);

    return AuthPage(
      compactTopPadding: 24,
      regularTopPadding: 36,
      children: [
        const AuthBrandHeader(
          title: 'Join PULSO',
          subtitle:
              'Create a profile for community updates, events, and local support.',
        ),
        const SizedBox(height: 28),
        const AuthSectionTitle(
          title: 'Create your account',
          subtitle: 'Join PULSO and start connecting with your community.',
        ),
        if (authState.errorMessage != null) ...[
          const SizedBox(height: 16),
          AuthMessageBanner(message: authState.errorMessage!, isError: true),
        ],
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthInputField(
                controller: _firstNameController,
                label: 'First name (required)',
                hintText: 'Juan',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: _validateFirstName,
              ),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _middleInitialController,
                label: 'Middle initial (optional)',
                hintText: 'D',
                icon: Icons.badge_outlined,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.characters,
                validator: _validateMiddleInitial,
              ),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _lastNameController,
                label: 'Last name (required)',
                hintText: 'Dela Cruz',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: _validateLastName,
              ),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _suffixController,
                label: 'Suffix (optional)',
                hintText: 'Jr., Sr., III',
                icon: Icons.workspace_premium_outlined,
                textInputAction: TextInputAction.next,
                validator: _validateSuffix,
              ),
              const SizedBox(height: 16),
              _GenderDropdown(
                value: _gender,
                onChanged: (value) {
                  setState(() {
                    _gender = value;
                  });
                },
                validator: _validateGender,
              ),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _birthdayController,
                label: 'Birthday (required)',
                hintText: 'Select your birthday',
                icon: Icons.cake_outlined,
                trailingIcon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _pickBirthday,
                onTrailingPressed: _pickBirthday,
                validator: (_) => _validateBirthday(_birthday),
              ),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _usernameController,
                label: 'Username',
                hintText: 'juan_delacruz',
                icon: Icons.alternate_email_rounded,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  final normalized = value.trim().toLowerCase();
                  if (value != normalized) {
                    _usernameController.value = TextEditingValue(
                      text: normalized,
                      selection: TextSelection.collapsed(
                        offset: normalized.length,
                      ),
                    );
                  }
                },
                validator: _validateUsername,
              ),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _emailController,
                label: 'Email address',
                hintText: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Create a password',
                icon: Icons.lock_outline_rounded,
                obscureText: !authState.isSignupPasswordVisible,
                trailingIcon: authState.isSignupPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                textInputAction: TextInputAction.next,
                onTrailingPressed: authNotifier.toggleSignupPasswordVisibility,
                validator: _validateNewPassword,
              ),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                hintText: 'Re-enter your password',
                icon: Icons.verified_user_outlined,
                obscureText: !authState.isSignupConfirmPasswordVisible,
                trailingIcon: authState.isSignupConfirmPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                onTrailingPressed:
                    authNotifier.toggleSignupConfirmPasswordVisibility,
                validator: _validateConfirmPassword,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Account type',
          style: textTheme.labelLarge?.copyWith(
            color: AppTheme.midnight,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            AuthTypePill(
              label: 'Personal',
              icon: Icons.person_outline_rounded,
              selected: authState.accountType == AuthAccountType.personal,
              onPressed: () {
                authNotifier.selectAccountType(AuthAccountType.personal);
              },
            ),
            AuthTypePill(
              label: 'Business',
              icon: Icons.business_center_outlined,
              selected: authState.accountType == AuthAccountType.business,
              onPressed: () {
                authNotifier.selectAccountType(AuthAccountType.business);
              },
            ),
            AuthTypePill(
              label: 'Organization',
              icon: Icons.apartment_outlined,
              selected: authState.accountType == AuthAccountType.organization,
              onPressed: () {
                authNotifier.selectAccountType(AuthAccountType.organization);
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthCheckmark(
              checked: authState.acceptsTerms,
              margin: const EdgeInsets.only(top: 1),
              onPressed: authNotifier.toggleAcceptsTerms,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'I agree to the ',
                  children: [
                    TextSpan(
                      text: 'Terms',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.midnight.withValues(alpha: 0.72),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AuthPrimaryAction(
          label: 'Create account',
          isLoading: authState.isLoading,
          onPressed: canSubmit ? _submit : null,
        ),
        const SizedBox(height: 28),
        AuthFooterPrompt(
          text: 'Already have an account? ',
          actionText: 'Sign in',
          onActionPressed: () {
            authNotifier.showLogin();
            context.go(AppRoutes.login);
          },
        ),
      ],
    );
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
    final dateOnlyToday = DateTime(today.year, today.month, today.day);
    final dateOnlyBirthday = DateTime(
      birthday.year,
      birthday.month,
      birthday.day,
    );

    if (dateOnlyBirthday.isAfter(dateOnlyToday)) {
      return 'Birthday cannot be in the future.';
    }

    if (dateOnlyBirthday.isBefore(
      DateTime(today.year - 120, today.month, today.day),
    )) {
      return 'Enter a realistic birthday.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (email.isEmpty) {
      return 'Email is required.';
    }

    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validateUsername(String? value) {
    final username = value?.trim().toLowerCase() ?? '';
    final usernamePattern = RegExp(r'^[a-z0-9_]+$');

    if (username.isEmpty) {
      return 'Username is required.';
    }

    if (username.length < 3) {
      return 'Username must be at least 3 characters.';
    }

    if (username.length > 24) {
      return 'Username must be 24 characters or less.';
    }

    if (!usernamePattern.hasMatch(username)) {
      return 'Use only lowercase letters, numbers, and underscores.';
    }

    return null;
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required.';
    }

    if (password.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters.';
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

  String _formatDateForDisplay(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatDateForDatabase(DateTime? date) {
    if (date == null) {
      return '';
    }

    return _formatDateForDisplay(date);
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
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender (required)',
          style: textTheme.labelLarge?.copyWith(
            color: AuthColors.label,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          validator: validator,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          decoration: InputDecoration(
            hintText: 'Select your gender',
            prefixIcon: const Icon(Icons.wc_outlined),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AuthColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.royalBlue,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1.4,
              ),
            ),
          ),
          items: _options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
