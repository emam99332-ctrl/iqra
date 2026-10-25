import 'package:flutter/material.dart';
import 'package:iqra/services/adhan_service.dart';
import 'package:iqra/styles/style.dart';
import 'dart:math' as math;
import 'dart:async';

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
              const AdhanAnimation(),
              const SizedBox(height: 24),
              AdhanWords(isFajr: name == 'الفجر'),
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

class AdhanAnimation extends StatefulWidget {
  const AdhanAnimation({super.key});

  @override
  State<AdhanAnimation> createState() => _AdhanAnimationState();
}

class _AdhanAnimationState extends State<AdhanAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final wave = math.sin(_c.value * 2 * math.pi);
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(260, 260),
                painter: _RingsPainter(_c.value),
              ),
              Transform.scale(
                scale: 1 + 0.06 * wave,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: emerald.withValues(alpha: 0.35),
                    boxShadow: [
                      BoxShadow(
                        color: gold.withValues(alpha: 0.5),
                        blurRadius: 30 + 15 * wave,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mosque, size: 70, color: gold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double t;
  _RingsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.width / 2;

    // حلقات تتسع وتتلاشى
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = gold.withValues(alpha: (1 - p) * 0.6);
      canvas.drawCircle(center, 60 + (maxR - 60) * p, ring);
    }

    // نجوم صغيرة تدور وتلمع
    for (var i = 0; i < 12; i++) {
      final a = t * 2 * math.pi + i * 2 * math.pi / 12;
      final twinkle = 0.5 + 0.5 * math.sin(t * 4 * math.pi + i);
      final dot = Paint()
        ..color = cream.withValues(alpha: 0.3 + 0.6 * twinkle);
      canvas.drawCircle(
        center + Offset(math.cos(a), math.sin(a)) * (maxR - 8),
        1.5 + 2 * twinkle,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.t != t;
}

class AdhanWords extends StatefulWidget {
  final bool isFajr;
  const AdhanWords({super.key, this.isFajr = false});

  @override
  State<AdhanWords> createState() => _AdhanWordsState();
}

class _AdhanWordsState extends State<AdhanWords> {
  // عدّل المدة حسب طول الأذان الذي تستخدمه
  static const _secondsPerLine = 8;

  late final List<String> _lines = [
    'الله أكبر الله أكبر',
    'الله أكبر الله أكبر',
    'أشهد أن لا إله إلا الله',
    'أشهد أن لا إله إلا الله',
    'أشهد أن محمدًا رسول الله',
    'أشهد أن محمدًا رسول الله',
    'حيَّ على الصلاة',
    'حيَّ على الصلاة',
    'حيَّ على الفلاح',
    'حيَّ على الفلاح',
    if (widget.isFajr) ...[
      'الصلاة خيرٌ من النوم',
      'الصلاة خيرٌ من النوم',
    ],
    'الله أكبر الله أكبر',
    'لا إله إلا الله',
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: _secondsPerLine), (t) {
      if (!mounted) return;
      if (_index >= _lines.length - 1) {
        t.cancel(); // يبقى آخر سطر ظاهراً
        return;
      }
      setState(() => _index++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Text(
            _lines[_index],
            key: ValueKey(_index),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'me',
              fontSize: 32,
              color: cream,
            ),
          ),
        ),
      ),
    );
  }
}