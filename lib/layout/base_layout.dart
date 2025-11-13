import 'package:flutter/material.dart';
import '../widgets/footer.dart'; // pastikan path footer.dart benar

class BaseLayout extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const BaseLayout({
    super.key,
    required this.child,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SingleChildScrollView(
        child: Column(
          children: [
            child,              // isi halaman dinamis
            const AnimoFooter(),     // footer kamu
          ],
        ),
      ),
    );
  }
}
