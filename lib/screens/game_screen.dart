import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // Para el Timer
import '../game/maze_widget.dart'; // Importamos el widget
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// Importaciones para el Paso 4 (las activaremos luego)
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class GameScreen extends StatefulWidget {
  final List<List<int>> map;
  final String mapId; // "mapa_1", "mapa_2" o "mapa_3"

  const GameScreen({
    Key? key,
    required this.map,
    required this.mapId,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late PlayerPosition _playerPos;
  late Stopwatch _stopwatch;
  late Timer _timer;
  String _formattedTime = '00:00:000';
  bool _gameFinished = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _playerPos = _findStartPosition();
    _startGameTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _startGameTimer() {
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_stopwatch.isRunning) {
        setState(() {
          _formattedTime = _formatTime(_stopwatch.elapsedMilliseconds);
        });
      }
    });
  }

  String _formatTime(int milliseconds) {
    int minutes = (milliseconds ~/ 60000);
    int seconds = ((milliseconds % 60000) ~/ 1000);
    int millis = (milliseconds % 1000);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}:${millis.toString().padLeft(3, '0')}';
  }

  PlayerPosition _findStartPosition() {
    for (int r = 0; r < widget.map.length; r++) {
      for (int c = 0; c < widget.map[r].length; c++) {
        if (widget.map[r][c] == 8) {
          return PlayerPosition(r, c);
        }
      }
    }
    return PlayerPosition(0, 0);
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _timer.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _movePlayer(LogicalKeyboardKey key) {
    if (_gameFinished) return;

    int newRow = _playerPos.row;
    int newCol = _playerPos.col;

    if (key == LogicalKeyboardKey.arrowUp) newRow--;
    if (key == LogicalKeyboardKey.arrowDown) newRow++;
    if (key == LogicalKeyboardKey.arrowLeft) newCol--;
    if (key == LogicalKeyboardKey.arrowRight) newCol++;

    _updatePlayerPosition(newRow, newCol);
  }

  void _movePlayerWithButtons(String direction) {
    if (_gameFinished) return;

    int newRow = _playerPos.row;
    int newCol = _playerPos.col;

    switch (direction) {
      case 'up':
        newRow--;
        break;
      case 'down':
        newRow++;
        break;
      case 'left':
        newCol--;
        break;
      case 'right':
        newCol++;
        break;
    }
    _updatePlayerPosition(newRow, newCol);
  }

  void _updatePlayerPosition(int newRow, int newCol) {
    if (_isValidMove(newRow, newCol)) {
      setState(() {
        _playerPos = PlayerPosition(newRow, newCol);
      });

      if (widget.map[newRow][newCol] == 9) {
        _winGame();
      }
    }
  }

  bool _isValidMove(int row, int col) {
    if (row < 0 ||
        row >= widget.map.length ||
        col < 0 ||
        col >= widget.map[0].length) {
      return false;
    }
    if (widget.map[row][col] == 1) {
      return false;
    }
    return true;
  }

  void _winGame() async {
    if (_gameFinished) return;
    _stopwatch.stop();
    _timer.cancel();
    setState(() {
      _gameFinished = true;
    });

    final int finalTimeMs = _stopwatch.elapsedMilliseconds;
    await saveScore(widget.mapId, finalTimeMs);

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Ganaste! Tu tiempo: $_formattedTime',
            style:
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        duration: const Duration(days: 1), // Persistent
        action: SnackBarAction(
          label: 'VOLVER AL MENÚ',
          textColor: Colors.white,
          onPressed: () {
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  // 5. Guardar la puntuación en Firestore
  Future<void> saveScore(String mapId, int newTime) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // No hay usuario, no se puede guardar

      // 1. Obtenemos el username que guardamos durante el registro
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final username = userDoc.data()?['username'] ?? user.email ?? 'Anónimo';

      // 2. Referencia al documento de puntuación del usuario
      final scoreRef = FirebaseFirestore.instance
          .collection('rankings')
          .doc(mapId)
          .collection('scores')
          .doc(user.uid); // Usamos el UID del usuario como ID

      final currentScoreDoc = await scoreRef.get();

      if (currentScoreDoc.exists) {
        // 3. Si ya existe, solo actualizamos si el tiempo es MEJOR (menor)
        final existingTime = currentScoreDoc.data()!['time_ms'] as int;
        if (newTime < existingTime) {
          await scoreRef.update({
            'time_ms': newTime,
            'last_updated': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // 4. Si no existe, creamos el documento
        await scoreRef.set({
          'username': username,
          'time_ms': newTime,
          'last_updated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Opcional: mostrar un error si no se pudo guardar
      // ignore: avoid_print
      print("Error guardando puntuación: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mapa: ${widget.mapId.replaceAll('_', ' ')}', style: theme.textTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            _movePlayer(event.logicalKey);
          }
        },
        child: Column(
          children: [
            _buildTimerDisplay(theme),
            Expanded(
              child: Center(
                child: MazeWidget(
                  map: widget.map,
                  playerPos: _playerPos,
                  wallColor: theme.colorScheme.secondary.withOpacity(0.8),
                  pathColor: theme.scaffoldBackgroundColor,
                  playerColor: theme.colorScheme.primary,
                  goalColor: Colors.greenAccent,
                  startColor: Colors.blueAccent,
                ),
              ),
            ),
            _buildTouchControls(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        _formattedTime,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTouchControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(theme, Icons.arrow_upward, 'up'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(theme, Icons.arrow_back, 'left'),
              const SizedBox(width: 80),
              _buildControlButton(theme, Icons.arrow_forward, 'right'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(theme, Icons.arrow_downward, 'down'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(ThemeData theme, IconData icon, String direction) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () => _movePlayerWithButtons(direction),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(20),
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
        ),
        child: Icon(icon, size: 30),
      ),
    );
  }
}