import 'package:flutter/material.dart';
import 'package:iqra/pages/homePage.dart';
import 'package:iqra/services/apiService.dart';
import 'package:iqra/services/reciter_downloads.dart';
import 'package:iqra/styles/style.dart';

class Startuppage extends StatefulWidget {
  const Startuppage({super.key});

  @override
  State<Startuppage> createState() => _StartuppageState();
}

class _StartuppageState extends State<Startuppage> {
  String _status = 'جارٍ التحضير...';
  double? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    ReciterDownloads.instance.init();
    _run();
  }

  Future<void> _run() async {
    if (!mounted) return;
    setState(() => _error = null);
    try {
      if (!await ApiService.isQuranDownloaded()) {
        if (!mounted) return;
        setState(() {
          _status = 'جارٍ تحميل المصحف...';
          _progress = null;
        });
        await ApiService.downloadQuran();
      }
      if (!await ApiService.isAzkarDownloaded()) {
        if (!mounted) return;
        setState(() {
          _status = 'جارٍ تحميل الأذكار...';
          _progress = 0;
        });
        await ApiService.downloadAzkar((done, total) {
          if (mounted) setState(() => _progress = done / total);
        });
      }
      _goHome();
    } catch (e) {
      debugPrint('startup error: $e');
      if (!mounted) return;
      setState(() => _error =
      'تعذر التحميل. تأكد من الاتصال بالإنترنت وحاول مرة أخرى.');
    }
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => Homepage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: cream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اِقـــرأ',
                style: TextStyle(fontFamily: 'Kufi', fontSize: 34),
              ),
              const SizedBox(height: 64),
              if (_error == null) ...[
                Text(_status, style: const TextStyle(fontSize: 18, fontFamily: 'ar', color: emerald)),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress, color: emerald,),
                const SizedBox(height: 12),
                const Text(
                  'يتم تجهيز التطبيق',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontFamily: 'ar'),
                ),
              ] else ...[
                Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontFamily: 'ar', color: gold)),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: gold),
                  onPressed: _run,
                  child: const Text('إعادة المحاولة',style: TextStyle(color: emerald, fontWeight: FontWeight.bold, fontFamily: 'ar') ),
                ),
                TextButton(
                  onPressed: _goHome,
                  child: const Text('متابعة بدون تحميل', style: TextStyle(color: gold, fontWeight: FontWeight.bold, fontFamily: 'ar')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}