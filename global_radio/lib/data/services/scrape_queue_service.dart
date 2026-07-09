import 'package:cloud_firestore/cloud_firestore.dart';

/// Queues a request to scrape/generate content for an interest that has no
/// matching catalog items yet — drained by tools/process_scrape_queue.py.
/// No sign-in required (see firestore.rules): this is just a topic string,
/// and adding an interest works pre-account like everything else in this
/// app's onboarding.
abstract class ScrapeQueueService {
  Future<void> requestScrape(String interest);
}

class FirestoreScrapeQueueService implements ScrapeQueueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> requestScrape(String interest) async {
    final doc = _firestore.collection('scrapeQueue').doc(interest);
    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(doc);
        if (snap.exists) {
          // Already queued (or already processed) — just bump the demand
          // signal, never touch `status` (server-owned once processing
          // starts; client rules only allow this collection's status to be
          // set to 'pending' on create, never overwritten on update).
          tx.update(doc, {
            'requestCount': FieldValue.increment(1),
            'requestedAt': FieldValue.serverTimestamp(),
          });
        } else {
          tx.set(doc, {
            'interest': interest,
            'status': 'pending',
            'requestedAt': FieldValue.serverTimestamp(),
            'requestCount': 1,
          });
        }
      });
    } catch (e) {
      print('[ScrapeQueueService] Error queueing scrape for "$interest": $e');
    }
  }
}
