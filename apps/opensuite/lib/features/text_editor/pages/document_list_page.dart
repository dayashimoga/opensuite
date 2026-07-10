import 'package:fileutility_l10n/fileutility_l10n.dart';
import 'package:fileutility_ui_kit/fileutility_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';

/// Document list page showing all saved text documents.
class DocumentListPage extends StatelessWidget {
  const DocumentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppLocalizations.textEditor),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: AppLocalizations.newDocument,
            onPressed: () => context.go(AppRouter.newDocument),
          ),
        ],
      ),
      body: EmptyState(
        icon: Icons.edit_document,
        title: AppLocalizations.noDocuments,
        description: AppLocalizations.noDocumentsDescription,
        actionLabel: AppLocalizations.newDocument,
        onAction: () => context.go(AppRouter.newDocument),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRouter.newDocument),
        tooltip: AppLocalizations.newDocument,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
