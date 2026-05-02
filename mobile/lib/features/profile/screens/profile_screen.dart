import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/providers.dart';
import '../../../shared/widgets/member_avatar.dart';
import '../../auth/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploading = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      await ref.read(membersRepositoryProvider).uploadPhoto(file.path);
      await ref.read(authControllerProvider.notifier).refreshMe();
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final m = state.member;
    return Scaffold(
      appBar: AppBar(
        title: const Text('بروفايلي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: m == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      MemberAvatar(photoUrl: m.photoUrl, name: m.fullNameAr, radius: 56),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _uploading ? null : _pickPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: _uploading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(m.fullNameAr,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  Text(m.judicialRank,
                      style: const TextStyle(color: AppColors.primary, fontSize: 16)),
                  Text(m.currentCourt,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  if (state.user?.isAdmin == true)
                    _menuTile(
                      Icons.admin_panel_settings_outlined,
                      'لوحة الإدارة',
                      () => context.push('/admin'),
                      color: AppColors.accent,
                    ),
                  _menuTile(
                    Icons.feedback_outlined,
                    'الاقتراحات والشكاوى',
                    () => context.push('/suggestions'),
                  ),
                  _menuTile(
                    Icons.policy_outlined,
                    'سياسة الخصوصية',
                    () => context.push('/legal/privacy'),
                  ),
                  _menuTile(
                    Icons.description_outlined,
                    'شروط الاستخدام',
                    () => context.push('/legal/terms'),
                  ),
                  _menuTile(
                    Icons.logout,
                    'تسجيل خروج',
                    () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    color: AppColors.danger,
                  ),
                  _menuTile(
                    Icons.delete_forever_outlined,
                    'حذف الحساب',
                    () => context.push('/delete-account'),
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _menuTile(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.primary),
        title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
