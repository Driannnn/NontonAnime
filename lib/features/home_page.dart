import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../models/comment_models.dart';
import '../utils/string_utils.dart';
import '../widgets/common.dart';
import '../models/anime_models.dart';
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
  Widget _buildUserProfileWidget(BuildContext context, {bool asDrawerItem = false}) {
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
            if (userSnapshot.hasData) {
              displayName = userSnapshot.data?.username ??
                  currentUser.email ??
                  'user';
            } else if (userSnapshot.hasError) {
              displayName = 'error';
            }
            
            if (asDrawerItem) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(displayName),
                onTap: () {
                  context.pop(); // Close drawer
                  context.go('/profile');
                },
              );
            }

            return Row(
              children: [
                Text(displayName),
                IconButton(
                  icon: const Icon(Icons.person),
                  tooltip: 'Profil',
                  onPressed: () => context.go('/profile'),
                ),
              ],
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
        icon: const Icon(Icons.check_circle_outline),
        tooltip: 'Anime Tamat',
        onPressed: () => context.go('/completed'),
      ),
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
      // Mobile: actions kosong, biarkan drawer di 'leading' (otomatis)
      appBarActions = [];
      appBarLeading = null; // Ini akan membuat AppBar otomatis menampilkan ikon hamburger
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
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: cs.primary,
                  ),
                  child: const Center( 
                    child: Text(
                      'Menu ANIMO', 
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
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
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Anime Tamat'),
                  onTap: () {
                    context.pop(); // Tutup drawer
                    context.go('/completed');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Genre'),
                  onTap: () {
                    context.pop(); // Tutup drawer
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GenreListPage()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('Cari Anime'),
                  onTap: () {
                    context.pop(); // Tutup drawer
                    context.go('/search');
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

          // --- PERUBAHAN DI SINI ---
          // Kita kembalikan ke GridView, tapi ganti 'gridDelegate' nya
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            
            // Ganti dari 'SliverGridDelegateWithFixedCrossAxisCount'
            // menjadi 'SliverGridDelegateWithMaxCrossAxisExtent'
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              // Ini menentukan lebar MAKSIMAL kartu.
              // Flutter akan otomatis menampilkan kolom sebanyak mungkin
              // (misal: 2 di HP sempit, 3 di HP lebar, 5 di tablet, dst.)
              maxCrossAxisExtent: 130.0,
              
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.62, // Rasio ini dari kode asli Anda
            ),
            itemBuilder: (context, i) {
              final it = items[i];
              final display = AnimeDisplay.fromMap(it);
              return AnimeCard(display: display);
            },
          ),
          // --- PERUBAHAN BERAKHIR DI SINI ---

        ],
      ),
    );
    
  }
}