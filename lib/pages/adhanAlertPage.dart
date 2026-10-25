import 'package:flutter/material.dart';
import 'package:iqra/services/adhan_service.dart';
import 'package:iqra/styles/style.dart';

class AdhanAlertpage extends StatelessWidget {
  const AdhanAlertpage({super.key});

  @override
  Widget build(BuildContext context) {
    final payload = (ModalRoute.of(context)?.settings.arguments as String?) ??
        AdhanService.instance.launchPayload ??
        '';
    final parts = payload.split('|');
    final name = parts.first;
    final id = parts.length > 1 ? int.tryParse(parts.last) : null;

    return Scaffold(
      backgroundColor: emerald,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bckg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mosque, size: 90, color: gold),
              const SizedBox(height: 24),
              const Text('الله أكبر الله أكبر',
                  style: TextStyle(
                      fontFamily: 'me', fontSize: 32, color: cream)),
              const SizedBox(height: 16),
              Text(name.isEmpty ? 'حان وقت الصلاة' : 'حان وقت صلاة $name',
                  style: const TextStyle(
                      fontFamily: 'ar',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: gold)),
              const SizedBox(height: 48),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: gold),
                icon: const Icon(Icons.stop, color: emerald),
                label: const Text('إيقاف الأذان',
                    style: TextStyle(
                        fontFamily: 'ar',
                        fontWeight: FontWeight.bold,
                        color: emerald)),
                onPressed: () async {
                  if (id != null) await AdhanService.instance.stop(id);
                  if (!context.mounted) return;
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  if (id != null) await AdhanService.instance.stop(id);
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (_) => false);
                  }
                },
                child: const Text('الرئيسية',
                    style: TextStyle(fontFamily: 'ar', color: cream)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}