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

  // Función para formatear el tiempo (ms a SS.ms)
  String _formatTime(int milliseconds) {
    final seconds = (milliseconds / 1000).toStringAsFixed(3);
    return '$seconds s';
  }

  @override
  Widget build(BuildContext context) {
    // 4. La Query a Firestore
    final query = FirebaseFirestore.instance
        .collection('rankings')
        .doc(mapId)
        .collection('scores')
        .orderBy('time_ms') // Ordenar por tiempo (el más rápido primero)
        .limit(20);          // Traer solo el Top 20

    // 5. Usamos StreamBuilder para datos en tiempo real
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

        // Sin datos o lista vacía
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aún no hay puntajes para este mapa'));
        }

        // 6. Tenemos datos: construimos la lista
        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            return ListTile(
              // Posición (1., 2., 3.)
              leading: Text(
                '${index + 1}.',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Nombre de usuario
              title: Text(
                data['username'] ?? 'Anónimo',
                style: const TextStyle(fontSize: 16),
              ),
              // Tiempo
              trailing: Text(
                _formatTime(data['time_ms'] ?? 0),
                style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.w500),
              ),
            );
          },
        );
      },
    );
  }
}