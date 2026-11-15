import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_paginated_list/flutter_bloc_paginated_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Minimal state model used by the tests.
sealed class _State {
  const _State();
}

class _Loading extends _State {
  const _Loading();
}

class _Loaded extends _State {
  const _Loaded(this.items);
  final List<int> items;
}

class _Failed extends _State {
  const _Failed(this.message);
  final String message;
}

/// A fake cubit whose pages are supplied by the test.
class _FakeCubit extends Cubit<_State> {
  _FakeCubit(this.pages) : super(const _Loading());

  /// Map of page number -> page contents.
  final Map<int, List<int>> pages;
  bool fail = false;

  void fetch(int page, int limit) {
    emit(const _Loading());
    if (fail) {
      emit(const _Failed('boom'));
      return;
    }
    emit(_Loaded(pages[page] ?? const []));
  }
}

Widget _harness(_FakeCubit cubit, {int pageSize = 3}) {
  return MaterialApp(
    home: Scaffold(
      body: BlocPaginatedListView<int, _FakeCubit, _State>(
        bloc: cubit,
        pageSize: pageSize,
        onFetchData: cubit.fetch,
        isLoadingState: (s) => s is _Loading,
        isSuccessState: (s) => s is _Loaded,
        isErrorState: (s) => s is _Failed,
        extractData: (s) => (s as _Loaded).items,
        extractErrorMessage: (s) => (s as _Failed).message,
        itemBuilder: (context, item, index) =>
            SizedBox(height: 100, child: Text('item $item')),
        loadingItemBuilder: (context, index) => const Text('skeleton'),
        emptyBuilder: (context) => const Text('empty'),
        errorBuilder: (context, error, retry) =>
            TextButton(onPressed: retry, child: Text('error: $error')),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the first page after the initial fetch', (tester) async {
    final cubit = _FakeCubit({
      1: [1, 2, 3],
    });
    await tester.pumpWidget(_harness(cubit));
    await tester.pumpAndSettle();

    expect(find.text('item 1'), findsOneWidget);
    expect(find.text('item 3'), findsOneWidget);
    expect(find.text('empty'), findsNothing);
  });

  testWidgets('shows the empty builder when the first page is empty', (
    tester,
  ) async {
    final cubit = _FakeCubit({1: <int>[]});
    await tester.pumpWidget(_harness(cubit));
    await tester.pumpAndSettle();

    expect(find.text('empty'), findsOneWidget);
  });

  testWidgets('shows the error builder and retry re-fetches', (tester) async {
    final cubit = _FakeCubit({
      1: [1, 2, 3],
    })..fail = true;
    await tester.pumpWidget(_harness(cubit));
    await tester.pumpAndSettle();

    expect(find.textContaining('error: boom'), findsOneWidget);

    // Recover and retry.
    cubit.fail = false;
    await tester.tap(find.textContaining('error: boom'));
    await tester.pumpAndSettle();

    expect(find.text('item 1'), findsOneWidget);
  });

  testWidgets('appends the next page when scrolled to the bottom', (
    tester,
  ) async {
    // Page 1 must overflow the viewport (each item is 100px tall) so there is
    // something to scroll before load-more can trigger.
    final cubit = _FakeCubit({
      1: List<int>.generate(8, (i) => i + 1), // 1..8
      2: [9, 10, 11],
    });
    await tester.pumpWidget(_harness(cubit, pageSize: 8));
    await tester.pumpAndSettle();

    expect(find.text('item 9'), findsNothing);

    // Scrolling toward the bottom triggers load-more and reveals page 2.
    await tester.scrollUntilVisible(
      find.text('item 9'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.text('item 9'), findsOneWidget);
  });
}
