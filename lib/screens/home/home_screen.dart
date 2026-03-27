import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../widgets/session_card.dart';
import '../workout/new_session_screen.dart';
import '../workout/saved_session_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final sessionService = context.watch<SessionService>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Historial',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '${sessionService.sessions.length} sesiones registradas',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13),
              ),
            ),
          ),
          if (sessionService.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFE53935)),
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
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pulsa + para empezar',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SavedSessionScreen(
                              session: sessionService.sessions[index]),
                        ),
                      ),
                      child: SessionCard(
                          session: sessionService.sessions[index]),
                    ),
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
        label:
            const Text('Sesión', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
