import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../match/models/match_model.dart';
import '../../../services/firestore_service.dart';

class _ScoreAction {
  final int runs;
  final int wickets;
  final int extras;
  final int balls;
  final String label;

  const _ScoreAction({
    this.runs = 0,
    this.wickets = 0,
    this.extras = 0,
    this.balls = 0,
    required this.label,
  });

  _ScoreAction inverse() {
    return _ScoreAction(
      runs: -runs,
      wickets: -wickets,
      extras: -extras,
      balls: -balls,
      label: 'Revert $label',
    );
  }
}

class MatchScoreScreen extends StatefulWidget {
  final String matchId;

  const MatchScoreScreen({super.key, required this.matchId});

  @override
  State<MatchScoreScreen> createState() => _MatchScoreScreenState();
}

class _MatchScoreScreenState extends State<MatchScoreScreen> {
  final List<_ScoreAction> _actionHistory = [];
  bool _isUpdating = false;
  bool _joinedMatch = false;
  String _currentUserId = '';
  String _currentUserName = 'Guest';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = AuthService.getCurrentUser();
    if (user == null) return;
    final userSnapshot = await FirestoreService.getUser(user.uid);
    if (!mounted) return;
    setState(() {
      _currentUserId = user.uid;
      _currentUserName = userSnapshot.data()?['name'] as String? ?? 'Guest';
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isCurrentHost(MatchModel match) {
    return _currentUserId.isNotEmpty && _currentUserId == match.currentHostId;
  }

  bool _inningsComplete(MatchModel match) {
    return match.oversCompleted >= match.totalOvers;
  }

  bool _canScore(MatchModel match) {
    return _isCurrentHost(match) && !match.isComplete && !_inningsComplete(match);
  }

  Future<void> _ensureJoined(MatchModel match) async {
    if (_joinedMatch) return;
    if (_currentUserId.isEmpty) return;
    if (match.participants.any((participant) => participant['uid'] == _currentUserId)) {
      _joinedMatch = true;
      return;
    }
    _joinedMatch = true;
    await FirestoreService.addMatchParticipant(match.id, _currentUserId, _currentUserName);
  }

  String _ballLabel(_ScoreAction action) {
    if (action.extras > 0) return 'E${action.extras}';
    if (action.wickets > 0) return 'W';
    if (action.balls > 0 && action.runs == 0) return '.';
    return '${action.runs}';
  }

  Map<String, dynamic>? _calculateScoreUpdate(
    MatchModel match,
    _ScoreAction action,
  ) {
    final newRuns = match.runs + action.runs;
    final newWickets = match.wickets + action.wickets;
    final newExtras = match.extras + action.extras;
    var newBalls = match.balls + action.balls;
    var completedOvers = match.oversCompleted;
    final currentOver = List<String>.from(match.currentOver);

    if (newBalls < 0) {
      if (completedOvers == 0) {
        return null;
      }
      completedOvers -= 1;
      newBalls += 6;
    }

    if (newBalls >= 6) {
      completedOvers += newBalls ~/ 6;
      newBalls = newBalls % 6;
    }

    if (newRuns < 0 || newWickets < 0 || newExtras < 0 || completedOvers < 0 || newBalls < 0) {
      return null;
    }

    final token = _ballLabel(action);
    if (action.balls > 0) {
      final previousBalls = match.balls;
      final completedOver = previousBalls + action.balls >= 6;
      if (completedOver) {
        currentOver.clear();
      } else {
        currentOver.add(token);
      }
    } else if (action.extras > 0) {
      currentOver.add(token);
    } else if (action.balls < 0 || action.extras < 0) {
      if (currentOver.isNotEmpty) {
        currentOver.removeLast();
      }
    }

    final updatedInnings = match.innings
        .asMap()
        .entries
        .map((entry) => entry.key == match.currentInnings - 1
            ? entry.value.copyWith(
                runs: newRuns,
                wickets: newWickets,
                extras: newExtras,
                oversCompleted: completedOvers,
                balls: newBalls,
              )
            : entry.value)
        .toList();

    final bool matchEnded = match.currentInnings == 2 && completedOvers >= match.totalOvers;

    return {
      'runs': newRuns,
      'wickets': newWickets,
      'extras': newExtras,
      'balls': newBalls,
      'oversCompleted': completedOvers,
      'innings': updatedInnings.map((inning) => inning.toMap()).toList(),
      'isComplete': matchEnded,
      'currentOver': currentOver,
    };
  }

  Future<void> _applyScoreAction(
    MatchModel match,
    _ScoreAction action, {
    bool recordHistory = true,
  }) async {
    if (!_canScore(match) && recordHistory) {
      _showSnackBar('Only the current host can update score.');
      return;
    }
    if (_isUpdating) return;

    final updatedRuns = match.runs + action.runs;
    final values = _calculateScoreUpdate(match, action);
    if (values == null) {
      _showSnackBar('Unable to apply this score change.');
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      if (recordHistory) {
        _actionHistory.add(action);
      }
      await FirestoreService.updateMatch(match.id, values);
      if (match.currentInnings == 2 && updatedRuns > match.innings[0].runs) {
        await _showTeamTwoWinPrompt(match, updatedRuns);
      }
    } catch (error) {
      _showSnackBar('Failed to update score: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _revertLastDecision(MatchModel match) {
    if (!_isCurrentHost(match)) {
      _showSnackBar('Only the current host can revert decisions.');
      return;
    }
    if (_actionHistory.isEmpty) {
      _showSnackBar('No recent decision to revert.');
      return;
    }

    final lastAction = _actionHistory.removeLast();
    _applyScoreAction(match, lastAction.inverse(), recordHistory: false);
  }

  void _showExtraPicker(BuildContext context, MatchModel match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Extra Runs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(7, (index) {
                  final value = index + 1;
                  return _ExtraChoiceChip(
                    value: value,
                    onPressed: () {
                      Navigator.pop(context);
                      _applyScoreAction(
                        match,
                        _ScoreAction(
                          runs: value,
                          extras: value,
                          balls: 0,
                          label: '+$value Extra',
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _transferHost(String matchId, String newHostId) async {
    if (_isUpdating) return;
    setState(() {
      _isUpdating = true;
    });
    try {
      await FirestoreService.updateMatch(matchId, {'currentHostId': newHostId});
      _showSnackBar('Host permissions transferred successfully.');
    } catch (error) {
      _showSnackBar('Failed to transfer host: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showTransferHostPicker(BuildContext context, MatchModel match) {
    final availableParticipants = match.participants
        .where((participant) => participant['uid'] != match.currentHostId)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Transfer Host To',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (availableParticipants.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No other joined users available yet.'),
                )
              else
                ...availableParticipants.map((participant) {
                  final name = participant['name'] as String? ?? 'Unknown';
                  return Card(
                    color: AppColors.card,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(name),
                      onTap: () {
                        Navigator.pop(context);
                        _transferHost(match.id, participant['uid'] as String);
                      },
                    ),
                  );
                }),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startSecondInnings(MatchModel match) async {
    if (!_isCurrentHost(match)) {
      _showSnackBar('Only the current host can end the innings.');
      return;
    }
    if (match.currentInnings != 1) return;

    await FirestoreService.updateMatch(match.id, {
      'currentInnings': 2,
      'runs': 0,
      'wickets': 0,
      'extras': 0,
      'balls': 0,
      'oversCompleted': 0,
      'currentOver': [],
    });
    _showSnackBar('Second innings started.');
  }

  Future<void> _confirmEndFirstInnings(MatchModel match) async {
    if (!_isCurrentHost(match)) {
      _showSnackBar('Only the current host can end the innings.');
      return;
    }
    if (match.currentInnings != 1) return;

    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Innings?'),
        content: const Text('Are you sure you want to end the first innings now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Innings'),
          ),
        ],
      ),
    );

    if (shouldEnd == true) {
      await _startSecondInnings(match);
    }
  }

  Future<void> _endMatch(MatchModel match) async {
    if (!_isCurrentHost(match)) {
      _showSnackBar('Only the current host can end the match.');
      return;
    }
    if (match.currentInnings != 2) return;

    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Match?'),
        content: const Text('Are you sure you want to end the match now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Match'),
          ),
        ],
      ),
    );

    if (shouldEnd != true) return;
    await FirestoreService.updateMatch(match.id, {'isComplete': true});
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
    _showSnackBar('Match ended. Everyone is now a viewer.');
  }

  Future<void> _showTeamTwoWinPrompt(MatchModel match, int updatedRuns) async {
    final target = match.innings[0].runs;
    if (match.currentInnings != 2 || updatedRuns <= target) return;

    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Team 2 is ahead'),
        content: const Text('Team 2 has surpassed the target. End the match now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Match'),
          ),
        ],
      ),
    );

