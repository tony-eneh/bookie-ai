import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bookie_ai/core/constants/app_constants.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/data/services/storage_service.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.record_voice_over_rounded,
    title: 'Your Money, Understood',
    description:
        'Just speak naturally. BookieAI listens, understands, and logs your transactions — no typing, no spreadsheets.',
  ),
  _OnboardingPage(
    icon: Icons.auto_awesome_rounded,
    title: 'Smart Categorization',
    description:
        'AI automatically categorizes every transaction. It learns your habits and gets smarter over time.',
  ),
  _OnboardingPage(
    icon: Icons.flag_rounded,
    title: 'Goals That Matter',
    description:
        'Set financial goals and track your progress effortlessly. BookieAI nudges you when you\'re off track.',
  ),
];

const _incomeStyles = {
  'FIXED_SALARY': 'Fixed Salary',
  'IRREGULAR': 'Irregular Income',
  'BUSINESS': 'Business Owner',
  'MIXED': 'Mixed Sources',
};

const _personalities = {
  'GENTLE': 'Gentle & Supportive',
  'DIRECT': 'Direct & Honest',
  'COACH_LIKE': 'Coach Me Hard',
};

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  String _selectedCurrency = 'USD';
  String _selectedIncomeStyle = 'FIXED_SALARY';
  String _selectedPersonality = 'GENTLE';

  int get _totalPages => _pages.length + 1;
  bool get _isLastPage => _currentPage == _totalPages - 1;

  void _next() {
    if (_isLastPage) {
      _complete();
    } else {
      _pageController.nextPage(
        duration: AppConstants.animationDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    _pageController.animateToPage(
      _totalPages - 1,
      duration: AppConstants.animationDuration,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _complete() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setOnboardingCompleted();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_isLastPage)
                      TextButton(
                        onPressed: _skip,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _totalPages,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    if (index < _pages.length) {
                      return _InfoPage(page: _pages[index]);
                    }
                    return _PreferencesPage(
                      selectedCurrency: _selectedCurrency,
                      selectedIncomeStyle: _selectedIncomeStyle,
                      selectedPersonality: _selectedPersonality,
                      onCurrencyChanged: (v) =>
                          setState(() => _selectedCurrency = v),
                      onIncomeStyleChanged: (v) =>
                          setState(() => _selectedIncomeStyle = v),
                      onPersonalityChanged: (v) =>
                          setState(() => _selectedPersonality = v),
                    );
                  },
                ),
              ),
              _PageIndicator(
                count: _totalPages,
                current: _currentPage,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(_isLastPage ? 'Get Started' : 'Next'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({required this.page});
  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.accentGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(page.icon, size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferencesPage extends StatelessWidget {
  const _PreferencesPage({
    required this.selectedCurrency,
    required this.selectedIncomeStyle,
    required this.selectedPersonality,
    required this.onCurrencyChanged,
    required this.onIncomeStyleChanged,
    required this.onPersonalityChanged,
  });

  final String selectedCurrency;
  final String selectedIncomeStyle;
  final String selectedPersonality;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onIncomeStyleChanged;
  final ValueChanged<String> onPersonalityChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Center(
            child: Text(
              "Let's Get Started",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Personalize your experience',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _SectionLabel('Primary Currency'),
          const SizedBox(height: 8),
          _CurrencySelector(
            selected: selectedCurrency,
            onChanged: onCurrencyChanged,
          ),
          const SizedBox(height: 24),
          _SectionLabel('Income Style'),
          const SizedBox(height: 8),
          ..._incomeStyles.entries.map(
            (e) => _ChoiceTile(
              label: e.value,
              selected: selectedIncomeStyle == e.key,
              onTap: () => onIncomeStyleChanged(e.key),
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel('Financial Personality'),
          const SizedBox(height: 8),
          ..._personalities.entries.map(
            (e) => _ChoiceTile(
              label: e.value,
              selected: selectedPersonality == e.key,
              onTap: () => onPersonalityChanged(e.key),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  const _CurrencySelector({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.supportedCurrencies.map((code) {
        final isSelected = code == selected;
        final symbol = AppConstants.currencySymbols[code] ?? code;
        return GestureDetector(
          onTap: () => onChanged(code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? AppColors.accent : AppColors.surfaceBorder,
              ),
            ),
            child: Text(
              '$symbol $code',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSubtle : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.surfaceBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 20,
                color: selected ? AppColors.accent : AppColors.textTertiary,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color:
                      selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final isActive = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive ? AppColors.accent : AppColors.surfaceLight,
            ),
          );
        }),
      ),
    );
  }
}
