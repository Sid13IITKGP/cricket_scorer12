import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cricket_scoring_app/features/match/models/match_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get matches =>
      _firestore.collection('matches');

  static Future<DocumentReference<Map<String, dynamic>>> createMatch(
      MatchModel match) {
    return matches.add(match.toMap());
  }

  static Stream<List<MatchModel>> watchMatches() {
    return matches
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromSnapshot(doc))
            .toList());
  }

  static Stream<List<MatchModel>> watchMatchesForUser(String uid) {
    return watchMatches().map((matches) => matches
        .where((match) => match.hostId == uid ||
            match.currentHostId == uid ||
            match.participants.any((participant) => participant['uid'] == uid))
        .toList());
  }

  static Stream<MatchModel> watchMatch(String matchId) {
    return matches.doc(matchId).snapshots().map(
          (snapshot) => MatchModel.fromSnapshot(snapshot),
        );
  }

  static Future<MatchModel?> getMatchById(String matchId) async {
    final snapshot = await matches.doc(matchId).get();
    if (!snapshot.exists) {
      return null;
    }
    return MatchModel.fromSnapshot(snapshot);
  }

  static Future<MatchModel?> getMatchByCode(String code) async {
    final query = await matches.where('code', isEqualTo: code).limit(1).get();
    if (query.docs.isEmpty) return null;
    return MatchModel.fromSnapshot(query.docs.first);
  }

  static Future<void> addMatchParticipant(
    String matchId,
    String uid,
    String name,
  ) {
    return matches.doc(matchId).update({
      'participants': FieldValue.arrayUnion([
        {'uid': uid, 'name': name},
      ]),
    });
  }

  static Stream<List<MatchModel>> watchLiveMatches() {
    return matches
        .where('isComplete', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromSnapshot(doc))
            .toList());
  }

  static Future<void> updateMatch(
      String matchId, Map<String, dynamic> data) {
    return matches.doc(matchId).update(data);
  }

  // Users collection helpers
  static CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');

  static Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return users.doc(uid).get();
  }

  static Future<void> createOrUpdateUser(String uid, Map<String, dynamic> data) {
    return users.doc(uid).set(data, SetOptions(merge: true));
  }
}
