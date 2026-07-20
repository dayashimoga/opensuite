import 'package:flutter/material.dart';

/// Dialog for configuring and running batch image processing.
class BatchProcessingDialog extends StatefulWidget {
  final List<String> selectedFiles;
  final ValueChanged<BatchProcessingConfig>? onProcess;

  const BatchProcessingDialog({
    super.key,
    required this.selectedFiles,
    this.onProcess,
  });

  @override
  State<BatchProcessingDialog> createState() => _BatchProcessingDialogState();
}

class BatchProcessingConfig {
  final List<String> files;
  final String outputFormat;
  final int? resizeWidth;
  final int? resizeHeight;
  final String? filter;
  final int quality;
  final bool addWatermark;
  final String? watermarkText;

  const BatchProcessingConfig({
    required this.files,
    this.outputFormat = 'png',
    this.resizeWidth,
    this.resizeHeight,
    this.filter,
    this.quality = 90,
    this.addWatermark = false,
    this.watermarkText,
  });
}

class _BatchProcessingDialogState extends State<BatchProcessingDialog> {
  String _outputFormat = 'png';
  int? _resizeWidth;
  int? _resizeHeight;
  String? _selectedFilter;
  int _quality = 90;
  bool _addWatermark = false;
  final _watermarkController = TextEditingController();

  @override
  void dispose() {
    _watermarkController.dispose();
    super.dispose();
  }

  static const _formats = ['png', 'jpeg', 'webp', 'bmp', 'tiff'];
  static const _filters = [
    (null, 'None'),
    ('grayscale', 'Grayscale'),
    ('sepia', 'Sepia'),
    ('blur', 'Blur'),
    ('sharpen', 'Sharpen'),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Batch Processing'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.selectedFiles.length} files selected',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _outputFormat,
                decoration: const InputDecoration(
                  labelText: 'Output Format',
                  border: OutlineInputBorder(),
                ),
                items: _formats
                    .map((f) => DropdownMenuItem(
                        value: f, child: Text(f.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _outputFormat = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Width',
                        border: OutlineInputBorder(),
                        suffixText: 'px',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _resizeWidth = int.tryParse(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Height',
                        border: OutlineInputBorder(),
                        suffixText: 'px',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _resizeHeight = int.tryParse(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _selectedFilter,
                decoration: const InputDecoration(
                  labelText: 'Apply Filter',
                  border: OutlineInputBorder(),
                ),
                items: _filters
                    .map(
                        (f) => DropdownMenuItem(value: f.$1, child: Text(f.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedFilter = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Quality:'),
                  Expanded(
                    child: Slider(
                      value: _quality.toDouble(),
                      min: 10,
                      max: 100,
                      divisions: 9,
                      label: '$_quality%',
                      onChanged: (v) => setState(() => _quality = v.round()),
                    ),
                  ),
                  Text('$_quality%'),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Add Watermark'),
                value: _addWatermark,
                onChanged: (v) => setState(() => _addWatermark = v),
              ),
              if (_addWatermark)
                TextField(
                  controller: _watermarkController,
                  decoration: const InputDecoration(
                    labelText: 'Watermark Text',
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onProcess?.call(BatchProcessingConfig(
              files: widget.selectedFiles,
              outputFormat: _outputFormat,
              resizeWidth: _resizeWidth,
              resizeHeight: _resizeHeight,
              filter: _selectedFilter,
              quality: _quality,
              addWatermark: _addWatermark,
              watermarkText: _addWatermark ? _watermarkController.text : null,
            ));
            Navigator.pop(context);
          },
          child: const Text('Process'),
        ),
      ],
    );
  }
}
