import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_theme.dart';
import '../models/nav_bar_style.dart';

class NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class GlassyNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final NavBarStyle style;
  final List<NavItemData> items;

  const GlassyNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.style,
    required this.items,
  });

  static double globalNavIndex = 0.0;

  @override
  State<GlassyNavBar> createState() => _GlassyNavBarState();
}

class _GlassyNavBarState extends State<GlassyNavBar> {
  // App brand colors matching the video & corporate identity
  static const Color neonCyan = Color(0xFF2DD4BF);

  double _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastIndex = GlassyNavBar.globalNavIndex;
    GlassyNavBar.globalNavIndex = widget.selectedIndex.toDouble();
  }

  @override
  void didUpdateWidget(covariant GlassyNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _lastIndex = oldWidget.selectedIndex.toDouble();
      GlassyNavBar.globalNavIndex = widget.selectedIndex.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final count = widget.items.length;
            final tabWidth = totalWidth / count;
            final isRtl = Directionality.of(context) == TextDirection.rtl;

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: _lastIndex,
                end: widget.selectedIndex.toDouble(),
              ),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              builder: (context, animIndex, child) {
                // In RTL, Row child 0 is on the far right, and child (count - 1) is on the far left.
                // We map animIndex to visual coordinate space so the glow/bubble aligns precisely with the active tab.
                final visualIndex = isRtl ? (count - 1 - animIndex) : animIndex;
                final activeCenter = (visualIndex + 0.5) * tabWidth;

                return SizedBox(
                  height: 74,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Background Frosted Glass Container
                      Positioned.fill(
                        child: _buildGlassBackground(activeCenter, tabWidth, totalWidth),
                      ),

                      // 2. Style-Specific Active Visual Overlay
                      if (widget.style == NavBarStyle.neonWave)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: NeonWaveContourPainter(
                                activeCenter: activeCenter,
                                waveWidth: tabWidth * 0.82,
                                waveHeight: 10.0,
                                neonColor: neonCyan,
                              ),
                            ),
                          ),
                        )
                      else if (widget.style == NavBarStyle.spotlightBeam)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: SpotlightBeamPainter(
                                activeCenter: activeCenter,
                                lightWidth: 42.0,
                                beamBottomWidth: tabWidth * 0.95,
                                neonColor: neonCyan,
                              ),
                            ),
                          ),
                        )
                      else if (widget.style == NavBarStyle.minimalGlassy)
                        Positioned(
                          left: activeCenter - 30,
                          top: 10,
                          child: Container(
                            width: 60,
                            height: 44,
                            decoration: BoxDecoration(
                              color: neonCyan.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: neonCyan.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: neonCyan.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // 3. Floating Bubble for Style 3
                      if (widget.style == NavBarStyle.floatingBubble)
                        Positioned(
                          left: activeCenter - 27,
                          top: -16,
                          child: GestureDetector(
                            onTap: () => widget.onDestinationSelected(widget.selectedIndex),
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF0E5C82),
                                    Color(0xFF2DD4BF),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: neonCyan.withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  widget.items[widget.selectedIndex].selectedIcon,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // 4. Interactive Tabs Row
                      Positioned.fill(
                        child: Row(
                          children: List.generate(count, (index) {
                            final item = widget.items[index];
                            final isSelected = index == widget.selectedIndex;
                            final isBubbleActive = widget.style == NavBarStyle.floatingBubble && isSelected;

                            return Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(32),
                                  splashColor: neonCyan.withValues(alpha: 0.15),
                                  highlightColor: Colors.transparent,
                                  onTap: () => widget.onDestinationSelected(index),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // If bubble active in Style 3, keep spacer for elevated bubble
                                      if (isBubbleActive)
                                        const SizedBox(height: 28)
                                      else ...[
                                        AnimatedScale(
                                          scale: isSelected ? 1.14 : 1.0,
                                          duration: const Duration(milliseconds: 250),
                                          curve: Curves.easeOutBack,
                                          child: Icon(
                                            isSelected ? item.selectedIcon : item.icon,
                                            size: 24,
                                            color: isSelected
                                                ? (widget.style == NavBarStyle.minimalGlassy ? AppTheme.primary : neonCyan)
                                                : Colors.white.withValues(alpha: 0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.label,
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            color: isSelected
                                                ? (widget.style == NavBarStyle.minimalGlassy ? AppTheme.primary : Colors.white)
                                                : Colors.white.withValues(alpha: 0.55),
                                          ),
                                        ),
                                      ],

                                      // Indicator Neon Dot under active item (Styles 1, 2, 4)
                                      if (isSelected && widget.style != NavBarStyle.floatingBubble) ...[
                                        const SizedBox(height: 3),
                                        Container(
                                          width: 4.5,
                                          height: 4.5,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: widget.style == NavBarStyle.minimalGlassy ? AppTheme.primary : neonCyan,
                                            boxShadow: [
                                              BoxShadow(
                                                color: (widget.style == NavBarStyle.minimalGlassy ? AppTheme.primary : neonCyan)
                                                    .withValues(alpha: 0.8),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ] else if (isBubbleActive) ...[
                                        Text(
                                          item.label,
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: neonCyan,
                                          ),
                                        ),
                                      ] else
                                        const SizedBox(height: 7.5),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassBackground(double activeCenter, double tabWidth, double totalWidth) {
    if (widget.style == NavBarStyle.floatingBubble) {
      return ClipPath(
        clipper: LiquidNotchClipper(
          activeCenter: activeCenter,
          notchWidth: 70,
          notchDepth: 18,
          borderRadius: 34,
        ),
        child: _glassContainerDecoration(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: _glassContainerDecoration(),
    );
  }

  Widget _glassContainerDecoration() {
    final isMinimal = widget.style == NavBarStyle.minimalGlassy;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isMinimal
                ? [
                    const Color(0xFFF1F5F9).withValues(alpha: 0.88),
                    const Color(0xFFE2E8F0).withValues(alpha: 0.82),
                  ]
                : [
                    const Color(0xFF0B1E2B).withValues(alpha: 0.86),
                    const Color(0xFF07141E).withValues(alpha: 0.92),
                  ],
          ),
          border: Border.all(
            color: isMinimal
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryDark.withValues(alpha: isMinimal ? 0.12 : 0.4),
              blurRadius: 28,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for Style 1: Neon Wave Contour
class NeonWaveContourPainter extends CustomPainter {
  final double activeCenter;
  final double waveWidth;
  final double waveHeight;
  final Color neonColor;

  NeonWaveContourPainter({
    required this.activeCenter,
    required this.waveWidth,
    required this.waveHeight,
    required this.neonColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final half = waveWidth / 2;
    final startX = activeCenter - half;
    final endX = activeCenter + half;

    // Glowing Neon Stroke
    final glowPaint = Paint()
      ..color = neonColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final accentPaint = Paint()
      ..color = neonColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    path.moveTo(0, 0);
    if (startX > 0) {
      path.lineTo(startX, 0);
    } else {
      path.moveTo(0, 0);
    }

    // Smooth wave arch peaking over active tab
    path.cubicTo(
      activeCenter - half * 0.45,
      0,
      activeCenter - half * 0.45,
      -waveHeight,
      activeCenter,
      -waveHeight,
    );
    path.cubicTo(
      activeCenter + half * 0.45,
      -waveHeight,
      activeCenter + half * 0.45,
      0,
      endX,
      0,
    );

    if (endX < size.width) {
      path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, accentPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant NeonWaveContourPainter oldDelegate) {
    return oldDelegate.activeCenter != activeCenter ||
        oldDelegate.waveWidth != waveWidth ||
        oldDelegate.neonColor != neonColor;
  }
}

/// Custom painter for Style 2: Spotlight Beam
class SpotlightBeamPainter extends CustomPainter {
  final double activeCenter;
  final double lightWidth;
  final double beamBottomWidth;
  final Color neonColor;

  SpotlightBeamPainter({
    required this.activeCenter,
    required this.lightWidth,
    required this.beamBottomWidth,
    required this.neonColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final topHalf = lightWidth / 2;
    final bottomHalf = beamBottomWidth / 2;

    // 1. Trapezoid Light Beam Path
    final beamPath = Path();
    beamPath.moveTo(activeCenter - topHalf, 0);
    beamPath.lineTo(activeCenter + topHalf, 0);
    beamPath.lineTo(activeCenter + bottomHalf, size.height);
    beamPath.lineTo(activeCenter - bottomHalf, size.height);
    beamPath.close();

    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          neonColor.withValues(alpha: 0.55),
          neonColor.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(beamPath, beamPaint);

    // 2. Overhead Bright Lamp Bar on Top Border
    final lampRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(activeCenter, 1.5),
        width: lightWidth,
        height: 3.5,
      ),
      const Radius.circular(2.0),
    );

    final lampGlow = Paint()
      ..color = neonColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    final lampCore = Paint()..color = Colors.white;

    canvas.drawRRect(lampRect, lampGlow);
    canvas.drawRRect(lampRect, lampCore);
  }

  @override
  bool shouldRepaint(covariant SpotlightBeamPainter oldDelegate) {
    return oldDelegate.activeCenter != activeCenter ||
        oldDelegate.lightWidth != lightWidth ||
        oldDelegate.neonColor != neonColor;
  }
}

/// Custom clipper for Style 3: Liquid Notch
class LiquidNotchClipper extends CustomClipper<Path> {
  final double activeCenter;
  final double notchWidth;
  final double notchDepth;
  final double borderRadius;

  LiquidNotchClipper({
    required this.activeCenter,
    required this.notchWidth,
    required this.notchDepth,
    required this.borderRadius,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final half = notchWidth / 2;
    final nStart = activeCenter - half;
    final nEnd = activeCenter + half;

    // Rounded Outer Boundary
    path.moveTo(borderRadius, 0);

    // Leading segment before notch
    if (nStart > borderRadius) {
      path.lineTo(nStart, 0);
    } else {
      path.lineTo(borderRadius, 0);
    }

    // Smooth concave liquid valley
    path.cubicTo(
      activeCenter - half * 0.5,
      0,
      activeCenter - half * 0.5,
      notchDepth,
      activeCenter,
      notchDepth,
    );
    path.cubicTo(
      activeCenter + half * 0.5,
      notchDepth,
      activeCenter + half * 0.5,
      0,
      nEnd,
      0,
    );

    // Top right edge
    path.lineTo(size.width - borderRadius, 0);
    path.arcToPoint(
      Offset(size.width, borderRadius),
      radius: Radius.circular(borderRadius),
    );

    // Bottom right
    path.lineTo(size.width, size.height - borderRadius);
    path.arcToPoint(
      Offset(size.width - borderRadius, size.height),
      radius: Radius.circular(borderRadius),
    );

    // Bottom left
    path.lineTo(borderRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - borderRadius),
      radius: Radius.circular(borderRadius),
    );

    // Top left
    path.lineTo(0, borderRadius);
    path.arcToPoint(
      Offset(borderRadius, 0),
      radius: Radius.circular(borderRadius),
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant LiquidNotchClipper oldClipper) {
    return oldClipper.activeCenter != activeCenter ||
        oldClipper.notchWidth != notchWidth ||
        oldClipper.notchDepth != notchDepth;
  }
}

