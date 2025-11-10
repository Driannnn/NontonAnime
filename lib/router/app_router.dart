import 'package:go_router/go_router.dart';
import '../features/home_page.dart';
import '../features/anime_detail_page.dart';
import '../features/episode_page.dart';
import '../features/anime_search_page.dart';
import '../features/genre_results_page.dart';
import '../features/completed_anime_page.dart';
import '../features/user_page.dart';
import '../features/team_page.dart';
import '../features/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Splash screen
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Home page
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),

    // Anime detail page
    GoRoute(
      path: '/anime/:animeSlug',
      name: 'animeDetail',
      builder: (context, state) {
        final animeSlug = state.pathParameters['animeSlug']!;
        final source = state.uri.queryParameters['source'] ?? 'home';
        final genreSlug = state.uri.queryParameters['genreSlug'];
        final genreName = state.uri.queryParameters['genreName'];
        return AnimeDetailPage(
          slug: animeSlug,
          source: source,
          genreSlug: genreSlug,
          genreName: genreName,
        );
      },
    ),

    // Episode/Stream page
    GoRoute(
      path: '/episode/:episodeSlug',
      name: 'episode',
      builder: (context, state) {
        final episodeSlug = state.pathParameters['episodeSlug']!;
        final titleFallback = state.uri.queryParameters['title'];
        return EpisodePage(
          episodeSlug: episodeSlug,
          titleFallback: titleFallback,
        );
      },
    ),

    // Search page
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) {
        return const AnimeSearchPage();
      },
    ),

    // Genre results page
    GoRoute(
      path: '/genre/:genreSlug',
      name: 'genre',
      builder: (context, state) {
        final genreSlug = state.pathParameters['genreSlug']!;
        final genreName = state.uri.queryParameters['name'] ?? genreSlug;
        return GenreAnimePage(genreSlug: genreSlug, genreName: genreName);
      },
    ),

    // Completed anime page
    GoRoute(
      path: '/completed',
      name: 'completed',
      builder: (context, state) => const CompletedAnimePage(),
    ),

    // User/Profile page
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const UserPage(),
    ),

    // Team page
    GoRoute(
      path: '/team',
      name: 'team',
      builder: (context, state) => const TeamPage(),
    ),
  ],
);
