import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A reusable paginated [ListView] driven by a BLoC/Cubit.
///
/// [BlocPaginatedListView] handles the wiring that every infinite-scroll list
/// needs — tracking the current page, appending pages as the user scrolls,
/// pull-to-refresh, and swapping between loading / empty / error / data views —
/// while leaving every piece of UI up to you through builder callbacks.
///
/// It is state-shape agnostic: instead of forcing a particular state class, you
/// provide predicate callbacks ([isLoadingState], [isSuccessState],
/// [isErrorState]) and extractors ([extractData], [extractErrorMessage]) so it
/// can adapt to whatever states your existing BLoC already emits.
///
/// The three type parameters are:
///  * `T` — the type of a single list item.
///  * `B` — the BLoC/Cubit type (any [StateStreamable]).
///  * `S` — the state type emitted by `B`.
///
/// Example:
/// ```dart
/// BlocPaginatedListView<Post, PostCubit, PostState>(
///   bloc: context.read<PostCubit>(),
///   onFetchData: (page, limit) =>
///       context.read<PostCubit>().fetchPosts(page: page, limit: limit),
///   isLoadingState: (s) => s is PostLoading,
///   isSuccessState: (s) => s is PostLoaded,
///   isErrorState: (s) => s is PostError,
///   extractData: (s) => (s as PostLoaded).posts,
///   extractErrorMessage: (s) => (s as PostError).message,
///   itemBuilder: (context, post, index) => PostTile(post: post),
///   loadingItemBuilder: (context, index) => const PostSkeleton(),
///   emptyBuilder: (context) => const Center(child: Text('No posts yet')),
///   errorBuilder: (context, error, retry) =>
///       ErrorView(message: error, onRetry: retry),
/// )
/// ```
class BlocPaginatedListView<T, B extends StateStreamable<S>, S>
    extends StatefulWidget {
  /// The BLoC/Cubit instance that emits pages of data.
  final B bloc;

  /// Called whenever a page of data should be fetched.
  ///
  /// Invoked with the 1-based [page] number and the configured [pageSize] as
  /// `limit`. Trigger your BLoC's fetch method here.
  final void Function(int page, int limit) onFetchData;

  /// Returns `true` when [state] represents a loading state.
  final bool Function(S state) isLoadingState;

  /// Returns `true` when [state] represents a successful data state.
  final bool Function(S state) isSuccessState;

  /// Returns `true` when [state] represents an error state.
  final bool Function(S state) isErrorState;

  /// Extracts the list of items from a success [state].
  final List<T> Function(S state) extractData;

  /// Extracts a human-readable error message from an error [state].
  final String Function(S state) extractErrorMessage;

  /// Builds a single item in the list.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Builds a single placeholder/skeleton item shown during the initial load.
  final Widget Function(BuildContext context, int index) loadingItemBuilder;

  /// Builds the widget shown when the list is empty.
  final Widget Function(BuildContext context) emptyBuilder;

  /// Builds the widget shown when the first page fails to load.
  ///
  /// The provided `retry` callback re-fetches the current page.
  final Widget Function(BuildContext context, String error, VoidCallback retry)
      errorBuilder;

  /// Optional header that scrolls together with the list (always at index 0).
  final Widget Function(BuildContext context)? headerBuilder;

  /// Number of items requested per page. Also used to decide whether more pages
  /// are available (a page smaller than [pageSize] is treated as the last one).
  final int pageSize;

  /// Number of placeholder items rendered by [loadingItemBuilder] during the
  /// initial load.
  final int shimmerCount;

  /// Padding applied to the underlying [ListView].
  final EdgeInsetsGeometry? padding;

  /// Optional separator builder. When provided a [ListView.separated] is used.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Whether to show a loading indicator at the bottom while fetching the next
  /// page.
  final bool showBottomLoader;

  /// Custom widget for the bottom "loading more" indicator. Falls back to a
  /// platform-appropriate spinner tinted with [progressIndicatorColor].
  final Widget? bottomLoaderWidget;

  /// Whether pull-to-refresh is enabled.
  final bool enableRefresh;

  /// Optional external [ScrollController]. When omitted an internal controller
  /// is created and disposed automatically.
  final ScrollController? scrollController;

  /// Scroll physics for the list. Defaults to
  /// [AlwaysScrollableScrollPhysics] so pull-to-refresh works even when the
  /// content is short.
  final ScrollPhysics? physics;

  /// Whether the underlying [ListView] should shrink-wrap its content.
  final bool shrinkWrap;

  /// Distance in pixels from the bottom of the list at which the next page is
  /// requested.
  final double loadMoreThreshold;

  /// Color used for the built-in [RefreshIndicator] and the default bottom
  /// loader. Defaults to the theme's primary color when null.
  final Color? progressIndicatorColor;

  const BlocPaginatedListView({
    super.key,
    required this.bloc,
    required this.onFetchData,
    required this.isLoadingState,
    required this.isSuccessState,
    required this.isErrorState,
    required this.extractData,
    required this.extractErrorMessage,
    required this.itemBuilder,
    required this.loadingItemBuilder,
    required this.emptyBuilder,
    required this.errorBuilder,
    this.headerBuilder,
    this.pageSize = 10,
    this.shimmerCount = 8,
    this.padding,
    this.separatorBuilder,
    this.showBottomLoader = true,
    this.bottomLoaderWidget,
    this.enableRefresh = true,
    this.scrollController,
    this.physics,
    this.shrinkWrap = false,
    this.loadMoreThreshold = 200,
    this.progressIndicatorColor,
  });

  @override
  State<BlocPaginatedListView<T, B, S>> createState() =>
      _BlocPaginatedListViewState<T, B, S>();
}

