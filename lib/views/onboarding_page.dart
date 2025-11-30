import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  void _finish() {
    final box = GetStorage();
    box.write('seenOnboarding', true);
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F7ED), Color(0xFFE8F5E0), Color(0xFFF5F9F3)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _buildPage(
                      'Selamat Datang di Mood to Matcha',
                      'Catat mood kamu setiap hari dan dapatkan poin',
                      Icons.spa,
                      [Color(0xFF4F7942), Color(0xFF6B8E23)],
                    ),
                    _buildPage(
                      'Matcha Gratis',
                      'Kumpulkan poinmu dan tukarkan dengan segelas matcha',
                      Icons.local_cafe,
                      [Color(0xFF4F7942), Color(0xFF6B8E23)],
                    ),
                    _buildPage(
                      'Minum Sesuai Mood',
                      'Pilih segelas matcha yang sesuai dengan mood kamu hari ini',
                      Icons.favorite,
                      [Color(0xFF4F7942), Color(0xFF6B8E23)],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (i) => AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: _page == i ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: _page == i
                                ? LinearGradient(
                                    colors: [
                                      Color(0xFF4F7942),
                                      Color(0xFF6B8E23),
                                    ],
                                  )
                                : null,
                            color: _page == i ? null : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_page > 0)
                          TextButton(
                            onPressed: () => _controller.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeIn,
                            ),
                            child: Text(
                              'Kembali',
                              style: TextStyle(
                                color: Color(0xFF4F7942),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          SizedBox(width: 80),
                        Expanded(
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF4F7942), Color(0xFF6B8E23)],
                              ),
                              borderRadius: BorderRadius.circular(27),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF4F7942).withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _page == 2
                                  ? _finish
                                  : () => _controller.nextPage(
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeIn,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(27),
                                ),
                              ),
                              child: Text(
                                _page == 2 ? 'Mulai Sekarang' : 'Lanjut',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(
    String title,
    String caption,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 40),
          TweenAnimationBuilder(
            duration: Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.3),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Icon(icon, size: 100, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 48),
          TweenAnimationBuilder(
            duration: Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E2E2E),
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          caption,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7C7C7C),
                            height: 1.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
