import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MiAppPeliculas());
}

class MiAppPeliculas extends StatelessWidget {
  const MiAppPeliculas({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catálogo de Películas',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const PantallaInicio(),
    );
  }
}

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController directorController = TextEditingController();
  final TextEditingController anioController = TextEditingController();

  Future<void> agregarPelicula() async {
    if (tituloController.text.isEmpty ||
        directorController.text.isEmpty ||
        anioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('peliculas').add({
      'titulo': tituloController.text,
      'director': directorController.text,
      'anio': int.tryParse(anioController.text) ?? 0,
      'fechaRegistro': DateTime.now(),
    });

    tituloController.clear();
    directorController.clear();
    anioController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Película agregada correctamente')),
    );
  }

  Future<void> eliminarPelicula(String id) async {
    await FirebaseFirestore.instance.collection('peliculas').doc(id).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Película eliminada')),
    );
  }

  @override
  void dispose() {
    tituloController.dispose();
    directorController.dispose();
    anioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff1f1f1),
      appBar: AppBar(
        title: const Text('Catálogo de Películas'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xff263238),
                    Color(0xff455a64),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text(
                  'Bienvenido a tu app de películas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Agregar nueva película',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título de la película',
                      prefixIcon: Icon(Icons.movie),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: directorController,
                    decoration: const InputDecoration(
                      labelText: 'Director',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: anioController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      prefixIcon: Icon(Icons.calendar_month),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: agregarPelicula,
                    icon: const Icon(Icons.add),
                    label: const Text('Guardar en Firebase'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Categorías principales',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                categoriaItem('Acción', Icons.local_fire_department),
                categoriaItem('Drama', Icons.theater_comedy),
                categoriaItem('Comedia', Icons.sentiment_satisfied),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              'Películas en Firebase',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('peliculas')
                  .orderBy('fechaRegistro', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error al cargar películas');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final peliculas = snapshot.data!.docs;

                if (peliculas.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Aún no hay películas registradas.'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: peliculas.length,
                  itemBuilder: (context, index) {
                    final pelicula = peliculas[index];
                    final data = pelicula.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 7,
                            color: Colors.black12,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: Icon(
                            Icons.movie,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          data['titulo'] ?? 'Sin título',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          '${data['director'] ?? 'Sin director'} - ${data['anio'] ?? ''}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => eliminarPelicula(pelicula.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  static Widget categoriaItem(String titulo, IconData icono) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            blurRadius: 5,
            color: Colors.black12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icono, color: Colors.white, size: 30),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}