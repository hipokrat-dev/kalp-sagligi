import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/challenge_service.dart';
import '../services/auth_service.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final ChallengeData challenge;

  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final _service = ChallengeService.instance;
  List<LeaderboardEntry> _leaderboard = [];
  bool _loading = true;

  ChallengeData get challenge => widget.challenge;
  String? get _currentUid => AuthService.instance.currentUserId;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final lb = await _service.getChallengeLeaderboard(challenge);
    if (mounted) {
      setState(() {
        _leaderboard = lb;
        _loading = false;
      });
    }
  }

  Future<void> _leaveChallenge() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Challenge\'dan Ayril',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bu challenge\'dan ayrilmak istediginize emin misiniz?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Iptal', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: Text('Ayril', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final result = await _service.leaveChallenge(challenge.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : AppTheme.primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        if (result.success) Navigator.pop(context);
      }
    }
  }

  Future<void> _deleteChallenge() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Challenge\'i Sil',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bu challenge tamamen silinecek. Emin misiniz?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Iptal', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: Text('Sil', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final result = await _service.deleteChallenge(challenge.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : AppTheme.primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        if (result.success) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _typeGradient(challenge.type);
    final icon = _typeIcon(challenge.type);
    final isCreator = challenge.createdBy == _currentUid;
    final isCompleted = challenge.status == 'completed';

    final remaining = challenge.timeRemaining;
    String timeText;
    if (isCompleted) {
      timeText = 'Tamamlandi';
    } else if (remaining.inDays > 0) {
      timeText = '${remaining.inDays} gun ${remaining.inHours % 24} saat kaldi';
    } else if (remaining.inHours > 0) {
      timeText = '${remaining.inHours} saat ${remaining.inMinutes % 60} dk kaldi';
    } else if (remaining.inMinutes > 0) {
      timeText = '${remaining.inMinutes} dk kaldi';
    } else {
      timeText = 'Bitmek uzere...';
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: gradient.colors.first,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: gradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: Colors.white, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                challenge.title,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                challenge.duration == 'daily' ? 'Gunluk' : 'Haftalik',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              isCompleted ? Icons.check_circle_outline : Icons.timer_outlined,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeText,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Winner banner (if completed)
          if (isCompleted && challenge.winner != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700).withValues(alpha: 0.18),
                      const Color(0xFFFFA000).withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    const Text('\u{1F3C6}', style: TextStyle(fontSize: 36)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kazanan!',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFFA000),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            challenge.winner!['name'] ?? '',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          _scoreLabel(challenge.winner!['score'] ?? 0, challenge.type),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: const Color(0xFFFFA000),
                          ),
                        ),
                        Text(
                          _scoreUnit(challenge.type),
                          style: GoogleFonts.inter(
                            color: AppTheme.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Leaderboard header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Siralama',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ),

          // Leaderboard
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
              ),
            )
          else if (_leaderboard.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'Henuz veri yok',
                    style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 14),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = _leaderboard[index];
                  return _buildLeaderboardTile(entry);
                },
                childCount: _leaderboard.length,
              ),
            ),

          // Info section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detaylar',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Olusturan', challenge.createdByName),
                  _buildInfoRow('Tur', _typeLabel(challenge.type)),
                  _buildInfoRow('Baslangic', _formatDate(challenge.startDate)),
                  _buildInfoRow('Bitis', _formatDate(challenge.endDate)),
                  _buildInfoRow('Katilimci', '${challenge.participants.length} kisi'),
                ],
              ),
            ),
          ),

          // Action buttons
          if (!isCompleted)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Row(
                  children: [
                    if (isCreator)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _deleteChallenge,
                          icon: const Icon(Icons.delete_outline, color: AppTheme.primaryRed),
                          label: Text(
                            'Sil',
                            style: GoogleFonts.inter(
                              color: AppTheme.primaryRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryRed),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _leaveChallenge,
                          icon: const Icon(Icons.exit_to_app, color: AppTheme.primaryRed),
                          label: Text(
                            'Ayril',
                            style: GoogleFonts.inter(
                              color: AppTheme.primaryRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryRed),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(LeaderboardEntry entry) {
    final isMe = entry.uid == _currentUid;
    final medal = switch (entry.rank) {
      1 => '\u{1F947}',
      2 => '\u{1F948}',
      3 => '\u{1F949}',
      _ => '',
    };

    // Progress bar max is the top scorer's score
    final maxScore = _leaderboard.isNotEmpty ? _leaderboard.first.score : 1;
    final progress = maxScore > 0 ? entry.score / maxScore : 0.0;
    final barColor = _typeColor(challenge.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.primaryRed.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isMe ? Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.25), width: 1.5) : null,
        boxShadow: isMe ? AppTheme.softShadow(AppTheme.primaryRed) : AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank
              SizedBox(
                width: 36,
                child: medal.isNotEmpty
                    ? Text(medal, style: const TextStyle(fontSize: 22))
                    : Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.rank}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: isMe ? AppTheme.primaryGradient : AppTheme.darkGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? '${entry.name} (Sen)' : entry.name,
                      style: GoogleFonts.inter(
                        fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                        color: isMe ? AppTheme.primaryRed : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _scoreLabel(entry.score, challenge.type),
                      style: GoogleFonts.inter(
                        color: AppTheme.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Score
              Text(
                _formatScore(entry.score, challenge.type),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: entry.rank == 1 ? const Color(0xFFFFA000) : AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: barColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textLight,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.textDark,
            ),
          ),
        ],
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

  Color _typeColor(String type) {
    return switch (type) {
      'steps' => const Color(0xFF1E88E5),
      'water' => const Color(0xFF00ACC1),
      'smoking' => const Color(0xFF43A047),
      _ => AppTheme.primaryRed,
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

  String _typeLabel(String type) {
    return switch (type) {
      'steps' => 'Adim Sayisi',
      'water' => 'Su Tketimi',
      'smoking' => 'Sigarayi Birakma',
      _ => 'Challenge',
    };
  }

  String _scoreLabel(int score, String type) {
    return switch (type) {
      'steps' => '$score adim',
      'water' => '$score gun hedefe ulasildi',
      'smoking' => '$score gun sigarasiz',
      _ => '$score',
    };
  }

  String _formatScore(int score, String type) {
    if (type == 'steps') {
      if (score >= 1000000) return '${(score / 1000000).toStringAsFixed(1)}M';
      if (score >= 1000) return '${(score / 1000).toStringAsFixed(1)}k';
    }
    return '$score';
  }

  String _scoreUnit(String type) {
    return switch (type) {
      'steps' => 'adim',
      'water' => 'gun',
      'smoking' => 'gun',
      _ => '',
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
