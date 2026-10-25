
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:iqra/services/radio_service.dart';
import 'package:iqra/styles/style.dart';

class Radiopage extends StatelessWidget {
  const Radiopage({super.key});

  Future<void> _onToggle(BuildContext context) async {
    final error = await RadioService.instance.toggle();

    if (error == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radio = RadioService.instance;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(
          'إذاعة القرآن الكريم',
          style: titleStyle(),
        ),
        foregroundColor: emerald,
        backgroundColor: cream,
        centerTitle: true,
      ),
      body: Center(
        child: ListenableBuilder(
          listenable: radio,
          builder: (context, _) {
            final loading = radio.isLoading;
            final playing = radio.isPlaying;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.radio,
                  size: 80,
                  color: emerald,
                ),
                const SizedBox(height: 16),
                const Text(
                  'إذاعة القرآن الكريم من القاهرة',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ar',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                RadioVisualizer(isPlaying: playing),

                const SizedBox(height: 28),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (loading)
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: CircularProgressIndicator(
                          color: emerald,
                        ),
                      ),
                    IconButton.filled(
                      iconSize: 48,
                      style: IconButton.styleFrom(
                        backgroundColor: emerald,
                        foregroundColor: cream,
                      ),
                      icon: Icon(
                        playing || loading
                            ? Icons.stop
                            : Icons.play_arrow,
                      ),
                      onPressed: radio.isStarting
                          ? null
                          : () => _onToggle(context),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class RadioVisualizer extends StatefulWidget {
  final bool isPlaying;

  const RadioVisualizer({
    super.key,
    required this.isPlaying,
  });

  @override
  State<RadioVisualizer> createState() => _RadioVisualizerState();
}

class _RadioVisualizerState extends State<RadioVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RadioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate( thirtyBars, (index) {
              final phase = index * 0.48;

              final wave = math.sin(
                _controller.value * 2 * math.pi + phase,
              );

              final height = widget.isPlaying
                  ? 8.0 + (wave + 1) * 25.0
                  : 5.0;

              return Container(
                width: 4,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: emerald,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

const int thirtyBars = 30;
