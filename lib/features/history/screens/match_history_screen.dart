import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../history/screens/match_history_detail_screen.dart';
import '../../match/models/match_model.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  PageRoute<T> _buildPageRoute<T>(Widget page) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoPageRoute(builder: (_) => page);
    }
    return MaterialPageRoute(builder: (_) => page);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();
    final currentUserId = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match History'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.card.withOpacity(0.92)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(CupertinoIcons.clock, color: Colors.white70),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You can only see matches you are hosting or have joined.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: currentUserId.isEmpty
                  ? const Center(
                      child: Text('Sign in to see your match history.'),
                    )
                  : StreamBuilder<List<MatchModel>>(
                      stream: FirestoreService.watchMatchesForUser(currentUserId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData) {
                          return const Center(child: CupertinoActivityIndicator());
                        }

                        final matches = snapshot.data!;
                        if (matches.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'No joined or hosted matches yet. Start a match or join one to see history here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          itemCount: matches.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final match = matches[index];

                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 300 + (index * 25)),
                              builder: (context, opacity, child) {
                                return Opacity(
                                  opacity: opacity,
                                  child: Transform.translate(
                                    offset: Offset(0, 24 * (1 - opacity)),
                                    child: child,
                                  ),
                                );
                              },
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    _buildPageRoute(
                                      MatchHistoryDetailScreen(match: match),
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: 'match-card-${match.id}',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.card.withOpacity(0.9),
                                          AppColors.background.withOpacity(0.75),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.white12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.24),
                                          blurRadius: 18,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                match.name,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: match.isComplete
                                                    ? Colors.greenAccent.withOpacity(0.18)
                                                    : AppColors.secondary.withOpacity(0.18),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Text(
                                                match.isComplete ? 'Finished' : 'Live',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            _InfoBadge(
                                              icon: CupertinoIcons.person_2_fill,
                                              label: 'Players',
                                              value: '${match.participants.length}',
                                            ),
                                            const SizedBox(width: 10),
                                            _InfoBadge(
                                              icon: CupertinoIcons.clock_fill,
                                              label: 'Innings',
                                              value: '${match.currentInnings}',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          'Host: ${match.participants.firstWhere(
                                            (participant) => participant['uid'] == match.currentHostId,
                                            orElse: () => {'name': 'Unknown'},
                                          )['name'] as String? ?? 'Unknown'}',
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoBadge({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