class _BlocPaginatedListViewState<T, B extends StateStreamable<S>, S>
    extends State<BlocPaginatedListView<T, B, S>> {
  late ScrollController _scrollController;
  List<T> items = [];
  int currentPage = 1;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasNextPage = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);

    // Initial data fetch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    // Only dispose the controller we created ourselves.
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - widget.loadMoreThreshold) {
      _loadMore();
    }
  }

  void _fetchData() {
    widget.onFetchData(currentPage, widget.pageSize);
  }

  void _loadMore() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      currentPage++;
      _fetchData();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      currentPage = 1;
      hasNextPage = true;
      items.clear();
    });
    _fetchData();
  }

  void _retry() {
    _fetchData();
  }

  Color _progressColor(BuildContext context) =>
      widget.progressIndicatorColor ?? Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<B, S>(
      bloc: widget.bloc,
      listener: (context, state) {
        if (widget.isLoadingState(state)) {
          setState(() {
            if (currentPage == 1) {
              isLoading = true;
              items.clear();
              errorMessage = null;
            } else {
              isLoadingMore = true;
            }
          });
        } else if (widget.isSuccessState(state)) {
          final newData = widget.extractData(state);
          setState(() {
            if (currentPage == 1) {
              // Refresh or initial load.
              items = newData;
            } else {
              // Pagination — append to existing items.
              items.addAll(newData);
            }
            hasNextPage = newData.length >= widget.pageSize;
            isLoading = false;
            isLoadingMore = false;
            errorMessage = null;
          });
        } else if (widget.isErrorState(state)) {
          setState(() {
            errorMessage = widget.extractErrorMessage(state);
            isLoading = false;
            isLoadingMore = false;
          });
        }
      },
      builder: (context, state) {
        // Error state (only when there is nothing to show).
        if (errorMessage != null && items.isEmpty) {
          return widget.errorBuilder(context, errorMessage!, _retry);
        }

        // Initial loading state.
        if (isLoading && items.isEmpty) {
          return _buildLoadingList();
        }

        // Empty state.
        if (items.isEmpty && !isLoading) {
          return widget.emptyBuilder(context);
        }

        // Data.
        return widget.enableRefresh
            ? RefreshIndicator(
                onRefresh: _refresh,
                color: _progressColor(context),
                child: _buildList(),
              )
            : _buildList();
      },
    );
  }

  Widget _buildList() {
    final hasHeader = widget.headerBuilder != null;
    final headerOffset = hasHeader ? 1 : 0;
    final itemCount = headerOffset +
        items.length +
        (isLoadingMore && widget.showBottomLoader ? 1 : 0);

    if (widget.separatorBuilder != null) {
      return ListView.separated(
        controller: _scrollController,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        padding: widget.padding,
        itemCount: itemCount,
        itemBuilder: (context, index) =>
            _buildListItem(context, index, hasHeader),
        separatorBuilder: (context, index) {
          // No separator directly after the header.
          if (hasHeader && index == 0) {
            return const SizedBox.shrink();
          }
          return widget.separatorBuilder!(
            context,
            hasHeader ? index - 1 : index,
          );
        },
        shrinkWrap: widget.shrinkWrap,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          _buildListItem(context, index, hasHeader),
      shrinkWrap: widget.shrinkWrap,
    );
  }

  Widget _buildListItem(BuildContext context, int index, bool hasHeader) {
    // Header first.
    if (hasHeader && index == 0) {
      return widget.headerBuilder!(context);
    }

    final adjustedIndex = hasHeader ? index - 1 : index;

    // Bottom loader.
    if (adjustedIndex >= items.length) {
      return widget.bottomLoaderWidget ??
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Theme.of(context).platform == TargetPlatform.iOS
                  ? const CupertinoActivityIndicator()
                  : CircularProgressIndicator(color: _progressColor(context)),
            ),
          );
    }

    return widget.itemBuilder(context, items[adjustedIndex], adjustedIndex);
  }

  Widget _buildLoadingList() {
    final hasHeader = widget.headerBuilder != null;
    final headerOffset = hasHeader ? 1 : 0;
    final itemCount = headerOffset + widget.shimmerCount;

    if (widget.separatorBuilder != null) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: widget.padding,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (hasHeader && index == 0) {
            return widget.headerBuilder!(context);
          }
          return widget.loadingItemBuilder(
            context,
            hasHeader ? index - 1 : index,
          );
        },
        separatorBuilder: (context, index) {
          if (hasHeader && index == 0) {
            return const SizedBox.shrink();
          }
          return widget.separatorBuilder!(
            context,
            hasHeader ? index - 1 : index,
          );
        },
        shrinkWrap: widget.shrinkWrap,
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (hasHeader && index == 0) {
          return widget.headerBuilder!(context);
        }
        return widget.loadingItemBuilder(
          context,
          hasHeader ? index - 1 : index,
        );
      },
      shrinkWrap: widget.shrinkWrap,
    );
  }
}
