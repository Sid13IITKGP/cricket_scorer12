import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../match/models/match_model.dart';

class MatchHistoryDetailScreen extends StatefulWidget {
  final MatchModel match;

  const MatchHistoryDetailScreen({super.key, required this.match});

  @override
  State<MatchHistoryDetailScreen> createState() => _MatchHistoryDetailScreenState();
}

class _MatchHistoryDetailScreenState extends State<MatchHistoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String inningsLabel(InningsStats? innings) {
    if (innings == null) return 'Not started';
    if (innings.oversCompleted == 0 && innings.runs == 0 && innings.wickets == 0 && innings.extras == 0) {
      return 'Not started';
    }
    return '${innings.runs}/${innings.wickets} • ${innings.formattedOvers} overs • ${innings.extras} extras';
  }

  @override
  Widget build(BuildContext context) {
    final inningsOne = widget.match.innings.isNotEmpty ? widget.match.innings[0] : null;
    final inningsTwo = widget.match.innings.length > 1 ? widget.match.innings[1] : null;
    final hostName = widget.match.participants.firstWhere(
      (participant) => participant['uid'] == widget.match.currentHostId,
      orElse: () => {'name': 'Host'},
    )['name'] as String? ?? 'Host';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeController,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1.0),
                duration: const Duration(milliseconds: 400),
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.18),
                        AppColors.secondary.withOpacity(0.14),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.match.name,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Code: ${widget.match.code}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.match.isComplete
                                  ? Colors.green.withOpacity(0.15)
                                  : AppColors.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.match.isComplete
                                    ? Colors.green.withOpacity(0.3)
                                    : AppColors.secondary.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              widget.match.isComplete ? '✓ Finished' : '● Live',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: widget.match.isComplete ? Colors.green : AppColors.secondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _InfoChip(
                            icon: CupertinoIcons.person_2_fill,
                            label: '${widget.match.participants.length} Players',
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          _InfoChip(
                            icon: CupertinoIcons.number,
                            label: 'Innings ${widget.match.currentInnings}',
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Innings Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _StatRow(title: '1st Innings', value: inningsLabel(inningsOne)),
                      Divider(color: Colors.white.withOpacity(0.1), height: 24),
                      _StatRow(title: '2nd Innings', value: inningsLabel(inningsTwo)),
                      Divider(color: Colors.white.withOpacity(0.1), height: 24),
                      _StatRow(title: 'Total Overs', value: '${widget.match.totalOvers}'),
                      Divider(color: Colors.white.withOpacity(0.1), height: 24),
                      _StatRow(title: 'Host', value: hostName),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Match Totals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _StatRow(title: 'Runs', value: '${widget.match.runs}'),
                      Divider(color: Colors.white.withOpacity(0.1), height: 24),
                      _StatRow(title: 'Wickets', value: '${widget.match.wickets}'),
                      Divider(color: Colors.white.withOpacity(0.1), height: 24),
                      _StatRow(title: 'Extras', value: '${widget.match.extras}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String title;
  final String value;

  const _StatRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

