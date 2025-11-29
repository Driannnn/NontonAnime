import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home_page.dart';
import '../features/anime_detail_page.dart';
import '../features/episode_page.dart';
import '../features/anime_search_page.dart';
import '../features/genre_list_page.dart';
import '../features/genre_results_page.dart';
import '../features/completed_anime_page.dart';
import '../features/user_page.dart';
import '../features/team_page.dart';
import '../features/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  errorPageBuilder: (context, state) {
    return MaterialPage(
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Page not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  },
  routes: [
    // Splash screen - cannot go back from here
    GoRoute(
      path: '/',
      name: 'splash',
      pageBuilder: (context, state) =>
          const MaterialPage(child: SplashScreen()),
    ),

    // Home page - root of main navigation
    GoRoute(
      path: '/home',
      name: 'home',
      pageBuilder: (context, state) => const MaterialPage(child: HomePage()),
    ),

    // Anime detail page
    GoRoute(
      path: '/anime/:animeSlug',
      name: 'animeDetail',
      pageBuilder: (context, state) {
        final animeSlug = state.pathParameters['animeSlug']!;
        final source = state.uri.queryParameters['source'] ?? 'home';
        final genreSlug = state.uri.queryParameters['genreSlug'];
        final genreName = state.uri.queryParameters['genreName'];
        return MaterialPage(
          child: AnimeDetailPage(
            slug: animeSlug,
            source: source,
            genreSlug: genreSlug,
            genreName: genreName,
          ),
        );
      },
    ),

    // Episode/Stream page
    GoRoute(
      path: '/episode/:episodeSlug',
      name: 'episode',
      pageBuilder: (context, state) {
        final episodeSlug = state.pathParameters['episodeSlug']!;
        final titleFallback = state.uri.queryParameters['title'];
        final animeImage = state.uri.queryParameters['animeImage'];
        return MaterialPage(
          child: EpisodePage(
            episodeSlug: episodeSlug,
            titleFallback: titleFallback,
            animeImageUrl: animeImage,
          ),
        );
      },
    ),

    // Search page
    GoRoute(
      path: '/search',
      name: 'search',
      pageBuilder: (context, state) {
        return const MaterialPage(child: AnimeSearchPage());
      },
    ),

    // Genre list page
    GoRoute(
      path: '/genre',
      name: 'genreList',
      pageBuilder: (context, state) =>
          const MaterialPage(child: GenreListPage()),
    ),

    // Genre results page
    GoRoute(
      path: '/genre/:genreSlug',
      name: 'genre',
      pageBuilder: (context, state) {
        final genreSlug = state.pathParameters['genreSlug']!;
        final genreName = state.uri.queryParameters['name'] ?? genreSlug;
        final source = state.uri.queryParameters['source'];
        final animeSlug = state.uri.queryParameters['animeSlug'];
        return MaterialPage(
          child: GenreAnimePage(
            genreSlug: genreSlug,
            genreName: genreName,
            source: source,
            animeSlug: animeSlug,
          ),
        );
      },
    ),

    // Completed anime page
    GoRoute(
      path: '/completed',
      name: 'completed',
      pageBuilder: (context, state) =>
          const MaterialPage(child: CompletedAnimePage()),
    ),

    // User/Profile page
    GoRoute(
      path: '/profile',
      name: 'profile',
      pageBuilder: (context, state) => const MaterialPage(child: UserPage()),
    ),

    // Team page
    GoRoute(
      path: '/team',
      name: 'team',
      pageBuilder: (context, state) => const MaterialPage(child: TeamPage()),
    ),
  ],
);
