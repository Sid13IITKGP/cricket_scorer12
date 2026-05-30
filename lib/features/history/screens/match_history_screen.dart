import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/firestore_service.dart';
import '../../history/screens/match_history_detail_screen.dart';
import '../../match/models/match_model.dart';

class MatchHistoryScreen extends StatelessWidget {
  const MatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match History'),
      ),
      body: StreamBuilder<List<MatchModel>>(
        stream: FirestoreService.watchMatches(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data!;
          if (matches.isEmpty) {
            return const Center(
              child: Text('No matches yet. Start one from the home screen.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final match = matches[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                tileColor: AppColors.card,
                title: Text(match.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      '1st Innings: ${match.innings[0].runs}/${match.innings[0].wickets} • ${match.innings[0].formattedOvers}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '2nd Innings: ${match.innings.length > 1 ? '${match.innings[1].runs}/${match.innings[1].wickets} • ${match.innings[1].formattedOvers}' : 'Not started'}',
                    ),
                  ],
                ),
                trailing: Text(
                  match.isComplete ? 'Finished' : 'Live',
                  style: TextStyle(
                    color: match.isComplete ? Colors.greenAccent : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MatchHistoryDetailScreen(match: match),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
