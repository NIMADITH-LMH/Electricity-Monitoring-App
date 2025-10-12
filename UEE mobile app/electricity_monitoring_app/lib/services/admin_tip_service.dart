import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/admin_tip_model.dart';

class AdminTipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();

      return adminDoc.exists && (adminDoc.data()?['isActive'] ?? false);
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Create admin tip
  Future<void> createAdminTip(AdminTipModel tip) async {
    if (!await isCurrentUserAdmin()) {
      throw Exception('Unauthorized: Only admins can create tips');
    }

    try {
      await _firestore.collection('admin_tips').add(tip.toMap());
    } catch (e) {
      throw Exception('Failed to create admin tip: $e');
    }
  }

  // Update admin tip
  Future<void> updateAdminTip(AdminTipModel tip) async {
    if (!await isCurrentUserAdmin()) {
      throw Exception('Unauthorized: Only admins can update tips');
    }

    try {
      await _firestore.collection('admin_tips').doc(tip.id).update(tip.toMap());
    } catch (e) {
      throw Exception('Failed to update admin tip: $e');
    }
  }

  // Delete admin tip
  Future<void> deleteAdminTip(String tipId) async {
    if (!await isCurrentUserAdmin()) {
      throw Exception('Unauthorized: Only admins can delete tips');
    }

    try {
      await _firestore.collection('admin_tips').doc(tipId).delete();
    } catch (e) {
      throw Exception('Failed to delete admin tip: $e');
    }
  }

  // Get all admin tips
  Stream<List<AdminTipModel>> getAdminTips() {
    return _firestore
        .collection('admin_tips')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AdminTipModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get active admin tips
  Stream<List<AdminTipModel>> getActiveAdminTips() {
    return _firestore
        .collection('admin_tips')
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AdminTipModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Send tip to specific users
  Future<void> sendTipToUsers(AdminTipModel tip, List<String> userIds) async {
    if (!await isCurrentUserAdmin()) {
      throw Exception('Unauthorized: Only admins can send tips');
    }

    try {
      final batch = _firestore.batch();

      for (String userId in userIds) {
        // Add to user's received tips
        final userTipRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('received_tips')
            .doc();

        batch.set(userTipRef, {
          'tipId': tip.id,
          'title': tip.title,
          'description': tip.description,
          'category': tip.category,
          'estimatedSavings': tip.estimatedSavings,
          'difficulty': tip.difficulty,
          'potentialSavingsKwh': tip.potentialSavingsKwh,
          'priority': tip.priority,
          'tags': tip.tags,
          'imageUrl': tip.imageUrl,
          'actionUrl': tip.actionUrl,
          'sentAt': DateTime.now(),
          'isRead': false,
          'sentBy': 'admin',
        });

        // Send push notification
        await _sendPushNotification(userId, tip);
      }

      await batch.commit();

      // Update tip stats
      await _updateTipStats(tip.id, userIds.length);
    } catch (e) {
      throw Exception('Failed to send tip to users: $e');
    }
  }

  // Send tip to user groups based on criteria
  Future<void> sendTipToTargetGroups(AdminTipModel tip) async {
    if (!await isCurrentUserAdmin()) {
      throw Exception('Unauthorized: Only admins can send tips');
    }

    try {
      List<String> targetUserIds = await _getTargetUsers(tip);
      await sendTipToUsers(tip, targetUserIds);
    } catch (e) {
      throw Exception('Failed to send tip to target groups: $e');
    }
  }

  // Get users based on targeting criteria
  Future<List<String>> _getTargetUsers(AdminTipModel tip) async {
    List<String> userIds = [];

    try {
      Query usersQuery = _firestore.collection('users');

      // Apply targeting criteria
      if (tip.targetUserGroups.contains('high_usage')) {
        usersQuery = usersQuery.where('usageCategory', isEqualTo: 'high');
      } else if (tip.targetUserGroups.contains('medium_usage')) {
        usersQuery = usersQuery.where('usageCategory', isEqualTo: 'medium');
      } else if (tip.targetUserGroups.contains('low_usage')) {
        usersQuery = usersQuery.where('usageCategory', isEqualTo: 'low');
      }

      QuerySnapshot snapshot = await usersQuery.get();
      userIds = snapshot.docs.map((doc) => doc.id).toList();

      // Apply additional filtering based on target criteria
      if (tip.targetCriteria.isNotEmpty) {
        userIds = await _filterUsersByCriteria(userIds, tip.targetCriteria);
      }
    } catch (e) {
      print('Error getting target users: $e');
      // Fallback to all users if targeting fails
      QuerySnapshot allUsers = await _firestore.collection('users').get();
      userIds = allUsers.docs.map((doc) => doc.id).toList();
    }

    return userIds;
  }

  // Filter users by additional criteria
  Future<List<String>> _filterUsersByCriteria(
    List<String> userIds,
    Map<String, dynamic> criteria,
  ) async {
    List<String> filteredIds = [];

    for (String userId in userIds) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          bool matches = true;

          // Check monthly usage criteria
          if (criteria.containsKey('monthlyUsageMin')) {
            double userUsage = userData['monthlyUsage']?.toDouble() ?? 0.0;
            if (userUsage < criteria['monthlyUsageMin']) matches = false;
          }

          if (criteria.containsKey('monthlyUsageMax')) {
            double userUsage = userData['monthlyUsage']?.toDouble() ?? 0.0;
            if (userUsage > criteria['monthlyUsageMax']) matches = false;
          }

          // Check appliance criteria
          if (criteria.containsKey('hasAppliances')) {
            List<String> requiredAppliances = List<String>.from(
              criteria['hasAppliances'],
            );
            List<String> userAppliances = List<String>.from(
              userData['appliances'] ?? [],
            );
            bool hasRequired = requiredAppliances.any(
              (appliance) => userAppliances.contains(appliance),
            );
            if (!hasRequired) matches = false;
          }

          if (matches) {
            filteredIds.add(userId);
          }
        }
      } catch (e) {
        print('Error filtering user $userId: $e');
      }
    }

    return filteredIds;
  }

  // Send push notification
  Future<void> _sendPushNotification(String userId, AdminTipModel tip) async {
    try {
      // Get user's FCM token
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String? fcmToken = userData['fcmToken'];

        if (fcmToken != null) {
          // Here you would typically use Firebase Cloud Functions
          // or a server-side implementation to send the notification
          // For now, we'll store the notification request
          await _firestore.collection('notification_queue').add({
            'userId': userId,
            'fcmToken': fcmToken,
            'title': '💡 New Electricity Saving Tip',
            'body': tip.title,
            'data': {
              'tipId': tip.id,
              'type': 'admin_tip',
              'priority': tip.priority,
            },
            'createdAt': DateTime.now(),
            'sent': false,
          });
        }
      }
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // Update tip statistics
  Future<void> _updateTipStats(String tipId, int sentCount) async {
    try {
      await _firestore.collection('admin_tip_stats').doc(tipId).set({
        'tipId': tipId,
        'sentCount': FieldValue.increment(sentCount),
        'lastSentAt': DateTime.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating tip stats: $e');
    }
  }

  // Get tip statistics
  Future<Map<String, dynamic>> getTipStats(String tipId) async {
    try {
      DocumentSnapshot statsDoc = await _firestore
          .collection('admin_tip_stats')
          .doc(tipId)
          .get();

      if (statsDoc.exists) {
        return statsDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error getting tip stats: $e');
    }

    return {'sentCount': 0, 'readCount': 0, 'lastSentAt': null};
  }

  // Schedule tip for later sending
  Future<void> scheduleTip(AdminTipModel tip, DateTime scheduledTime) async {
    if (!await isCurrentUserAdmin()) {
      throw Exception('Unauthorized: Only admins can schedule tips');
    }

    try {
      final updatedTip = tip.copyWith(
        scheduledAt: scheduledTime,
        isScheduled: true,
      );

      if (tip.id.isNotEmpty) {
        await updateAdminTip(updatedTip);
      } else {
        await createAdminTip(updatedTip);
      }
    } catch (e) {
      throw Exception('Failed to schedule tip: $e');
    }
  }

  // Get user engagement stats
  Future<Map<String, dynamic>> getUserEngagementStats() async {
    try {
      // Total users
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();
      int totalUsers = usersSnapshot.docs.length;

      // Active users (received tips in last 30 days)
      DateTime thirtyDaysAgo = DateTime.now().subtract(
        const Duration(days: 30),
      );

      QuerySnapshot recentTipsSnapshot = await _firestore
          .collectionGroup('received_tips')
          .where('sentAt', isGreaterThan: thirtyDaysAgo)
          .get();

      Set<String> activeUserIds = recentTipsSnapshot.docs
          .map((doc) => doc.reference.parent.parent!.id)
          .toSet();

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUserIds.length,
        'engagementRate': totalUsers > 0
            ? (activeUserIds.length / totalUsers * 100)
            : 0,
      };
    } catch (e) {
      print('Error getting user engagement stats: $e');
      return {'totalUsers': 0, 'activeUsers': 0, 'engagementRate': 0};
    }
  }
}
