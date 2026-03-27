import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../widgets/session_card.dart';
import '../progress/progress_screen.dart';
import '../profile/profile_screen.dart';
import '../workout/new_session_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.currentUser != null) {
        context.read<SessionService>().loadSessions(auth.currentUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final sessionService = context.watch<SessionService>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'PowerLog',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_outlined),
                tooltip: 'Progreso',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProgressScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_outline),
                tooltip: 'Perfil',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${auth.currentUser?.displayName ?? "Atleta"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sessionService.sessions.length} sesiones registradas',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          if (sessionService.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFE53935)),
              ),
            )
          else if (sessionService.sessions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fitness_center,
                        color: Colors.white.withOpacity(0.2), size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Sin sesiones aún',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pulsa + para empezar',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3), fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SessionCard(session: sessionService.sessions[index]),
                  ),
                  childCount: sessionService.sessions.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewSessionScreen()),
        ),
        backgroundColor: const Color(0xFFE53935),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Sesión', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
