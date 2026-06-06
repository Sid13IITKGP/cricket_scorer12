import 'dart:math';

import 'package:flutter/cupertino.dart';
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

class _StartMatchScreenState extends State<StartMatchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController matchNameController = TextEditingController();
  final TextEditingController oversController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    matchNameController.dispose();
    oversController.dispose();
    super.dispose();
  }

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
          content: Text('Please enter a match name and valid overs per innings.'),
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
          SnackBar(content: Text('Error: $error')),
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
        title: const Text("Start Match", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.14),
                      AppColors.secondary.withOpacity(0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(CupertinoIcons.sportscourt, color: AppColors.primary, size: 40),
                    const SizedBox(height: 16),
                    const Text(
                      'Match Setup',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Configure your match and start scoring in real-time.',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 40 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BuildTextField(
                      label: 'Match Name',
                      hint: 'e.g., City Cup Final',
                      icon: CupertinoIcons.sportscourt,
                      controller: matchNameController,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    _BuildTextField(
                      label: 'Overs per Innings',
                      hint: '20',
                      icon: CupertinoIcons.clock,
                      controller: oversController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 62,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isSubmitting ? null : _createMatch,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation(Colors.black87),
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(CupertinoIcons.play_fill, color: Colors.black87, size: 20),
                                        SizedBox(width: 10),
                                        Text(
                                          'Start Match',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '✓ Your match code will be generated automatically\n✓ Share it with players to join\n✓ You can transfer host permissions anytime',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                  height: 1.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final Function(String) onChanged;

  const _BuildTextField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_BuildTextField> createState() => _BuildTextFieldState();
}

class _BuildTextFieldState extends State<_BuildTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.black12,
                Colors.black26,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: Icon(widget.icon, color: AppColors.primary),
              filled: false,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }
}

