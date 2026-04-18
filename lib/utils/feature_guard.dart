import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

/// Mixin to handle role-based and subscription-based access control
mixin FeatureGuard {
  bool canAccessFeature(BuildContext context, String feature) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return false;

    // Admin has access to everything
    if (user.isAdmin) return true;

    switch (feature) {
      case 'financial_management':
        return user.isMainLawyer && user.hasProFeatures;
      case 'ai_analysis':
        return user.hasProFeatures;
      case 'lawsuit_creation':
        return user.isMainLawyer || user.isAssistant;
      case 'client_view':
        return user.isClient;
      default:
        return true;
    }
  }

  void showUpgradeRequired(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ترقية الحساب مطلوبة'),
        content: Text('تحتاج إلى الاشتراك في الباقة الاحترافية للوصول إلى ميزة $featureName.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لاحقاً'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Navigate to subscription screen
            },
            child: const Text('عرض الباقات'),
          ),
        ],
      ),
    );
  }

  void showPermissionDenied(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ليس لديك صلاحية للقيام بهذا الإجراء.')),
    );
  }
}
