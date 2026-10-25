
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iqra/styles/style.dart';

class SocialFooter extends StatelessWidget {
  const SocialFooter({super.key});

  static Color backgroundColor = gold;
  static Color iconColor = cream;
  static Color accentColor = const Color(0xFF03382B);

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        debugPrint('تعذر فتح الرابط: $url');
      }
    } catch (e) {
      debugPrint('خطأ أثناء فتح الرابط: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(

        children: [
          Align(alignment: Alignment.centerLeft,
              child: Text('Developed By Eng.Emam Mohamed \n',
                textAlign: TextAlign.left,
                style: TextStyle(color: cream,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ar'
                ),
              )
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialIcon(
                iconPath: 'assets/icons/whatsapp.svg',
                label: 'WhatsApp',
                onTap: () => _openLink(
                  'https://wa.me/201119491439',
                ),
              ),
              const SizedBox(width: 24),
              _socialIcon(
                iconPath: 'assets/icons/phone.svg',
                label: 'Phone',
                onTap: () => _openLink(
                  'tel:+201119491439',
                ),
              ),
              const SizedBox(width: 24),
              _socialIcon(
                iconPath: 'assets/icons/linkedin.svg',
                label: 'LinkedIn',
                onTap: () => _openLink(
                  'https://www.linkedin.com/in/emem-mohamed/',
                ),
              ),
            ],
          ),
          Text('\n© 2026 — جميع الحقوق محفوظة',
            textAlign: TextAlign.left,
            style: TextStyle(color: cream,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'ar'
            ),
          )
        ],
      ),
    );
  }

  Widget _socialIcon({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            iconPath,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              iconColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
