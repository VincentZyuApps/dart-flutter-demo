import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/page3_enums.dart';
import '../services/app_config_service.dart';
import '../services/github_repository_service.dart';
import '../services/network_proxy_service.dart';
import '../widgets/animated_page.dart';
import '../widgets/repository_card.dart';
import '../widgets/repository_list_tile.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/state_shell.dart';

class Page3AdaptiveGrid extends StatefulWidget {
  const Page3AdaptiveGrid({super.key});

  @override
  State<Page3AdaptiveGrid> createState() => _Page3AdaptiveGridState();
}

class _Page3AdaptiveGridState extends State<Page3AdaptiveGrid> {
  final _service = GitHubRepositoryService();
  final _searchController = TextEditingController();

  LayoutMode _layoutMode = LayoutMode.masonry;
  DensityMode _densityMode = DensityMode.three;
  SortMode _sortMode = SortMode.updated;
  int _pageSize = 25;
  late final TextEditingController _pageSizeController;
  late final FocusNode _pageSizeFocusNode;
  bool _controlsExpanded = false;
  bool _autoColumns = true;
  bool _animateTransitions = true;

  bool _loading = false;
  String? _error;
  String _status = 'Ready';
  List<GitHubRepositoryItem> _displayRepositories = const [];
  final List<GitHubRepositoryItem> _incomingQueue = [];
  final Set<String> _knownRepoIds = {};
  Timer? _staggerTimer;
  List<String> _logs = const [];

