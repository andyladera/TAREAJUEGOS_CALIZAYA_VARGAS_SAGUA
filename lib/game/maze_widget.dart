// lib/game/maze_widget.dart

import 'package:flutter/material.dart';

// Usaremos esta clase simple para guardar la posición (fila, columna)
class PlayerPosition {
  int row;
  int col;
  PlayerPosition(this.row, this.col);
}

class MazeWidget extends StatelessWidget {
  final List<List<int>> map;
  final PlayerPosition playerPos;

  const MazeWidget({
    Key? key,
    required this.map,
    required this.playerPos,
  }) : super(key: key);

  // Define los colores para cada tipo de celda
  Color _getColor(int tileType) {
    switch (tileType) {
      case 1: // Muro
        return Colors.black;
      case 8: // Inicio
        return Colors.blueGrey;
      case 9: // Meta
        return Colors.green;
      default: // 0 = Camino
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos GridView.builder para crear la cuadrícula
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(), // Evita el scroll
      shrinkWrap: true,
      itemCount: map.length * map[0].length, // Total de celdas
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: map[0].length, // Número de columnas
      ),
      itemBuilder: (context, index) {
        // Calculamos la fila y columna a partir del índice
        int row = index ~/ map[0].length;
        int col = index % map[0].length;

        int tileType = map[row][col];

        // ¿Es la posición del jugador?
        bool isPlayer = (playerPos.row == row && playerPos.col == col);

        return Container(
          decoration: BoxDecoration(
            color: _getColor(tileType),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          // Dibujamos al jugador (un círculo azul) si está en esta celda
          child: isPlayer
              ? Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null, // Si no, no dibujamos nada extra
        );
      },
    );
  }
}