import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// A content request from users.
class ContentRequest {
  final String id;
  final String title;
  final String description;
  final String category;
  final String language;
  final int votes;
  final DateTime createdAt;
  final String status; // pending, approved, completed, rejected
  final bool hasVoted;

  const ContentRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.language,
    required this.votes,
    required this.createdAt,
    required this.status,
    this.hasVoted = false,
  });

  ContentRequest copyWith({
    int? votes,
    String? status,
    bool? hasVoted,
  }) {
    return ContentRequest(
      id: id,
      title: title,
      description: description,
      category: category,
      language: language,
      votes: votes ?? this.votes,
      createdAt: createdAt,
      status: status ?? this.status,
      hasVoted: hasVoted ?? this.hasVoted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'language': language,
        'votes': votes,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status,
      };

  factory ContentRequest.fromJson(Map<String, dynamic> json) {
    dynamic createdAtData = json['createdAt'];
    DateTime parsedDate;
    if (createdAtData is Timestamp) {
      parsedDate = createdAtData.toDate();
    } else if (createdAtData is String) {
      parsedDate = DateTime.parse(createdAtData);
    } else {
      parsedDate = DateTime.now();
    }

    return ContentRequest(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      language: json['language'] as String? ?? '',
      votes: json['votes'] as int? ?? 0,
      createdAt: parsedDate,
      status: json['status'] as String? ?? 'pending',
    );
  }
}

/// Service for content requests and voting.
class VotingService {
  static const _boxName = 'content_requests';
  static const _votesKey = 'my_votes';

  Box? _box;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Get user's voted request IDs.
  Set<String> getMyVotes() {
    final list = _box?.get(_votesKey) as List?;
    if (list == null) return {};
    return Set<String>.from(list.cast<String>());
  }

  /// Record a vote.
  Future<void> vote(String requestId) async {
    final votes = getMyVotes();
    votes.add(requestId);
    await _box?.put(_votesKey, votes.toList());
    
    await _firestore.collection('requests').doc(requestId).update({
      'votes': FieldValue.increment(1),
    });
  }

  /// Remove a vote.
  Future<void> unvote(String requestId) async {
    final votes = getMyVotes();
    votes.remove(requestId);
    await _box?.put(_votesKey, votes.toList());

    await _firestore.collection('requests').doc(requestId).update({
      'votes': FieldValue.increment(-1),
    });
  }

  /// Check if user has voted for a request.
  bool hasVoted(String requestId) {
    return getMyVotes().contains(requestId);
  }

  /// Get all requests.
  Future<List<ContentRequest>> getAllRequests() async {
    final snapshot = await _firestore.collection('requests').orderBy('createdAt', descending: true).get();
    final myVotes = getMyVotes();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      final r = ContentRequest.fromJson(data);
      if (myVotes.contains(r.id)) {
        return r.copyWith(hasVoted: true);
      }
      return r;
    }).toList();
  }

  /// Submit a new content request.
  Future<ContentRequest> submitRequest({
    required String title,
    required String description,
    required String category,
    required String language,
  }) async {
    final docRef = _firestore.collection('requests').doc();
    
    final request = ContentRequest(
      id: docRef.id,
      title: title,
      description: description,
      category: category,
      language: language,
      votes: 1, // Auto-vote for own request
      createdAt: DateTime.now(),
      status: 'pending',
      hasVoted: true,
    );

    await docRef.set(request.toJson());
    
    final votes = getMyVotes();
    votes.add(request.id);
    await _box?.put(_votesKey, votes.toList());

    return request;
  }
}

/// Provider for the voting service.
final votingServiceProvider = Provider<VotingService>((ref) {
  final service = VotingService();
  service.init();
  return service;
});

/// Provider for all content requests.
final contentRequestsProvider =
    StateNotifierProvider<ContentRequestsNotifier, List<ContentRequest>>((ref) {
  final service = ref.watch(votingServiceProvider);
  return ContentRequestsNotifier(service);
});

class ContentRequestsNotifier extends StateNotifier<List<ContentRequest>> {
  final VotingService _service;

  ContentRequestsNotifier(this._service) : super([]) {
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    await _service.init();
    state = await _service.getAllRequests();
  }

  Future<void> vote(String requestId) async {
    await _service.vote(requestId);

    state = state.map((r) {
      if (r.id == requestId) {
        return r.copyWith(
          votes: r.votes + 1,
          hasVoted: true,
        );
      }
      return r;
    }).toList();
  }

  Future<void> unvote(String requestId) async {
    await _service.unvote(requestId);

    state = state.map((r) {
      if (r.id == requestId) {
        return r.copyWith(
          votes: r.votes - 1,
          hasVoted: false,
        );
      }
      return r;
    }).toList();
  }

  Future<void> submitRequest({
    required String title,
    required String description,
    required String category,
    required String language,
  }) async {
    final request = await _service.submitRequest(
      title: title,
      description: description,
      category: category,
      language: language,
    );

    state = [request, ...state];
  }

  void refresh() {
    _loadRequests();
  }
}

/// Provider for trending requests (top voted).
final trendingRequestsProvider = Provider<List<ContentRequest>>((ref) {
  final requests = ref.watch(contentRequestsProvider);
  final sorted = List<ContentRequest>.from(requests)
    ..sort((a, b) => b.votes.compareTo(a.votes));
  return sorted.take(5).toList();
});

/// Provider for requests by status.
final requestsByStatusProvider =
    Provider.family<List<ContentRequest>, String>((ref, status) {
  final requests = ref.watch(contentRequestsProvider);
  return requests.where((r) => r.status == status).toList();
});

/// Provider for requests by language.
final requestsByLanguageProvider =
    Provider.family<List<ContentRequest>, String>((ref, language) {
  final requests = ref.watch(contentRequestsProvider);
  return requests.where((r) => r.language == language).toList();
});
