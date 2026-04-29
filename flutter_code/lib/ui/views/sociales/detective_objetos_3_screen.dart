import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../terminado.dart';

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
const _kBoardImage = '$_kBase/Rompecabezas sin fondo.png';

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
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  final Map<String, AnimationController> _popCtrl = {};

  late final Player _player;
  bool _isPlayingAudio = false;
  StreamSubscription<bool>? _playingSub;

  String _popKey(int row, int col) => '${row}_$col';

  @override
  void initState() {
    super.initState();
    _tray = List.of(kPieces)..shuffle(Random());

    _completeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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

    for (final p in kPieces) {
      _popCtrl[_popKey(p.correctRow, p.correctCol)] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      );
    }

    _player = Player();
    _initAndPlayAudio();
  }

  Future<void> _initAndPlayAudio() async {
    try {
      _playingSub = _player.stream.playing.listen((playing) {
        if (mounted) setState(() => _isPlayingAudio = playing);
      });
      await _player.open(
          Media('asset:///assets/Audio/sociales/audio_sociales6_mezcla.mp3'));
      await _player.play();
    } catch (e) {
      debugPrint('Error audio: $e');
    }
  }

  Future<void> _toggleAudio() async {
    try {
      if (_player.state.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (e) {
      debugPrint('Error audio: $e');
    }
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _completeCtrl.dispose();
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    _player.dispose();
    for (final c in _popCtrl.values) c.dispose();
    super.dispose();
  }

  void _mostrarFeedback(bool esCorrecto, VoidCallback onAction) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: esCorrecto ? const Color(0xFFD7FFD3) : const Color(0xFFFFD3D3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    esCorrecto ? Icons.check_circle : Icons.cancel,
                    color: esCorrecto ? const Color(0xFF59E347) : const Color(0xFFF65757),
                    size: 40,
                  ),
                  const SizedBox(width: 15),
                  Text(
                    esCorrecto ? '¡Excelente trabajo!' : '¡Inténtalo de nuevo!',
                    style: TextStyle(
                      fontFamily: 'Hiruko',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: esCorrecto ? Colors.green[900] : Colors.red[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: esCorrecto ? const Color(0xFF59E347) : const Color(0xFFF65757),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onAction();
                  },
                  child: Text(
                    esCorrecto ? 'Continuar' : 'Reintentar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectTray(PuzzlePiece piece) {
    if (_completed) return;
    setState(() {
      _selectedId = (_selectedId == piece.id) ? null : piece.id;
    });
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
      _mostrarFeedback(false, () {});
    }
  }

  void _checkCompletion() {
  if (kPieces.every((p) => _board[p.correctRow][p.correctCol] == p.id)) {
    setState(() => _completed = true);
    _pulseCtrl.stop();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        widget.onCompleted?.call();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (newContext) => ActividadTerminadaScreen(
              onVolver: () => Navigator.of(newContext).popUntil((route) => route.isFirst),
            ),
          ),
        );
      }
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
      backgroundColor: const Color(0xFFFFBF47),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final availableHeight = constraints.maxHeight;
                    // Título (~80) + feedback (~44) + bandeja (~130) + gaps (~24) = ~278
                    // Usar fracción del alto disponible para pantallas pequeñas
                    final reservedHeight = availableHeight * 0.38;
                    final maxBoardH = availableHeight - reservedHeight;
                    final boardSide = min(
                      min(availableWidth - 24, maxBoardH),
                      400.0,
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildTitle(),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: boardSide,
                              maxHeight: boardSide,
                            ),
                            child: _buildBoard(boardSide),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(opacity: anim, child: child),
                              child: _buildTray(boardSide),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
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
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEE9A10), Color(0xFFFFBF47)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        // Sin esquinas redondeadas — el bloque naranja va de borde a borde
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Center(
            child: Text(
              'Detective de Objetos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                shadows: [Shadow(color: Color(0x44000000), blurRadius: 4)],
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: const Icon(
                Icons.close_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final titleSize = (w * 0.058).clamp(16.0, 23.0);
        final bodySize = (w * 0.038).clamp(12.0, 15.0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Rompecabezas de Pancho',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _toggleAudio,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _isPlayingAudio
                            ? _kOrange.withValues(alpha: 0.25)
                            : _kOrange.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isPlayingAudio
                              ? _kOrange
                              : _kOrange.withValues(alpha: 0.40),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _isPlayingAudio ? Icons.pause_rounded : Icons.volume_up_rounded,
                        color: _kOrange,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Arma la imagen y descubre qué está haciendo Pancho.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: bodySize,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF555555),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildBoard(double boardSide) {
    const frameThickness = 10.0;
    const frameRadius = 18.0;

    return Container(
      decoration: BoxDecoration(
        color: _kTrayBg,
        borderRadius: BorderRadius.circular(frameRadius),
        border: Border.all(color: _kTrayBorder, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(frameThickness),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(frameRadius - frameThickness),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: LayoutBuilder(
            builder: (context, innerConstraints) {
              // cellW/cellH siempre derivados del tamaño REAL renderizado
              final realSide = innerConstraints.maxWidth;
              final cellW = realSide / 4;
              final cellH = realSide / 4;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      _kBoardImage,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(color: Colors.white),
                    ),
                  ),
                  for (int row = 0; row < 4; row++)
                    for (int col = 0; col < 4; col++)
                      if (isHole(row, col))
                        _buildHoleCell(row, col, cellW, cellH),
                ],
              );
            },
          ),
        ),
      ),
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

      // Piezas 1,2,3,6: el PNG mide 430x349px.
      // - Ancho del PNG = ancho real de la celda (sin ajuste en X).
      // - La pestana izquierda es concava (entra hacia adentro), no agrega ancho.
      // - La pestana INFERIOR es convexa: agrega ~81px extra hacia abajo.
      //   Contenido celda = 268px de alto, PNG total = 349px.
      //   Factor alto = 349/268 = 1.3022 → renderizar mas alto para que encaje.
      // - OverflowBox + Clip.none permiten que la pestana sobresalga hacia abajo.
      // Piezas 4,5,7,8: logica original intacta, no se tocan.
      const tabPieceIds = {1, 2, 3, 6};
      final hasTab = tabPieceIds.contains(piece.id);

      Widget pieceImage;
      if (hasTab) {
        final imgW = cellW;           // ancho exacto de la celda, sin cambio
        final imgH = cellH * 1.3022;  // escalar alto para que celda = cellH exacto
        pieceImage = OverflowBox(
          maxWidth: imgW,
          maxHeight: imgH,
          alignment: Alignment.topLeft,
          child: Image.asset(
            piece.asset,
            width: imgW,
            height: imgH,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
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
        );
      } else {
        pieceImage = SizedBox(
          width: cellW,
          height: cellH,
          child: Image.asset(
            piece.asset,
            width: cellW,
            height: cellH,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
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
        );
      }

      inner = FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _popCtrl[popKey]!, curve: Curves.easeIn),
        ),
        child: GestureDetector(
          onTap: () => _onCellTap(row, col),
          child: pieceImage,
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
    // Escalar el ícono proporcionalmente al tamaño de celda (referencia: 26 para celda de ~95px)
    final iconSize = (cellW * 0.27).clamp(14.0, 30.0);
    return Container(
      width: cellW,
      height: cellH,
      decoration: isTarget
          ? BoxDecoration(
              color: _kOrange.withValues(alpha: 0.22 * _pulseAnim.value),
              border: Border.all(
                color: _kOrange.withValues(alpha: 0.85 * _pulseAnim.value),
                width: (cellW * 0.023).clamp(1.2, 2.8),
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            )
          : const BoxDecoration(),
      child: isTarget
          ? Center(
              child: Opacity(
                opacity: _pulseAnim.value,
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  color: _kOrange,
                  size: iconSize,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTray(double boardSide) {
    // Escalar piezas del tray proporcionalmente al tablero
    // Referencia: boardSide 380 → pieza 68×54
    final pieceW = (boardSide * 0.179).clamp(48.0, 80.0);
    final pieceH = (boardSide * 0.142).clamp(38.0, 64.0);

    if (_tray.isEmpty) {
      return const SizedBox.shrink();
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
        children: _tray.map((p) => _buildTrayPiece(p, pieceW, pieceH)).toList(),
      ),
    );
  }

  Widget _buildTrayPiece(PuzzlePiece piece, double pieceW, double pieceH) {
    final selected = _selectedId == piece.id;
    return GestureDetector(
      onTap: () => _selectTray(piece),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: pieceW,
        height: pieceH,
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
            filterQuality: FilterQuality.high,
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

}
