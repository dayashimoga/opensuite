import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';

/// An animated module card with staggered entrance animation,
/// hover elevation effects, and a gradient accent stripe.
class AnimatedModuleCard extends StatefulWidget {
  /// Creates an [AnimatedModuleCard].
  const AnimatedModuleCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.staggerIndex,
    this.onTap,
  });

  /// Module title.
  final String title;

  /// Module description.
  final String description;

  /// Module icon.
  final IconData icon;

  /// Module accent color.
  final Color color;

  /// Index for staggered animation delay.
  final int staggerIndex;

  /// Tap callback for navigation.
  final VoidCallback? onTap;

  @override
  State<AnimatedModuleCard> createState() => _AnimatedModuleCardState();
}

class _AnimatedModuleCardState extends State<AnimatedModuleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Staggered start
    Future.delayed(Duration(milliseconds: 80 * widget.staggerIndex), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: widget.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
            transformAlignment: Alignment.center,
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: _isHovered ? 4 : 0,
              shadowColor: widget.color.withValues(alpha: 0.3),
              child: InkWell(
                onTap: widget.onTap,
                splashColor: widget.color.withValues(alpha: 0.1),
                highlightColor: widget.color.withValues(alpha: 0.05),
                child: Stack(
                  children: [
                    // Gradient accent stripe on the left
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              widget.color,
                              widget.color.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Card content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: _isHovered
                                      ? widget.color.withValues(alpha: 0.18)
                                      : widget.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: widget.color,
                                  size: 24,
                                ),
                              ),
                              const Spacer(),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: _isHovered ? 1.0 : 0.0,
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.darkOnSurfaceVariant
                                      : AppColors.lightOnSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            widget.title,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Expanded(
                            child: Text(
                              widget.description,
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
