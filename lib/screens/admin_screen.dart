import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/pdf_event.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/stats_service.dart';

class AdminScreen extends StatefulWidget {
  final UserProfile profile;
  const AdminScreen({super.key, required this.profile});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const _navy    = Color(0xFF0F2057);
  static const _navyL   = Color(0xFF1E3A8A);
  static const _burgun  = Color(0xFF8B1A4A);
  static const _bg      = Color(0xFFF5F7FA);
  static const _border  = Color(0xFFE8ECF2);
  static const _textMid = Color(0xFF6B7280);

  List<PdfEvent> _events = [];
  List<UserProfile> _users = [];
  bool _loading = true;
  String _period = 'Tümü';

  static const _periods = ['Tümü', 'Günlük', 'Haftalık', 'Aylık', 'Yıllık'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      StatsService.getAllEvents(),
      StatsService.getAllUsers(),
    ]);
    if (!mounted) return;
    setState(() {
      _events = results[0] as List<PdfEvent>;
      _users  = results[1] as List<UserProfile>;
      _loading = false;
    });
  }

  List<PdfEvent> get _filtered =>
      StatsService.filterByPeriod(_events, _period);

  Map<String, int> get _byUser =>
      StatsService.countByUser(_filtered);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        _buildHeader(),
        if (_loading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: _navy, strokeWidth: 2),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: _navy,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 20),
                    _buildPeriodFilter(),
                    const SizedBox(height: 20),
                    _buildUserLeaderboard(),
                    const SizedBox(height: 20),
                    _buildEventLog(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
      ]),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, _navyL, _burgun],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Admin Paneli',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                )),
              Text('Merhaba, ${widget.profile.name}',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                )),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: AuthService.signOut,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.logout_rounded, size: 13, color: Colors.white70),
                  const SizedBox(width: 5),
                  Text('Çıkış', style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Summary Cards ───────────────────────────────────────────────────────────
  Widget _buildSummaryCards() {
    final totalEvents = _filtered.length;
    final totalUsers  = _users.length;
    final uniqueToday = StatsService.filterByPeriod(_events, 'Günlük').length;

    return Row(children: [
      Expanded(child: _statCard(
        icon: Icons.picture_as_pdf_outlined,
        value: '$totalEvents',
        label: _period == 'Tümü' ? 'Toplam PDF' : '$_period PDF',
        color: _navy,
      )),
      const SizedBox(width: 12),
      Expanded(child: _statCard(
        icon: Icons.people_outline_rounded,
        value: '$totalUsers',
        label: 'Danışman',
        color: const Color(0xFF7950F2),
      )),
      const SizedBox(width: 12),
      Expanded(child: _statCard(
        icon: Icons.today_outlined,
        value: '$uniqueToday',
        label: 'Bugün PDF',
        color: _burgun,
      )),
    ]);
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 10),
        Text(value,
          style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w800, color: _navy)),
        Text(label,
          style: GoogleFonts.poppins(
            fontSize: 10.5, color: _textMid, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ─── Period Filter ──────────────────────────────────────────────────────────
  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Zaman Filtresi',
          style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w700, color: _navy)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _periods.map((p) {
            final sel = p == _period;
            return GestureDetector(
              onTap: () => setState(() => _period = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? _navy : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: sel ? _navy : _border),
                ),
                child: Text(p,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? Colors.white : _textMid,
                  )),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  // ─── User Leaderboard ───────────────────────────────────────────────────────
  Widget _buildUserLeaderboard() {
    final map = _byUser;
    if (map.isEmpty) {
      return _emptyCard('Bu dönemde henüz PDF oluşturulmamış.');
    }

    final entries = map.entries.toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            const Icon(Icons.leaderboard_rounded, size: 16, color: _navy),
            const SizedBox(width: 8),
            Text('Danışman Sıralaması',
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700, color: _navy)),
            const Spacer(),
            Text('${entries.length} kişi',
              style: GoogleFonts.poppins(fontSize: 11, color: _textMid)),
          ]),
        ),
        const SizedBox(height: 12),
        ...entries.asMap().entries.map((e) {
          final rank  = e.key + 1;
          final name  = e.value.key;
          final count = e.value.value;
          final isTop = rank == 1;
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isTop
                  ? _navy.withValues(alpha: 0.05)
                  : _bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTop ? _navy.withValues(alpha: 0.2) : Colors.transparent),
            ),
            child: Row(children: [
              // Rank badge
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isTop ? _navy : _border,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$rank',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isTop ? Colors.white : _textMid,
                    )),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
                    color: _navy,
                  )),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isTop ? _navy : _border,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('$count PDF',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isTop ? Colors.white : _textMid,
                  )),
              ),
            ]),
          );
        }),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ─── Event Log ──────────────────────────────────────────────────────────────
  Widget _buildEventLog() {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return _emptyCard('Bu dönemde etkinlik yok.');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            const Icon(Icons.history_rounded, size: 16, color: _navy),
            const SizedBox(width: 8),
            Text('Detaylı Kayıtlar',
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700, color: _navy)),
            const Spacer(),
            Text('${filtered.length} işlem',
              style: GoogleFonts.poppins(fontSize: 11, color: _textMid)),
          ]),
        ),
        const SizedBox(height: 12),
        ...filtered.map((e) => _eventTile(e)),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _eventTile(PdfEvent e) {
    final fmt = DateFormat('dd MMM yyyy · HH:mm', 'tr_TR');
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(e.studentName.isNotEmpty ? e.studentName : '—',
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700, color: _navy)),
          ),
          Text(fmt.format(e.createdAt),
            style: GoogleFonts.poppins(fontSize: 10.5, color: _textMid)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.person_outline_rounded, size: 12, color: _textMid),
          const SizedBox(width: 4),
          Text(e.userFullName,
            style: GoogleFonts.poppins(fontSize: 11.5, color: _textMid, fontWeight: FontWeight.w500)),
        ]),
        if (e.universities.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: e.universities.take(4).map((u) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _border),
              ),
              child: Text(u,
                style: GoogleFonts.poppins(
                  fontSize: 9.5, color: _navy, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            )).toList()
            ..addAll(e.universities.length > 4
              ? [Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _border),
                  ),
                  child: Text('+${e.universities.length - 4} daha',
                    style: GoogleFonts.poppins(
                      fontSize: 9.5, color: _textMid, fontWeight: FontWeight.w500)),
                )]
              : []),
          ),
        ],
      ]),
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Column(children: [
          Icon(Icons.inbox_outlined, size: 40, color: _border),
          const SizedBox(height: 10),
          Text(msg,
            style: GoogleFonts.poppins(fontSize: 12.5, color: _textMid),
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
