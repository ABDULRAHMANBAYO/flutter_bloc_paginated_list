import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_paginated_list/flutter_bloc_paginated_list.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlocPaginatedListView Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

// ---------------------------------------------------------------------------
// A tiny cubit that serves pages from an in-memory "server" with fake latency.
// ---------------------------------------------------------------------------

sealed class ItemsState {
  const ItemsState();
}

class ItemsInitial extends ItemsState {
  const ItemsInitial();
}

class ItemsLoading extends ItemsState {
  const ItemsLoading();
}

class ItemsLoaded extends ItemsState {
  const ItemsLoaded(this.items);
  final List<String> items;
}

class ItemsError extends ItemsState {
  const ItemsError(this.message);
  final String message;
}

class ItemsCubit extends Cubit<ItemsState> {
  ItemsCubit() : super(const ItemsInitial());

  static const int _total = 47; // total items on the fake server

  Future<void> fetch({required int page, required int limit}) async {
    emit(const ItemsLoading());
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final start = (page - 1) * limit;
    if (start >= _total) {
      emit(const ItemsLoaded([]));
      return;
    }
    final end = (start + limit).clamp(0, _total);
    emit(ItemsLoaded([
      for (var i = start; i < end; i++) 'Item #${i + 1}',
    ]));
  }
}

// ---------------------------------------------------------------------------
// The screen.
// ---------------------------------------------------------------------------

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ItemsCubit(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Paginated list')),
        body: Builder(
          builder: (context) {
            final cubit = context.read<ItemsCubit>();
            return BlocPaginatedListView<String, ItemsCubit, ItemsState>(
              bloc: cubit,
              pageSize: 15,
              onFetchData: (page, limit) =>
                  cubit.fetch(page: page, limit: limit),
              isLoadingState: (s) => s is ItemsLoading,
              isSuccessState: (s) => s is ItemsLoaded,
              isErrorState: (s) => s is ItemsError,
              extractData: (s) => (s as ItemsLoaded).items,
              extractErrorMessage: (s) => (s as ItemsError).message,
              padding: const EdgeInsets.all(12),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, item, index) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(item),
                ),
              ),
              loadingItemBuilder: (context, index) => const Card(
                child: ListTile(
                  leading: CircleAvatar(),
                  title: SizedBox(
                    height: 14,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(0x11000000)),
                    ),
                  ),
                ),
              ),
              emptyBuilder: (context) =>
                  const Center(child: Text('Nothing here yet')),
              errorBuilder: (context, error, retry) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: retry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
