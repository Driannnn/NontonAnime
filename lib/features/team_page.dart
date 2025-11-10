import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
          onPressed: () => context.push('/home'),
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
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                children: [
                  const Icon(
                    Icons.groups,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Meet Our Team',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '8 Orang hebat di balik proyek ini',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Team Members Section
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: const [
                    TeamMemberCard(
                      name: 'User 1',
                      role: 'Mobile Developer',
                      description: 'Spesialis dalam pengembangan aplikasi mobile dengan Flutter dan React Native',
                      icon: Icons.code,
                      color: Colors.deepPurple,
                      initial: 'U1',
                    ),
                    SizedBox(height: 16),
                    TeamMemberCard(
                      name: 'User 2',
                      role: 'UI/UX Designer',
                      description: 'Menciptakan pengalaman pengguna yang intuitif dan desain yang menarik',
                      icon: Icons.palette,
                      color: Colors.pink,
                      initial: 'U2',
                    ),
                    SizedBox(height: 16),
                    TeamMemberCard(
                      name: 'User 3',
                      role: 'Project Manager',
                      description: 'Mengelola timeline proyek dan memastikan tim bekerja dengan efisien',
                      icon: Icons.business_center,
                      color: Colors.teal,
                      initial: 'U3',
                    ),
                    SizedBox(height: 16),
                    TeamMemberCard(
                      name: 'User 4',
                      role: 'Backend Developer',
                      description: 'Membangun dan mengelola server, database, dan API yang robust',
                      icon: Icons.storage,
                      color: Colors.orange,
                      initial: 'U4',
                    ),
                    SizedBox(height: 16),
                    TeamMemberCard(
                      name: 'User 5',
                      role: 'Frontend Developer',
                      description: 'Mengembangkan antarmuka web yang responsive dan interaktif',
                      icon: Icons.web,
                      color: Colors.blue,
                      initial: 'U5',
                    ),
                    SizedBox(height: 16),
                    TeamMemberCard(
                      name: 'User 6',
                      role: 'QA Engineer',
                      description: 'Memastikan kualitas aplikasi dengan testing yang menyeluruh',
                      icon: Icons.bug_report,
                      color: Colors.red,
                      initial: 'U6',
                    ),
                    SizedBox(height: 16),
                    TeamMemberCard(
                      name: 'User 7',
                      role: 'DevOps Engineer',
                      description: 'Menangani deployment, CI/CD, dan infrastruktur cloud',
                      icon: Icons.cloud_upload,
                      color: Colors.green,
                      initial: 'U7',
                    ),
                    SizedBox(height: 16),
                    TeamMemberCard(
                      name: 'User 8',
                      role: 'Data Analyst',
                      description: 'Menganalisis data untuk insight dan pengambilan keputusan',
                      icon: Icons.analytics,
                      color: Colors.indigo,
                      initial: 'U8',
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeamMemberCard extends StatelessWidget {
  const TeamMemberCard({
    super.key,
    required this.name,
    required this.role,
    required this.description,
    required this.icon,
    required this.color,
    required this.initial,
  });

  final String name;
  final String role;
  final String description;
  final IconData icon;
  final Color color;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Section
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          role,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}