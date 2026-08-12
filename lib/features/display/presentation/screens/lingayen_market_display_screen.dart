import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../data/market_display_repository.dart';
import '../../domain/market_display_models.dart';
import '../widgets/market_display_widgets.dart';

class LingayenMarketDisplayScreen extends StatefulWidget {
  const LingayenMarketDisplayScreen({super.key});

  @override
  State<LingayenMarketDisplayScreen> createState() =>
      _LingayenMarketDisplayScreenState();
}

class _LingayenMarketDisplayScreenState
    extends State<LingayenMarketDisplayScreen> {
  static const int _itemsPerPage = 10;

  MarketDisplayRepository? _repository;
  Future<MarketDisplayData>? _displayFuture;
  StreamSubscription<MarketDisplayData>? _displaySubscription;
  late DateTime _currentTime;
  Timer? _refreshTimer;
  bool _bootstrapped = false;
  int _pageIndex = 0;
  bool _isAutoRefreshing = false;
  String _query = '';
  String _category = 'all';
  String _compliance = 'all';

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _handleAutoRefreshTick(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) {
      return;
    }

    final dependencies = context.read<AppDependencies>();
    _repository = dependencies.marketDisplayRepository;
    _displayFuture = _repository!.getLingayenMarketDisplayData();
    _displaySubscription = _repository!.watchLingayenMarketDisplayData().listen(
      _handleLiveDisplayData,
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) {
          return;
        }
        setState(() {
          _displayFuture = Future<MarketDisplayData>.error(error, stackTrace);
          _currentTime = DateTime.now();
        });
      },
    );
    _bootstrapped = true;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _displaySubscription?.cancel();
    super.dispose();
  }

  void _handleLiveDisplayData(MarketDisplayData data) {
    if (!mounted) {
      return;
    }

    final pageCount = _resolvePageCount(data.items.length);
    setState(() {
      if (_category != 'all' &&
          !data.items.any((item) => item.categoryName == _category)) {
        _category = 'all';
      }
      _displayFuture = Future.value(data);
      _currentTime = DateTime.now();
      if (_pageIndex >= pageCount) {
        _pageIndex = 0;
      }
    });
  }

  Future<void> _refreshBoard() async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    final future = repository.getLingayenMarketDisplayData();
    setState(() {
      _displayFuture = future;
      _currentTime = DateTime.now();
    });
    await future;
  }

  Future<void> _handleAutoRefreshTick() async {
    if (!mounted || _displayFuture == null || _isAutoRefreshing) {
      return;
    }

    _isAutoRefreshing = true;

    try {
      final data = await _displayFuture!;
      if (!mounted) {
        return;
      }

      final pageCount = _resolvePageCount(data.items.length);
      setState(() {
        _pageIndex = (_pageIndex + 1) % pageCount;
      });
    } finally {
      _isAutoRefreshing = false;
    }
  }

  int _resolvePageCount(int itemCount) {
    final pageCount = (itemCount / _itemsPerPage).ceil();
    return pageCount <= 0 ? 1 : pageCount;
  }

  void _openLogin() {
    if (!mounted) {
      return;
    }

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final future = _displayFuture;

    return Scaffold(
      body: AppBackground(
        showTopGlow: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1180;
            final shallow = constraints.maxHeight < 860;
            final wideLayout = constraints.maxWidth >= 1180;
            final edgePadding = compact
                ? const EdgeInsets.all(AppSpacing.md)
                : EdgeInsets.symmetric(
                    horizontal: shallow ? AppSpacing.lg : AppSpacing.xl,
                    vertical: shallow ? AppSpacing.md : AppSpacing.lg,
                  );

            return SafeArea(
              child: Padding(
                padding: edgePadding,
                child: future == null
                    ? const Center(child: CircularProgressIndicator())
                    : FutureBuilder<MarketDisplayData>(
                        future: future,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const _DisplayLoadingState();
                          }

                          if (snapshot.hasError) {
                            return _DisplayErrorState(
                              message: _readableDisplayError(snapshot.error),
                              onRetry: _refreshBoard,
                            );
                          }

                          final data = snapshot.data;
                          if (data == null) {
                            return _DisplayErrorState(
                              message:
                                  'No Lingayen market data is available yet.',
                              onRetry: _refreshBoard,
                            );
                          }

                          final filteredData = _filteredData(data);
                          final pageCount = _resolvePageCount(
                            filteredData.items.length,
                          );
                          final effectivePageIndex = _pageIndex >= pageCount
                              ? 0
                              : _pageIndex;

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: _DisplayBoard(
                              key: ValueKey(
                                '${data.lastUpdatedAt}-$effectivePageIndex',
                              ),
                              data: filteredData,
                              categories:
                                  data.items
                                      .map((item) => item.categoryName)
                                      .toSet()
                                      .toList()
                                    ..sort(),
                              currentTime: _currentTime,
                              pageIndex: effectivePageIndex,
                              itemsPerPage: _itemsPerPage,
                              compact: compact,
                              shallow: shallow,
                              wideLayout: wideLayout,
                              onLogin: _openLogin,
                              onRefresh: _refreshBoard,
                              query: _query,
                              category: _category,
                              compliance: _compliance,
                              onFiltersChanged: (query, category, compliance) {
                                setState(() {
                                  _query = query;
                                  _category = category;
                                  _compliance = compliance;
                                  _pageIndex = 0;
                                });
                              },
                              onPreviousPage: () => setState(() {
                                _pageIndex =
                                    (_pageIndex - 1 + pageCount) % pageCount;
                              }),
                              onNextPage: () => setState(() {
                                _pageIndex = (_pageIndex + 1) % pageCount;
                              }),
                            ),
                          );
                        },
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  MarketDisplayData _filteredData(MarketDisplayData data) {
    final normalized = _query.trim().toLowerCase();
    final items = data.items.where((item) {
      final matchesQuery =
          normalized.isEmpty ||
          item.commodityName.toLowerCase().contains(normalized) ||
          item.categoryName.toLowerCase().contains(normalized);
      final matchesCategory =
          _category == 'all' || item.categoryName == _category;
      final matchesCompliance =
          _compliance == 'all' ||
          (_compliance == 'above' && item.isAboveSrp) ||
          (_compliance == 'within' && !item.isAboveSrp);
      return matchesQuery && matchesCategory && matchesCompliance;
    }).toList();
    return MarketDisplayData(
      storeId: data.storeId,
      storeName: data.storeName,
      marketName: data.marketName,
      address: data.address,
      city: data.city,
      lastUpdatedAt: data.lastUpdatedAt,
      items: items,
    );
  }

  String _readableDisplayError(Object? error) {
    final value = error.toString().toLowerCase();
    if (value.contains('permission-denied')) {
      return 'The public price feed is temporarily unavailable. Please contact the market administrator.';
    }
    if (value.contains('network') || value.contains('unavailable')) {
      return 'The market board could not connect. Check the internet connection and try again.';
    }
    return 'The latest market prices could not be loaded. Please try again shortly.';
  }
}

class _DisplayBoard extends StatelessWidget {
  const _DisplayBoard({
    super.key,
    required this.data,
    required this.currentTime,
    required this.pageIndex,
    required this.itemsPerPage,
    required this.compact,
    required this.shallow,
    required this.wideLayout,
    required this.onLogin,
    required this.onRefresh,
    required this.categories,
    required this.query,
    required this.category,
    required this.compliance,
    required this.onFiltersChanged,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final MarketDisplayData data;
  final DateTime currentTime;
  final int pageIndex;
  final int itemsPerPage;
  final bool compact;
  final bool shallow;
  final bool wideLayout;
  final VoidCallback onLogin;
  final Future<void> Function() onRefresh;
  final List<String> categories;
  final String query;
  final String category;
  final String compliance;
  final void Function(String, String, String) onFiltersChanged;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) {
    final sectionGap = AppSpacing.sm;
    final headerCompact = compact && !wideLayout;
    final boardCompact = compact || (shallow && !wideLayout);
    final footerCompact = compact && !wideLayout;
    final phoneLayout = compact && !wideLayout;

    if (phoneLayout) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MarketDisplayHeader(
              data: data,
              currentTime: currentTime,
              onLogin: onLogin,
              onRefresh: () => onRefresh(),
              compact: headerCompact,
            ),
            SizedBox(height: sectionGap),
            _PublicBoardFilters(
              categories: categories,
              query: query,
              category: category,
              compliance: compliance,
              onChanged: onFiltersChanged,
              onPreviousPage: onPreviousPage,
              onNextPage: onNextPage,
            ),
            SizedBox(height: sectionGap),
            MarketDisplayGridPanel(
              data: data,
              pageIndex: pageIndex,
              itemsPerPage: itemsPerPage,
              compact: true,
              wideLayout: false,
              stretchForMobile: true,
            ),
            SizedBox(height: sectionGap),
            MarketDisplayFooterStrip(data: data, compact: footerCompact),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MarketDisplayHeader(
          data: data,
          currentTime: currentTime,
          onLogin: onLogin,
          onRefresh: () => onRefresh(),
          compact: headerCompact,
        ),
        SizedBox(height: sectionGap),
        _PublicBoardFilters(
          categories: categories,
          query: query,
          category: category,
          compliance: compliance,
          onChanged: onFiltersChanged,
          onPreviousPage: onPreviousPage,
          onNextPage: onNextPage,
        ),
        SizedBox(height: sectionGap),
        Expanded(
          child: MarketDisplayGridPanel(
            data: data,
            pageIndex: pageIndex,
            itemsPerPage: itemsPerPage,
            compact: boardCompact,
            wideLayout: wideLayout,
            stretchForMobile: false,
          ),
        ),
        SizedBox(height: sectionGap),
        MarketDisplayFooterStrip(data: data, compact: footerCompact),
      ],
    );
  }
}

class _PublicBoardFilters extends StatelessWidget {
  const _PublicBoardFilters({
    required this.categories,
    required this.query,
    required this.category,
    required this.compliance,
    required this.onChanged,
    required this.onPreviousPage,
    required this.onNextPage,
  });
  final List<String> categories;
  final String query;
  final String category;
  final String compliance;
  final void Function(String, String, String) onChanged;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.borderFor(context)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final search = TextFormField(
          key: ValueKey(query),
          initialValue: query,
          onChanged: (value) => onChanged(value, category, compliance),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Search commodity',
            isDense: true,
          ),
        );
        final categoryField = DropdownButtonFormField<String>(
          initialValue: category,
          decoration: const InputDecoration(
            labelText: 'Category',
            isDense: true,
          ),
          items: [
            const DropdownMenuItem(value: 'all', child: Text('All categories')),
            ...categories.map(
              (value) => DropdownMenuItem(value: value, child: Text(value)),
            ),
          ],
          onChanged: (value) => onChanged(query, value ?? 'all', compliance),
        );
        final complianceField = DropdownButtonFormField<String>(
          initialValue: compliance,
          decoration: const InputDecoration(
            labelText: 'SRP status',
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All prices')),
            DropdownMenuItem(value: 'within', child: Text('Within SRP')),
            DropdownMenuItem(value: 'above', child: Text('Above SRP')),
          ],
          onChanged: (value) => onChanged(query, category, value ?? 'all'),
        );
        final navigation = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Previous price page',
              onPressed: onPreviousPage,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: 'Next price page',
              onPressed: onNextPage,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            IconButton(
              tooltip: 'Clear filters',
              onPressed: () => onChanged('', 'all', 'all'),
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
          ],
        );
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              search,
              const SizedBox(height: 10),
              categoryField,
              const SizedBox(height: 10),
              complianceField,
              navigation,
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 2, child: search),
            const SizedBox(width: 10),
            Expanded(child: categoryField),
            const SizedBox(width: 10),
            Expanded(child: complianceField),
            navigation,
          ],
        );
      },
    ),
  );
}

