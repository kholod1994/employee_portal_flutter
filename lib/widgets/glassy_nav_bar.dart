import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  static const Color neonCyan = Color(0xFF2DD4BF);
  static const Color solidBarBg = Color(0xFF0F172A); // Solid Slate 900 (non-glassy)
  static const Color solidBorder = Color(0xFF1E293B);

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
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, animIndex, child) {
                // RTL mapping for visual alignment
                final visualIndex = isRtl ? (count - 1 - animIndex) : animIndex;
                final activeCenter = (visualIndex + 0.5) * tabWidth;

                return SizedBox(
                  height: 74,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Solid Clean Background Container (NO glass / NO blur)
                      Positioned.fill(
                        child: _buildSolidBackground(activeCenter, tabWidth, totalWidth),
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
                      else if (widget.style == NavBarStyle.solidCapsule)
                        Positioned(
                          left: activeCenter - 30,
                          top: 10,
                          child: Container(
                            width: 60,
                            height: 44,
                            decoration: BoxDecoration(
                              color: neonCyan.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: neonCyan.withValues(alpha: 0.5),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: neonCyan.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // 3. V10 Floating Dome / Bubble (المنيو الأخيرة في الفيديو)
                      if (widget.style == NavBarStyle.v10FloatingDome)
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
                                  color: Colors.white,
                                  width: 2.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: neonCyan.withValues(alpha: 0.55),
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
                            final isV10Active = widget.style == NavBarStyle.v10FloatingDome && isSelected;

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
                                      if (isV10Active)
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
                                                ? neonCyan
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.label,
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],

                                      if (isSelected && widget.style != NavBarStyle.v10FloatingDome) ...[
                                        const SizedBox(height: 3),
                                        Container(
                                          width: 4.5,
                                          height: 4.5,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: neonCyan,
                                            boxShadow: [
                                              BoxShadow(
                                                color: neonCyan.withValues(alpha: 0.8),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ] else if (isV10Active) ...[
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

  Widget _buildSolidBackground(double activeCenter, double tabWidth, double totalWidth) {
    if (widget.style == NavBarStyle.v10FloatingDome) {
      return ClipPath(
        clipper: LiquidNotchClipper(
          activeCenter: activeCenter,
          notchWidth: 70,
          notchDepth: 16,
          borderRadius: 34,
        ),
        child: _solidContainerDecoration(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: _solidContainerDecoration(),
    );
  }

  // 100% Solid Container Decoration - NO BackdropFilter, NO Blur, NO Glass
  Widget _solidContainerDecoration() {
    return Container(
      decoration: BoxDecoration(
        color: solidBarBg,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: solidBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Custom painter for Style: Neon Wave Contour
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

/// Custom painter for Style: Spotlight Beam
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

/// Custom clipper for V10 Liquid Notch
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

    path.moveTo(borderRadius, 0);

    if (nStart > borderRadius) {
      path.lineTo(nStart, 0);
    } else {
      path.lineTo(borderRadius, 0);
    }

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

    path.lineTo(size.width - borderRadius, 0);
    path.arcToPoint(
      Offset(size.width, borderRadius),
      radius: Radius.circular(borderRadius),
    );

    path.lineTo(size.width, size.height - borderRadius);
    path.arcToPoint(
      Offset(size.width - borderRadius, size.height),
      radius: Radius.circular(borderRadius),
    );

    path.lineTo(borderRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - borderRadius),
      radius: Radius.circular(borderRadius),
    );

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
