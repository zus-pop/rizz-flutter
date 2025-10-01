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
                  'Thông tin hồ sơ',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // First Name
                Text(
                  'Tên',
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
                    hintText: 'Tên của bạn',
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
                      return 'Nhập Tên';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 12),
                // Last Name
                Text(
                  'Họ',
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
                    hintText: 'Họ của bạn',
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
                  'Ngày sinh',
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
                              : 'Chọn ngày sinh nhật',
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
                  'Giới tính',
                  style: AppTheme.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: genderOptions.map((gender) {
                    final isSelected = _selectedGender == gender.name;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedGender = gender.name),
                        child: Container(
                          margin: EdgeInsets.only(
                            right: gender == genderOptions.last ? 0 : 12,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.primary.withValues(alpha: .15)
                                : context.colors.surface,
                            border: Border.all(
                              color: isSelected
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
                                gender.id == 'male' ? Icons.male : Icons.female,
                                color: isSelected
                                    ? context.primary
                                    : context.onSurface.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                gender.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
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
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),

                // University
                Text(
                  'Trường Đại Học',
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
                    hintText: ' Trường Đại Học của bạn',
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Tiếp theo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
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
