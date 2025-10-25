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
  late Timer _timer; // Para actualizar la UI del cronómetro
  String _formattedTime = '00:00:000';
  bool _gameFinished = false;

  // Usamos FocusNode para capturar los eventos del teclado
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _playerPos = _findStartPosition();
    _startGameTimer();

    // Asegurarnos de que el widget pueda recibir foco
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  // 1. Iniciar el cronómetro
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

  // 2. Encontrar la posición '8' (Inicio) en el mapa
  PlayerPosition _findStartPosition() {
    for (int r = 0; r < widget.map.length; r++) {
      for (int c = 0; c < widget.map[r].length; c++) {
        if (widget.map[r][c] == 8) {
          return PlayerPosition(r, c);
        }
      }
    }
    return PlayerPosition(0, 0); // Fallback
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _timer.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  // 3. Lógica de movimiento (¡reutilizada por todos los controles!)
  void _movePlayer(LogicalKeyboardKey key) {
    if (_gameFinished) return; // Si el juego terminó, no moverse

    int newRow = _playerPos.row;
    int newCol = _playerPos.col;

    if (key == LogicalKeyboardKey.arrowUp) newRow--;
    if (key == LogicalKeyboardKey.arrowDown) newRow++;
    if (key == LogicalKeyboardKey.arrowLeft) newCol--;
    if (key == LogicalKeyboardKey.arrowRight) newCol++;

    // Verificación de colisión
    if (_isValidMove(newRow, newCol)) {
      setState(() {
        _playerPos = PlayerPosition(newRow, newCol);
      });

      // Verificación de victoria
      if (widget.map[newRow][newCol] == 9) {
        _winGame();
      }
    }
  }

  bool _isValidMove(int row, int col) {
    // ¿Está dentro de los límites del mapa?
    if (row < 0 ||
        row >= widget.map.length ||
        col < 0 ||
        col >= widget.map[0].length) {
      return false;
    }
    // ¿Es un muro (1)?
    if (widget.map[row][col] == 1) {
      return false;
    }
    return true;
  }

  // 4. Lógica de victoria
  void _winGame() async {
    _stopwatch.stop();
    _timer.cancel();
    _gameFinished = true;

    final int finalTimeMs = _stopwatch.elapsedMilliseconds;

    // ¡Llamamos a la función para guardar el tiempo!
    await saveScore(widget.mapId, finalTimeMs);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Ganaste!'),
        content: Text('Tu tiempo: $_formattedTime'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el diálogo
              Navigator.of(context).pop(); // Vuelve al Home
            },
            child: const Text('OK'),
          ),
        ],
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
    // RawKeyboardListener es el widget clave para la entrada de teclado
    return RawKeyboardListener(
      autofocus: true,
      focusNode: _focusNode,
      onKey: (RawKeyEvent event) {
        // Nos aseguramos de que sea un evento de "tecla presionada"
        if (event is RawKeyDownEvent) {
          _movePlayer(event.logicalKey);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mapa: ${widget.mapId}'),
          // Mostramos el tiempo en la AppBar
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Text(
                  _formattedTime,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
        
        // --- INICIO DE LA MODIFICACIÓN ---
        // Usamos un Column para poner el juego ARRIBA y los controles ABAJO
        body: Column(
          children: [
            // 1. El juego (envuelto en Expanded para que ocupe el espacio)
            Expanded(
              child: GestureDetector(
                // --- El código de gestos de swipe se queda igual ---
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < -100) { 
                    _movePlayer(LogicalKeyboardKey.arrowUp);
                  } else if (details.primaryVelocity! > 100) {
                    _movePlayer(LogicalKeyboardKey.arrowDown);
                  }
                },
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < -100) {
                    _movePlayer(LogicalKeyboardKey.arrowLeft);
                  } else if (details.primaryVelocity! > 100) {
                    _movePlayer(LogicalKeyboardKey.arrowRight);
                  }
                },
                // --- Fin del código de gestos ---
                
                child: Container(
                  color: Colors.transparent, // Para que el swipe funcione en áreas vacías
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: widget.map[0].length / widget.map.length,
                      child: MazeWidget(
                        map: widget.map,
                        playerPos: _playerPos,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Los controles (el D-Pad visible)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              color: Colors.grey[200], // Un fondo para el área de control
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Botón Izquierda
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 40,
                    onPressed: () => _movePlayer(LogicalKeyboardKey.arrowLeft),
                  ),

                  // Columna para Arriba y Abajo
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón Arriba
                      IconButton(
                        icon: const Icon(Icons.arrow_upward),
                        iconSize: 40,
                        onPressed: () => _movePlayer(LogicalKeyboardKey.arrowUp),
                      ),
                      const SizedBox(height: 20), // Espacio
                      // Botón Abajo
                      IconButton(
                        icon: const Icon(Icons.arrow_downward),
                        iconSize: 40,
                        onPressed: () => _movePlayer(LogicalKeyboardKey.arrowDown),
                      ),
                    ],
                  ),

                  // Botón Derecha
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    iconSize: 40,
                    onPressed: () => _movePlayer(LogicalKeyboardKey.arrowRight),
                  ),
                ],
              ),
            ),
          ],
        ),
        // --- FIN DE LA MODIFICACIÓN ---
      ),
    );
  }
}