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
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };

  factory ContentRequest.fromJson(Map<String, dynamic> json) {
    return ContentRequest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String,
      language: json['language'] as String,
      votes: json['votes'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }
}

/// Service for content requests and voting.
class VotingService {
  static const _boxName = 'content_requests';
  static const _votesKey = 'my_votes';
  static const _requestsKey = 'requests';

  Box? _box;

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
  }

  /// Remove a vote.
  Future<void> unvote(String requestId) async {
    final votes = getMyVotes();
    votes.remove(requestId);
    await _box?.put(_votesKey, votes.toList());
  }

  /// Check if user has voted for a request.
  bool hasVoted(String requestId) {
    return getMyVotes().contains(requestId);
  }

  /// Get all requests (mock data for demo - in production, would fetch from server).
  List<ContentRequest> getAllRequests() {
    final myVotes = getMyVotes();

    // Demo data
    final requests = [
      ContentRequest(
        id: 'req_1',
        title: 'Panchatantra Stories in Kannada',
        description: 'Classic Panchatantra tales with moral lessons for kids',
        category: 'kids_stories',
        language: 'kannada',
        votes: 47,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        status: 'pending',
      ),
      ContentRequest(
        id: 'req_2',
        title: 'Bengali Science Podcasts',
        description: 'Scientific discoveries explained in simple Bengali',
        category: 'podcast',
        language: 'bengali',
        votes: 32,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        status: 'approved',
      ),
      ContentRequest(
        id: 'req_3',
        title: 'Marathi Stand-up Comedy',
        description: 'Popular stand-up comedians in Marathi',
        category: 'comedy',
        language: 'marathi',
        votes: 89,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        status: 'completed',
      ),
      ContentRequest(
        id: 'req_4',
        title: 'Tamil Tech News Daily',
        description: 'Latest technology news in Tamil language',
        category: 'news',
        language: 'tamil',
        votes: 56,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        status: 'pending',
      ),
      ContentRequest(
        id: 'req_5',
        title: 'Gujarati Business Podcasts',
        description: 'Entrepreneurship and business tips in Gujarati',
        category: 'podcast',
        language: 'gujarati',
        votes: 28,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: 'pending',
      ),
      ContentRequest(
        id: 'req_6',
        title: 'Telugu Horror Stories',
        description: 'Thrilling horror stories and suspense tales',
        category: 'stories',
        language: 'telugu',
        votes: 73,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        status: 'approved',
      ),
      ContentRequest(
        id: 'req_7',
        title: 'Hindi History Podcasts',
        description: 'Indian history narrated in engaging Hindi',
        category: 'podcast',
        language: 'hindi',
        votes: 112,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        status: 'pending',
      ),
      ContentRequest(
        id: 'req_8',
        title: 'Malayalam Cooking Shows',
        description: 'Traditional Kerala recipes and cooking tips',
        category: 'lifestyle',
        language: 'malayalam',
        votes: 41,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        status: 'pending',
      ),
    ];

    // Mark voted ones
    return requests.map((r) {
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
    final request = ContentRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      category: category,
      language: language,
      votes: 1, // Auto-vote for own request
      createdAt: DateTime.now(),
      status: 'pending',
      hasVoted: true,
    );

    // Save to local (in production, would POST to server)
    await vote(request.id);

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
    state = _service.getAllRequests();
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