  @override
  void initState() {
    super.initState();
    _pageSizeController = TextEditingController(text: '$_pageSize');
    _pageSizeFocusNode = FocusNode();
    _pageSizeFocusNode.addListener(() {
      if (!_pageSizeFocusNode.hasFocus) {
        _commitPageSize(_pageSizeController.text);
      }
    });
    AppConfigService.instance.changeNotifier.addListener(_onConfigChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _pageSizeController.dispose();
    _pageSizeFocusNode.dispose();
    AppConfigService.instance.changeNotifier.removeListener(_onConfigChanged);
    _staggerTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _commitPageSize(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) {
      _pageSizeController.text = '$_pageSize';
      return;
    }
    final clamped = parsed.clamp(1, 100);
    setState(() {
      _pageSize = clamped;
      _pageSizeController.text = '$clamped';
    });
  }

  void _onConfigChanged() {
    if (mounted) {
      _refresh();
    }
  }

  void _startStaggerTimerIfNeeded() {
    if (_staggerTimer != null && _staggerTimer!.isActive) return;
    _staggerTimer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_incomingQueue.isEmpty) {
        if (!_loading) {
          timer.cancel();
          setState(() {
            _status =
                'Loaded ${_displayRepositories.length} repositories from ${AppConfigService.instance.sources.length} sources';
          });
        }
        return;
      }

      final nextItem = _incomingQueue.removeAt(0);
      setState(() {
        _displayRepositories = [..._displayRepositories, nextItem];
        if (_incomingQueue.isNotEmpty) {
          _status =
              'Streaming: ${_displayRepositories.length} displayed (+${_incomingQueue.length} queued)...';
        }
      });
    });
  }

  Future<void> _refresh() async {
    _staggerTimer?.cancel();
    _incomingQueue.clear();
    _knownRepoIds.clear();

    final sources = AppConfigService.instance.sources;
    if (sources.isEmpty) {
      setState(() {
        _error = 'Add at least one GitHub repositories page in Settings.';
        _status = 'No sources';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _status = 'Connecting...';
      _logs = [];
      _displayRepositories = [];
    });

    try {
      await for (final chunk in _service.fetchRepositoriesStream(
        sourceUrls: sources,
        pageSize: _pageSize,
      )) {
        if (!mounted) return;
        _logs.add(chunk.log);
        for (final item in chunk.newItems) {
          if (_knownRepoIds.add(item.id)) {
            _incomingQueue.add(item);
          }
        }
        _startStaggerTimerIfNeeded();
        setState(() {
          _status =
              'Streaming ${chunk.source.label}: ${_displayRepositories.length} displayed (+${_incomingQueue.length} queued)...';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _status = 'Load failed';
        _logs.add('Error: $e');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        if (_incomingQueue.isEmpty) {
          setState(() {
            _status =
                'Loaded ${_displayRepositories.length} repositories from ${sources.length} sources';
          });
        }
      }
    }
  }

  List<GitHubRepositoryItem> get _filteredRepositories {
    final query = _searchController.text.trim().toLowerCase();
    final isStreaming = _loading || _incomingQueue.isNotEmpty;
    // 流式加载期间保持稳定的到达顺序（Append Only），避免新卡片插队导致已有卡片全局索引位移与跳列
    final baseList = isStreaming ? _displayRepositories : _sortRepositories(_displayRepositories);
    if (query.isEmpty) return baseList;
    return baseList.where((repo) {
      return repo.name.toLowerCase().contains(query) ||
          repo.fullName.toLowerCase().contains(query) ||
          (repo.description ?? '').toLowerCase().contains(query) ||
          (repo.language ?? '').toLowerCase().contains(query);
    }).toList();
  }

  List<GitHubRepositoryItem> _sortRepositories(List<GitHubRepositoryItem> items) {
    if (_sortMode == SortMode.natural) return items;
    final sorted = [...items];
    sorted.sort((a, b) {
      return switch (_sortMode) {
        SortMode.natural => 0,
        SortMode.updated => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        SortMode.stars => b.stars.compareTo(a.stars),
        SortMode.name => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      };
    });
    return sorted;
  }

  String _widthBucket(double width) {
    if (width < 700) return '<700';
    if (width < 1100) return '700-1099';
    return '>=1100';
  }

  int _columnCount(double width) {
    final autoBase = width < 420
        ? 1
        : width < 720
            ? 2
            : width < 1040
                ? 3
                : width < 1440
                    ? 4
                    : 5;
    final target = _densityMode.columnCount;
    return _autoColumns ? autoBase : target;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedPageWrapper(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = _columnCount(width);
          final filtered = _filteredRepositories;
          final effectiveDensity = _autoColumns
              ? DensityMode.fromColumnCount(columns)
              : _densityMode;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildControls(theme, width, effectiveDensity),
                const SizedBox(height: 10),
                _buildStateBar(theme, width, columns, filtered.length, effectiveDensity),
                const SizedBox(height: 10),
                if (_error != null) _buildErrorBanner(theme),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: _animatedTransitionBuilder,
                  child: (_loading && _displayRepositories.isEmpty)
                      ? _buildLoadingState(key: const ValueKey('loading'))
                      : filtered.isEmpty
                          ? _buildEmptyState(key: const ValueKey('empty'))
                          : SizedBox(
                              key: const ValueKey('content'),
                              child: AnimatedSwitcher(
                                duration: _animateTransitions
                                    ? const Duration(milliseconds: 500)
                                    : Duration.zero,
                                transitionBuilder: _animateTransitions
                                    ? _animatedTransitionBuilder
                                    : AnimatedSwitcher.defaultTransitionBuilder,
                                child: switch (_layoutMode) {
                                  LayoutMode.grid => _buildGrid(
                                      filtered, columns, effectiveDensity,
                                      key: ValueKey(_animateTransitions ? 'grid-$columns' : 'grid'),
                                    ),
                                  LayoutMode.masonry => _buildMasonry(
                                      filtered, columns, effectiveDensity,
                                      key: ValueKey(_animateTransitions ? 'masonry-$columns' : 'masonry'),
                                    ),
                                  LayoutMode.list => _buildList(
                                      filtered, effectiveDensity,
                                      key: ValueKey(_animateTransitions ? 'list-$columns' : 'list'),
                                    ),
                                },
                              ),
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _animatedTransitionBuilder(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }

  Widget _buildControls(ThemeData theme, double width, DensityMode effectiveDensity) {
    final compact = !_controlsExpanded;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, compact ? 10 : 16, 16, compact ? 10 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _controlsExpanded = !_controlsExpanded),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 0 : 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuration',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (_controlsExpanded) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Tap to collapse sources, network, filter, sort, and layout.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (compact)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        'Collapsed',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Icon(
                    _controlsExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (_controlsExpanded) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adjust Columns',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Manual target columns',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SegmentedButton<LayoutMode>(
                  segments: const [
                    ButtonSegment(value: LayoutMode.grid, label: Text('Grid'), icon: Icon(Icons.grid_view_rounded)),
                    ButtonSegment(value: LayoutMode.masonry, label: Text('Masonry'), icon: Icon(Icons.view_week_rounded)),
                    ButtonSegment(value: LayoutMode.list, label: Text('List'), icon: Icon(Icons.view_agenda_rounded)),
                  ],
                  selected: {_layoutMode},
                  onSelectionChanged: (value) => setState(() => _layoutMode = value.first),
                ),
                SegmentedButton<DensityMode>(
                  segments: const [
                    ButtonSegment(value: DensityMode.five, label: Text('5')),
                    ButtonSegment(value: DensityMode.four, label: Text('4')),
                    ButtonSegment(value: DensityMode.three, label: Text('3')),
                    ButtonSegment(value: DensityMode.two, label: Text('2')),
                    ButtonSegment(value: DensityMode.one, label: Text('1')),
                  ],
                  selected: {effectiveDensity},
                  onSelectionChanged: (value) => setState(() {
                    _densityMode = value.first;
                    _autoColumns = false;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<SortMode>(
                  value: _sortMode,
                  items: const [
                    DropdownMenuItem(value: SortMode.updated, child: Text('Sort: Updated')),
                    DropdownMenuItem(value: SortMode.stars, child: Text('Sort: Stars')),
                    DropdownMenuItem(value: SortMode.name, child: Text('Sort: Name')),
                    DropdownMenuItem(value: SortMode.natural, child: Text('Sort: Natural (Arrival)')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _sortMode = value);
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_stories_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Page Size: ',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        width: 40,
                        height: 28,
                        child: TextField(
                          controller: _pageSizeController,
                          focusNode: _pageSizeFocusNode,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                            ),
                          ),
                          onSubmitted: _commitPageSize,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Decrease (Min 1)',
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _pageSize <= 1
                            ? null
                            : () {
                                setState(() {
                                  _pageSize--;
                                  _pageSizeController.text = '$_pageSize';
                                });
                              },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Increase (Max 100)',
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _pageSize >= 100
                            ? null
                            : () {
                                setState(() {
                                  _pageSize++;
                                  _pageSizeController.text = '$_pageSize';
                                });
                              },
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: _autoColumns,
                      onChanged: (value) => setState(() {
                        _autoColumns = value;
                        if (value) {
                          _densityMode = DensityMode.fromColumnCount(_columnCount(width));
                        }
                      }),
                    ),
                    const SizedBox(width: 6),
                    const Text('Auto columns'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: _animateTransitions,
                      onChanged: (value) => setState(() => _animateTransitions = value),
                    ),
                    const SizedBox(width: 6),
                    const Text('Animate transitions'),
                  ],
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Filter',
                      hintText: 'Search repo name / description',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _loading
                      ? null
                      : () {
                          setState(() => _controlsExpanded = false);
                          _refresh();
                        },
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(_loading ? 'Loading...' : 'Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<int>(
              valueListenable: AppConfigService.instance.changeNotifier,
              builder: (context, _, __) {
                final token = AppConfigService.instance.githubToken.trim();
                final sourcesCount = AppConfigService.instance.sources.length;
                final proxySummary = NetworkProxyService.instance.summary;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            token.isNotEmpty ? Icons.key_rounded : Icons.key_off_rounded,
                            size: 18,
                            color: token.isNotEmpty ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            token.isNotEmpty ? 'Token: 已鉴权 (5,000次/h)' : 'Token: 未配置 (60次/h限制)',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.source_rounded, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text('$sourcesCount 个数据源', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.vpn_lock_rounded, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text('代理: $proxySummary', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () => SettingsDialog.show(context),
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('管理数据源与全局设置'),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_logs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fetch Trace',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    for (final line in _logs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SelectableText(
                          line,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStateBar(ThemeData theme, double width, int columns, int count, DensityMode density) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          Text('Current columns: $columns'),
          Text('Gap: ${density.gap.toStringAsFixed(0)}'),
          Text('Width: ${width.round()}px'),
          Text('Range: ${_widthBucket(width)}'),
          Text('Layout: ${_layoutMode.name}'),
          Text(_autoColumns ? 'Adaptive columns: on' : 'Adaptive columns: off'),
          Text('Target columns: ${density.columnCount}'),
          Text('Repos: $count'),
          Text(_status),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _error!,
        style: TextStyle(color: theme.colorScheme.onErrorContainer),
      ),
    );
  }

  Widget _buildLoadingState({Key? key}) {
    return StateShell(
      key: key,
      icon: Icons.cloud_download_outlined,
      title: 'Loading repositories',
      subtitle: 'Fetching GitHub data and building the layout...',
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState({Key? key}) {
    return StateShell(
      key: key,
      icon: Icons.inbox_outlined,
      title: 'No repositories to show',
      subtitle: 'Try a different filter or refresh the sources.',
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildGrid(List<GitHubRepositoryItem> items, int columns, DensityMode density, {Key? key}) {
    final gap = density.gap;
    return GridView.builder(
      key: key,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(gap),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        childAspectRatio: columns >= 4 ? 2.2 : 1.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => RepositoryCard(
        key: ValueKey(items[index].id),
        repository: items[index],
        density: density,
        padding: density.cardPadding,
        radius: density.cardRadius,
        delayMs: 20,
        onOpen: () => _openRepository(items[index].htmlUrl),
      ),
    );
  }

  double _estimateCardHeight(GitHubRepositoryItem repo, DensityMode density) {
    double h = 80.0;
    final desc = repo.description;
    if (desc != null && desc.isNotEmpty) {
      final lines = (desc.length / 32).ceil().clamp(1, 4);
      h += lines * 18.0;
    }
    h += 24.0;
    return h;
  }

  Widget _buildMasonry(List<GitHubRepositoryItem> items, int columns, DensityMode density, {Key? key}) {
    final gap = density.gap;
    final buckets = List.generate(columns, (_) => <GitHubRepositoryItem>[]);
    final columnHeights = List.filled(columns, 0.0);

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      int targetCol = 0;
      double minH = columnHeights[0];
      for (var col = 1; col < columns; col++) {
        if (columnHeights[col] < minH) {
          minH = columnHeights[col];
          targetCol = col;
        }
      }
      buckets[targetCol].add(item);
      columnHeights[targetCol] += _estimateCardHeight(item, density) + gap;
    }

    return Padding(
      key: key,
      padding: EdgeInsets.all(gap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(columns, (columnIndex) {
          final columnItems = buckets[columnIndex];
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: columnIndex == columns - 1 ? 0 : gap),
              child: Column(
                children: [
                  for (var i = 0; i < columnItems.length; i++) ...[
                    RepositoryCard(
                      key: ValueKey(columnItems[i].id),
                      repository: columnItems[i],
                      density: density,
                      padding: density.cardPadding,
                      radius: density.cardRadius,
                      delayMs: 20,
                      onOpen: () => _openRepository(columnItems[i].htmlUrl),
                    ),
                    SizedBox(height: gap),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildList(List<GitHubRepositoryItem> items, DensityMode density, {Key? key}) {
    final gap = density.gap;
    return ListView.separated(
      key: key,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(gap),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: gap),
      itemBuilder: (context, index) => RepositoryListTile(
        key: ValueKey(items[index].id),
        repository: items[index],
        density: density,
        delayMs: 20,
        onOpen: () => _openRepository(items[index].htmlUrl),
      ),
    );
  }

  Future<void> _openRepository(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
