import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../models/university.dart';
import '../services/data_service.dart';
import '../services/pdf_service.dart';

// ─── Brand ───────────────────────────────────────────────────────────────────
class _B {
  // Core
  static const navy      = Color(0xFF0F2057);
  static const navyLight = Color(0xFF1A3A6B);
  static const orange    = Color(0xFFE87040);
  static const orangeLight = Color(0xFFF4A27A);
  static const bg        = Color(0xFFF5F7FA);
  static const white     = Colors.white;
  static const textDark  = Color(0xFF1A1A2E);
  static const textMid   = Color(0xFF6B7280);
  static const textLight = Color(0xFFB0B8C8);
  static const border    = Color(0xFFE8ECF2);

  // Field colour palette — vivid but not garish
  static const _palette = [
    Color(0xFF3B5BDB), Color(0xFF7950F2), Color(0xFF0CA678),
    Color(0xFF1098AD), Color(0xFFE64980), Color(0xFFF76707),
    Color(0xFF2B8A3E), Color(0xFFD6336C), Color(0xFF0B7285),
    Color(0xFF5C7CFA), Color(0xFF20C997), Color(0xFFFF922B),
  ];

  static Color fieldColor(String field) {
    final idx = field.codeUnits.fold(0, (a, b) => a + b) % _palette.length;
    return _palette[idx];
  }
}

