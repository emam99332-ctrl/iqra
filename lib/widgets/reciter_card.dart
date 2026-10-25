import 'package:flutter/material.dart';
import 'package:iqra/services/reciter_downloads.dart';
import 'package:iqra/styles/style.dart';

class ReciterCard extends StatelessWidget {
  final String image;
  final String name;
  final bool selected;
  final VoidCallback onTap;
  final DownloadStatus downloadStatus;
  final double downloadProgress;
  final VoidCallback onDownloadTap;

  const ReciterCard({
    super.key,
    required this.image,
    required this.name,
    required this.selected,
    required this.onTap,
    required this.downloadStatus,
    required this.downloadProgress,
    required this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 160,
        height: 200,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(image, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.5, 0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(textAlign: TextAlign.right,
                name,
                maxLines: 1,
                style: const TextStyle(
                  color: gold,
                  fontSize: 13,
                  fontFamily: 'ar',
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
            ),
            if (selected) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: emerald,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: emerald,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check, color: cream, size: 16),
                ),
              ),
            ],
            Positioned(
              top: 4,
              left: 4,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDownloadTap,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _DownloadBadge(
                    status: downloadStatus,
                    progress: downloadProgress,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadBadge extends StatelessWidget {
  final DownloadStatus status;
  final double progress;
  const _DownloadBadge({required this.status, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: switch (status) {
        DownloadStatus.none =>
        const Icon(Icons.download, color: cream, size: 18),
        DownloadStatus.downloading => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: progress > 0 ? progress
                    : null,
                strokeWidth: 2.5,
                color: emerald,
              ),
            ),
            const Icon(Icons.close, color: gold, size: 12),
          ],
        ),
        DownloadStatus.done =>
        const Icon(Icons.download_done, color: emerald, size: 18),
      },
    );
  }
}