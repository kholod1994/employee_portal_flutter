import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/nav_bar_style.dart';
import '../providers/portal_provider.dart';

class NavBarStyleSelectorCard extends StatelessWidget {
  const NavBarStyleSelectorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final currentStyle = context.watch<PortalProvider>().navBarStyle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2DD4BF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.dock_rounded,
                  color: Color(0xFF0D4C6A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'شريط التنقل السفلي (Navigation Tabs)',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    Text(
                      'تصاميم صلبة عصرية وعالية التباين (بدون زجاج)',
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Style Options List
          Column(
            children: NavBarStyle.values.map((style) {
              final isSelected = style == currentStyle;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StyleOptionTile(
                  style: style,
                  isSelected: isSelected,
                  onSelect: () {
                    context.read<PortalProvider>().setNavBarStyle(style);
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StyleOptionTile extends StatelessWidget {
  final NavBarStyle style;
  final bool isSelected;
  final VoidCallback onSelect;

  const _StyleOptionTile({
    required this.style,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF2DD4BF);
    final borderColor = isSelected ? neonCyan : Colors.grey.shade200;
    final bgColor = isSelected
        ? const Color(0xFF0D4C6A).withValues(alpha: 0.04)
        : Colors.grey.shade50;

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: neonCyan.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Style visual icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF0D4C6A)
                    : Colors.grey.shade200,
              ),
              child: Icon(
                _getStyleIcon(style),
                color: isSelected ? neonCyan : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          style.titleAr,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                            color: isSelected ? const Color(0xFF0D4C6A) : AppTheme.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: neonCyan.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: neonCyan.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'مفعل',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0D4C6A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    style.descriptionAr,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppTheme.muted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Radio Indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0D4C6A) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2DD4BF),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStyleIcon(NavBarStyle s) {
    switch (s) {
      case NavBarStyle.v10FloatingDome:
        return Icons.bubble_chart_rounded;
      case NavBarStyle.neonWave:
        return Icons.waves_rounded;
      case NavBarStyle.spotlightBeam:
        return Icons.highlight_rounded;
      case NavBarStyle.solidCapsule:
        return Icons.dock_rounded;
    }
  }
}
