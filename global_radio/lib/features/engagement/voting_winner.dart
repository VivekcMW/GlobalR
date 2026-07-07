/// Close the voting loop publicly: surface the top-voted request that we have
/// shipped ("completed") — "You asked, we made it" — so voters see their
/// voice mattered and non-voters learn voting works.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../voting/voting_service.dart';

/// The most-voted completed request, or null when nothing has shipped yet.
final votingWinnerProvider = Provider<ContentRequest?>((ref) {
  final completed = ref.watch(requestsByStatusProvider('completed'));
  if (completed.isEmpty) return null;
  final sorted = [...completed]..sort((a, b) => b.votes.compareTo(a.votes));
  return sorted.first;
});
