import 'package:flutter/material.dart';

class AttendInnIntro extends StatefulWidget {
  final VoidCallback onFinished;
  const AttendInnIntro({super.key, required this.onFinished});

  @override
  State<AttendInnIntro> createState() => _AttendInnIntroState();
}

class _AttendInnIntroState extends State<AttendInnIntro> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _introData = [
    {
      "title": "IT'S TIME TO SAY",
      "subtitle": "Present Sir !!",
      "image": "assets/intro1.png",
    },
    {
      "title": "IT'S TIME TO",
      "subtitle": "See your Attendance",
      "image": "assets/intro2.png",
    },
    {
      "title": "IT'S TIME TO",
      "subtitle": "Be Smarter",
      "image": "assets/intro3.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _introData.length,
            itemBuilder: (context, index) {
              return IntroContent(
                title: _introData[index]['title']!,
                subtitle: _introData[index]['subtitle']!,
                image: _introData[index]['image']!,
                isLastPage: index == _introData.length - 1,
                imageHeightFactor: 0.68,
                fit: BoxFit.fitWidth,
                onLoginPressed: widget.onFinished, // Use the callback to go to Login
              );
            },
          ),

          // Navigation Arrows and Indicators
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _currentPage > 0
                    ? CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 25,
                  child: IconButton(
                    padding: const EdgeInsets.only(left: 8),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.indigo),
                    onPressed: () {
                      _controller.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    },
                  ),
                )
                    : const SizedBox(width: 48),

                Row(
                  children: List.generate(
                    _introData.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 5),
                      height: 10,
                      width: _currentPage == index ? 20 : 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.indigo : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),

                _currentPage < _introData.length - 1
                    ? CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 25,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.indigo),
                    onPressed: () {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    },
                  ),
                )
                    : const SizedBox(width: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IntroContent extends StatelessWidget {
  final String title, subtitle, image;
  final bool isLastPage;
  final double imageHeightFactor;
  final BoxFit fit;
  final VoidCallback onLoginPressed;

  const IntroContent({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.isLastPage,
    required this.onLoginPressed,
    this.imageHeightFactor = 0.65,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 65),
        Image.asset('assets/logo.png', height: 55),
        const SizedBox(height: 20),
        const Text(
          "WELCOME",
          style: TextStyle(fontSize: 16, color: Colors.brown, letterSpacing: 2),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            fontFamily: 'Impact',
          ),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            color: Color(0xFF8DBB5E),
            fontFamily: 'Cursive',
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          "but In A Smarter Way",
          style: TextStyle(fontSize: 22, color: Colors.brown, fontFamily: 'Serif'),
        ),
        const Spacer(),
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * (imageHeightFactor - 0.1),
              width: double.infinity,
              margin: const EdgeInsets.only(left: 40),
              decoration: const BoxDecoration(
                color: Color(0xFFD1C4E9),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(100)),
              ),
            ),
            Image.asset(
              image,
              fit: fit,
              alignment: Alignment.bottomCenter,
              width: fit == BoxFit.fitWidth ? double.infinity : null,
              height: MediaQuery.of(context).size.height * imageHeightFactor,
            ),

            if (isLastPage)
              Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: ElevatedButton(
                  onPressed: onLoginPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    foregroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("LOG IN", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
