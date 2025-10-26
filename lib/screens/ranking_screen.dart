import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Usamos un TabController para las 3 pestañas
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ranking de Tiempos'),
          // 2. El TabBar (las pestañas)
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mapa 1'),
              Tab(text: 'Mapa 2'),
              Tab(text: 'Mapa 3'),
            ],
          ),
        ),
        // 3. El contenido de cada pestaña
        body: const TabBarView(
          children: [
            // Pasamos el ID del mapa a nuestro widget de lista
            RankingList(mapId: 'mapa_1'),
            RankingList(mapId: 'mapa_2'),
            RankingList(mapId: 'mapa_3'),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET AUXILIAR ---
// Este widget se encarga de mostrar la lista de un mapa específico

class RankingList extends StatelessWidget {
  final String mapId;
  const RankingList({Key? key, required this.mapId}) : super(key: key);

  // Función para formatear el tiempo (MM:SS:ms)
  String _formatTime(int milliseconds) {
    int minutes = (milliseconds ~/ 60000);
    int seconds = ((milliseconds % 60000) ~/ 1000);
    int millis = (milliseconds % 1000);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(3, '0')}';
  }

  // Devuelve un trofeo para el Top 3, o el número para los demás
  Widget _getRankWidget(int rank) {
    switch (rank) {
      case 1:
        return Icon(Icons.emoji_events, color: Colors.amber[600], size: 32);
      case 2:
        return Icon(Icons.emoji_events, color: Colors.grey[400], size: 32);
      case 3:
        return Icon(Icons.emoji_events, color: Colors.brown[400], size: 32);
      default:
        return SizedBox(
          width: 32,
          child: Center(
            child: Text(
              '$rank.',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // La Query a Firestore
    final query = FirebaseFirestore.instance
        .collection('rankings')
        .doc(mapId)
        .collection('scores')
        .orderBy('time_ms') // Ordenar por tiempo (el más rápido primero)
        .limit(20); // Traer solo el Top 20

    // Usamos StreamBuilder para datos en tiempo real
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        // Estado de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar datos'));
        }

        // Sin datos o lista vacía (con el nuevo diseño)
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aún no hay puntajes',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                Text(
                  '¡Sé el primero en marcar un récord!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // Tenemos datos: construimos la lista con el nuevo diseño
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final rank = index + 1;

            return Card(
              elevation: 2.0,
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                leading: _getRankWidget(rank),
                title: Text(
                  data['username'] ?? 'Anónimo',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                trailing: Text(
                  _formatTime(data['time_ms'] ?? 0),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'monospace', // Le da un look de cronómetro
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}