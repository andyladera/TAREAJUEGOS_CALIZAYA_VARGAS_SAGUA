import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../game/maze_maps.dart';
import 'game_screen.dart';
import 'ranking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && userDoc.exists) {
        setState(() {
          _username = userDoc.data()?['username'];
        });
      }
    }
  }

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Laberinto', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildWelcomeHeader(theme),
          const SizedBox(height: 30),
          Text('Elige un Desafío', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildMapCard(
            context: context,
            theme: theme,
            mapId: 'mapa_1',
            map: MazeMaps.map1,
            title: 'El Inicio del Viaje',
            icon: Icons.explore_outlined,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildMapCard(
            context: context,
            theme: theme,
            mapId: 'mapa_2',
            map: MazeMaps.map2,
            title: 'El Corazón del Bosque',
            icon: Icons.park_outlined,
            color: Colors.teal,
          ),
          const SizedBox(height: 16),
          _buildMapCard(
            context: context,
            theme: theme,
            mapId: 'mapa_3',
            map: MazeMaps.map3,
            title: 'La Cima de la Montaña',
            icon: Icons.filter_hdr_outlined,
            color: Colors.orange,
          ),
          const SizedBox(height: 30),
          _buildRankingButton(context, theme),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Bienvenido de vuelta,',
          style: theme.textTheme.titleLarge,
        ),
        Text(
          _username ?? 'Jugador',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard({
    required BuildContext context,
    required ThemeData theme,
    required String mapId,
    required List<List<int>> map,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _playMap(context, mapId, map),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 20),
              Expanded(
                child: Text(title, style: theme.textTheme.titleLarge),
              ),
              Icon(Icons.play_arrow_rounded, size: 30, color: theme.colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingButton(BuildContext context, ThemeData theme) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.leaderboard_outlined),
      label: const Text('Ver Tabla de Clasificación'),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RankingScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}