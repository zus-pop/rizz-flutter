import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/constants/profile_options.dart';
import 'package:rizz_mobile/pages/splash_screen.dart';
import 'package:rizz_mobile/providers/app_setting_provider.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';
import 'package:rizz_mobile/services/onboarding_service.dart';
import 'package:rizz_mobile/services/profile_setup_service.dart';
import 'package:rizz_mobile/theme/app_theme.dart';
import 'package:rizz_mobile/theme/theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Preference Settings (Discovery & Matching)
  RangeValues _ageRange = const RangeValues(22, 30);
  double _distance = 50.0;
  String? _selectedLookingFor;
  final Set<String> _selectedInterests = <String>{};

  // Profile Detail Settings (Personal Information)
  String? _selectedUniversity;
  String? _selectedAfterGraduation;
  String? _selectedLoveLanguage;
  String? _selectedZodiac;
  String? _selectedGender;

  // App Settings (Notifications & Privacy)
  bool _pushNotifications = true;
  bool _showOnlineStatus = true;
  bool _showDistance = true;
  bool _discoverable = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize default values
    if (lookingForOptions.isNotEmpty) {
      _selectedLookingFor = lookingForOptions.first.name;
    }
    if (genderOptions.isNotEmpty) {
      _selectedGender = genderOptions.first.name;
    }
    if (universityOptions.isNotEmpty) {
      _selectedUniversity = universityOptions.first.name;
    }
    if (afterGraduation.isNotEmpty) {
      _selectedAfterGraduation = afterGraduation.first.name;
    }
    if (loveLanguageOptions.isNotEmpty) {
      _selectedLoveLanguage = loveLanguageOptions.first.name;
    }
    if (zodiacOptions.isNotEmpty) {
      _selectedZodiac = zodiacOptions.first.name;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _darkMode = context.watch<AppSettingProvider>().themeData == darkMode;
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: Text(
          'Cài đặt',
          style: AppTheme.headline3.copyWith(color: context.colors.onPrimary),
        ),
        backgroundColor: context.primary,
        foregroundColor: context.colors.onPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.colors.onPrimary,
          unselectedLabelColor: context.colors.onPrimary.withValues(alpha: 0.7),
          indicatorColor: context.colors.onPrimary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.tune), text: 'Ưa thích'),
            Tab(icon: Icon(Icons.person), text: 'Hồ sơ'),
            Tab(icon: Icon(Icons.settings), text: 'Ứng dụng'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _applySettings),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPreferencesTab(),
          _buildProfileTab(),
          _buildAppSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAgeRangeSection(),
          const SizedBox(height: 16),
          _buildDistanceSection(),
          const SizedBox(height: 16),
          _buildLookingForSection(),
          const SizedBox(height: 16),
          _buildInterestsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildUniversitySection(),
          const SizedBox(height: 16),
          _buildAfterGraduationSection(),
          const SizedBox(height: 16),
          _buildLoveLanguageSection(),
          const SizedBox(height: 16),
          _buildZodiacSection(),
          const SizedBox(height: 16),
          _buildGenderSection(),
        ],
      ),
    );
  }

  Widget _buildAppSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildNotificationSettings(),
          const SizedBox(height: 16),
          _buildPrivacySettings(),
          const SizedBox(height: 16),
          _buildAppPreferences(),
        ],
      ),
    );
  }

  // Preference Settings Components
  Widget _buildAgeRangeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cake, color: context.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Độ tuổi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_ageRange.start.round()} - ${_ageRange.end.round()} tuổi',
              style: TextStyle(
                fontSize: 14,
                color: context.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            RangeSlider(
              min: 18,
              max: 100,
              divisions: 82,
              activeColor: context.primary,
              inactiveColor: context.primary.withValues(alpha: 0.3),
              values: _ageRange,
              labels: RangeLabels(
                _ageRange.start.round().toString(),
                _ageRange.end.round().toString(),
              ),
              onChanged: (values) => setState(() => _ageRange = values),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: context.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Khoảng cách tối đa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _distance == 100 ? 'Bất cứ đâu' : 'Cách ${_distance.round()} km',
              style: TextStyle(
                fontSize: 14,
                color: context.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              min: 1,
              max: 100,
              divisions: 99,
              activeColor: context.primary,
              inactiveColor: context.primary.withValues(alpha: 0.3),
              value: _distance,
              label: _distance == 100
                  ? 'Bất cứ đâu'
                  : '${_distance.round()} km',
              onChanged: (value) => setState(() => _distance = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLookingForSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: context.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Tìm kiếm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lookingForOptions.map((option) {
                final isSelected = _selectedLookingFor == option.name;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedLookingFor = option.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primary
                          : context.colors.surfaceContainerHigh,
                      border: Border.all(
                        color: isSelected ? context.primary : context.outline,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      option.name,
                      style: TextStyle(
                        color: isSelected
                            ? context.colors.onPrimary
                            : context.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.interests, color: context.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Sở thích',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn tối đa 5 sở thích (${_selectedInterests.length}/5)',
              style: TextStyle(
                fontSize: 14,
                color: context.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map((interest) {
                final isSelected = _selectedInterests.contains(interest.name);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedInterests.remove(interest.name);
                      } else if (_selectedInterests.length < 5) {
                        _selectedInterests.add(interest.name);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primary
                          : context.colors.surfaceContainerHigh,
                      border: Border.all(
                        color: isSelected ? context.primary : context.outline,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      interest.name,
                      style: TextStyle(
                        color: isSelected
                            ? context.colors.onPrimary
                            : context.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Profile Detail Components
  Widget _buildUniversitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: context.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Đại học',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.fade,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedUniversity,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: universityOptions.map((option) {
                return DropdownMenuItem(
                  value: option.name,
                  child: Text(option.name, overflow: TextOverflow.fade),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedUniversity = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAfterGraduationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, color: context.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Sau khi ra trường',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedAfterGraduation,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: afterGraduation.map((option) {
                return DropdownMenuItem(
                  value: option.name,
                  child: Text(option.name),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedAfterGraduation = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoveLanguageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: context.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Ngôn ngữ yêu thích',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedLoveLanguage,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: loveLanguageOptions.map((option) {
                return DropdownMenuItem(
                  value: option.name,
                  child: Text(option.name),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedLoveLanguage = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZodiacSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars, color: context.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Cung hoàng đạo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedZodiac,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: zodiacOptions.map((option) {
                return DropdownMenuItem(
                  value: option.name,
                  child: Text(option.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedZodiac = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: context.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Giới tính',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...genderOptions.map((option) {
              final isSelected = _selectedGender == option.name;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGender = option.name),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? context.primary : context.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: isSelected
                              ? context.primary
                              : context.onSurface.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? context.primary
                                  : context.onSurface,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: context.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // App Settings Components
  Widget _buildNotificationSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: context.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Thông báo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Push Notifications',
              'Nhận thông báo cho match và chat',
              _pushNotifications,
              (value) => setState(() => _pushNotifications = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip, color: context.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Quyền riêng tư & Hiển thị',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Hiển thị trạng thái hoạt động',
              'Cho phép người khác biết khi bạn đang hoạt động',
              _showOnlineStatus,
              (value) => setState(() => _showOnlineStatus = value),
            ),
            const Divider(),
            _buildSwitchTile(
              'Hiển thị khoảng cách',
              'Hiển thị khoảng cách trên hồ sơ của bạn',
              _showDistance,
              (value) => setState(() => _showDistance = value),
            ),
            const Divider(),
            _buildSwitchTile(
              'Có thể được tìm thấy',
              'Cho phép người khác tìm thấy bạn trong khám phá',
              _discoverable,
              (value) => setState(() => _discoverable = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppPreferences() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: context.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Giao diện ứng dụng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Chế độ tối',
              'Sử dụng giao diện tối cho ứng dụng',
              _darkMode,
              (value) => context.read<AppSettingProvider>().toggleTheme(),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout, color: Colors.red.shade400),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Đăng xuất khỏi tài khoản của bạn'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Đăng xuất'),
                    content: const Text(
                      'Bạn có chắc chắn muốn đăng xuất không?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _performSignOut();
                        },
                        child: Text(
                          'Đăng xuất',
                          style: TextStyle(color: context.colors.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_outline, color: Colors.blue.shade400),
              title: const Text(
                'Đặt lại hồ sơ',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Làm lại quá trình thiết lập hồ sơ'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Đặt lại hồ sơ'),
                    content: const Text(
                      'Thao tác này sẽ đặt lại quá trình thiết lập hồ sơ. Bạn sẽ cần hoàn thành lại. Bạn có chắc không?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _resetProfileSetup();
                        },
                        child: Text(
                          'Đặt lại',
                          style: TextStyle(color: Colors.blue.shade400),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.refresh, color: Colors.orange.shade400),
              title: const Text(
                'Đặt lại bản demo',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Đặt lại onboarding cho mục đích demo'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Đặt lại bản demo'),
                    content: const Text(
                      'Thao tác này sẽ đặt lại luồng onboarding cho mục đích demo. Bạn có chắc không?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _resetDemoFlow();
                        },
                        child: Text(
                          'Đặt lại',
                          style: TextStyle(color: Colors.orange.shade400),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: AppTheme.body1.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.caption.copyWith(
          color: context.onSurface.withValues(alpha: 0.7),
        ),
      ),
      value: value,
      activeThumbColor: context.primary,
      onChanged: onChanged,
    );
  }

  // Settings Management
  void _applySettings() {
    // TODO: Save settings to backend/local storage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Settings saved successfully',
          style: AppTheme.body1.copyWith(color: context.colors.onPrimary),
        ),
        backgroundColor: context.primary,
      ),
    );
  }

  // Logout functionality
  Future<void> _performSignOut() async {
    try {
      // Clear authentication data
      final authProvider = Provider.of<AuthenticationProvider>(
        context,
        listen: false,
      );
      await authProvider.logout();

      // Reset onboarding for demo purposes
      // await OnboardingService.resetOnboarding();

      // Reset profile setup as well
      // await ProfileSetupService.resetProfileSetup();

      if (mounted) {
        // Navigate to splash screen to restart the flow
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully. Demo flow reset!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Reset profile setup only
  Future<void> _resetProfileSetup() async {
    try {
      // Reset profile setup
      await ProfileSetupService.resetProfileSetup();

      if (!mounted) return;

      // Update the auth provider
      final authProvider = Provider.of<AuthenticationProvider>(
        context,
        listen: false,
      );
      await authProvider.updateProfileSetupStatus();

      if (mounted) {
        // Navigate to splash screen to restart the flow
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile setup reset! You\'ll need to complete it again.',
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting profile setup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Reset demo flow for testing
  Future<void> _resetDemoFlow() async {
    try {
      // Clear authentication data without logging out
      // Reset onboarding to show it again
      await OnboardingService.resetOnboarding();

      if (mounted) {
        // Navigate to splash screen to restart the flow
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SplashScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo flow reset! You\'ll see onboarding again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting demo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
