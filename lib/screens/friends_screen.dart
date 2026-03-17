import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/friends_service.dart';
import '../services/challenge_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = FriendsService.instance;
  final _searchController = TextEditingController();

  List<FriendData> _friends = [];
  List<FriendRequest> _pendingRequests = [];
  List<Map<String, dynamic>> _searchResults = [];
  final Map<String, FriendPublicData> _friendPublicData = {};
  bool _loadingFriends = true;
  bool _loadingRequests = true;
  bool _searching = false;
  bool _sendingRequest = false;

  StreamSubscription? _friendsSub;
  StreamSubscription? _requestsSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _listenToStreams();
  }

  void _listenToStreams() {
    _friendsSub = _service.friendsStream().listen((friends) {
      if (mounted) {
        setState(() => _friends = friends);
        _loadFriendPublicData(friends);
      }
    });

    _requestsSub = _service.pendingRequestCountStream().listen((_) {
      _loadPendingRequests();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadFriends(),
      _loadPendingRequests(),
    ]);
  }

  Future<void> _loadFriends() async {
    final friends = await _service.getFriendsList();
    if (mounted) {
      setState(() {
        _friends = friends;
        _loadingFriends = false;
      });
      _loadFriendPublicData(friends);
    }
  }

  Future<void> _loadFriendPublicData(List<FriendData> friends) async {
    for (final friend in friends) {
      final data = await _service.getFriendPublicData(friend.uid);
      if (mounted) {
        setState(() {
          _friendPublicData[friend.uid] = data;
        });
      }
    }
  }

  Future<void> _loadPendingRequests() async {
    final requests = await _service.getPendingRequests();
    if (mounted) {
      setState(() {
        _pendingRequests = requests;
        _loadingRequests = false;
      });
    }
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _searching = true);
    try {
      final results = await _service.searchUsersByEmail(query);
      if (mounted) setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Arama sirasinda hata olustu', isError: true);
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _sendRequest(Map<String, dynamic> user) async {
    setState(() => _sendingRequest = true);
    final result = await _service.sendFriendRequest(
      toUid: user['uid'],
      toEmail: user['email'],
    );
    if (mounted) {
      _showSnackBar(result.message, isError: !result.success);
      if (result.success) {
        setState(() {
          _searchResults = [];
          _searchController.clear();
        });
      }
      setState(() => _sendingRequest = false);
    }
  }

  Future<void> _acceptRequest(FriendRequest request) async {
    final result = await _service.acceptFriendRequest(request);
    if (mounted) {
      _showSnackBar(result.message, isError: !result.success);
      if (result.success) {
        _loadData();
      }
    }
  }

  Future<void> _rejectRequest(FriendRequest request) async {
    final result = await _service.rejectFriendRequest(request.id);
    if (mounted) {
      _showSnackBar(result.message, isError: !result.success);
      if (result.success) {
        _loadPendingRequests();
      }
    }
  }

  Future<void> _unfriend(FriendData friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arkadasi Sil'),
        content: Text('${friend.name} adli kisiyi arkadaslarinizdan silmek istediginize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Iptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _service.unfriend(friend.uid);
      if (mounted) {
        _showSnackBar(result.message, isError: !result.success);
        if (result.success) _loadFriends();
      }
    }
  }

  void _openCreateChallengeWithFriend(FriendData friend) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateChallengeFromFriendSheet(
        preSelectedFriend: friend,
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.primaryRed : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _friendsSub?.cancel();
    _requestsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Arkadaslar',
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
              const Tab(text: 'Arkadaslar'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Istekler'),
                    if (_pendingRequests.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_pendingRequests.length}',
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
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'E-posta ile arkadas ara...',
                      hintStyle: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textLight),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _searchUsers(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _searching ? null : _searchUsers,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _searching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Ara'),
                  ),
                ),
              ],
            ),
          ),

          // Search results
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      'Arama Sonuclari',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                  ..._searchResults.map((user) => _buildSearchResultTile(user)),
                  const SizedBox(height: 8),
                ],
              ),
            ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(Map<String, dynamic> user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1),
        child: Text(
          (user['displayName'] as String).isNotEmpty
              ? (user['displayName'] as String)[0].toUpperCase()
              : '?',
          style: GoogleFonts.inter(
            color: AppTheme.primaryRed,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        user['displayName'] ?? '',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        user['email'] ?? '',
        style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 12),
      ),
      trailing: SizedBox(
        height: 36,
        child: ElevatedButton.icon(
          onPressed: _sendingRequest ? null : () => _sendRequest(user),
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('Ekle'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ── Friends Tab ──

  Widget _buildFriendsTab() {
    if (_loadingFriends) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
    }

    if (_friends.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'Henuz arkadasiniz yok',
        subtitle: 'Yukardaki arama cubugundan e-posta ile\narkadas ekleyebilirsiniz',
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryRed,
      onRefresh: _loadFriends,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (context, index) => _buildFriendCard(_friends[index]),
      ),
    );
  }

  Widget _buildFriendCard(FriendData friend) {
    final publicData = _friendPublicData[friend.uid];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header row
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name & email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        friend.email,
                        style: GoogleFonts.inter(
                          color: AppTheme.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Risk badge
                if (publicData != null && publicData.riskScore > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _riskBadgeColor(publicData.riskScore).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      publicData.riskLevel,
                      style: GoogleFonts.inter(
                        color: _riskBadgeColor(publicData.riskScore),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                // Challenge button
                IconButton(
                  icon: const Icon(Icons.emoji_events_rounded, size: 22),
                  color: const Color(0xFFFFA000),
                  tooltip: 'Challenge Olustur',
                  onPressed: () => _openCreateChallengeWithFriend(friend),
                ),
                // More options
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppTheme.textLight),
                  onSelected: (value) {
                    if (value == 'unfriend') _unfriend(friend);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'unfriend',
                      child: Row(
                        children: [
                          Icon(Icons.person_remove, color: AppTheme.primaryRed, size: 20),
                          SizedBox(width: 8),
                          Text('Arkadasliktan Cikar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Stats row
            if (publicData != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildStatItem(
                      icon: Icons.directions_walk,
                      value: _formatNumber(publicData.steps),
                      label: 'Adim',
                      color: Colors.blue,
                    ),
                    _buildStatDivider(),
                    _buildStatItem(
                      icon: Icons.water_drop,
                      value: '${publicData.water}',
                      label: 'Su',
                      color: Colors.cyan,
                    ),
                    _buildStatDivider(),
                    _buildStatItem(
                      icon: Icons.shield,
                      value: '${publicData.riskScore}',
                      label: 'Risk',
                      color: _riskBadgeColor(publicData.riskScore),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textLight,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.textLight.withValues(alpha: 0.2),
    );
  }

  Color _riskBadgeColor(int score) {
    if (score >= 60) return AppTheme.primaryRed;
    if (score >= 35) return Colors.orange;
    if (score > 0) return Colors.green;
    return Colors.grey;
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return '$number';
  }

  // ── Requests Tab ──

  Widget _buildRequestsTab() {
    if (_loadingRequests) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed));
    }

    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.mail_outline,
        title: 'Bekleyen istek yok',
        subtitle: 'Yeni arkadaslik istekleri\nburada gorunecek',
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryRed,
      onRefresh: _loadPendingRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) => _buildRequestCard(_pendingRequests[index]),
      ),
    );
  }

  Widget _buildRequestCard(FriendRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.primaryRed.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  request.fromName.isNotEmpty ? request.fromName[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.fromName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.fromEmail,
                    style: GoogleFonts.inter(
                      color: AppTheme.textLight,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(request.createdAt),
                    style: GoogleFonts.inter(
                      color: AppTheme.textLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Buttons
            Column(
              children: [
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(request),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Kabul Et'),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    onPressed: () => _rejectRequest(request),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      side: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
                      textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: Text(
                      'Reddet',
                      style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Az once';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk once';
    if (diff.inHours < 24) return '${diff.inHours} saat once';
    if (diff.inDays < 7) return '${diff.inDays} gun once';
    return '${date.day}.${date.month}.${date.year}';
  }

  // ── Empty state ──

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

// ── Quick Challenge Creation Sheet (from friend card) ──

class _CreateChallengeFromFriendSheet extends StatefulWidget {
  final FriendData preSelectedFriend;

  const _CreateChallengeFromFriendSheet({required this.preSelectedFriend});

  @override
  State<_CreateChallengeFromFriendSheet> createState() => _CreateChallengeFromFriendSheetState();
}

class _CreateChallengeFromFriendSheetState extends State<_CreateChallengeFromFriendSheet> {
  String _selectedType = 'steps';
  String _selectedDuration = 'daily';
  bool _creating = false;

  String get _defaultTitle {
    final typeLabel = switch (_selectedType) {
      'steps' => 'Adim',
      'water' => 'Su',
      'smoking' => 'Sigara',
      _ => '',
    };
    final durationLabel = _selectedDuration == 'daily' ? 'Gunluk' : 'Haftalik';
    return '$durationLabel $typeLabel Challenge';
  }

  Future<void> _create() async {
    setState(() => _creating = true);

    final result = await ChallengeService.instance.createChallenge(
      type: _selectedType,
      title: _defaultTitle,
      duration: _selectedDuration,
      friendUids: [widget.preSelectedFriend.uid],
    );

    if (mounted) {
      setState(() => _creating = false);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : AppTheme.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
            '${widget.preSelectedFriend.name} ile Challenge',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),

          // Type selector
          Text(
            'Tur',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTypeOption('steps', 'Adim', Icons.directions_walk_rounded, const Color(0xFF1E88E5)),
              const SizedBox(width: 10),
              _buildTypeOption('water', 'Su', Icons.water_drop_rounded, const Color(0xFF00ACC1)),
              const SizedBox(width: 10),
              _buildTypeOption('smoking', 'Sigara', Icons.smoke_free_rounded, const Color(0xFF43A047)),
            ],
          ),
          const SizedBox(height: 20),

          // Duration selector
          Text(
            'Sure',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDurationOption('daily', 'Gunluk'),
              const SizedBox(width: 10),
              _buildDurationOption('weekly', 'Haftalik'),
            ],
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
                      width: 22, height: 22,
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
    );
  }

  Widget _buildTypeOption(String type, String label, IconData icon, Color color) {
    final selected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: selected ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)]) : null,
            color: selected ? null : AppTheme.background,
            borderRadius: BorderRadius.circular(14),
            border: selected ? null : Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : AppTheme.textLight, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? Colors.white : AppTheme.textLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationOption(String duration, String label) {
    final selected = _selectedDuration == duration;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDuration = duration),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryRed : AppTheme.background,
            borderRadius: BorderRadius.circular(14),
            border: selected ? null : Border.all(color: AppTheme.textLight.withValues(alpha: 0.2)),
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
