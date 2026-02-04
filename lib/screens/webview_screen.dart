import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:url_launcher/url_launcher.dart';

/// WebView Screen - لعرض الروابط داخل التطبيق مع تحسينات للمواقع الحكومية
class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;
  String? _errorMessage;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _startTimeout();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'الموقع يستغرق وقتاً طويلاً للرد. قد يكون هناك ضغط على الخادم أو مشكلة في الاتصال.';
        });
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params);

    // User Agent محسّن لضمان قبول الطلب من الخوادم الحكومية
    const String userAgent = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36";

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100;
                if (progress > 80) _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            developer.log('Loading: $url', name: 'WebView');
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (String url) {
            developer.log('Finished: $url', name: 'WebView');
            _timeoutTimer?.cancel();
            if (mounted) {
              setState(() => _isLoading = false);
            }
            // تحسين ظهور الصفحة
            _controller.runJavaScript("document.body.style.webkitTouchCallout='none';");
          },
          onWebResourceError: (WebResourceError error) {
            developer.log('Error: ${error.errorCode} ${error.description}', name: 'WebView');
            
            // تجاهل أخطاء غير مؤثرة
            if (error.errorCode == -999 || error.errorCode == -1) return;

            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'تعذر تحميل الصفحة (${error.errorCode}).\nالمواقع الحكومية قد تتطلب اتصالاً مباشراً بدون VPN أو بروكسي.';
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // السماح بفتح روابط معينة خارج الـ WebView إذا لزم الأمر
            if (!request.url.startsWith('http')) {
              _openExternally(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // إعدادات إضافية للأندرويد
    if (_controller.platform is AndroidWebViewController) {
      final androidController = _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);

      // السماح بملفات تعريف الارتباط (مهم جداً للمواقع الحكومية التي تتطلب تسجيل دخول)
      final cookieManager = WebViewCookieManager();
      cookieManager.setCookie(
        WebViewCookie(name: 'app_bridge', value: 'true', domain: Uri.parse(widget.url).host),
      );
    }

    _loadUrl();
  }

  void _loadUrl() {
    try {
      _controller.loadRequest(Uri.parse(widget.url));
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'الرابط غير صحيح';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _startTimeout();
              _controller.reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => _openExternally(widget.url),
            tooltip: 'فتح في المتصفح الخارجي',
          ),
        ],
        bottom: _isLoading ? PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _progress > 0 ? _progress : null,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ) : null,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_errorMessage != null) _buildErrorScreen(),
          if (_isLoading && _progress < 0.1) _buildInitialLoading(),
        ],
      ),
    );
  }

  Widget _buildInitialLoading() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF1E3A8A)),
            const SizedBox(height: 20),
            const Text('جاري الاتصال بالبوابة الإلكترونية...', style: TextStyle(fontFamily: 'Cairo')),
            const SizedBox(height: 8),
            Text(widget.url, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 70, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _openExternally(widget.url),
              icon: const Icon(Icons.open_in_browser),
              label: const Text('فتح في متصفح خارجي', style: TextStyle(fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() => _errorMessage = null);
                _loadUrl();
              },
              child: const Text('إعادة المحاولة داخل التطبيق', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternally(String url) async {
    final uri = Uri.parse(url);
    try {
      // استخدام وضع التصفح الخارجي الصريح لضمان أفضل توافقية
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // محاولة ثانية بوضع مختلف إذا فشل الأول
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح المتصفح الخارجي')),
        );
      }
    }
  }
}
