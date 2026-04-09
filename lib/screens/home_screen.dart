import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../models/university.dart';
import '../services/data_service.dart';
import '../services/pdf_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ─── Renkler ───────────────────────────────────────────────
  static const _navy = Color(0xFF1E3A6E);
  static const _red = Color(0xFFB71C1C);

  // ─── State ─────────────────────────────────────────────────
  List<University> _allUniversities = [];
  List<University> _filtered = [];
  final Set<String> _selectedIds = {};
  String _searchQuery = '';
  String _selectedField = 'Tümü';
  List<String> _fields = [];
  bool _loading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final unis = await DataService.loadUniversities();
    final fields = ['Tümü', ...DataService.extractFields(unis)];
    setState(() {
      _allUniversities = unis;
      _fields = fields;
      _loading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      _filtered = _allUniversities.where((u) {
        final matchesSearch = _searchQuery.isEmpty ||
            u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.program.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.city.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesField =
            _selectedField == 'Tümü' || u.field == _selectedField;
        return matchesSearch && matchesField;
      }).toList();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length >= 8) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('En fazla 8 okul seçebilirsiniz.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _generatePdf() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az 1 okul seçin.')),
      );
      return;
    }

    // Öğrenci adı sor
    final studentName = await _askStudentName();
    if (studentName == null) return;

    final selectedList = _allUniversities
        .where((u) => _selectedIds.contains(u.id))
        .toList();

    try {
      final pdfBytes = await PdfService.generatePdf(
        studentName: studentName,
        selected: selectedList,
      );

      final filename =
          studentName.isNotEmpty ? '${studentName}_universiteler.pdf' : 'myeducoach_liste.pdf';

      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF oluşturulamadı: $e')),
        );
      }
    }
  }

  Future<String?> _askStudentName() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Öğrenci Bilgisi'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Öğrenci Adı Soyadı',
            hintText: 'Örn: Ahmet Yılmaz',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _navy),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('PDF Oluştur', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                _buildFieldFilters(),
                _buildResultCount(),
                Expanded(child: _buildList()),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _navy,
      foregroundColor: Colors.white,
      title: Text(
        'Myeducoach — Üniversite Seçici',
        style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      actions: [
        if (_selectedIds.isNotEmpty)
          TextButton.icon(
            onPressed: _clearSelection,
            icon: const Icon(Icons.clear_all, color: Colors.white70),
            label: const Text('Temizle', style: TextStyle(color: Colors.white70)),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (v) {
          _searchQuery = v;
          _applyFilter();
        },
        decoration: InputDecoration(
          hintText: 'Okul adı, bölüm veya şehir ara...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    _searchQuery = '';
                    _applyFilter();
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF0F2F5),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFieldFilters() {
    return Container(
      color: Colors.white,
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _fields.length,
        itemBuilder: (_, i) {
          final field = _fields[i];
          final isSelected = field == _selectedField;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(field),
              selected: isSelected,
              onSelected: (_) {
                _selectedField = field;
                _applyFilter();
              },
              selectedColor: _navy,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              checkmarkColor: Colors.white,
              backgroundColor: const Color(0xFFEEF0F3),
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultCount() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFFF5F7FA),
      child: Text(
        '${_filtered.length} sonuç',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return const Center(
        child: Text(
          'Sonuç bulunamadı.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _UniversityCard(
        university: _filtered[i],
        isSelected: _selectedIds.contains(_filtered[i].id),
        onTap: () => _toggleSelect(_filtered[i].id),
      ),
    );
  }

  Widget _buildBottomBar() {
    final count = _selectedIds.length;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          // Seçili okullar sayacı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: count == 0 ? const Color(0xFFF0F2F5) : const Color(0xFFE8EDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: count == 0 ? Colors.transparent : _navy.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 18,
                  color: count == 0 ? Colors.grey : _navy,
                ),
                const SizedBox(width: 8),
                Text(
                  count == 0
                      ? 'Okul seçilmedi'
                      : '$count / 8 okul seçildi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: count == 0 ? Colors.grey : _navy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // PDF butonu
          Expanded(
            child: ElevatedButton.icon(
              onPressed: count == 0 ? null : _generatePdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF Oluştur & Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Üniversite Kartı Widget'ı ───────────────────────────────────────────────

class _UniversityCard extends StatelessWidget {
  final University university;
  final bool isSelected;
  final VoidCallback onTap;

  static const _navy = Color(0xFF1E3A6E);

  const _UniversityCard({
    required this.university,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8EDF5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _navy : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? _navy : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? _navy : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              // Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      university.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? _navy : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      university.program,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        _chip(university.field, const Color(0xFFE8EDF5), _navy),
                        _chip(
                          '📍 ${university.city}',
                          const Color(0xFFF0F0F0),
                          Colors.black54,
                        ),
                      ],
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

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
