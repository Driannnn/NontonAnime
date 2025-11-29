import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../models/comment_models.dart';
import '../utils/string_utils.dart';
import '../widgets/common.dart';
import '../models/anime_models.dart';
import '../widgets/carousel_slider.dart';
import '../widgets/paginated_completed_section.dart';
import 'anime_card.dart';
import 'genre_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<Map<String, List<Map<String, dynamic>>>>? _future;
  final AuthService _authService = AuthService();

  // Define breakpoint for adaptive UI
  static const double kMobileBreakpoint = 600.0;

  @override
  void initState() {
    super.initState();
    _future = fetchHome();
  }

  Future<void> _reload() async {
    setState(() => _future = fetchHome());
    await _future;
  }

  // Ekstrak widget profil/user untuk digunakan di actions dan drawer
  Widget _buildUserProfileWidget(
    BuildContext context, {
    bool asDrawerItem = false,
  }) {
    final currentUser = _authService.currentUser;
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (currentUser == null) {
          if (asDrawerItem) {
            return ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profil / Login'),
              onTap: () {
                context.pop(); // Close drawer
                context.go('/profile');
              },
            );
          }
          return Row(
            children: [
              const Text('user'),
              IconButton(
                icon: const Icon(Icons.person_outline),
                tooltip: 'Profil',
                onPressed: () => context.go('/profile'),
              ),
            ],
          );
        }
        return FutureBuilder<AppUser?>(
          future: _authService.getUser(currentUser.uid),
          builder: (context, userSnapshot) {
            String displayName = '...';
            String? profileImage;
            if (userSnapshot.hasData) {
              displayName =
                  userSnapshot.data?.username ?? currentUser.email ?? 'user';
              profileImage = userSnapshot.data?.profileImage;
            } else if (userSnapshot.hasError) {
              displayName = 'error';
            }

            // Helper untuk decode profile image dari base64
            ImageProvider? buildProfileImageProvider(String? imageUrl) {
              if (imageUrl == null || imageUrl.isEmpty) {
                return null;
              }
              try {
                // Handle base64 data URL format: data:image/jpeg;base64,{base64String}
                if (imageUrl.startsWith('data:image')) {
                  final base64String = imageUrl.split(',').last;
                  final bytes = base64Decode(base64String);
                  return MemoryImage(bytes);
                }
                // Fallback untuk URL biasa
                if (imageUrl.startsWith('http')) {
                  return NetworkImage(imageUrl);
                }
                return null;
              } catch (e) {
                return null;
              }
            }

            // Helper untuk build profile avatar
            Widget buildProfileAvatar() {
              return CircleAvatar(
                radius: asDrawerItem ? 30 : 16,
                backgroundColor: Colors.grey[300],
                backgroundImage: buildProfileImageProvider(profileImage),
                child: profileImage == null
                    ? Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: asDrawerItem ? 30 : 16,
                      )
                    : null,
              );
            }

            if (asDrawerItem) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    buildProfileAvatar(),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.pop(); // Close drawer
                        context.go('/profile');
                      },
                      child: const Text('Lihat Profil'),
                    ),
                  ],
                ),
              );
            }

            return GestureDetector(
              onTap: profileImage != null ? () => context.go('/profile') : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(displayName),
                  const SizedBox(width: 8),
                  buildProfileAvatar(),
                  if (profileImage == null)
                    IconButton(
                      icon: const Icon(Icons.person),
                      tooltip: 'Profil',
                      onPressed: () => context.go('/profile'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < kMobileBreakpoint;

    // Aksi Navigasi untuk tampilan lebar (desktop/tablet)
    final List<Widget> desktopNavigationActions = [
      _buildUserProfileWidget(context),
      IconButton(
        icon: const Icon(Icons.category_outlined),
        tooltip: 'Genre',
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const GenreListPage()));
        },
      ),
      IconButton(
        icon: const Icon(Icons.search),
        tooltip: 'Cari Anime',
        onPressed: () => context.go('/search'),
      ),
    ];

    // Aksi Adaptif untuk AppBar
    List<Widget> appBarActions;
    // Leading Adaptif untuk AppBar
    Widget? appBarLeading;

    if (isMobile) {
      // Mobile: search icon di pojok kanan atas
      appBarActions = [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Cari Anime',
          onPressed: () => context.go('/search'),
        ),
      ];
      appBarLeading =
          null; // Ini akan membuat AppBar otomatis menampilkan ikon hamburger
    } else {
      // Desktop: Tampilkan semua aksi navigasi dan ikon 'Tim' di leading
      appBarActions = desktopNavigationActions;
      appBarLeading = IconButton(
        icon: const Icon(Icons.group_outlined),
        tooltip: 'Tim',
        onPressed: () => context.go('/team'),
      );
    }

    // Drawer (Menu Hamburger) hanya untuk tampilan mobile
    final Widget? mobileDrawer = isMobile
        ? Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(
                  height: 60,
                  decoration: BoxDecoration(color: cs.primary),
                  child: const Center(
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                _buildUserProfileWidget(context, asDrawerItem: true),
                ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: const Text('Tim'),
                  onTap: () {
                    context.pop(); // Tutup drawer
                    context.go('/team');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Genre'),
                  onTap: () {
                    context.pop(); // Tutup drawer
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GenreListPage()),
                    );
                  },
                ),
              ],
            ),
          )
        : null;

    return Scaffold(
      backgroundColor: cs.background,
      drawer: mobileDrawer,
      appBar: AppBar(
        leading: appBarLeading,
        title: const Text('ANIMO'),
        actions: appBarActions,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.background, cs.secondary.withOpacity(0.25)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const CenteredLoading();
            }
            if (snap.hasError) {
              return ErrorView(
                message: snap.error.toString(),
                onRetry: _reload,
              );
            }
            final sections = snap.data!;
            final keys = sections.keys.toList();

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final key = keys[index];
                final items = sections[key]!;
                return _Section(title: prettifyKey(key), items: items);
              },
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Deteksi apakah ini section "Ongoing"
    final isOngoing =
        title.toLowerCase().contains('ongoing') ||
        title.toLowerCase().contains('sedang berlangsung');

    // Deteksi apakah ini section "Data Complete Anime"
    final isCompleted =
        title.toLowerCase().contains('complete') ||
        title.toLowerCase().contains('tamat');

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Text(title, style: textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 12),

          // Gunakan PaginatedCompletedSection untuk "complete", carousel untuk "ongoing", grid untuk lainnya
          if (isCompleted)
            PaginatedCompletedSection(title: title)
          else if (isOngoing)
            Transform.translate(
              offset: const Offset(-16, 0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: AnimeCarouselSlider(
                  items: items.map((it) => AnimeDisplay.fromMap(it)).toList(),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 130.0,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemBuilder: (context, i) {
                final it = items[i];
                final display = AnimeDisplay.fromMap(it);
                return AnimeCard(display: display);
              },
            ),
        ],
      ),
    );
  }
}
