import 'package:flutter/material.dart';

/// Layer data model for image editor.
class ImageLayerItem {
  final String id;
  final String name;

  /// 'raster', 'text', 'shape', 'drawing'
  final String type;
  bool visible;
  double opacity;

  /// 'normal', 'multiply', 'screen', 'overlay'
  String blendMode;
  bool locked;

  ImageLayerItem({
    required this.id,
    required this.name,
    this.type = 'raster',
    this.visible = true,
    this.opacity = 1.0,
    this.blendMode = 'normal',
    this.locked = false,
  });
}

/// Sidebar panel for managing image layers.
class LayerPanel extends StatelessWidget {
  final List<ImageLayerItem> layers;
  final String? selectedLayerId;
  final ValueChanged<String>? onSelect;
  final ValueChanged<String>? onToggleVisibility;
  final Function(String id, double opacity)? onOpacityChanged;
  final ValueChanged<String>? onDelete;
  final Function(int oldIndex, int newIndex)? onReorder;
  final VoidCallback? onAddLayer;
  final VoidCallback? onMergeLayers;

  const LayerPanel({
    super.key,
    required this.layers,
    this.selectedLayerId,
    this.onSelect,
    this.onToggleVisibility,
    this.onOpacityChanged,
    this.onDelete,
    this.onReorder,
    this.onAddLayer,
    this.onMergeLayers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.layers, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Layers', style: theme.textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.merge, size: 18),
                  tooltip: 'Merge Visible',
                  onPressed: onMergeLayers,
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Add Layer',
                  onPressed: onAddLayer,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: layers.isEmpty
                ? const Center(child: Text('No layers'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: layers.length,
                    onReorder: (o, n) => onReorder?.call(o, n),
                    itemBuilder: (ctx, idx) {
                      final layer = layers[idx];
                      final selected = selectedLayerId == layer.id;
                      return Card(
                        key: ValueKey(layer.id),
                        color: selected
                            ? theme.colorScheme.primaryContainer
                            : null,
                        margin: const EdgeInsets.only(bottom: 4),
                        child: InkWell(
                          onTap: () => onSelect?.call(layer.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        layer.visible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        size: 16,
                                      ),
                                      onPressed: () =>
                                          onToggleVisibility?.call(layer.id),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                          minWidth: 28, minHeight: 28),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _typeIcon(layer.type),
                                      size: 14,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        layer.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: selected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (layer.locked)
                                      const Icon(Icons.lock, size: 14),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 16),
                                      onPressed: () => onDelete?.call(layer.id),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                          minWidth: 28, minHeight: 28),
                                    ),
                                  ],
                                ),
                                if (selected)
                                  Row(
                                    children: [
                                      const Text('Opacity',
                                          style: TextStyle(fontSize: 10)),
                                      Expanded(
                                        child: Slider(
                                          value: layer.opacity,
                                          min: 0,
                                          max: 1,
                                          onChanged: (v) => onOpacityChanged
                                              ?.call(layer.id, v),
                                        ),
                                      ),
                                      Text(
                                        '${(layer.opacity * 100).round()}%',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'text' => Icons.text_fields,
      'shape' => Icons.square_outlined,
      'drawing' => Icons.brush,
      _ => Icons.image,
    };
  }
}