// ─── HomeScreen ──────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<University> _all = [];
  List<University> _filtered = [];
  final Set<String> _selected = {};
  String _search = '';
  String _field = 'Tümü';
  List<String> _fields = [];
  bool _loading = true;
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  Image? _logo;

  String get _level => _tab.index == 0 ? 'Lisans' : 'Yüksek Lisans';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)
      ..addListener(() { _field = 'Tümü'; _applyFilter(); });
    _load();
    _loadLogo();
  }

  Future<void> _loadLogo() async {
    try {
      await rootBundle.load('assets/images/logo.png');
      if (mounted) {
        setState(() => _logo = Image.asset('assets/images/logo.png', fit: BoxFit.contain));
      }
    } catch (_) {}
  }

  @override
  void dispose() { _tab.dispose(); _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final unis = await DataService.loadUniversities();
    setState(() { _all = unis; _loading = false; _applyFilter(); });
  }

  void _applyFilter() {
    final level = _all.where((u) => u.level == _level).toList();
    final fields = ['Tümü', ...DataService.extractFields(level)];
    setState(() {
      _fields = fields;
      if (!_fields.contains(_field)) _field = 'Tümü';
      _filtered = level.where((u) {
        final q = _search.toLowerCase();
        final m = _search.isEmpty ||
            u.name.toLowerCase().contains(q) ||
            u.program.toLowerCase().contains(q) ||
            u.city.toLowerCase().contains(q);
        return m && (_field == 'Tümü' || u.field == _field);
      }).toList();
    });
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        if (_selected.length >= 8) {
          _snack('En fazla 8 okul seçilebilir.');
          return;
        }
        _selected.add(id);
      }
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      backgroundColor: _B.textDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _generatePdf() async {
    if (_selected.isEmpty) return;
    final name = await _askStudentName();
    if (name == null) return;
    final list = _all.where((u) => _selected.contains(u.id)).toList();
    try {
      final bytes = await PdfService.generatePdf(studentName: name, selected: list);
      final fn = name.isNotEmpty ? '${name}_universiteler.pdf' : 'myeducoach_liste.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fn);
    } catch (e) {
      if (mounted) _snack('PDF oluşturulamadı: $e');
    }
  }

  Future<String?> _askStudentName() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierColor: _B.navy.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            color: _B.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 60, offset: const Offset(0, 24)),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Dialog header — gradient
            Container(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_B.navy, _B.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PDF Raporu', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Öğrenci adını girin', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                ]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
              child: Column(children: [
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: GoogleFonts.poppins(fontSize: 14, color: _B.textDark),
                  decoration: InputDecoration(
                    labelText: 'Ad Soyad',
                    labelStyle: GoogleFonts.poppins(color: _B.textMid, fontSize: 13),
                    hintText: 'Örn: Ahmet Yılmaz',
                    hintStyle: GoogleFonts.poppins(color: _B.textLight),
                    filled: true,
                    fillColor: _B.bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _B.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _B.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _B.navy, width: 2)),
                    prefixIcon: Icon(Icons.badge_outlined, size: 18, color: _B.textMid),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: _B.border, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      child: Text('İptal', style: GoogleFonts.poppins(color: _B.textMid, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_B.navy, _B.orange], begin: Alignment.centerLeft, end: Alignment.centerRight),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [BoxShadow(color: _B.orange.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          elevation: 0,
                        ),
                        child: Text('Oluştur', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _B.bg,
      body: Column(children: [
        _buildHeader(),
        _buildTabBar(),
        _buildSearchAndFilters(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _B.navy, strokeWidth: 2))
              : TabBarView(
                  controller: _tab,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_buildList(), _buildList()],
                ),
        ),
      ]),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final total = _all.where((u) => u.level == _level).length;
    final fieldCount = _fields.length > 1 ? _fields.length - 1 : 0;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F2057),
            Color(0xFF1E3A8A),
            Color(0xFFE87040),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top row: logo + title + clear
            Row(children: [
              // Logo / brand
              if (_logo != null)
                SizedBox(width: 42, height: 42, child: _logo)
              else
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('MYEDU COACH',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    )),
                  Text('Üniversite Seçici',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    )),
                ]),
              ),
              if (_selected.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _selected.clear()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.close_rounded, size: 13, color: Colors.white.withValues(alpha: 0.8)),
                      const SizedBox(width: 5),
                      Text('Temizle',
                        style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
            ]),
            const SizedBox(height: 20),
            // Stat pills
            Row(children: [
              _statPill(Icons.school_outlined, '$total Program'),
              const SizedBox(width: 10),
              _statPill(Icons.category_outlined, '$fieldCount Alan'),
              if (_field != 'Tümü') ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () { setState(() => _field = 'Tümü'); _applyFilter(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _B.orange.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: _B.orange.withValues(alpha: 0.5)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_field,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      const Icon(Icons.close_rounded, size: 12, color: Colors.white70),
                    ]),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _statPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: _B.orangeLight),
        const SizedBox(width: 6),
        Text(label,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ─── Tab Bar ─────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: _B.white,
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          border: Border(bottom: BorderSide(color: _B.orange, width: 3)),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 28),
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12.5, letterSpacing: 0.3),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w400),
        labelColor: _B.navy,
        unselectedLabelColor: _B.textMid,
        tabs: const [Tab(text: 'LİSANS'), Tab(text: 'YÜKSEK LİSANS')],
      ),
    );
  }

  // ─── Search + Filters ────────────────────────────────────────────────────
  Widget _buildSearchAndFilters() {
    return Container(
      color: _B.white,
      child: Column(children: [
        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) { _search = v; _applyFilter(); },
            style: GoogleFonts.poppins(fontSize: 13.5, color: _B.textDark),
            decoration: InputDecoration(
              hintText: 'Okul, bölüm veya şehir ara…',
              hintStyle: GoogleFonts.poppins(color: _B.textLight, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: _B.textLight, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, size: 17, color: _B.textMid),
                      onPressed: () { _searchCtrl.clear(); _search = ''; _applyFilter(); },
                    )
                  : null,
              filled: true,
              fillColor: _B.bg,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: const BorderSide(color: _B.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: const BorderSide(color: _B.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: const BorderSide(color: _B.navy, width: 1.5)),
            ),
          ),
        ),
        // Filter chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            itemCount: _fields.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _fields[i];
              final sel = f == _field;
              final fc = f == 'Tümü' ? _B.navy : _B.fieldColor(f);
              return GestureDetector(
                onTap: () { setState(() => _field = f); _applyFilter(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  decoration: BoxDecoration(
                    color: sel ? fc : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: sel ? fc : _B.border, width: 1.3),
                    boxShadow: sel ? [BoxShadow(color: fc.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
                  ),
                  child: Center(
                    child: Text(f,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel ? Colors.white : _B.textMid,
                      )),
                  ),
                ),
              );
            },
          ),
        ),
        // Result count bar
        Container(
          color: _B.bg,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(children: [
            Container(width: 3, height: 12, decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_B.navy, _B.orange]),
              borderRadius: BorderRadius.circular(2),
            )),
            const SizedBox(width: 10),
            Text('${_filtered.length} program',
              style: GoogleFonts.poppins(fontSize: 11, color: _B.textMid, fontWeight: FontWeight.w500)),
          ]),
        ),
        const Divider(height: 1, color: _B.border),
      ]),
    );
  }

  // ─── List ─────────────────────────────────────────────────────────────────
  Widget _buildList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, size: 56, color: _B.textLight),
          const SizedBox(height: 16),
          Text('Sonuç bulunamadı',
            style: GoogleFonts.poppins(color: _B.textMid, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Arama terimini değiştirin',
            style: GoogleFonts.poppins(color: _B.textLight, fontSize: 12)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _UniCard(
        university: _filtered[i],
        isSelected: _selected.contains(_filtered[i].id),
        onTap: () => _toggle(_filtered[i].id),
      ),
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final count = _selected.length;
    return Container(
      decoration: BoxDecoration(
        color: _B.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, -8)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Row(children: [
        // Counter pill
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: count == 0 ? _B.bg : _B.navy,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: count == 0 ? _B.border : _B.navy),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.school_outlined, size: 16, color: count == 0 ? _B.textLight : Colors.white),
            const SizedBox(width: 8),
            Text(
              count == 0 ? '0 / 8' : '$count / 8',
              style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: count == 0 ? _B.textLight : Colors.white,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        // PDF Button — pill, gradient
        Expanded(
          child: GestureDetector(
            onTap: count == 0 ? null : _generatePdf,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: count == 0
                    ? null
                    : const LinearGradient(
                        colors: [_B.navy, _B.orange],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                color: count == 0 ? _B.bg : null,
                borderRadius: BorderRadius.circular(100),
                border: count == 0 ? Border.all(color: _B.border) : null,
                boxShadow: count == 0
                    ? []
                    : [BoxShadow(color: _B.orange.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.picture_as_pdf_outlined, size: 18, color: count == 0 ? _B.textLight : Colors.white),
                const SizedBox(width: 8),
                Text('PDF Oluştur',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5, fontWeight: FontWeight.w700,
                    color: count == 0 ? _B.textLight : Colors.white,
                    letterSpacing: 0.3,
                  )),
                if (count > 0) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('$count',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── University Card ──────────────────────────────────────────────────────────
class _UniCard extends StatelessWidget {
  final University university;
  final bool isSelected;
  final VoidCallback onTap;

  const _UniCard({
    required this.university,
    required this.isSelected,
    required this.onTap,
  });

  static String _initials(String name) {
    final words = name.split(' ').where((w) => w.length > 2).toList();
    if (words.isEmpty) return name[0].toUpperCase();
    if (words.length == 1) return words[0].substring(0, 2).toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fc = _B.fieldColor(university.field);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _B.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _B.orange.withValues(alpha: 0.6) : Colors.transparent,
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _B.orange.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Avatar circle with initials
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isSelected ? _B.navy : fc.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [BoxShadow(color: _B.navy.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Center(
                child: Text(
                  _initials(university.name),
                  style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : fc,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info block
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(university.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5, fontWeight: FontWeight.w700,
                    color: _B.textDark, height: 1.2,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(university.program,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5, fontWeight: FontWeight.w400,
                    color: _B.textMid, height: 1.35,
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  // Field pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: fc.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(university.field,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5, color: fc,
                        fontWeight: FontWeight.w700, letterSpacing: 0.2),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 6),
                  // City pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: _B.bg,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('📍 ${university.city}',
                      style: GoogleFonts.poppins(fontSize: 9.5, color: _B.textMid, fontWeight: FontWeight.w500)),
                  ),
                ]),
              ]),
            ),
            const SizedBox(width: 12),
            // Check circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24, height: 24,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [_B.navy, _B.orange], begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                color: isSelected ? null : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.transparent : _B.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ]),
        ),
      ),
    );
  }
}
