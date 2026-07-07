import 'package:flutter/material.dart';
import '../data/esma_data.dart';
import '../theme/app_theme.dart';

class NamesListScreen extends StatefulWidget {
  const NamesListScreen({super.key});

  @override
  State<NamesListScreen> createState() => _NamesListScreenState();
}

class _NamesListScreenState extends State<NamesListScreen> {
  static const Color _accent = Color(0xFFFF6B35);
  static const Color _accentLight = Color(0xFFFF8E53);

  AppPalette _p = AppPalette.dark;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<int> get _filteredIndices {
    if (_query.isEmpty) {
      return List.generate(EsmaData.esmalar.length, (i) => i);
    }
    final q = _query.toLowerCase();
    return EsmaData.esmalar.asMap().entries.where((entry) {
      final e = entry.value;
      return e.latin.toLowerCase().contains(q) ||
          e.turkce.toLowerCase().contains(q) ||
          e.arapca.contains(q) ||
          e.anlami.toLowerCase().contains(q) ||
          e.index.toString() == q;
    }).map((entry) => entry.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    _p = ThemeScope.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _p.bg,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(
                child: _filteredIndices.isEmpty
                    ? _buildEmptyState()
                    : _buildNamesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _p.onBg(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: _accent,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '99 İsim',
              style: TextStyle(
                color: _p.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _accent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${_filteredIndices.length} / ${EsmaData.esmalar.length}',
              style: const TextStyle(
                color: _accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (v) => setState(() => _query = v),
        style: TextStyle(color: _p.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'İsim ara... (ör: Rahman, Er-Rahman)',
          hintStyle: TextStyle(color: _p.onBg(0.3)),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _p.onBg(0.4),
            size: 22,
          ),
          suffixIcon: _query.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: _p.onBg(0.4),
                    size: 20,
                  ),
                )
              : null,
          filled: true,
          fillColor: _p.onBg(0.06),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _p.onBg(0.08), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: _p.onBg(0.15),
            size: 70,
          ),
          const SizedBox(height: 16),
          Text(
            '"$_query" için sonuç bulunamadı',
            style: TextStyle(color: _p.onBg(0.4), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNamesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _filteredIndices.length,
      itemBuilder: (context, index) {
        final esmaIndex = _filteredIndices[index];
        final esma = EsmaData.esmalar[esmaIndex];

        return GestureDetector(
          onTap: () => Navigator.pop(context, esmaIndex),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _p.onBg(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _p.onBg(0.07),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_accent, _accentLight],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${esma.index}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        esma.latin,
                        style: TextStyle(
                          color: _p.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        esma.anlami,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _p.onBg(0.45),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  esma.arapca,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: _p.onBg(0.35),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _p.onBg(0.25),
                  size: 22,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
