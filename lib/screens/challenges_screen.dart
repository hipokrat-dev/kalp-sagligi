import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/challenge_service.dart';
import '../services/friends_service.dart';
import '../services/auth_service.dart';
import 'challenge_detail_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = ChallengeService.instance;

  List<ChallengeData> _activeChallenges = [];
  List<ChallengeData> _completedChallenges = [];
  final Map<String, List<LeaderboardEntry>> _leaderboards = {};
  bool _loadingActive = true;
  bool _loadingCompleted = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadActive(),
      _loadCompleted(),
    ]);
  }

  Future<void> _loadActive() async {
    final challenges = await _service.getActiveChallenges();
    if (mounted) {
      setState(() {
        _activeChallenges = challenges;
        _loadingActive = false;
      });
      // Load leaderboards for active challenges
      for (final c in challenges) {
        final lb = await _service.getChallengeLeaderboard(c);
        if (mounted) {
          setState(() => _leaderboards[c.id] = lb);
        }
      }
    }
  }

  Future<void> _loadCompleted() async {
    final challenges = await _service.getCompletedChallenges();
    if (mounted) {
      setState(() {
        _completedChallenges = challenges;
        _loadingCompleted = false;
      });
    }
  }

  void _showCreateDialog({List<String>? preSelectedFriendUids}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateChallengeSheet(
        preSelectedFriendUids: preSelectedFriendUids,
        onCreated: () {
          _loadData();
        },
      ),
    );
  }

  void _openDetail(ChallengeData challenge) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChallengeDetailScreen(challenge: challenge),
      ),
    ).then((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Challenge\'lar',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryRed,
            labelColor: AppTheme.primaryRed,
            unselectedLabelColor: AppTheme.textLight,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Aktif'),
                    if (_activeChallenges.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_activeChallenges.length}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Tamamlanan'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(),
          _buildCompletedTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Yeni Challenge',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Active Tab ──

  Widget _buildActiveTab() {
    if (_loadingActive) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
    }

    if (_activeChallenges.isEmpty) {
      return _buildEmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'Aktif challenge yok',
        subtitle: 'Arkadaslarinizla yeni bir challenge\nolusturmak icin + butonuna basin',
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryRed,
      onRefresh: _loadActive,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _activeChallenges.length,
        itemBuilder: (context, index) => _buildActiveChallengeCard(_activeChallenges[index]),
      ),
    );
  }

  Widget _buildActiveChallengeCard(ChallengeData challenge) {
    final gradient = _typeGradient(challenge.type);
    final icon = _typeIcon(challenge.type);
    final leaderboard = _leaderboards[challenge.id] ?? [];
    final remaining = challenge.timeRemaining;

    String timeText;
    if (remaining.inDays > 0) {
      timeText = '${remaining.inDays} gun ${remaining.inHours % 24} saat kaldi';
    } else if (remaining.inHours > 0) {
      timeText = '${remaining.inHours} saat ${remaining.inMinutes % 60} dk kaldi';
    } else if (remaining.inMinutes > 0) {
      timeText = '${remaining.inMinutes} dk kaldi';
    } else {
      timeText = 'Bitmek uzere...';
    }

    return GestureDetector(
      onTap: () => _openDetail(challenge),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                challenge.duration == 'daily' ? 'Gunluk' : 'Haftalik',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.timer_outlined, color: Colors.white.withValues(alpha: 0.9), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              timeText,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                ],
              ),
            ),
            // Leaderboard preview (top 3)
            if (leaderboard.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (int i = 0; i < leaderboard.length && i < 3; i++)
                      _buildLeaderboardRow(leaderboard[i], challenge.type),
                    if (leaderboard.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '+${leaderboard.length - 3} daha fazla katilimci',
                          style: GoogleFonts.inter(
                            color: AppTheme.textLight,
                            fontSize: 12,
                          ),
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

  Widget _buildLeaderboardRow(LeaderboardEntry entry, String type) {
    final currentUid = AuthService.instance.currentUserId;
    final isMe = entry.uid == currentUid;
    final medal = switch (entry.rank) {
      1 => '\u{1F947}',
      2 => '\u{1F948}',
      3 => '\u{1F949}',
      _ => '${entry.rank}.',
    };
    final scoreLabel = _scoreLabel(entry.score, type);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.primaryRed.withValues(alpha: 0.06) : AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: isMe ? Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.2)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              medal,
              style: GoogleFonts.inter(fontSize: entry.rank <= 3 ? 18 : 14, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              isMe ? '${entry.name} (Sen)' : entry.name,
              style: GoogleFonts.inter(
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
                color: isMe ? AppTheme.primaryRed : AppTheme.textDark,
              ),
            ),
          ),
          Text(
            scoreLabel,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Completed Tab ──

  Widget _buildCompletedTab() {
    if (_loadingCompleted) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
    }

    if (_completedChallenges.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: 'Tamamlanan challenge yok',
        subtitle: 'Tamamlanan challenge\'lariniz\nburada gorunecek',
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryRed,
      onRefresh: _loadCompleted,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _completedChallenges.length,
        itemBuilder: (context, index) => _buildCompletedChallengeCard(_completedChallenges[index]),
      ),
    );
  }

  Widget _buildCompletedChallengeCard(ChallengeData challenge) {
    final icon = _typeIcon(challenge.type);
    final winner = challenge.winner;

    return GestureDetector(
      onTap: () => _openDetail(challenge),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.textLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: AppTheme.textLight, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${challenge.duration == 'daily' ? 'Gunluk' : 'Haftalik'} \u2022 ${_formatDate(challenge.endDate)}',
                          style: GoogleFonts.inter(
                            color: AppTheme.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Bitti',
                      style: GoogleFonts.inter(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (winner != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700).withValues(alpha: 0.15),
                        const Color(0xFFFFA000).withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text('\u{1F3C6}', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kazanan',
                              style: GoogleFonts.inter(
                                color: AppTheme.textLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              winner['name'] ?? '',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _scoreLabel(winner['score'] ?? 0, challenge.type),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: const Color(0xFFFFA000),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──

  LinearGradient _typeGradient(String type) {
    return switch (type) {
      'steps' => const LinearGradient(
        colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'water' => const LinearGradient(
        colors: [Color(0xFF00ACC1), Color(0xFF26C6DA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'smoking' => const LinearGradient(
        colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      _ => AppTheme.primaryGradient,
    };
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'steps' => Icons.directions_walk_rounded,
      'water' => Icons.water_drop_rounded,
      'smoking' => Icons.smoke_free_rounded,
      _ => Icons.emoji_events_rounded,
    };
  }

  String _scoreLabel(int score, String type) {
    return switch (type) {
      'steps' => _formatNumber(score),
      'water' => '$score gun',
      'smoking' => '$score gun',
      _ => '$score',
    };
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}k';
    return '$number';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppTheme.primaryRed.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: AppTheme.textLight,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Challenge Bottom Sheet ──

class _CreateChallengeSheet extends StatefulWidget {
  final List<String>? preSelectedFriendUids;
  final VoidCallback onCreated;

  const _CreateChallengeSheet({
    this.preSelectedFriendUids,
    required this.onCreated,
  });

  @override
  State<_CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<_CreateChallengeSheet> {
  String _selectedType = 'steps';
  String _selectedDuration = 'daily';
  final _titleController = TextEditingController();
  List<FriendData> _friends = [];
  final Set<String> _selectedFriendUids = {};
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _updateDefaultTitle();
  }

  Future<void> _loadFriends() async {
    final friends = await FriendsService.instance.getFriendsList();
    if (mounted) {
      setState(() {
        _friends = friends;
        _loading = false;
        if (widget.preSelectedFriendUids != null) {
          _selectedFriendUids.addAll(widget.preSelectedFriendUids!);
        }
      });
    }
  }

  void _updateDefaultTitle() {
    final typeLabel = switch (_selectedType) {
      'steps' => 'Adim',
      'water' => 'Su',
      'smoking' => 'Sigara',
      _ => '',
    };
    final durationLabel = _selectedDuration == 'daily' ? 'Gunluk' : 'Haftalik';
    _titleController.text = '$durationLabel $typeLabel Challenge';
  }

  Future<void> _create() async {
    if (_selectedFriendUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('En az bir arkadas secmelisiniz'),
          backgroundColor: AppTheme.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _creating = true);

    final result = await ChallengeService.instance.createChallenge(
      type: _selectedType,
      title: _titleController.text.trim().isEmpty
          ? '${_selectedDuration == 'daily' ? 'Gunluk' : 'Haftalik'} Challenge'
          : _titleController.text.trim(),
      duration: _selectedDuration,
      friendUids: _selectedFriendUids.toList(),
    );

    if (mounted) {
      setState(() => _creating = false);

      if (result.success) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppTheme.primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Yeni Challenge',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 20),

            // Type selector
            Text(
              'Tur',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildTypeCard('steps', 'Adim', Icons.directions_walk_rounded,
                    const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)])),
                const SizedBox(width: 10),
                _buildTypeCard('water', 'Su', Icons.water_drop_rounded,
                    const LinearGradient(colors: [Color(0xFF00ACC1), Color(0xFF26C6DA)])),
                const SizedBox(width: 10),
                _buildTypeCard('smoking', 'Sigara', Icons.smoke_free_rounded,
                    const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF66BB6A)])),
              ],
            ),
            const SizedBox(height: 20),

            // Duration selector
            Text(
              'Sure',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildDurationChip('daily', 'Gunluk'),
                const SizedBox(width: 10),
                _buildDurationChip('weekly', 'Haftalik'),
              ],
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Baslik',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Challenge basligi...',
                hintStyle: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Friend selector
            Text(
              'Arkadaslar',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppTheme.primaryRed),
              ))
            else if (_friends.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Henuz arkadasiniz yok.\nOnce arkadas ekleyin.',
                  style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    final selected = _selectedFriendUids.contains(friend.uid);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedFriendUids.add(friend.uid);
                          } else {
                            _selectedFriendUids.remove(friend.uid);
                          }
                        });
                      },
                      activeColor: AppTheme.primaryRed,
                      title: Text(
                        friend.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                      subtitle: Text(
                        friend.email,
                        style: GoogleFonts.inter(
                          color: AppTheme.textLight,
                          fontSize: 12,
                        ),
                      ),
                      secondary: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      dense: true,
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Create button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _creating ? null : _create,
                child: _creating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Olustur',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(String type, String label, IconData icon, LinearGradient gradient) {
    final selected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedType = type);
          _updateDefaultTitle();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: selected ? gradient : null,
            color: selected ? null : AppTheme.background,
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? null
                : Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)),
            boxShadow: selected ? AppTheme.softShadow(gradient.colors.first) : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : AppTheme.textLight,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? Colors.white : AppTheme.textLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationChip(String duration, String label) {
    final selected = _selectedDuration == duration;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedDuration = duration);
          _updateDefaultTitle();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryRed : AppTheme.background,
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? null
                : Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? Colors.white : AppTheme.textLight,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
