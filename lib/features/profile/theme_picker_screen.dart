import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme_data.dart';
import '../../shared/providers/theme_provider.dart';

class ThemePickerScreen extends ConsumerWidget {
  const ThemePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Theme'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: PawThemeData.all.length,
        itemBuilder: (context, index) {
          final entry = PawThemeData.all.entries.elementAt(index);
          final isActive = entry.key == currentTheme;
          final t = entry.value;

          return GestureDetector(
            onTap: () {
              ref.read(themeNotifierProvider.notifier).setTheme(entry.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? t.primary : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(
                    t.name,
                    style: TextStyle(
                      fontFamily: 'DMSerifDisplay',
                      fontSize: 18,
                      color: t.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _ColorDot(t.primary),
                      const SizedBox(width: 6),
                      _ColorDot(t.primaryLight),
                      const SizedBox(width: 6),
                      _ColorDot(t.background),
                      if (isActive) ...[
                        const Spacer(),
                        Icon(Icons.check_circle, color: t.primary, size: 20),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;

  const _ColorDot(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
    );
  }
}
