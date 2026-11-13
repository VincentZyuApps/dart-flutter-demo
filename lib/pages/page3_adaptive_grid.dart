import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/page3_enums.dart';
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
  static const _defaultSources = <String>[
    'https://github.com/VincentZyu233?tab=repositories',
    'https://github.com/orgs/VincentZyuApps/repositories',
    'https://github.com/VincentZyuLive?tab=repositories',
  ];

  final _service = GitHubRepositoryService();
  final _searchController = TextEditingController();
  final List<TextEditingController> _sourceControllers = [];

  LayoutMode _layoutMode = LayoutMode.masonry;
  DensityMode _densityMode = DensityMode.three;
  SortMode _sortMode = SortMode.updated;
  int _pageSize = 25;
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
    for (final source in _defaultSources) {
      _sourceControllers.add(TextEditingController(text: source));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _staggerTimer?.cancel();
    _searchController.dispose();
    for (final controller in _sourceControllers) {
      controller.dispose();
    }
    super.dispose();
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
                'Loaded ${_displayRepositories.length} repositories from ${_sourceControllers.length} sources';
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

    final sources = _sourceControllers
        .map((c) => c.text.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    if (sources.isEmpty) {
      setState(() {
        _error = 'Add at least one GitHub repositories page.';
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

  void _addSource([String initialUrl = '']) {
    setState(() {
      _sourceControllers.add(TextEditingController(text: initialUrl));
    });
  }

  List<GitHubRepositoryItem> get _filteredRepositories {
    final query = _searchController.text.trim().toLowerCase();
    final sorted = _sortRepositories(_displayRepositories);
    if (query.isEmpty) return sorted;
    return sorted.where((repo) {
      return repo.name.toLowerCase().contains(query) ||
          repo.fullName.toLowerCase().contains(query) ||
          (repo.description ?? '').toLowerCase().contains(query) ||
          (repo.language ?? '').toLowerCase().contains(query);
    }).toList();
  }

  List<GitHubRepositoryItem> _sortRepositories(List<GitHubRepositoryItem> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      return switch (_sortMode) {
        SortMode.updated => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        SortMode.stars => b.stars.compareTo(a.stars),
        SortMode.name => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      };
    });
    return sorted;
  }

  void _removeSource(int index) {
    if (_sourceControllers.length <= 1) return;
    setState(() {
      _sourceControllers.removeAt(index).dispose();
    });
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
                        'Page Size: $_pageSize',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
                            : () => setState(() => _pageSize--),
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
                            : () => setState(() => _pageSize++),
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
                  onPressed: _loading ? null : _refresh,
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
            _buildSourceTable(theme),
            const SizedBox(height: 12),
            ValueListenableBuilder<ProxyMode>(
              valueListenable: NetworkProxyService.instance.modeNotifier,
              builder: (context, mode, _) {
                final summary = NetworkProxyService.instance.summary;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.vpn_lock_rounded, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '网络代理: $summary (已接管全局)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => SettingsDialog.show(context),
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('设置'),
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

  Widget _buildSourceTable(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Source URL')),
                DataColumn(label: Text('Kind')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('')),
              ],
              rows: List.generate(_sourceControllers.length, (index) {
                final controller = _sourceControllers[index];
                final parsed = _tryParseSource(controller.text.trim());
                final status = parsed == null
                    ? 'Invalid'
                    : parsed.kind == GitHubRepositorySourceKind.user
                        ? 'User'
                        : 'Org';
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 360,
                        child: TextField(
                          controller: controller,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: switch (index) {
                              0 => 'https://github.com/VincentZyu233?tab=repositories',
                              1 => 'https://github.com/orgs/VincentZyuApps/repositories',
                              _ => 'https://github.com/VincentZyuLive?tab=repositories',
                            },
                            errorText: controller.text.trim().isEmpty || parsed != null
                                ? null
                                : 'Invalid GitHub repositories page',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(status)),
                    DataCell(Text(parsed?.label ?? '-')),
                    DataCell(
                      IconButton(
                        tooltip: 'Remove source',
                        onPressed: _sourceControllers.length <= 1 ? null : () => _removeSource(index),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _addSource(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('添加数据源 (Add Source)'),
                ),
                TextButton.icon(
                  onPressed: () {
                    for (final c in _sourceControllers) {
                      c.dispose();
                    }
                    _sourceControllers.clear();
                    for (final s in _defaultSources) {
                      _sourceControllers.add(TextEditingController(text: s));
                    }
                    setState(() {});
                  },
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text('恢复预设三大源'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  GitHubRepositorySource? _tryParseSource(String value) {
    try {
      return _service.parseSource(value);
    } catch (_) {
      return null;
    }
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

  Widget _buildMasonry(List<GitHubRepositoryItem> items, int columns, DensityMode density, {Key? key}) {
    final gap = density.gap;
    final buckets = List.generate(columns, (_) => <GitHubRepositoryItem>[]);
    for (var i = 0; i < items.length; i++) {
      buckets[i % columns].add(items[i]);
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
