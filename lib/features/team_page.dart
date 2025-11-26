import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/footer.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  String searchQuery = '';

  final List<Map<String, dynamic>> teamMembers = [
    {
      'name': 'Ello Adrian Hariadi',
      'role': 'CEO & Co-Founder',
      'description': 'Visionary leader with C2 years in tech innovation and leadership',
      'imageUrl': 'https://avatars.githubusercontent.com/u/144525698?v=4',
      'github': 'https://github.com/Driannnn',
      'instagram': 'https://www.instagram.com/elloadrian/',
    },
    {
      'name': 'Muhammad Dwi Saputra',
      'role': 'VP Engineer',
      'description': 'Expert in AI and cloud systems, recently at Amazon',
      'imageUrl': 'https://avatars.githubusercontent.com/u/200634165?v=4',
      'github': 'https://github.com/POKSI77',
      'instagram': 'https://instagram.com',
    },
    {
      'name': 'Izora Elverda Narulita Putri',
      'role': 'Lead Backend',
      'description': 'Tech-driven solution architect overseeing millions of users globally',
      'imageUrl': 'https://avatars.githubusercontent.com/u/208224160?v=4',
      'github': 'https://github.com/Elverda',
      'instagram': 'https://www.instagram.com/elverdaputri/',
    },
    {
      'name': 'Hanna Maulidhea',
      'role': 'Product Lead',
      'description': 'Passionate about building exceptional products that solve real problems',
      'imageUrl': 'https://avatars.githubusercontent.com/u/207872670?v=4',
      'github': 'https://github.com/maulidhea',
      'instagram': 'https://www.instagram.com/hmaulidheaa/',
    },
    {
      'name': 'Najwa Chava Safiera',
      'role': 'Lead Architect',
      'description': 'Full-stack engineer expert focused on performance and design',
      'imageUrl': 'https://avatars.githubusercontent.com/u/181125174?v=4',
      'github': 'https://github.com/sh3vaya',
      'instagram': 'https://www.instagram.com/zoxrgx/',
    },
    {
      'name': 'Muhammad Dzikri Azkia Ridwani',
      'role': 'Security Director',
      'description': 'Strategic visionary driving growth through data and innovation',
      'imageUrl': 'https://avatars.githubusercontent.com/u/208134601?v=4',
      'github': 'https://github.com/azzkiaa',
      'instagram': 'https://www.instagram.com/azk_ia.r/',
    },
    {
      'name': 'Muhammad Dzacky Maulana Yahya',
      'role': 'CTO',
      'description': 'Transforming complex data into actionable insights for better decision making',
      'imageUrl': 'https://avatars.githubusercontent.com/u/207881192?v=4',
      'github': 'https://github.com/LofeYN',
      'instagram': 'https://www.instagram.com/mflofee/',
    },
    {
      'name': 'Eka Verarina',
      'role': 'UI/UX Designer',
      'description': 'Merancang pengalaman dan tampilan sebuah aplikasi atau website agar mudah digunakan, menarik, dan sesuai kebutuhan pengguna.',
      'imageUrl': 'https://avatars.githubusercontent.com/u/201080417?v=4',
      'github': 'https://github.com/kaekka',
      'instagram': 'https://www.instagram.com/e.verra_/',
    },
  ];

  List<Map<String, dynamic>> getFilteredTeam() {
    if (searchQuery.isEmpty) return teamMembers;
    return teamMembers
        .where((member) =>
            member['name']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
            member['role']!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width < 1000;
    final filteredMembers = getFilteredTeam();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tim Kami',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue.shade700,
                    Colors.blue.shade500,
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 20 : 24,
                isMobile ? 16 : 24,
                isMobile ? 32 : 48,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.groups,
                    size: isMobile ? 48 : 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Meet Our Team',
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tim kami terdiri dari individu-individu dengan keahlian di bidang teknologi dan desain yang saling melengkapi. Setiap anggota memiliki peran khusus mulai dari analisis kebutuhan, perancangan UI/UX, pengembangan sistem, hingga pengujian produk. Dengan latar belakang akademik dan pengalaman yang beragam, kami berkomitmen untuk berkolaborasi secara efektif guna menghasilkan solusi digital yang inovatif, fungsional, dan tepat sasaran.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search team members...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),

            // Team Members Section - Responsive Grid
            Transform.translate(
              offset: const Offset(0, -12),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
                    final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 12) / crossAxisCount;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var member in filteredMembers)
                          SizedBox(
                            width: isMobile ? double.infinity : itemWidth,
                            child: TeamMemberCard(
                              name: member['name']!,
                              role: member['role']!,
                              description: member['description']!,
                              imageUrl: member['imageUrl']!,
                              githubUrl: member['github'] as String?,
                              instagramUrl: member['instagram'] as String?,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),

            if (filteredMembers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No team members found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 24),

            // Call To Action Section - More Ways to Connect
            Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(
                isMobile ? 16.0 : 60.0,
                24.0,
                isMobile ? 16.0 : 60.0,
                24.0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade600,
                    Colors.blue.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20.0 : 50.0,
                vertical: isMobile ? 30.0 : 50.0,
              ),
              child: Column(
                children: [
                  Text(
                    'More Ways to Connect',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We would love to hear from you. Whether you have a question about our services,\nneed support, or just want to chat, we\'re here to help.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 50),
                  // Contact Options Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemsPerRow = isMobile ? 2 : 4;
                      final spacing = isMobile ? 20.0 : 30.0;
                      final itemWidth = (constraints.maxWidth - (itemsPerRow - 1) * spacing) / itemsPerRow;
                      
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          _buildContactOption(
                            width: itemWidth,
                            icon: Icons.phone,
                            title: 'Call our sales team',
                            subtitle: '-',
                            onTap: () {},
                          ),
                          _buildContactOption(
                            width: itemWidth,
                            icon: Icons.email,
                            title: 'Email us',
                            subtitle: '-',
                            onTap: () {},
                          ),
                          _buildContactOption(
                            width: itemWidth,
                            icon: Icons.chat,
                            title: 'Live chat support',
                            subtitle: '-',
                            onTap: () {},
                          ),
                          _buildContactOption(
                            width: itemWidth,
                            icon: Icons.location_on,
                            title: 'Visit our office',
                            subtitle: 'UNESA Kampus 5',
                            onTap: () async {
                              final Uri url = Uri.parse('https://maps.app.goo.gl/WFDtvPUjybTMzCBs8');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Footer
            const AnimoFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required double width,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: _ContactOptionWidget(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }
}

class _ContactOptionWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactOptionWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_ContactOptionWidget> createState() => _ContactOptionWidgetState();
}

class _ContactOptionWidgetState extends State<_ContactOptionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade600,
                    border: Border.all(
                      color: Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      if (_isHovered)
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCTAButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedCTAButton({required this.onPressed});

  @override
  State<_AnimatedCTAButton> createState() => _AnimatedCTAButtonState();
}

class _AnimatedCTAButtonState extends State<_AnimatedCTAButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton(
        onPressed: () {
          _animationController.forward().then((_) {
            _animationController.reverse();
          });
          widget.onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue.shade700,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'View Open Positions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class TeamMemberCard extends StatefulWidget {
  final String name;
  final String role;
  final String description;
  final String imageUrl;
  final String? githubUrl;
  final String? instagramUrl;

  const TeamMemberCard({
    super.key,
    required this.name,
    required this.role,
    required this.description,
    required this.imageUrl,
    this.githubUrl,
    this.instagramUrl,
  });

  @override
  State<TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<TeamMemberCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? 30 : 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Image Section
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  color: Colors.grey.shade200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                      // Hover overlay
                      if (_isHovered)
                        AnimatedOpacity(
                          opacity: _isHovered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            color: Colors.black.withOpacity(0.2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.role,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Social Icons with animation
                    AnimatedOpacity(
                      opacity: _isHovered ? 1.0 : 0.8,
                      duration: const Duration(milliseconds: 300),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _InteractiveSocialIconButton(
                              icon: FontAwesomeIcons.github,
                              label: 'GitHub',
                              url: widget.githubUrl,
                              isHovered: _isHovered,
                            ),
                            const SizedBox(width: 8),
                            _InteractiveSocialIconButton(
                              icon: FontAwesomeIcons.instagram,
                              label: 'Instagram',
                              url: widget.instagramUrl,
                              isHovered: _isHovered,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveSocialIconButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? url;
  final bool isHovered;

  const _InteractiveSocialIconButton({
    required this.icon,
    required this.label,
    required this.url,
    required this.isHovered,
  });

  @override
  State<_InteractiveSocialIconButton> createState() =>
      _InteractiveSocialIconButtonState();
}

class _InteractiveSocialIconButtonState
    extends State<_InteractiveSocialIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.label} belum dikonfigurasi'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }
    
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak bisa membuka ${widget.label}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
        _launchUrl(widget.url);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: MouseRegion(
          onEnter: (_) => _animationController.forward(),
          onExit: (_) => _animationController.reverse(),
          child: Tooltip(
            message: widget.label,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                boxShadow: [
                  if (widget.isHovered)
                    BoxShadow(
                      color: Colors.blue.shade700.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Center(
                child: FaIcon(
                  widget.icon,
                  size: 14,
                  color: widget.isHovered ? Colors.blue.shade700 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
 }