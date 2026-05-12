import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/section_header.dart';
import '../thesis/thesis_list_screen.dart';
import '../thesis/thesis_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final firstName = (user?.name ?? 'User').split(' ').first;
    final today = DateFormat('EEEE, d MMM').format(DateTime.now());
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello $firstName 👋',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        today,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showProfileSheet(context, auth),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.lavender,
                      child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SectionHeader(
                title: 'Quick Actions',
                actionLabel: 'See All',
                onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ThesisListScreen())),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: [
                  FeatureCard(
                    title: 'My Theses',
                    subtitle: 'View & manage',
                    icon: Icons.menu_book_rounded,
                    backgroundColor: AppColors.lavender,
                    iconColor: AppColors.primary,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ThesisListScreen())),
                  ),
                  FeatureCard(
                    title: 'New Session',
                    subtitle: 'Schedule now',
                    icon: Icons.calendar_today_rounded,
                    backgroundColor: AppColors.yellow,
                    iconColor: const Color(0xFF7A5500),
                    showBadge: true,
                    badgeText: 'New',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ThesisListScreen())),
                  ),
                  FeatureCard(
                    title: 'Add Thesis',
                    subtitle: 'Start a project',
                    icon: Icons.add_circle_outline_rounded,
                    backgroundColor: AppColors.dark,
                    iconColor: AppColors.surface,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ThesisFormScreen())),
                  ),
                  FeatureCard(
                    title: 'Milestones',
                    subtitle: 'Track progress',
                    icon: Icons.flag_rounded,
                    backgroundColor: AppColors.cardLight,
                    iconColor: AppColors.primary,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ThesisListScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, const Color(0xFF9B85FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Stay on track!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Complete your milestones before the deadline.',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.rocket_launch_rounded,
                        color: Colors.white, size: 36),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Recent Activity'),
              const SizedBox(height: 14),
              _ActivityItem(
                icon: Icons.menu_book_rounded,
                iconBg: AppColors.lavender,
                iconColor: AppColors.primary,
                title: 'Thesis created',
                subtitle: 'Add your first thesis to get started',
              ),
              const SizedBox(height: 10),
              _ActivityItem(
                icon: Icons.flag_rounded,
                iconBg: AppColors.yellow,
                iconColor: const Color(0xFF7A5500),
                title: 'Set milestones',
                subtitle: 'Break your thesis into manageable goals',
              ),
              const SizedBox(height: 10),
              _ActivityItem(
                icon: Icons.calendar_today_rounded,
                iconBg: AppColors.cardLight,
                iconColor: AppColors.primary,
                title: 'Schedule a session',
                subtitle: 'Meet your supervisor & track feedback',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.lavender,
              child: Text(
                (auth.user?.name ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              auth.user?.name ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              auth.user?.email ?? '',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                (auth.user?.role ?? 'student').toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('Sign Out',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                auth.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  const _ActivityItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textLight, size: 20),
        ],
      ),
    );
  }
}