    if (shouldEnd == true) {
      await FirestoreService.updateMatch(match.id, {'isComplete': true});
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MatchModel>(
      stream: FirestoreService.watchMatch(widget.matchId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Match Score')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Match Score')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final match = snapshot.data!;
        if (!_joinedMatch && _currentUserId.isNotEmpty) {
          _ensureJoined(match);
        }

        final isComplete = match.isComplete;
        if (isComplete) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: Text(match.name)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Match Ended',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This match has finished. Tap below to return to the home screen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Go to Home',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final canScore = _canScore(match);
        final showEndInnings = match.currentInnings == 1 && _isCurrentHost(match) && !match.isComplete;
        final showEndMatch = match.currentInnings == 2 && _isCurrentHost(match) && !match.isComplete;
        final currentHostName = match.participants
                .firstWhere(
                  (participant) => participant['uid'] == match.currentHostId,
                  orElse: () => {'name': 'Host'},
                )['name'] as String? ?? 'Host';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(match.name),
            actions: [
              if (!isComplete && _isCurrentHost(match))
                IconButton(
                  onPressed: () => _showTransferHostPicker(context, match),
                  icon: const Icon(Icons.transfer_within_a_station),
                  tooltip: 'Transfer Host',
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Match Code',
                                style: TextStyle(fontSize: 14, color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    match.code,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ClipOval(
                                    child: Material(
                                      color: Colors.white12,
                                      child: IconButton(
                                        icon: const Icon(Icons.copy, size: 18),
                                        color: Colors.white,
                                        padding: const EdgeInsets.all(10),
                                        tooltip: 'Copy match code',
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: match.code));
                                          _showSnackBar('Match code copied to clipboard');
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Host: ${currentHostName == _currentUserName ? 'You' : currentHostName}',
                                style: const TextStyle(fontSize: 14, color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Innings ${match.currentInnings}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _InningsSummaryChip(
                            label: '1st Innings',
                            value: match.innings[0].oversCompleted == 0
                                ? 'Yet to bat'
                                : '${match.innings[0].runs}/${match.innings[0].wickets} • ${match.innings[0].formattedOvers}',
                          ),
                          _InningsSummaryChip(
                            label: '2nd Innings',
                            value: match.currentInnings == 2 || match.innings[1].oversCompleted > 0
                                ? '${match.innings[1].runs}/${match.innings[1].wickets} • ${match.innings[1].formattedOvers}'
                                : 'Waiting',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Current Over',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          Text(
                            '${match.balls}/6 balls',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: match.currentOver.isEmpty
                              ? [
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text('New over', style: TextStyle(color: Colors.white70)),
                                  ),
                                ]
                              : match.currentOver
                                  .map(
                                    (ball) => Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white12,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(ball, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _MatchStatTile(
                              label: 'Overs',
                              value: '${match.formattedOvers}/${match.totalOvers}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MatchStatTile(
                              label: 'Runs',
                              value: '${match.runs}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MatchStatTile(
                              label: 'Wkts',
                              value: '${match.wickets}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MatchStatTile(
                              label: 'Extras',
                              value: '${match.extras}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!canScore)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isComplete
                          ? 'Match ended. All users are viewers now.'
                          : _isCurrentHost(match)
                              ? 'Innings complete. Start second innings or end the match below.'
                              : 'You are viewing this live match. Only the current host can score.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                if (!canScore) const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _ScoreButton(
                      label: '+1',
                      color: AppColors.primary,
                      onPressed: canScore
                          ? () => _applyScoreAction(
                                match,
                                const _ScoreAction(runs: 1, balls: 1, label: '+1'),
                              )
                          : null,
                    ),
                    _ScoreButton(
                      label: '+2',
                      color: AppColors.secondary,
                      onPressed: canScore
                          ? () => _applyScoreAction(
                                match,
                                const _ScoreAction(runs: 2, balls: 1, label: '+2'),
                              )
                          : null,
                    ),
                    _ScoreButton(
                      label: '+3',
                      color: Colors.teal.shade400,
                      onPressed: canScore
                          ? () => _applyScoreAction(
                                match,
                                const _ScoreAction(runs: 3, balls: 1, label: '+3'),
                              )
                          : null,
                    ),
                    _ScoreButton(
                      label: '+4',
                      color: Colors.orangeAccent.shade200,
                      onPressed: canScore
                          ? () => _applyScoreAction(
                                match,
                                const _ScoreAction(runs: 4, balls: 1, label: '+4'),
                              )
                          : null,
                    ),
                    _ScoreButton(
                      label: '+6',
                      color: AppColors.six,
                      onPressed: canScore
                          ? () => _applyScoreAction(
                                match,
                                const _ScoreAction(runs: 6, balls: 1, label: '+6'),
                              )
                          : null,
                    ),
                    _ScoreButton(
                      label: 'W',
                      color: AppColors.wicket,
                      onPressed: canScore
                          ? () => _applyScoreAction(
                                match,
                                const _ScoreAction(wickets: 1, balls: 1, label: 'Wicket'),
                              )
                          : null,
                    ),
                    _ScoreButton(
                      label: '.',
                      color: Colors.grey.shade700,
                      onPressed: canScore
                          ? () => _applyScoreAction(
                                match,
                                const _ScoreAction(balls: 1, label: 'Dot Ball'),
                              )
                          : null,
                    ),
                    _ScoreButton(
                      label: 'E',
                      color: Colors.blueGrey,
                      onPressed: canScore ? () => _showExtraPicker(context, match) : null,
                    ),
                    _ScoreButton(
                      label: 'Revert',
                      color: Colors.redAccent.shade200,
                      onPressed: canScore ? () => _revertLastDecision(match) : null,
                    ),
                  ],
                ),
                if (showEndInnings) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _confirmEndFirstInnings(match),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'End Innings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
                if (showEndMatch) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _endMatch(match),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.wicket,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'End Match',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScoreButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ScoreButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed == null ? Colors.white12 : color,
        foregroundColor: onPressed == null ? Colors.white54 : Colors.black,
        minimumSize: const Size(72, 72),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InningsSummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _InningsSummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MatchStatTile extends StatelessWidget {
  final String label;
  final String value;

  const _MatchStatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtraChoiceChip extends StatelessWidget {
  final int value;
  final VoidCallback onPressed;

  const _ExtraChoiceChip({required this.value, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          '+$value',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
