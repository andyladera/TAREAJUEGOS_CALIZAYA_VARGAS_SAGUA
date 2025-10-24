import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../game/maze_maps.dart'; // Importamos los mapas
import 'game_screen.dart'; // Importamos la pantalla de juego
import 'ranking_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _playMap(BuildContext context, String mapId, List<List<int>> map) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(map: map, mapId: mapId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Bienvenido!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Usuario: ${user?.email ?? '...'}',
            ),
            const SizedBox(height: 40),

            // --- BOTONES DEL JUEGO ---
            ElevatedButton(
              onPressed: () => _playMap(context, 'mapa_1', MazeMaps.map1),
              child: const Text('Jugar Mapa 1'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _playMap(context, 'mapa_2', MazeMaps.map2),
              child: const Text('Jugar Mapa 2'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _playMap(context, 'mapa_3', MazeMaps.map3),
              child: const Text('Jugar Mapa 3'),
            ),
            const SizedBox(height: 30),

            // --- BOTÓN DE RANKING (Aún no funciona) ---
            OutlinedButton(
              onPressed: () {
                // --- MODIFICAR AQUÍ ---
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RankingScreen(),
                  ),
                );
                // -----------------------
              },
              child: const Text('Ver Rankings'),
            ),
          ],
        ),
      ),
    );
  }
}