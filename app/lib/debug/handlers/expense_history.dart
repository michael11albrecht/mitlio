import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/expenses/ui/expense_history_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// `ext.mitlio.expenses.history` and `ext.mitlio.expenses.restoreRevision`:
/// the same ViewModel commands as the "Verlauf" sheet (keys without the
/// `ext.mitlio.` prefix).
Map<String, DriveHandler> expenseHistoryDriveHandlers(ProviderContainer c) {
  ExpenseHistoryViewModel history(String id) =>
      c.read(expenseHistoryViewModelProvider(id).notifier);
  return {
    'expenses.history': (p) async {
      final id = p['id'];
      if (id == null) return invalidParams('need id');
      return switch (await history(id).list()) {
        Ok(:final value) => {
          'revisions': [
            for (final r in value)
              {
                'id': r.id,
                'revision': r.revision,
                'changedAt': r.changedAt.toIso8601String(),
                'title': r.snapshot.title,
                'amountCents': r.snapshot.amountCents,
              },
          ],
        },
        Err(:final error) => driveError(error),
      };
    },
    'expenses.restoreRevision': (p) async {
      final id = p['id'];
      final revisionId = p['revisionId'];
      if (id == null || revisionId == null) {
        return invalidParams('need id, revisionId');
      }
      return switch (await history(id).restore(revisionId)) {
        Ok() => {'id': id, 'revisionId': revisionId},
        Err(:final error) => driveError(error),
      };
    },
  };
}
