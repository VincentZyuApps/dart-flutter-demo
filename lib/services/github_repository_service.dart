import 'dart:convert';
import 'dart:io';

import 'app_config_service.dart';

class GitHubRepositorySource {
  final String rawUrl;
  final GitHubRepositorySourceKind kind;
  final String handle;

  const GitHubRepositorySource({
    required this.rawUrl,
    required this.kind,
    required this.handle,
  });

  String get label => switch (kind) {
        GitHubRepositorySourceKind.user => '@$handle',
        GitHubRepositorySourceKind.organization => '$handle org',
      };
}

enum GitHubRepositorySourceKind {
  user,
  organization,
}

class GitHubRepositoryItem {
  final String id;
  final String name;
  final String fullName;
  final String htmlUrl;
  final String owner;
  final String ownerAvatarUrl;
  final String? description;
  final String? language;
  final int stars;
  final int forks;
  final bool archived;
  final bool isPrivate;
  final DateTime? updatedAt;
  final GitHubRepositorySource source;

  const GitHubRepositoryItem({
    required this.id,
    required this.name,
    required this.fullName,
    required this.htmlUrl,
    required this.owner,
    required this.ownerAvatarUrl,
    required this.description,
    required this.language,
    required this.stars,
    required this.forks,
    required this.archived,
    required this.isPrivate,
    required this.updatedAt,
    required this.source,
  });

