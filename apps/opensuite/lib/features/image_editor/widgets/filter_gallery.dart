import 'package:flutter/material.dart';

/// Preset filter definition.
class ImageFilter {
  final String id;
  final String name;
  final IconData icon;
  final String description;

  const ImageFilter({
    required this.id,
    required this.name,
    required this.icon,
    this.description = '',
  });
}

/// Grid gallery for selecting image filters.
class FilterGallery extends StatelessWidget {
  final String? selectedFilterId;
  final ValueChanged<String>? onFilterSelected;

  const FilterGallery({
    super.key,
    this.selectedFilterId,
    this.onFilterSelected,
  });

  static const filters = [
    ImageFilter(id: 'none', name: 'Original', icon: Icons.image),
    ImageFilter(id: 'grayscale', name: 'Grayscale', icon: Icons.filter_b_and_w),
    ImageFilter(id: 'sepia', name: 'Sepia', icon: Icons.filter_vintage),
    ImageFilter(id: 'invert', name: 'Invert', icon: Icons.invert_colors),
    ImageFilter(id: 'blur', name: 'Blur', icon: Icons.blur_on),
    ImageFilter(id: 'sharpen', name: 'Sharpen', icon: Icons.deblur),
    ImageFilter(id: 'emboss', name: 'Emboss', icon: Icons.landscape),
    ImageFilter(id: 'edge', name: 'Edge Detect', icon: Icons.border_style),
    ImageFilter(id: 'vignette', name: 'Vignette', icon: Icons.vignette),
    ImageFilter(id: 'posterize', name: 'Posterize', icon: Icons.palette),
    ImageFilter(id: 'solarize', name: 'Solarize', icon: Icons.wb_sunny),
    ImageFilter(id: 'pixelate', name: 'Pixelate', icon: Icons.grid_on),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final filter = filters[idx];
                final selected = selectedFilterId == filter.id;
                return GestureDetector(
                  onTap: () => onFilterSelected?.call(filter.id),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.dividerColor,
                            width: selected ? 2 : 1,
                          ),
                          color: selected
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: Icon(filter.icon,
                            size: 24,
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        filter.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
