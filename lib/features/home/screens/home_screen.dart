import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/auth_service.dart';
import '../../history/screens/match_history_screen.dart';
import '../../match/screens/join_match_screen.dart';
import '../../match/screens/start_match_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              AuthService.signOut();
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  PageRoute<T> _buildPageRoute<T>(BuildContext context, Widget page) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoPageRoute(builder: (_) => page);
    }
    return MaterialPageRoute(builder: (_) => page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(),
                child: Text('CricScore', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Match History'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    _buildPageRoute(context, const MatchHistoryScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Contact'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Contact'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Siddhesh Dhondalkar'),
                          SizedBox(height: 8),
                          Text('siddheshdhondalkar.iitkgp@gmail.com'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share App'),
                onTap: () {
                  Navigator.pop(context);
                  Share.share(
                    'Check out CricScore — a realtime cricket scoring app. Join matches with a code and score live games together!',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Developers'),
                onTap: () {
                  Navigator.pop(context);
                  showAboutDialog(
                    context: context,
                    applicationName: 'CricScore',
                    applicationVersion: '0.1.0',
                    children: const [Text('Developed by the CricScore team.')],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text("Cricket Scoring"),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.background.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.secondary.withOpacity(0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                            CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
                          ),
                          child: const Text(
                            "🏏",
                            style: TextStyle(fontSize: 80),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "CricScore",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Live Cricket Scoring",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Real-time scoring for gully cricket",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _ActionButton(
                    icon: CupertinoIcons.play_fill,
                    title: "Start Match",
                    subtitle: "Host a new match",
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        _buildPageRoute(context, const StartMatchScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _ActionButton(
                    icon: CupertinoIcons.person_add,
                    title: "Join Match",
                    subtitle: "Enter match code",
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.push(
                        context,
                        _buildPageRoute(context, const JoinMatchScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1200),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _ActionButton(
                    icon: CupertinoIcons.clock_solid,
                    title: "Match History",
                    subtitle: "View past matches",
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        _buildPageRoute(context, const MatchHistoryScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) {
        _hoverController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _hoverController.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.96).animate(
          CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.15),
                widget.color.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                color: widget.color.withOpacity(0.6),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