  factory GitHubRepositoryItem.fromJson(
    Map<String, dynamic> json,
    GitHubRepositorySource source,
  ) {
    final owner = json['owner'] as Map<String, dynamic>? ?? const {};
    return GitHubRepositoryItem(
      id: (json['id'] ?? json['full_name'] ?? json['html_url']).toString(),
      name: (json['name'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      htmlUrl: (json['html_url'] ?? '').toString(),
      owner: (owner['login'] ?? '').toString(),
      ownerAvatarUrl: (owner['avatar_url'] ?? '').toString(),
      description: (json['description'] as String?)?.trim(),
      language: (json['language'] as String?)?.trim(),
      stars: (json['stargazers_count'] as num?)?.toInt() ?? 0,
      forks: (json['forks_count'] as num?)?.toInt() ?? 0,
      archived: json['archived'] == true,
      isPrivate: json['private'] == true,
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
      source: source,
    );
  }
}

class GitHubRepositoryFetchResult {
  final List<GitHubRepositoryItem> repositories;
  final List<String> logs;

  const GitHubRepositoryFetchResult({
    required this.repositories,
    required this.logs,
  });
}

class GitHubRepositorySourceParseException implements Exception {
  final String message;

  const GitHubRepositorySourceParseException(this.message);

  @override
  String toString() => message;
}

class GitHubRepositoryStreamChunk {
  const GitHubRepositoryStreamChunk({
    required this.newItems,
    required this.source,
    required this.page,
    required this.isSourceDone,
    required this.isAllDone,
    required this.log,
  });

  final List<GitHubRepositoryItem> newItems;
  final GitHubRepositorySource source;
  final int page;
  final bool isSourceDone;
  final bool isAllDone;
  final String log;
}

class GitHubRepositoryService {
  static final RegExp _userPathPattern =
      RegExp(r'^/([A-Za-z0-9](?:[A-Za-z0-9-]{0,38}))/?$');
  static final RegExp _orgPathPattern =
      RegExp(r'^/orgs/([A-Za-z0-9](?:[A-Za-z0-9-]{0,38}))/repositories/?$');

  GitHubRepositorySource parseSource(String rawUrl) {
    final trimmed = rawUrl.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.toLowerCase() != 'github.com') {
      throw const GitHubRepositorySourceParseException(
        'Only GitHub repository pages are allowed.',
      );
    }

    final orgMatch = _orgPathPattern.firstMatch(uri.path);
    if (orgMatch != null) {
      return GitHubRepositorySource(
        rawUrl: trimmed,
        kind: GitHubRepositorySourceKind.organization,
        handle: orgMatch.group(1)!,
      );
    }

    final userMatch = _userPathPattern.firstMatch(uri.path);
    final tab = uri.queryParameters['tab'];
    if (userMatch != null && (tab == null || tab == 'repositories')) {
      return GitHubRepositorySource(
        rawUrl: trimmed,
        kind: GitHubRepositorySourceKind.user,
        handle: userMatch.group(1)!,
      );
    }

    throw const GitHubRepositorySourceParseException(
      'Use a personal repositories page or an organization repositories page.',
    );
  }

  Stream<GitHubRepositoryStreamChunk> fetchRepositoriesStream({
    required List<String> sourceUrls,
    int pageSize = 25,
    bool? useProxy,
    String? proxyUrl,
  }) async* {
    final effectivePageSize = pageSize.clamp(1, 100);
    final parsedSources = <GitHubRepositorySource>[];
    for (final sourceUrl in sourceUrls) {
      parsedSources.add(parseSource(sourceUrl));
    }

    final client = HttpClient();
    if (useProxy == true && proxyUrl != null && proxyUrl.trim().isNotEmpty) {
      final proxy = Uri.tryParse(proxyUrl.trim());
      if (proxy == null || proxy.host.isEmpty || proxy.port <= 0) {
        throw const GitHubRepositorySourceParseException(
          'Proxy URL is invalid.',
        );
      }
      client.findProxy = (_) => 'PROXY ${proxy.host}:${proxy.port}';
      yield GitHubRepositoryStreamChunk(
        newItems: const [],
        source: parsedSources.first,
        page: 0,
        isSourceDone: false,
        isAllDone: false,
        log: 'Proxy enabled: ${proxy.scheme}://${proxy.host}:${proxy.port}',
      );
    } else if (useProxy == false) {
      client.findProxy = (_) => 'DIRECT';
      yield GitHubRepositoryStreamChunk(
        newItems: const [],
        source: parsedSources.first,
        page: 0,
        isSourceDone: false,
        isAllDone: false,
        log: 'Proxy disabled (forced direct).',
      );
    } else {
      yield GitHubRepositoryStreamChunk(
        newItems: const [],
        source: parsedSources.first,
        page: 0,
        isSourceDone: false,
        isAllDone: false,
        log: 'Using global network proxy configuration.',
      );
    }

    final configuredToken = AppConfigService.instance.githubToken.trim();
    yield GitHubRepositoryStreamChunk(
      newItems: const [],
      source: parsedSources.first,
      page: 0,
      isSourceDone: false,
      isAllDone: false,
      log: configuredToken.isNotEmpty
          ? 'GitHub Token: Authenticated (5,000 req/hr quota)'
          : 'GitHub Token: Not configured (60 req/hr anonymous limit)',
    );

    try {
      for (var sIdx = 0; sIdx < parsedSources.length; sIdx++) {
        final source = parsedSources[sIdx];
        final isLastSource = sIdx == parsedSources.length - 1;

        yield GitHubRepositoryStreamChunk(
          newItems: const [],
          source: source,
          page: 0,
          isSourceDone: false,
          isAllDone: false,
          log: 'Fetching ${source.rawUrl}',
        );

        for (var page = 1; page <= 5; page++) {
          final uri = switch (source.kind) {
            GitHubRepositorySourceKind.user => Uri.https(
                'api.github.com',
                '/users/${source.handle}/repos',
                <String, String>{
                  'type': 'owner',
                  'sort': 'updated',
                  'per_page': '$effectivePageSize',
                  'page': '$page',
                },
              ),
            GitHubRepositorySourceKind.organization => Uri.https(
                'api.github.com',
                '/orgs/${source.handle}/repos',
                <String, String>{
                  'type': 'public',
                  'sort': 'updated',
                  'per_page': '$effectivePageSize',
                  'page': '$page',
                },
              ),
          };

          final request = await client.getUrl(uri);
          request.headers.set(
            HttpHeaders.acceptHeader,
            'application/vnd.github+json',
          );
          request.headers.set(
            HttpHeaders.userAgentHeader,
            'dart_flutter_demo/0.2',
          );
          request.headers.set('X-GitHub-Api-Version', '2022-11-28');

          final token = AppConfigService.instance.githubToken.trim();
          if (token.isNotEmpty) {
            request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
          }

          final response = await request.close();
          final body = await utf8.decodeStream(response);
          if (response.statusCode < 200 || response.statusCode >= 300) {
            throw HttpException(
              'GitHub API request failed (${response.statusCode}) for ${source.handle}: $body',
              uri: uri,
            );
          }

          final json = jsonDecode(body);
          if (json is! List) {
            throw HttpException(
              'GitHub API returned an unexpected payload.',
              uri: uri,
            );
          }

          final pageItems = json
              .whereType<Map>()
              .map((item) => GitHubRepositoryItem.fromJson(
                    Map<String, dynamic>.from(item),
                    source,
                  ))
              .toList();

          final isSourceDone =
              pageItems.length < effectivePageSize || page == 5;
          final isAllDone = isLastSource && isSourceDone;

          yield GitHubRepositoryStreamChunk(
            newItems: pageItems,
            source: source,
            page: page,
            isSourceDone: isSourceDone,
            isAllDone: isAllDone,
            log:
                'Loaded ${pageItems.length} repos from ${source.label} (Page $page)',
          );

          if (isSourceDone) {
            break;
          }
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<GitHubRepositoryFetchResult> fetchRepositories({
    required List<String> sourceUrls,
    int pageSize = 25,
    bool? useProxy,
    String? proxyUrl,
  }) async {
    final allRepositories = <GitHubRepositoryItem>[];
    final logs = <String>[];

    await for (final chunk in fetchRepositoriesStream(
      sourceUrls: sourceUrls,
      pageSize: pageSize,
      useProxy: useProxy,
      proxyUrl: proxyUrl,
    )) {
      logs.add(chunk.log);
      allRepositories.addAll(chunk.newItems);
    }

    final deduped = <String, GitHubRepositoryItem>{};
    for (final repository in allRepositories) {
      deduped[repository.id] = repository;
    }

    return GitHubRepositoryFetchResult(
      repositories: deduped.values.toList(),
      logs: logs,
    );
  }
}
