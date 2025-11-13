import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AnimoFooter extends StatelessWidget {
  const AnimoFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.grey[800];
    final iconBg = isDark ? Colors.blue.withOpacity(0.1) : Colors.blue[50];
    final iconColor = Colors.blueAccent;

    return Container(
      color: isDark ? const Color(0xFF0C1625) : Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian Atas: Logo + Links
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo & Deskripsi
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Animo',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tempat terbaik untuk menonton anime favoritmu. '
                      'Nikmati ribuan judul dari klasik hingga terbaru, semua dalam satu platform.',
                      style: TextStyle(
                        color: textColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Links
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Links',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 10),
                    ...[
                      'Tentang Kami',
                      'Ketentuan Layanan',
                      'Kebijakan Privasi',
                      'Kontak',
                      'Pusat Bantuan'
                    ].map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Text(
                              item,
                              style: TextStyle(
                                color: textColor,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),

              // Connect With Us
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Terhubung dengan Kami',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _buildIcon(FontAwesomeIcons.twitter, iconColor, iconBg),
                        const SizedBox(width: 15),
                        _buildIcon(FontAwesomeIcons.discord, iconColor, iconBg),
                        const SizedBox(width: 15),
                        _buildIcon(FontAwesomeIcons.instagram, iconColor, iconBg),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
          Divider(color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 20),

          // Copyright
          Center(
            child: Text(
              'Copyright © 2025 Animo. All rights reserved.',
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Widget icon sosial media
  static Widget _buildIcon(IconData icon, Color iconColor, Color? bg) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50)),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}
