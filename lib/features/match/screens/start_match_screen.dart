import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../match/models/match_model.dart';
import 'match_score_screen.dart';

class StartMatchScreen extends StatefulWidget {
  const StartMatchScreen({super.key});

  @override
  State<StartMatchScreen> createState() => _StartMatchScreenState();
}

class _StartMatchScreenState extends State<StartMatchScreen> {
  final TextEditingController matchNameController = TextEditingController();
  final TextEditingController oversController = TextEditingController();
  bool _isSubmitting = false;

  String _buildMatchCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> _currentUserName() async {
    final user = AuthService.getCurrentUser();
    if (user == null) return 'Guest';

    final userSnapshot = await FirestoreService.getUser(user.uid);
    if (!userSnapshot.exists) return 'Guest';

    return userSnapshot.data()?['name'] as String? ?? 'Guest';
  }

  Future<void> _createMatch() async {
    final title = matchNameController.text.trim();
    final overs = int.tryParse(oversController.text.trim()) ?? 0;

    if (title.isEmpty || overs <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a match name and a valid overs per innings.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = AuthService.getCurrentUser();
      final hostId = user?.uid ?? '';
      final hostName = await _currentUserName();

      final match = MatchModel(
        id: '',
        code: _buildMatchCode(),
        name: title,
        hostId: hostId,
        currentHostId: hostId,
        totalOvers: overs,
        currentInnings: 1,
        oversCompleted: 0,
        balls: 0,
        runs: 0,
        wickets: 0,
        extras: 0,
        comments: '',
        isComplete: false,
        currentOver: const [],
        innings: const [
          InningsStats(number: 1),
          InningsStats(number: 2),
        ],
        participants: [
          {'uid': hostId, 'name': hostName},
        ],
        createdAt: Timestamp.now(),
      );

      final document = await FirestoreService.createMatch(match);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatchScoreScreen(matchId: document.id),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start match: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Start Match"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1F2A45), Color(0xFF27395E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.25 * 255).round()),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Match Setup',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Set the overs per innings and start scoring live for your players and viewers.',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: matchNameController,
                    decoration: InputDecoration(
                      labelText: 'Match Name',
                      hintText: 'e.g. City Cup Final',
                      filled: true,
                      fillColor: Colors.black12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: oversController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Overs per Innings',
                      hintText: '20',
                      filled: true,
                      fillColor: Colors.black12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _createMatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(Colors.black),
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Start Match',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
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

