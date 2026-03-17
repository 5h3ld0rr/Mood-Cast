import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_models.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;
  String? get displayName => _auth.currentUser?.displayName ?? 'Anonymous';

  // --- Support Chat ---
  Stream<List<ChatMessage>> getMessages() {
    if (uid == null) return Stream.value([]);
    
    return _firestore
        .collection('support_chats')
        .doc(uid)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  Future<void> sendMessage(String text) async {
    if (uid == null) return;

    final message = {
      'senderId': uid,
      'senderName': displayName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isUser': true,
    };

    // First ensure the chat document exists
    await _firestore.collection('support_chats').doc(uid).set({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'userId': uid,
      'userName': displayName,
      'isReadByAdmin': false,
    }, SetOptions(merge: true));

    // Then add the message to the subcollection
    await _firestore
        .collection('support_chats')
        .doc(uid)
        .collection('messages')
        .add(message);
  }

  // Auto-respond with Knowledge Base (Continuous Support)
  Future<void> simulateSupportResponse(String userMessage) async {
    if (uid == null) return;

    // Set typing status
    await _firestore.collection('support_chats').doc(uid).update({'isTyping': true});

    // Ikmana (Fast) reply: 800ms delay instead of 2s
    await Future.delayed(const Duration(milliseconds: 800));

    String text = userMessage.toLowerCase();
    String responseText = "That's an interesting point! Can you tell me more so I can assist you better?";

    // --- ULTIMATE KNOWLEDGE BASE ---
    if (text.contains("how to use") || text.contains("how it works") || text.contains("features")) {
      responseText = "MoodCast analyzes your current state through 'MoodSync' and creates personalized playlists based on the music you love. You can also manually sync your mood in the Scan tab!";
    } else if (text.contains("scan") || text.contains("moodsync")) {
      responseText = "MoodSync (in the center tab) uses your camera or manual selection to detect your mood and apply a dynamic theme across the whole app while choosing the perfect tracks for you.";
    } else if (text.contains("community") || text.contains("lift") || text.contains("vibe")) {
      responseText = "In the Community tab, you can 'Need a Lift' if you're feeling low, and others can 'Drop a Vibe' (share a song) to cheer you up. It's all about collective healing through music.";
    } else if (text.contains("premium") || text.contains("subscription") || text.contains("pro")) {
      responseText = "MoodCast Pro unlocks offline listening, better AI scanning, and exclusive themes. You can manage your subscription in Profile > Subscription.";
    } else if (text.contains("offline") || text.contains("download")) {
      responseText = "Offline listening is a Pro feature! Once you upgrade, you can download your favorite tracks and listen without an internet connection.";
    } else if (text.contains("insight") || text.contains("trend") || text.contains("stat") || text.contains("history")) {
      responseText = "Check your 'Trends & Insights' in Profile > Trends. You can see your Mood Breakdown, Emotional Intensity over the last 7 days, and your Recent Sessions history.";
    } else if (text.contains("search") || text.contains("artist") || text.contains("category")) {
      responseText = "Explore specific Genres like Pop, Chill, Rock, Electronic, Indie, Jazz, Hip-Hop, Classical, R&B, and K-Pop in the Search tab. You can also find Suggested Artists and your Search History there.";
    } else if (text.contains("library") || text.contains("playlist") || text.contains("liked")) {
      responseText = "Your Library is your personal music hub. You can find your Liked Songs, create custom Playlists, and see the Artists you follow.";
    } else if (text.contains("account") || text.contains("profile") || text.contains("edit") || text.contains("payment")) {
      responseText = "In your Profile, you can edit your display name, manage Payment Methods, and update Privacy & Security. You can also view your Recent Activity there.";
    } else if (text.contains("weather")) {
      responseText = "MoodCast fetches your local weather to help suggest the perfect music for your environment. It's all about syncing your vibe with the world!";
    } else if (text.contains("tech") || text.contains("build") || text.contains("app") || text.contains("system")) {
      responseText = "MoodCast is a modern mobile app built with Flutter and Firebase. We use the YouTube Music API to bring you millions of tracks with high-quality streaming.";
    } else if (text.contains("help") || text.contains("support")) {
      responseText = "I'm the MoodCast Support Assistant! I can help you with MoodSync, Community features, Insights, or Subscription. If I can't answer, please email us at support@moodcast.app.";
    } else if (text.contains("hello") || text.contains("hi") || text.contains("hey")) {
      responseText = "Hi there! I'm the MoodCast Support Assistant. I'm available 24/7 to answer your questions about the app. How can I help you today?";
    } else if (text.contains("thank") || text.contains("thanks")) {
      responseText = "You're very welcome! Is there anything else you'd like to know about MoodCast?";
    } else if (text.contains("who made this") || text.contains("developer")) {
      responseText = "MoodCast was built with ❤️ to help people connect with their emotions through the power of music.";
    } else {
      // Comprehensive Fallback
      responseText = "I'm still learning about the deep details of MoodCast. I couldn't find a perfect answer for that, but I've noted it down! Would you like to reach out to our human support team at support@moodcast.app?";
    }

    final response = {
      'senderId': 'support_agent',
      'senderName': 'MoodCast Support',
      'text': responseText,
      'timestamp': FieldValue.serverTimestamp(),
      'isUser': false,
    };

    // Add message and stop typing
    final batch = _firestore.batch();
    final messageRef = _firestore.collection('support_chats').doc(uid).collection('messages').doc();
    batch.set(messageRef, response);
    batch.update(_firestore.collection('support_chats').doc(uid), {'isTyping': false});
    
    await batch.commit();
  }

  Stream<bool> getTypingStatus() {
    if (uid == null) return Stream.value(false);
    return _firestore.collection('support_chats').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return false;
      return snapshot.data()?['isTyping'] ?? false;
    });
  }
}
