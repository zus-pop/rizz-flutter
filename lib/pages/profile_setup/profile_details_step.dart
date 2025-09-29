import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/profile_setup_data.dart';
import 'package:rizz_mobile/constants/profile_options.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class ProfileDetailsStep extends StatefulWidget {
  final ProfileSetupData profileData;
  final VoidCallback onNext;

  const ProfileDetailsStep({
    super.key,
    required this.profileData,
    required this.onNext,
  });

  @override
  State<ProfileDetailsStep> createState() => _ProfileDetailsStepState();
}

class _ProfileDetailsStepState extends State<ProfileDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  DateTime? _selectedBirthday;
  String? _selectedGender;
  String? _selectedUniversity;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.profileData.firstName ?? '';
    _lastNameController.text = widget.profileData.lastName ?? '';
    _selectedBirthday = widget.profileData.birthday;
    _selectedGender = widget.profileData.gender;
    _selectedUniversity = widget.profileData.university;

    _firstNameFocusNode.addListener(_onFocusChange);
    _lastNameFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_firstNameFocusNode.hasFocus || _lastNameFocusNode.hasFocus) {
      // Scroll to the input fields when they gain focus
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          100.0, // Position of the input fields
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _scrollController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _selectedBirthday != null &&
        _selectedGender != null &&
        _selectedUniversity != null;
  }

  void _saveAndNext() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.profileData.firstName = _firstNameController.text.trim();
      widget.profileData.lastName = _lastNameController.text.trim();
      widget.profileData.birthday = _selectedBirthday;
      widget.profileData.gender = _selectedGender;
      widget.profileData.university = _selectedUniversity;
      widget.onNext();
    }
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // 18+ only
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.primary,
              onPrimary: context.colors.onPrimary,
              surface: context.colors.surface,
              onSurface: context.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile details',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // First Name
                Text(
                  'First name',
                  style: AppTheme.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _firstNameController,
                  focusNode: _firstNameFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Your First Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 12),
                // Last Name
                Text(
                  'Last name',
                  style: AppTheme.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lastNameController,
                  focusNode: _lastNameFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Your Last Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 15),

                // Birthday
                Text(
                  'Birthday',
                  style: AppTheme.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectBirthday,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.outline),
                      borderRadius: BorderRadius.circular(12),
                      color: context.colors.surface,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: context.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedBirthday != null
                              ? '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}'
                              : 'Choose birthday date',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedBirthday != null
                                ? context.onSurface
                                : context.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Gender
                Text(
                  'Gender',
                  style: AppTheme.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGender = 'Male'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedGender == 'Male'
                                ? context.primary.withValues(alpha: .15)
                                : context.colors.surface,
                            border: Border.all(
                              color: _selectedGender == 'Male'
                                  ? context.primary
                                  : context.outline,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.male,
                                color: _selectedGender == 'Male'
                                    ? context.primary
                                    : context.onSurface.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Male',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedGender == 'Male'
                                      ? context.primary
                                      : context.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGender = 'Female'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedGender == 'Female'
                                ? context.primary.withValues(alpha: .15)
                                : context.colors.surface,
                            border: Border.all(
                              color: _selectedGender == 'Female'
                                  ? context.primary
                                  : context.outline,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.female,
                                color: _selectedGender == 'Female'
                                    ? context.primary
                                    : context.onSurface.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Female',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedGender == 'Female'
                                      ? context.primary
                                      : context.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // University
                Text(
                  'University',
                  style: AppTheme.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedUniversity,
                  decoration: InputDecoration(
                    hintText: 'Your University',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    fillColor: context.colors.surface,
                    filled: true,
                  ),
                  items: universityOptions.map((university) {
                    return DropdownMenuItem(
                      value: university.name,
                      child: Text(
                        university.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.onSurface),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedUniversity = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your university';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isFormValid ? _saveAndNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary,
                      foregroundColor: context.colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: context.outline,
                      disabledForegroundColor: context.onSurface.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
