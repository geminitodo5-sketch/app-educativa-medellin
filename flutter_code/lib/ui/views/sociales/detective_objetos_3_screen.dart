import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const _DetectiveApp());

class _DetectiveApp extends StatelessWidget {
  const _DetectiveApp();
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const PuzzleScreen(),
  );
}

const _kBase = 'assets/images/actividades/sociales';
const _kBoardImage = '$_kBase/Completar_rompecabeza.png';

const _kOrange = Color(0xFFF5A623);
const _kOrangeDark = Color(0xFFD4881A);
const _kWoodBorder = Color(0xFFC4A45A);
const _kWoodFrame = Color(0xFFEDD9A3);
const _kBg = Color(0xFFFFF6EA);
const _kTrayBg = Color(0xFFF5E8CC);
const _kTrayBorder = Color(0xFFD4B98A);
const _kSlotBg = Color(0xFFDFC9A0);

bool isHole(int row, int col) => (row + col).isOdd;

class PuzzlePiece {
  final int id;
  final int correctRow;
  final int correctCol;
  const PuzzlePiece(this.id, this.correctRow, this.correctCol);
  String get asset => '$_kBase/pieza$id.png';
}

const List<PuzzlePiece> kPieces = [
  PuzzlePiece(1, 2, 1),
  PuzzlePiece(2, 0, 1),
  PuzzlePiece(3, 2, 3),
  PuzzlePiece(4, 1, 0),
  PuzzlePiece(5, 1, 2),
  PuzzlePiece(6, 0, 3),
  PuzzlePiece(7, 3, 0),
  PuzzlePiece(8, 3, 2),
];

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key, this.onCompleted});
  final VoidCallback? onCompleted;
  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen>
    with TickerProviderStateMixin {
  final List<List<int?>> _board = List.generate(4, (_) => List.filled(4, null));

  late List<PuzzlePiece> _tray;
  int? _selectedId;
  bool _completed = false;
  ({int row, int col})? _failCell;

  late final AnimationController _completeCtrl;
  late final Animation<double> _completeScale;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  final Map<String, AnimationController> _popCtrl = {};

  // ✅ Key unificada: siempre "row_col"
  String _popKey(int row, int col) => '${row}_$col';

  @override
  void initState() {
    super.initState();
    _tray = List.of(kPieces)..shuffle(Random());

    _completeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _completeScale = CurvedAnimation(
      parent: _completeCtrl,
      curve: Curves.elasticOut,
    );

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5, end: 0), weight: 1),
    ]).animate(_shakeCtrl);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.55,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // ✅ Usar _popKey() para inicializar consistentemente
    for (final p in kPieces) {
      _popCtrl[_popKey(p.correctRow, p.correctCol)] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      );
    }
  }

  @override
  void dispose() {
    _completeCtrl.dispose();
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    for (final c in _popCtrl.values) c.dispose();
    super.dispose();
  }

  void _selectTray(PuzzlePiece piece) {
    if (_completed) return;
    setState(() => _selectedId = (_selectedId == piece.id) ? null : piece.id);
  }

  void _onCellTap(int row, int col) {
    if (_completed) return;

    if (_selectedId == null) {
      final id = _board[row][col];
      if (id != null) {
        setState(() {
          _board[row][col] = null;
          _tray.add(kPieces.firstWhere((p) => p.id == id));
          _popCtrl[_popKey(row, col)]?.reset();
        });
      }
      return;
    }

    final piece = kPieces.firstWhere((p) => p.id == _selectedId);

    if (!isHole(row, col) || _board[row][col] != null) {
      setState(() => _selectedId = null);
      return;
    }

    if (piece.correctRow == row && piece.correctCol == col) {
      setState(() {
        _board[row][col] = piece.id;
        _tray.removeWhere((p) => p.id == piece.id);
        _selectedId = null;
      });
      _popCtrl[_popKey(row, col)]?.forward(from: 0);
      _checkCompletion();
    } else {
      setState(() {
        _failCell = (row: row, col: col);
        _selectedId = null;
      });
      _shakeCtrl.forward(from: 0).then((_) {
        if (mounted) setState(() => _failCell = null);
      });
    }
  }

  void _checkCompletion() {
    if (kPieces.every((p) => _board[p.correctRow][p.correctCol] == p.id)) {
      setState(() => _completed = true);
      _pulseCtrl.stop();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _completeCtrl.forward();
      });
    }
  }

  void _reset() {
    for (final c in _popCtrl.values) c.reset();
    setState(() {
      for (final row in _board) row.fillRange(0, 4, null);
      _tray = List.of(kPieces)..shuffle(Random());
      _selectedId = null;
      _completed = false;
      _failCell = null;
    });
    _completeCtrl.reset();
    _pulseCtrl.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    _buildTitle(),
                    const SizedBox(height: 16),
                    _buildBoard(),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: _completed ? _buildSuccessBanner() : _buildTray(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEE9A10), Color(0xFFFFBF47)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40F5A623),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Detective de Objetos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              shadows: [Shadow(color: Color(0x44000000), blurRadius: 4)],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const SizedBox(height: 4),
        const Text(
          'Rompecabezas de Pancho',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2D2010),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AudioButton(),
            const SizedBox(width: 8),
            Text(
              'Arma la imagen y descubre\nqué está haciendo Pancho.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.brown.shade600,
                height: 1.45,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardW = constraints.maxWidth;
        const imageRatio = 800 / 1000;
        final boardH = boardW / imageRatio;
        final cellW = boardW / 4;
        final cellH = boardH / 4;

        return Container(
          width: boardW,
          height: boardH,
          decoration: BoxDecoration(
            color: _kWoodFrame,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kWoodBorder, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    _kBoardImage,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: _kWoodFrame),
                  ),
                ),
                if (!_completed)
                  for (int row = 0; row < 4; row++)
                    for (int col = 0; col < 4; col++)
                      if (isHole(row, col))
                        _buildHoleCell(row, col, cellW, cellH),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHoleCell(int row, int col, double cellW, double cellH) {
    final id = _board[row][col];
    final isFail = _failCell?.row == row && _failCell?.col == col;
    final isTarget = _selectedId != null && id == null;
    final popKey = _popKey(row, col); // ✅ key unificada

    Widget inner;

    if (id != null) {
      final piece = kPieces.firstWhere((p) => p.id == id);
      inner = FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _popCtrl[popKey]!, curve: Curves.easeIn),
        ),
        child: GestureDetector(
          onTap: () => _onCellTap(row, col),
          child: SizedBox(
            width: cellW,
            height: cellH,
            child: Image.asset(
              piece.asset,
              width: cellW,
              height: cellH,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) => Container(
                width: cellW,
                height: cellH,
                color: _kSlotBg,
                alignment: Alignment.center,
                child: Text(
                  'P${piece.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _kWoodBorder,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      inner = GestureDetector(
        onTap: () => _onCellTap(row, col),
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) =>
              _emptySlot(isTarget: isTarget, cellW: cellW, cellH: cellH),
        ),
      );
    }

    Widget cell = isFail
        ? AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(_shakeAnim.value, 0),
              child: child,
            ),
            child: inner,
          )
        : inner;

    return Positioned(
      left: col * cellW,
      top: row * cellH,
      width: cellW,
      height: cellH,
      child: cell,
    );
  }

  Widget _emptySlot({
    required bool isTarget,
    required double cellW,
    required double cellH,
  }) {
    return Container(
      width: cellW,
      height: cellH,
      decoration: isTarget
          ? BoxDecoration(
              color: _kOrange.withValues(alpha: 0.22 * _pulseAnim.value),
              border: Border.all(
                color: _kOrange.withValues(alpha: 0.85 * _pulseAnim.value),
                width: 2.2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            )
          : const BoxDecoration(),
      child: isTarget
          ? Center(
              child: Opacity(
                opacity: _pulseAnim.value,
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: _kOrange,
                  size: 26,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTray() {
    if (_tray.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: Text(
          '¡Casi listo! Coloca todas las piezas.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.brown.shade400,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      key: const ValueKey('tray'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: _kTrayBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kTrayBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: _tray.map(_buildTrayPiece).toList(),
      ),
    );
  }

  Widget _buildTrayPiece(PuzzlePiece piece) {
    final selected = _selectedId == piece.id;
    return GestureDetector(
      onTap: () => _selectTray(piece),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 80,
        height: 65,
        transform: Matrix4.translationValues(0, selected ? -7 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _kOrange : _kTrayBorder,
            width: selected ? 2.8 : 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? _kOrange.withValues(alpha: 0.50)
                  : Colors.black.withValues(alpha: 0.10),
              blurRadius: selected ? 12 : 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            piece.asset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: _kSlotBg,
              alignment: Alignment.center,
              child: Text(
                'P${piece.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _kWoodBorder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return ScaleTransition(
      key: const ValueKey('banner'),
      scale: _completeScale,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEE9A10), Color(0xFFFFD166)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: _kOrange.withValues(alpha: 0.45),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 6),
            const Text(
              '¡Muy bien!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '¡Armaste el rompecabezas de Pancho!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Jugar de nuevo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _kOrangeDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                widget.onCompleted?.call();
                Navigator.maybePop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOrangeDark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _kOrange.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: _kOrange.withValues(alpha: 0.40), width: 1.5),
      ),
      child: const Icon(Icons.volume_up_rounded, color: _kOrange, size: 20),
    );
  }
}
