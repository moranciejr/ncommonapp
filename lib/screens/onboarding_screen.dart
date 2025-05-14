// Flutter Onboarding Flow for nCommonApp
// This flow runs only once on first app open

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Welcome to nCommon',
      'description': 'Meet people who enjoy what you enjoy — in real life.',
    },
    {
      'title': 'Check-In Nearby',
      'description': 'Let others know where you are and what you're in the mood for.',
    },
    {
      'title': 'Start a Hangout',
      'description': 'Plan activities like bowling, golfing, or just chilling.',
    },
    {
      'title': 'Message & Connect',
      'description': 'Chat safely and build friendships — after meeting in person.',
    },
    {
      'title': 'Privacy Built In',
      'description': 'Appear offline, hide your distance, and manage your mood.',
    },
    {
      'title': 'Let's Get Started',
      'description': 'Create your profile and discover your community.',
    },
  ];

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: onboardingData.length,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                onboardingData[index]['title']!,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                onboardingData[index]['description']!,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              if (index == onboardingData.length - 1)
                ElevatedButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Get Started'),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _currentPage < onboardingData.length - 1
          ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text('Skip'),
                  ),
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    ),
                    child: const Text('Next'),
                  ),
                ],
              ),
            )
          : null,
    );
  }
} 