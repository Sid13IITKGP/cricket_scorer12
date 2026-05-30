import 'package:cloud_firestore/cloud_firestore.dart';

class InningsStats {
  final int number;
  final int runs;
  final int wickets;
  final int extras;
  final int oversCompleted;
  final int balls;

  const InningsStats({
    required this.number,
    this.runs = 0,
    this.wickets = 0,
    this.extras = 0,
    this.oversCompleted = 0,
    this.balls = 0,
  });

  InningsStats copyWith({
    int? number,
    int? runs,
    int? wickets,
    int? extras,
    int? oversCompleted,
    int? balls,
  }) {
    return InningsStats(
      number: number ?? this.number,
      runs: runs ?? this.runs,
      wickets: wickets ?? this.wickets,
      extras: extras ?? this.extras,
      oversCompleted: oversCompleted ?? this.oversCompleted,
      balls: balls ?? this.balls,
    );
  }

  factory InningsStats.fromMap(Map<String, dynamic> data) {
    return InningsStats(
      number: data['number'] as int? ?? 1,
      runs: data['runs'] as int? ?? 0,
      wickets: data['wickets'] as int? ?? 0,
      extras: data['extras'] as int? ?? 0,
      oversCompleted: data['oversCompleted'] as int? ?? 0,
      balls: data['balls'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'runs': runs,
      'wickets': wickets,
      'extras': extras,
      'oversCompleted': oversCompleted,
      'balls': balls,
    };
  }

  String get formattedOvers => '$oversCompleted.${balls % 6}';
}

class MatchModel {
  final String id;
  final String code;
  final String name;
  final String hostId;
  final String currentHostId;
  final int totalOvers;
  final int currentInnings;
  final int oversCompleted;
  final int balls;
  final int runs;
  final int wickets;
  final int extras;
  final String comments;
  final bool isComplete;
  final List<String> currentOver;
  final List<InningsStats> innings;
  final List<Map<String, dynamic>> participants;
  final Timestamp createdAt;

  MatchModel({
    required this.id,
    required this.code,
    required this.name,
    required this.hostId,
    required this.currentHostId,
    required this.totalOvers,
    required this.currentInnings,
    required this.oversCompleted,
    required this.balls,
    required this.runs,
    required this.wickets,
    required this.extras,
    required this.comments,
    required this.isComplete,
    required this.currentOver,
    required this.innings,
    required this.participants,
    required this.createdAt,
  });

  factory MatchModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Match document ${snapshot.id} contains no data.');
    }

    return MatchModel(
      id: snapshot.id,
      code: data['code'] as String? ?? snapshot.id.substring(0, 6).toUpperCase(),
      name: data['name'] as String? ?? 'Untitled Match',
      hostId: data['hostId'] as String? ?? '',
      currentHostId: data['currentHostId'] as String? ?? data['hostId'] as String? ?? '',
      totalOvers: data['totalOvers'] as int? ?? 0,
      currentInnings: data['currentInnings'] as int? ?? 1,
      oversCompleted: data['oversCompleted'] as int? ?? 0,
      balls: data['balls'] as int? ?? 0,
      runs: data['runs'] as int? ?? 0,
      wickets: data['wickets'] as int? ?? 0,
      extras: data['extras'] as int? ?? 0,
      comments: data['comments'] as String? ?? '',
      isComplete: data['isComplete'] as bool? ?? false,
      currentOver: (data['currentOver'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList() ?? [],
      innings: (data['innings'] as List<dynamic>?)
          ?.map((item) => InningsStats.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList() ??
          [
            const InningsStats(number: 1),
            const InningsStats(number: 2),
          ],
      participants: (data['participants'] as List<dynamic>?)
          ?.map((item) => Map<String, dynamic>.from(item as Map))
          .toList() ??
          [],
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'hostId': hostId,
      'currentHostId': currentHostId,
      'totalOvers': totalOvers,
      'currentInnings': currentInnings,
      'oversCompleted': oversCompleted,
      'balls': balls,
      'runs': runs,
      'wickets': wickets,
      'extras': extras,
      'comments': comments,
      'isComplete': isComplete,
      'currentOver': currentOver,
      'innings': innings.map((inning) => inning.toMap()).toList(),
      'participants': participants,
      'createdAt': createdAt,
    };
  }

  String get formattedOvers {
    final ballCount = balls % 6;
    return '$oversCompleted.$ballCount';
  }

  String get currentOverDisplay {
    if (currentOver.isEmpty) return 'New over';
    return currentOver.join(' ');
  }
}
