import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../models/university.dart';
import '../services/data_service.dart';
import '../services/pdf_service.dart';

// ─── Brand ───────────────────────────────────────────────────────────────────
class _B {
  static const navy    = Color(0xFF0D1F3C);
  static const navyMid = Color(0xFF1A3A6B);
  static const crimson = Color(0xFF8B1A4A);
  static const cream   = Color(0xFFF8F6F2);
  static const smoke   = Color(0xFFF0EDE8);
  static const border  = Color(0xFFE0DBD3);
  static const dim     = Color(0xFF9A9390);
  static const white   = Colors.white;

  // Alan renk paleti — editorial renkler
  static const _palette = [
    Color(0xFF0D47A1), Color(0xFF6A1B9A), Color(0xFF37474F),
    Color(0xFF00695C), Color(0xFF1565C0), Color(0xFF4E342E),
    Color(0xFF283593), Color(0xFF558B2F), Color(0xFF00838F),
    Color(0xFF4527A0), Color(0xFF0277BD), Color(0xFF2E7D32),
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
      if (mounted) setState(() => _logo = Image.asset('assets/images/logo.png', fit: BoxFit.contain));
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
      margin: const EdgeInsets.all(16),
      backgroundColor: _B.navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Text(msg, style: const TextStyle(color: Colors.white)),
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
      barrierColor: _B.navy.withValues(alpha: 0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: _B.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: _B.navy.withValues(alpha: 0.2), blurRadius: 50, offset: const Offset(0, 20))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Dialog header
            Container(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_B.navy, _B.navyMid], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 20),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PDF Raporu',
                    style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Öğrenci adını girin',
                    style: GoogleFonts.roboto(color: Colors.white54, fontSize: 12)),
                ]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Column(children: [
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: GoogleFonts.roboto(fontSize: 15, color: _B.navy),
                  decoration: InputDecoration(
                    labelText: 'Ad Soyad',
                    labelStyle: GoogleFonts.roboto(color: _B.dim, fontSize: 13),
                    hintText: 'Örn: Ahmet Yılmaz',
                    hintStyle: GoogleFonts.roboto(color: _B.border),
                    filled: true,
                    fillColor: _B.cream,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _B.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _B.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _B.navyMid, width: 2)),
                    prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: _B.dim),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: _B.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('İptal', style: GoogleFonts.roboto(color: _B.dim, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _B.navy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Oluştur', style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.bold)),
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
      backgroundColor: _B.cream,
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF0D1F3C), Color(0xFF15305A)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          // Top bar: logo + title + clear button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
            child: Row(children: [
              // Logo or brand mark
              if (_logo != null)
                SizedBox(width: 44, height: 44, child: _logo)
              else
                _brandMark(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('MYEDUCOACH',
                    style: GoogleFonts.roboto(
                      color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w900, letterSpacing: 2.5)),
                  Text('Üniversite Seçici',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFC9A84C),
                      fontSize: 13, fontStyle: FontStyle.italic)),
                ]),
              ),
              if (_selected.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _selected.clear()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.close, size: 13, color: Colors.white54),
                      const SizedBox(width: 5),
                      Text('Temizle', style: GoogleFonts.roboto(color: Colors.white54, fontSize: 11)),
                    ]),
                  ),
                ),
            ]),
          ),
          // Stats banner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Row(children: [
              _statChip(Icons.school_outlined, '$total Program'),
              const SizedBox(width: 8),
              _statChip(Icons.category_outlined, '${_fields.length > 1 ? _fields.length - 1 : 0} Alan'),
              const Spacer(),
              if (_field != 'Tümü')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _B.crimson.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(children: [
                    Text(_field, style: GoogleFonts.roboto(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () { setState(() { _field = 'Tümü'; }); _applyFilter(); },
                      child: const Icon(Icons.close, size: 12, color: Colors.white70),
                    ),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _brandMark() {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_B.navyMid, _B.crimson], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: const Icon(Icons.school, color: Colors.white, size: 22),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: const Color(0xFFC9A84C)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.roboto(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ─── Tab Bar ─────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _B.white,
        border: Border(bottom: BorderSide(color: _B.border)),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: TabBar(
        controller: _tab,
        indicator: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _B.navy, width: 3)),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 24),
        labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
        unselectedLabelStyle: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w400),
        labelColor: _B.navy,
        unselectedLabelColor: _B.dim,
        tabs: const [Tab(text: 'LİSANS'), Tab(text: 'YÜKSEK LİSANS')],
      ),
    );
  }

  // ─── Search + Filters ────────────────────────────────────────────────────
  Widget _buildSearchAndFilters() {
    return Container(
      color: _B.white,
      child: Column(children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) { _search = v; _applyFilter(); },
            style: GoogleFonts.roboto(fontSize: 14, color: _B.navy),
            decoration: InputDecoration(
              hintText: 'Okul, bölüm veya şehir ara…',
              hintStyle: GoogleFonts.roboto(color: _B.dim, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: _B.dim, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 17, color: _B.dim),
                      onPressed: () { _searchCtrl.clear(); _search = ''; _applyFilter(); },
                    )
                  : null,
              filled: true,
              fillColor: _B.cream,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _B.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _B.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _B.navyMid, width: 1.5)),
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
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final f = _fields[i];
              final sel = f == _field;
              final fc = f == 'Tümü' ? _B.navy : _B.fieldColor(f);
              return GestureDetector(
                onTap: () { setState(() => _field = f); _applyFilter(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 0),
                  decoration: BoxDecoration(
                    color: sel ? fc : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: sel ? fc : _B.border, width: 1.2),
                  ),
                  child: Center(
                    child: Text(f,
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        fontWeight: sel ? FontWeight.bold : FontWeight.w400,
                        color: sel ? Colors.white : _B.dim,
                        letterSpacing: 0.2)),
                  ),
                ),
              );
            },
          ),
        ),
        // Result count
        Container(
          color: _B.smoke,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 7),
          child: Row(children: [
            Container(width: 3, height: 12, decoration: BoxDecoration(color: _B.navy, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('${_filtered.length} program listeleniyor',
              style: GoogleFonts.roboto(fontSize: 11, color: _B.dim, letterSpacing: 0.3)),
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
          Icon(Icons.search_off_rounded, size: 52, color: _B.dim.withValues(alpha: 0.3)),
          const SizedBox(height: 14),
          Text('Sonuç bulunamadı',
            style: GoogleFonts.roboto(color: _B.dim, fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('Arama terimini değiştirin',
            style: GoogleFonts.roboto(color: _B.dim.withValues(alpha: 0.6), fontSize: 12)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _UniCard(
        university: _filtered[i],
        isSelected: _selected.contains(_filtered[i].id),
        index: i,
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
        border: const Border(top: BorderSide(color: _B.border)),
        boxShadow: [BoxShadow(color: _B.navy.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Row(children: [
        // Counter block
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: count == 0 ? _B.cream : _B.navy,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: count == 0 ? _B.border : _B.navy),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.school_outlined, size: 16, color: count == 0 ? _B.dim : Colors.white),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(count == 0 ? 'Seçim yok' : '$count / 8',
                style: GoogleFonts.roboto(
                  fontSize: 13, fontWeight: FontWeight.bold,
                  color: count == 0 ? _B.dim : Colors.white)),
              if (count > 0)
                Text('okul seçildi',
                  style: GoogleFonts.roboto(fontSize: 10, color: Colors.white60)),
            ]),
          ]),
        ),
        const SizedBox(width: 12),
        // PDF Button
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: count == 0 ? null : _generatePdf,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: count == 0
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF0A1628), Color(0xFF1A3A6B)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                  color: count == 0 ? _B.smoke : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: count == 0 ? [] : [
                    BoxShadow(color: _B.navy.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.picture_as_pdf_outlined, size: 18,
                    color: count == 0 ? _B.dim : Colors.white),
                  const SizedBox(width: 8),
                  Text('PDF Oluştur',
                    style: GoogleFonts.roboto(
                      fontSize: 14, fontWeight: FontWeight.bold,
                      color: count == 0 ? _B.dim : Colors.white,
                      letterSpacing: 0.5)),
                  if (count > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9A84C).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFC9A84C).withValues(alpha: 0.4)),
                      ),
                      child: Text('$count',
                        style: GoogleFonts.roboto(
                          fontSize: 11, fontWeight: FontWeight.bold,
                          color: const Color(0xFFC9A84C))),
                    ),
                  ],
                ]),
              ),
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
  final int index;
  final VoidCallback onTap;

  const _UniCard({
    required this.university,
    required this.isSelected,
    required this.index,
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
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECF0F8) : _B.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A3A6B) : _B.border,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _B.navy.withValues(alpha: isSelected ? 0.08 : 0.04),
              blurRadius: isSelected ? 16 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Row(children: [
            // Field color bar — no IntrinsicHeight needed
            Container(
              width: 5,
              height: 90,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1A3A6B) : fc.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(13),
                  bottomLeft: Radius.circular(13),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 13, 10, 13),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  // Avatar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1A3A6B) : fc.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _initials(university.name),
                        style: GoogleFonts.roboto(
                          fontSize: 13, fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : fc,
                          letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(university.name,
                        style: GoogleFonts.roboto(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFF0D1F3C) : const Color(0xFF1A1A2E),
                          height: 1.2,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(university.program,
                        style: GoogleFonts.roboto(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: _B.dim, height: 1.35),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(children: [
                        // Field tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: fc.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: fc.withValues(alpha: 0.2)),
                          ),
                          child: Text(university.field,
                            style: GoogleFonts.roboto(
                              fontSize: 10, color: fc,
                              fontWeight: FontWeight.w700, letterSpacing: 0.2),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        // City tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _B.smoke,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text('📍 ${university.city}',
                            style: GoogleFonts.roboto(fontSize: 10, color: _B.dim, fontWeight: FontWeight.w500)),
                        ),
                      ]),
                    ]),
                  ),
                  // Checkbox
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0D1F3C) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0D1F3C) : _B.border,
                        width: 1.5),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : null,
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
