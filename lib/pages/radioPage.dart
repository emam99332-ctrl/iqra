import 'dart:math' as math;
import 'dart:ui';
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

  Future<void> _onSelect(BuildContext context, int i) async {
    final error = await RadioService.instance.selectChannel(i);
    if (error == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final radio = RadioService.instance;

    return ListenableBuilder(
      listenable: radio,
      builder: (context, _) {
        final selectedChannelIndex = radio.selected;
        final loading = radio.isLoading;
        final playing = radio.isPlaying;

        return Scaffold(
          backgroundColor: cream,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              'إذاعة القرآن الكريم',
              style: titleStyle(),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.maybePop(context),
            ),
            elevation: 0,
            foregroundColor: emerald,
            backgroundColor: Colors.transparent,
            centerTitle: true,
          ),
          body: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: ImageFiltered(
                  key: ValueKey<int>(selectedChannelIndex),
                  imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1), // درجة الضبابية
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/radio/$selectedChannelIndex.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          cream.withValues(alpha: 0.75), // طبقة لتقليل حدة ألوان الصورة
                          BlendMode.srcOver,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ChannelPager(onChanged: (i) => _onSelect(context, i)),
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
                              playing || loading ? Icons.stop : Icons.play_arrow,
                            ),
                            onPressed: radio.isStarting
                                ? null
                                : () => _onToggle(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

class _ChannelPager extends StatefulWidget {
  final void Function(int) onChanged;
  const _ChannelPager({required this.onChanged});

  @override
  State<_ChannelPager> createState() => _ChannelPagerState();
}

class _ChannelPagerState extends State<_ChannelPager> {
  final radio = RadioService.instance;
  late final PageController _c = PageController(initialPage: radio.selected);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 230,
          child: PageView.builder(
            controller: _c,
            itemCount: RadioService.channels.length,
            onPageChanged: widget.onChanged,
            itemBuilder: (context, i) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                    'assets/radio/$i.jpg',
                    fit: BoxFit.fill,
                    height: 180,
                    width: 180,)
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    RadioService.channels[i].title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ar'),
                  ),
                ),
              ],
            ),
          ),
        ),
        ListenableBuilder(
          listenable: radio,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < RadioService.channels.length; i++)
                Container(
                  width: i == radio.selected ? 18 : 8,
                  height: 8,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: i == radio.selected ? emerald : gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}