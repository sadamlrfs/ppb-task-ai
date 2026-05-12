import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'models/thesis_model.dart';
import 'providers/auth_provider.dart';
import 'providers/gemma_provider.dart';
import 'services/firestore_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/thesis/thesis_form_screen.dart';
import 'screens/bimbingan/bimbingan_list_screen.dart';

class ThesisTrackApp extends StatelessWidget {
  const ThesisTrackApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GemmaProvider()),
      ],
      child: MaterialApp(
        title: 'MyBimbingan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checked = false;
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await context.read<AuthProvider>().loadCurrentUser();
    if (mounted) setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
        ),
      );
    }
    final auth = context.watch<AuthProvider>();
    return auth.isLoggedIn ? const _ThesisGate() : const LoginScreen();
  }
}

class _ThesisGate extends StatelessWidget {
  const _ThesisGate();
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    return StreamBuilder<List<ThesisModel>>(
      stream: FirestoreService().thesesStream(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final theses = snap.data ?? [];
        if (theses.isEmpty) {
          return PopScope(
            canPop: false,
            child: ThesisFormScreen(isSetup: true),
          );
        }
        return BimbinganListScreen(thesis: theses.first);
      },
    );
  }
}
