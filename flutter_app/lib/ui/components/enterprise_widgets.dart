import 'package:flutter/material.dart';
import 'dart:ui';

/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// ENTERPRISE UI COMPONENTS
/// Premium healthcare dashboard widgets
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// ─── Theme ─────────────────────────────────────────────
class AppColors {
  static const primary = Color(0xFF1A73E8);
  static const secondary = Color(0xFF6C63FF);
  static const success = Color(0xFF0F9D58);
  static const warning = Color(0xFFF9AB00);
  static const danger = Color(0xFFEA4335);
  static const critical = Color(0xFFD93025);
  static const surface = Color(0xFF1E1E2E);
  static const surfaceLight = Color(0xFF2D2D3F);
  static const textPrimary = Color(0xFFE1E1E6);
  static const textSecondary = Color(0xFF8E8E9A);
  
  static const gradientBlue = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
  );
  static const gradientGreen = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
  );
  static const gradientRed = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFeb3349), Color(0xFFf45c43)],
  );
  static const gradientOrange = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFf7971e), Color(0xFFffd200)],
  );
}

// ─── Glassmorphism Card ────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double opacity;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient ?? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(opacity),
                Colors.white.withOpacity(opacity * 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}

// ─── Metric Card with Animated Counter ─────────────────
class MetricCard extends StatefulWidget {
  final String label;
  final int value;
  final IconData icon;
  final Gradient gradient;
  final String? trend;
  final double? trendValue;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.trend,
    this.trendValue,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _countAnimation = Tween<double>(
      begin: 0, end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              if (widget.trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.trend == 'up'
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.danger.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.trend == 'up' ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: widget.trend == 'up' ? AppColors.success : AppColors.danger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.trendValue?.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.trend == 'up' ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _countAnimation,
            builder: (context, _) {
              return Text(
                _countAnimation.value.toInt().toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Severity Indicator ───────────────────────
class SeverityIndicator extends StatefulWidget {
  final String severity;
  final bool animate;

  const SeverityIndicator({
    super.key,
    required this.severity,
    this.animate = true,
  });

  @override
  State<SeverityIndicator> createState() => _SeverityIndicatorState();
}

class _SeverityIndicatorState extends State<SeverityIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: _getPulseDuration(),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.animate && _shouldPulse()) {
      _pulseController.repeat(reverse: true);
    }
  }

  Duration _getPulseDuration() {
    switch (widget.severity) {
      case 'contraindicated': return const Duration(milliseconds: 600);
      case 'severe': return const Duration(milliseconds: 1000);
      default: return const Duration(milliseconds: 1500);
    }
  }

  bool _shouldPulse() {
    return widget.severity == 'contraindicated' || widget.severity == 'severe';
  }

  Color _getColor() {
    switch (widget.severity) {
      case 'contraindicated': return AppColors.critical;
      case 'severe': return AppColors.danger;
      case 'moderate': return AppColors.warning;
      case 'mild': return AppColors.success;
      default: return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (widget.severity) {
      case 'contraindicated': return Icons.dangerous;
      case 'severe': return Icons.warning_amber;
      case 'moderate': return Icons.info_outline;
      case 'mild': return Icons.check_circle_outline;
      default: return Icons.help_outline;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _shouldPulse() ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4)),
              boxShadow: _shouldPulse()
                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getIcon(), size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  widget.severity.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Skeleton Loader ───────────────────────────────────
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                Color(0xFF2D2D3F),
                Color(0xFF3D3D4F),
                Color(0xFF2D2D3F),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(width: 44, height: 44, borderRadius: BorderRadius.all(Radius.circular(12))),
              SkeletonLoader(width: 60, height: 24, borderRadius: BorderRadius.all(Radius.circular(8))),
            ],
          ),
          SizedBox(height: 16),
          SkeletonLoader(width: 80, height: 32),
          SizedBox(height: 4),
          SkeletonLoader(width: 120, height: 16),
        ],
      ),
    );
  }
}

// ─── Gradient Header ───────────────────────────────────
class GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const GradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800,
                color: Colors.white, letterSpacing: -0.5,
              )),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(
                fontSize: 14, color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w400,
              )),
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
