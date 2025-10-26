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
  final Color wallColor;
  final Color pathColor;
  final Color playerColor;
  final Color goalColor;
  final Color startColor;

  const MazeWidget({
    Key? key,
    required this.map,
    required this.playerPos,
    this.wallColor = Colors.black,
    this.pathColor = Colors.white,
    this.playerColor = Colors.blue,
    this.goalColor = Colors.green,
    this.startColor = Colors.blueGrey,
  }) : super(key: key);

  Color _getColor(int tileType) {
    switch (tileType) {
      case 1:
        return wallColor;
      case 8:
        return startColor;
      case 9:
        return goalColor;
      default:
        return pathColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: map.length * map[0].length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: map[0].length,
      ),
      itemBuilder: (context, index) {
        int row = index ~/ map[0].length;
        int col = index % map[0].length;
        int tileType = map[row][col];
        bool isPlayer = (playerPos.row == row && playerPos.col == col);

        return Container(
          decoration: BoxDecoration(
            color: _getColor(tileType),
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.5),
          ),
          child: isPlayer
              ? Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: playerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}