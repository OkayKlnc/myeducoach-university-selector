import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../models/university.dart';
import '../services/data_service.dart';
import '../services/pdf_service.dart';

// ─── Brand Palette ────────────────────────────────────────────────────────────
class _Brand {
  static const navy      = Color(0xFF0D2045);
  static const navyLight = Color(0xFF1E3A6E);
  static const gold      = Color(0xFFC9A84C);
  static const red       = Color(0xFFB71C1C);
  static const bg        = Color(0xFFF2F5F9);
  static const surface   = Colors.white;
  static const border    = Color(0xFFDDE3ED);
  static const textDim   = Color(0xFF7A8BA8);
}

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

  String get _level => _tab.index == 0 ? 'Lisans' : 'Yüksek Lisans';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)
      ..addListener(() {
        _field = 'Tümü';
        _applyFilter();
      });
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

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
        final matchSearch = _search.isEmpty ||
            u.name.toLowerCase().contains(q) ||
            u.program.toLowerCase().contains(q) ||
            u.city.toLowerCase().contains(q);
        final matchField = _field == 'Tümü' || u.field == _field;
        return matchSearch && matchField;
      }).toList();
    });
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        if (_selected.length >= 8) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: _Brand.navy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Text('En fazla 8 okul seçilebilir.',
                style: TextStyle(color: Colors.white)),
            duration: const Duration(seconds: 2),
          ));
          return;
        }
        _selected.add(id);
      }
    });
  }

  Future<void> _generatePdf() async {
    if (_selected.isEmpty) return;
    final name = await _askStudentName();
    if (name == null) return;
    final list = _all.where((u) => _selected.contains(u.id)).toList();
    try {
      final bytes = await PdfService.generatePdf(studentName: name, selected: list);
      final filename = name.isNotEmpty ? '${name}_universiteler.pdf' : 'myeducoach_liste.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF oluşturulamadı: $e')));
      }
    }
  }

  Future<String?> _askStudentName() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _Brand.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _Brand.navy.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(color: _Brand.navy, shape: BoxShape.circle),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text('Öğrenci Bilgisi',
                  style: GoogleFonts.roboto(
                    fontSize: 17, fontWeight: FontWeight.bold, color: _Brand.navy)),
              ]),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: GoogleFonts.roboto(fontSize: 15, color: _Brand.navy),
                decoration: InputDecoration(
                  hintText: 'Ad Soyad',
                  hintStyle: TextStyle(color: _Brand.textDim),
                  filled: true,
                  fillColor: _Brand.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _Brand.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _Brand.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _Brand.navyLight, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: _Brand.border),
                      ),
                    ),
                    child: Text('İptal',
                      style: GoogleFonts.roboto(color: _Brand.textDim, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Brand.navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('PDF Oluştur',
                      style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Brand.bg,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _Brand.navy))
          : TabBarView(
              controller: _tab,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildBody(), _buildBody()],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _Brand.navy,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D2045), Color(0xFF1A3666)],
          ),
        ),
      ),
      title: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: _Brand.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _Brand.gold.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.school, color: _Brand.gold, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Myeducoach',
              style: GoogleFonts.roboto(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15,
                letterSpacing: 0.3)),
            Text('Üniversite Seçici',
              style: GoogleFonts.roboto(
                color: _Brand.gold, fontSize: 11, letterSpacing: 0.5,
                fontWeight: FontWeight.w400)),
          ],
        ),
      ]),
      actions: [
        if (_selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => setState(() => _selected.clear()),
              icon: const Icon(Icons.close, size: 15, color: Colors.white54),
              label: Text('Temizle',
                style: GoogleFonts.roboto(color: Colors.white54, fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Column(children: [
          Container(height: 1, color: _Brand.gold.withValues(alpha: 0.2)),
          TabBar(
            controller: _tab,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: _Brand.gold, width: 2.5),
              insets: EdgeInsets.symmetric(horizontal: 24),
            ),
            labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
            unselectedLabelStyle: GoogleFonts.roboto(fontSize: 13),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: 'Lisans'),
              Tab(text: 'Yüksek Lisans'),
            ],
          ),
        ]),
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Column(children: [
      _buildSearchBar(),
      _buildFilters(),
      _buildResultBanner(),
      Expanded(child: _buildList()),
    ]);
  }

  Widget _buildSearchBar() {
    return Container(
      color: _Brand.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) { _search = v; _applyFilter(); },
        style: GoogleFonts.roboto(fontSize: 14, color: _Brand.navy),
        decoration: InputDecoration(
          hintText: 'Okul adı, bölüm veya şehir ara...',
          hintStyle: GoogleFonts.roboto(color: _Brand.textDim, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: _Brand.textDim, size: 20),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: _Brand.textDim),
                  onPressed: () { _searchCtrl.clear(); _search = ''; _applyFilter(); },
                )
              : null,
          filled: true,
          fillColor: _Brand.bg,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _Brand.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _Brand.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _Brand.navyLight, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: _Brand.surface,
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _fields.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _fields[i];
          final sel = f == _field;
          return GestureDetector(
            onTap: () { setState(() { _field = f; }); _applyFilter(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              decoration: BoxDecoration(
                color: sel ? _Brand.navy : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: sel ? _Brand.navy : _Brand.border,
                  width: sel ? 0 : 1,
                ),
              ),
              child: Center(
                child: Text(f,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.bold : FontWeight.w400,
                    color: sel ? Colors.white : _Brand.textDim,
                    letterSpacing: 0.2,
                  )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultBanner() {
    return Container(
      width: double.infinity,
      color: _Brand.bg,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${_filtered.length} program listelendi',
            style: GoogleFonts.roboto(
              fontSize: 12, color: _Brand.textDim, letterSpacing: 0.2)),
          if (_field != 'Tümü')
            GestureDetector(
              onTap: () { setState(() { _field = 'Tümü'; }); _applyFilter(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _Brand.navyLight.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Text(_field,
                    style: GoogleFonts.roboto(
                      fontSize: 11, color: _Brand.navyLight, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(Icons.close, size: 12, color: _Brand.navyLight),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, size: 48, color: _Brand.textDim.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('Sonuç bulunamadı',
            style: GoogleFonts.roboto(color: _Brand.textDim, fontSize: 15)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
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
        color: _Brand.surface,
        border: const Border(top: BorderSide(color: _Brand.border)),
        boxShadow: [
          BoxShadow(
            color: _Brand.navy.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Row(children: [
        // Sayaç
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: count == 0 ? _Brand.bg : _Brand.navy.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: count == 0 ? _Brand.border : _Brand.navy.withValues(alpha: 0.2),
            ),
          ),
          child: Row(children: [
            Icon(Icons.school_outlined, size: 17,
              color: count == 0 ? _Brand.textDim : _Brand.navy),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(count == 0 ? 'Seçim yok' : '$count / 8',
                style: GoogleFonts.roboto(
                  fontSize: 13, fontWeight: FontWeight.bold,
                  color: count == 0 ? _Brand.textDim : _Brand.navy)),
              if (count > 0)
                Text('okul seçildi',
                  style: GoogleFonts.roboto(fontSize: 10, color: _Brand.textDim)),
            ]),
          ]),
        ),
        const SizedBox(width: 12),
        // PDF Butonu
        Expanded(
          child: ElevatedButton(
            onPressed: count == 0 ? null : _generatePdf,
            style: ElevatedButton.styleFrom(
              backgroundColor: _Brand.navy,
              disabledBackgroundColor: _Brand.border,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: count == 0 ? 0 : 2,
              shadowColor: _Brand.navy.withValues(alpha: 0.3),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.picture_as_pdf_outlined, size: 18,
                color: count == 0 ? _Brand.textDim : Colors.white),
              const SizedBox(width: 8),
              Text('PDF Oluştur',
                style: GoogleFonts.roboto(
                  fontSize: 14, fontWeight: FontWeight.bold,
                  color: count == 0 ? _Brand.textDim : Colors.white,
                  letterSpacing: 0.3)),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _Brand.gold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$count',
                    style: GoogleFonts.roboto(
                      fontSize: 11, fontWeight: FontWeight.bold, color: _Brand.gold)),
                ),
              ],
            ]),
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
    final words = name.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    // Skip common prefixes
    final skip = {'the', 'of', 'for', 'university', 'college'};
    final significant = words.where((w) => !skip.contains(w.toLowerCase())).toList();
    if (significant.length >= 2) {
      return '${significant[0][0]}${significant[1][0]}'.toUpperCase();
    }
    return words[0].substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDF1F8) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _Brand.navyLight : _Brand.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _Brand.navy.withValues(alpha: isSelected ? 0.06 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left accent strip
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 4,
              height: 72,
              decoration: BoxDecoration(
                color: isSelected ? _Brand.navy : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            // Avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected ? _Brand.navy : _Brand.bg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? _Brand.navy : _Brand.border,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials(university.name),
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : _Brand.navyLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      university.name,
                      style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? _Brand.navy : const Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      university.program,
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: _Brand.textDim,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(children: [
                      _tag(university.field, _Brand.navy.withValues(alpha: 0.07), _Brand.navyLight),
                      const SizedBox(width: 6),
                      _tag('📍 ${university.city}', const Color(0xFFF0F0F0), _Brand.textDim),
                    ]),
                  ],
                ),
              ),
            ),
            // Check
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? _Brand.navy : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? _Brand.navy : _Brand.border,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
        style: GoogleFonts.roboto(
          fontSize: 10.5, color: fg, fontWeight: FontWeight.w600, letterSpacing: 0.1)),
    );
  }
}
