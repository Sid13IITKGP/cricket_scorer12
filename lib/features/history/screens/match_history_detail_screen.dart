import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../match/models/match_model.dart';

class MatchHistoryDetailScreen extends StatelessWidget {
  final MatchModel match;

  const MatchHistoryDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final inningsOne = match.innings.isNotEmpty ? match.innings[0] : null;
    final inningsTwo = match.innings.length > 1 ? match.innings[1] : null;

    String inningsLabel(InningsStats? innings) {
      if (innings == null) return 'Not started';
      if (innings.oversCompleted == 0 && innings.runs == 0 && innings.wickets == 0 && innings.extras == 0) {
        return 'Not started';
      }
      return '${innings.runs}/${innings.wickets} • ${innings.formattedOvers} overs • ${innings.extras} extras';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Summary'),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match.name,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Code: ${match.code}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _DetailChip(label: match.isComplete ? 'Finished' : 'Live', color: match.isComplete ? Colors.greenAccent : AppColors.secondary),
                      const SizedBox(width: 10),
                      _DetailChip(label: 'Innings ${match.currentInnings}', color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Innings Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _HistoryStatRow(
                    title: '1st Innings',
                    value: inningsLabel(inningsOne),
                  ),
                  const Divider(color: Colors.white12),
                  _HistoryStatRow(
                    title: '2nd Innings',
                    value: inningsLabel(inningsTwo),
                  ),
                  const Divider(color: Colors.white12),
                  _HistoryStatRow(
                    title: 'Total Overs',
                    value: '${match.totalOvers}',
                  ),
                  _HistoryStatRow(
                    title: 'Host',
                    value: match.participants.firstWhere(
                      (participant) => participant['uid'] == match.currentHostId,
                      orElse: () => {'name': 'Host'},
                    )['name'] as String? ?? 'Host',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final Color color;

  const _DetailChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HistoryStatRow extends StatelessWidget {
  final String title;
  final String value;

  const _HistoryStatRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
