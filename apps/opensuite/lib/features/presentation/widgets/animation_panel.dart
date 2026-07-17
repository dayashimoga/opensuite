import 'package:fileutility_core/fileutility_core.dart';
import 'package:flutter/material.dart';

/// Panel for managing slide element animations.
class AnimationPanel extends StatelessWidget {
  final List<SlideAnimation> animations;
  final List<SlideElement> elements;
  final String? selectedElementId;
  final ValueChanged<SlideAnimation>? onAdd;
  final ValueChanged<String>? onRemove;
  final Function(String id, SlideAnimation updated)? onUpdate;
  final Function(int oldIndex, int newIndex)? onReorder;

  const AnimationPanel({
    super.key,
    required this.animations,
    required this.elements,
    this.selectedElementId,
    this.onAdd,
    this.onRemove,
    this.onUpdate,
    this.onReorder,
  });

  static const _animationTypes = [
    ('fadeIn', 'Fade In', Icons.visibility),
    ('fadeOut', 'Fade Out', Icons.visibility_off),
    ('slideLeft', 'Slide Left', Icons.arrow_back),
    ('slideRight', 'Slide Right', Icons.arrow_forward),
    ('slideUp', 'Slide Up', Icons.arrow_upward),
    ('slideDown', 'Slide Down', Icons.arrow_downward),
    ('zoomIn', 'Zoom In', Icons.zoom_in),
    ('zoomOut', 'Zoom Out', Icons.zoom_out),
    ('bounce', 'Bounce', Icons.sports_basketball),
    ('spin', 'Spin', Icons.rotate_right),
  ];

  static const _triggerTypes = [
    ('onClick', 'On Click'),
    ('afterPrevious', 'After Previous'),
    ('withPrevious', 'With Previous'),
  ];

  String _elementLabel(String elementId) {
    final el = elements.where((e) => e.id == elementId).firstOrNull;
    if (el == null) return elementId;
    return '${el.type} (${el.id.substring(0, el.id.length.clamp(0, 6))})';
  }

  void _showAddDialog(BuildContext context) {
    if (selectedElementId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an element first')),
      );
      return;
    }

    String type = 'fadeIn';
    String trigger = 'onClick';
    int duration = 500;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Animation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: _animationTypes
                    .map((t) => DropdownMenuItem(
                          value: t.$1,
                          child: Row(children: [
                            Icon(t.$3, size: 18),
                            const SizedBox(width: 8),
                            Text(t.$2),
                          ]),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => type = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: trigger,
                decoration: const InputDecoration(labelText: 'Trigger'),
                items: _triggerTypes
                    .map((t) => DropdownMenuItem(
                          value: t.$1,
                          child: Text(t.$2),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => trigger = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '$duration',
                decoration: const InputDecoration(labelText: 'Duration (ms)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => duration = int.tryParse(v) ?? 500,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                onAdd?.call(SlideAnimation(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  targetElementId: selectedElementId!,
                  type: type,
                  durationMs: duration,
                  trigger: trigger,
                  order: animations.length,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          left: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.animation,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Animations', style: theme.textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Add Animation',
                  onPressed: () => _showAddDialog(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: animations.isEmpty
                ? Center(
                    child: Text(
                      'No animations.\nSelect an element and tap +',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: animations.length,
                    onReorder: (oldIdx, newIdx) =>
                        onReorder?.call(oldIdx, newIdx),
                    itemBuilder: (ctx, idx) {
                      final anim = animations[idx];
                      final typeInfo = _animationTypes.firstWhere(
                        (t) => t.$1 == anim.type,
                        orElse: () => ('fadeIn', 'Fade In', Icons.visibility),
                      );
                      return Card(
                        key: ValueKey(anim.id),
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: Icon(typeInfo.$3, size: 20),
                          title: Text(typeInfo.$2,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            '${_elementLabel(anim.targetElementId)} • ${anim.durationMs}ms',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => onRemove?.call(anim.id),
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
}
