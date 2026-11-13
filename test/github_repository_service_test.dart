import 'package:flutter_test/flutter_test.dart';
import 'package:dart_flutter_demo/services/github_repository_service.dart';

void main() {
  group('GitHubRepositoryService parseSource tests', () {
    final service = GitHubRepositoryService();

    test('parse personal user page', () {
      final source = service.parseSource('https://github.com/VincentZyu233?tab=repositories');
      expect(source.kind, GitHubRepositorySourceKind.user);
      expect(source.handle, 'VincentZyu233');
      expect(source.label, '@VincentZyu233');
    });

    test('parse organization page', () {
      final source = service.parseSource('https://github.com/orgs/VincentZyuApps/repositories');
      expect(source.kind, GitHubRepositorySourceKind.organization);
      expect(source.handle, 'VincentZyuApps');
      expect(source.label, 'VincentZyuApps org');
    });

    test('parse newly added VincentZyuLive without tab query', () {
      final source = service.parseSource('https://github.com/VincentZyuLive');
      expect(source.kind, GitHubRepositorySourceKind.user);
      expect(source.handle, 'VincentZyuLive');
      expect(source.label, '@VincentZyuLive');
    });

    test('parse newly added VincentZyuLive with tab query', () {
      final source = service.parseSource('https://github.com/VincentZyuLive?tab=repositories');
      expect(source.kind, GitHubRepositorySourceKind.user);
      expect(source.handle, 'VincentZyuLive');
      expect(source.label, '@VincentZyuLive');
    });
  });
}