class _DisplayLoadingState extends StatelessWidget {
  const _DisplayLoadingState();

  @override
  Widget build(BuildContext context) {
    final useDark = AppColors.isDark(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(
              context,
            ).withValues(alpha: useDark ? 0.96 : 0.92),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.borderFor(context)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowFor(context).withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Preparing the Lingayen Market price board...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimaryFor(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisplayErrorState extends StatelessWidget {
  const _DisplayErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useDark = AppColors.isDark(context);
    final titleColor = AppColors.textPrimaryFor(context);
    final messageColor = AppColors.textSecondaryFor(context);
    final accent = useDark ? AppColors.darkPrimarySoft : AppColors.primary;
    final accentDeep = useDark ? AppColors.darkPrimary : AppColors.primaryDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 520 || constraints.maxHeight < 620;
        final cardPadding = compact ? AppSpacing.lg : AppSpacing.xxl;
        final iconSize = compact ? 60.0 : 72.0;

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DisplayErrorBackdropPainter(useDark),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? AppSpacing.sm : AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    padding: EdgeInsets.all(cardPadding),
                    decoration: BoxDecoration(
                      gradient: AppColors.surfaceGradientFor(context),
                      borderRadius: BorderRadius.circular(compact ? 24 : 32),
                      border: Border.all(
                        color: AppColors.borderFor(
                          context,
                        ).withValues(alpha: useDark ? 0.72 : 0.95),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowFor(
                            context,
                          ).withValues(alpha: useDark ? 0.42 : 0.2),
                          blurRadius: compact ? 22 : 34,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(
                              alpha: useDark ? 0.18 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: accent.withValues(
                                alpha: useDark ? 0.24 : 0.16,
                              ),
                            ),
                          ),
                          child: Text(
                            'Connection blocked',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: compact ? AppSpacing.md : AppSpacing.lg,
                        ),
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradientFor(context),
                            borderRadius: BorderRadius.circular(
                              compact ? 20 : 24,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentDeep.withValues(
                                  alpha: useDark ? 0.34 : 0.22,
                                ),
                                blurRadius: 22,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.monitor_rounded,
                            size: compact ? 30 : 34,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          height: compact ? AppSpacing.md : AppSpacing.lg,
                        ),
                        Text(
                          'Display unavailable',
                          textAlign: TextAlign.center,
                          style:
                              (compact
                                      ? theme.textTheme.titleLarge
                                      : theme.textTheme.headlineSmall)
                                  ?.copyWith(
                                    color: titleColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                            compact ? AppSpacing.md : AppSpacing.lg,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMutedFor(
                              context,
                            ).withValues(alpha: useDark ? 0.74 : 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.borderFor(
                                context,
                              ).withValues(alpha: useDark ? 0.52 : 0.8),
                            ),
                          ),
                          child: Text(
                            message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: messageColor,
                              fontWeight: FontWeight.w700,
                              height: 1.45,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          height: compact ? AppSpacing.md : AppSpacing.lg,
                        ),
                        SizedBox(
                          width: compact ? double.infinity : 240,
                          height: 48,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: accentDeep,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onPressed: () => onRetry(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try again'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DisplayErrorBackdropPainter extends CustomPainter {
  const _DisplayErrorBackdropPainter(this.useDark);

  final bool useDark;

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: useDark
            ? const [Color(0xFF1B0D19), Color(0xFF2A1230), Color(0xFF160A15)]
            : const [Color(0xFFFFF7FA), Color(0xFFF5E8EF), Color(0xFFFFFFFF)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);

    final ribbonPaint = Paint()
      ..color = (useDark ? AppColors.darkPrimarySoft : AppColors.primary)
          .withValues(alpha: useDark ? 0.12 : 0.08)
      ..style = PaintingStyle.fill;
    final ribbonPath = Path()
      ..moveTo(-size.width * 0.08, size.height * 0.18)
      ..lineTo(size.width * 1.08, size.height * 0.02)
      ..lineTo(size.width * 1.08, size.height * 0.18)
      ..lineTo(-size.width * 0.08, size.height * 0.36)
      ..close();
    canvas.drawPath(ribbonPath, ribbonPaint);

    final lowerRibbonPaint = Paint()
      ..color = (useDark ? AppColors.darkPrimary : AppColors.primarySoft)
          .withValues(alpha: useDark ? 0.1 : 0.07)
      ..style = PaintingStyle.fill;
    final lowerRibbonPath = Path()
      ..moveTo(-size.width * 0.1, size.height * 0.82)
      ..lineTo(size.width * 1.1, size.height * 0.66)
      ..lineTo(size.width * 1.1, size.height * 0.82)
      ..lineTo(-size.width * 0.1, size.height * 0.98)
      ..close();
    canvas.drawPath(lowerRibbonPath, lowerRibbonPaint);

    final linePaint = Paint()
      ..color = (useDark ? Colors.white : AppColors.primaryDark).withValues(
        alpha: useDark ? 0.04 : 0.045,
      )
      ..strokeWidth = 1;
    const gap = 36.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DisplayErrorBackdropPainter oldDelegate) {
    return oldDelegate.useDark != useDark;
  }
}
