import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

/// Notification Model
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? type; // 'admin', 'calendar', 'system'
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.type,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'type': type,
      'data': data,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      type: json['type'],
      data: json['data'],
    );
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    String? type,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }
}

/// Notification Provider
class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  NotificationProvider(this._apiService) {
    _loadNotifications();
  }

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load from local storage
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications');
      if (notificationsJson != null) {
        final List<dynamic> decoded = jsonDecode(notificationsJson);
        _notifications = decoded.map((item) => AppNotification.fromJson(item)).toList();
      }

      // Fetch from server
      await _fetchNotificationsFromServer();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchNotificationsFromServer() async {
    try {
      final response = await _apiService.getNotifications();
      if (response is Map && response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final List<dynamic> serverNotifications = (data is Map) ? (data['results'] ?? []) : (data is List ? data : []);
        
        // Merge server notifications with local ones
        for (var serverNotif in serverNotifications) {
          final notification = AppNotification(
            id: serverNotif['id']?.toString() ?? '',
            title: serverNotif['title'] ?? '',
            body: serverNotif['message'] ?? serverNotif['body'] ?? '',
            createdAt: DateTime.tryParse(serverNotif['created_at'] ?? '') ?? DateTime.now(),
            isRead: serverNotif['is_read'] ?? false,
            type: serverNotif['type'] ?? 'admin',
            data: serverNotif['data'],
          );

          // Check if notification already exists
          if (!_notifications.any((n) => n.id == notification.id)) {
            _notifications.insert(0, notification);
          }
        }

        // Sort by date (newest first)
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        await _saveNotifications();
      }
    } catch (e) {
      debugPrint('Error fetching notifications from server: $e');
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_notifications.map((n) => n.toJson()).toList());
    await prefs.setString('notifications', encoded);
  }

  Future<void> addNotification(AppNotification notification) async {
    // Check if notification already exists
    if (!_notifications.any((n) => n.id == notification.id)) {
      _notifications.insert(0, notification);
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      
      // Update on server if it's from server
      try {
        await _apiService.markNotificationAsRead(notificationId);
      } catch (e) {
        debugPrint('Error marking notification as read on server: $e');
      }
      
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    await _saveNotifications();
    
    // Update on server
    try {
      await _apiService.markAllNotificationsAsRead();
    } catch (e) {
      debugPrint('Error marking all notifications as read on server: $e');
    }
    
    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    
    // Delete from server
    try {
      await _apiService.deleteNotification(notificationId);
    } catch (e) {
      debugPrint('Error deleting notification from server: $e');
    }
    
    notifyListeners();
  }

  Future<void> deleteAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    await _fetchNotificationsFromServer();
  }
}
