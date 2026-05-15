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
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
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

  String generoSeleccionado = 'Acción';
  int calificacionSeleccionada = 5;

  final List<String> generos = ['Acción', 'Drama', 'Comedia', 'Terror', 'Sci-Fi'];

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
      'genero': generoSeleccionado,
      'calificacion': calificacionSeleccionada,
      'fechaRegistro': FieldValue.serverTimestamp(),
    });

    tituloController.clear();
    directorController.clear();
    anioController.clear();

    setState(() {
      generoSeleccionado = 'Acción';
      calificacionSeleccionada = 5;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Película agregada correctamente')),
    );
  }

  Future<void> eliminarPelicula(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar película'),
          content: const Text('¿Seguro que deseas eliminar esta película?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance.collection('peliculas').doc(id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Película eliminada')),
      );
    }
  }

  Future<void> editarPelicula(
    String id,
    Map<String, dynamic> data,
  ) async {
    final TextEditingController editarTitulo =
        TextEditingController(text: data['titulo'] ?? '');
    final TextEditingController editarDirector =
        TextEditingController(text: data['director'] ?? '');
    final TextEditingController editarAnio =
        TextEditingController(text: '${data['anio'] ?? ''}');

    String editarGenero = data['genero'] ?? 'Acción';
    int editarCalificacion = data['calificacion'] ?? 5;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar película'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: editarTitulo,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editarDirector,
                      decoration: const InputDecoration(
                        labelText: 'Director',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editarAnio,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: editarGenero,
                      decoration: const InputDecoration(
                        labelText: 'Género',
                        border: OutlineInputBorder(),
                      ),
                      items: generos.map((genero) {
                        return DropdownMenuItem(
                          value: genero,
                          child: Text(genero),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          editarGenero = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: editarCalificacion,
                      decoration: const InputDecoration(
                        labelText: 'Calificación',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(5, (index) {
                        final valor = index + 1;
                        return DropdownMenuItem(
                          value: valor,
                          child: Text('$valor estrellas'),
                        );
                      }),
                      onChanged: (value) {
                        setDialogState(() {
                          editarCalificacion = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('peliculas')
                        .doc(id)
                        .update({
                      'titulo': editarTitulo.text,
                      'director': editarDirector.text,
                      'anio': int.tryParse(editarAnio.text) ?? 0,
                      'genero': editarGenero,
                      'calificacion': editarCalificacion,
                      'fechaActualizacion': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Película actualizada correctamente'),
                      ),
                    );
                  },
                  child: const Text('Guardar cambios'),
                ),
              ],
            );
          },
        );
      },
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: generoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Género',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: generos.map((genero) {
                      return DropdownMenuItem(
                        value: genero,
                        child: Text(genero),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        generoSeleccionado = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: calificacionSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Calificación',
                      prefixIcon: Icon(Icons.star),
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(5, (index) {
                      final valor = index + 1;
                      return DropdownMenuItem(
                        value: valor,
                        child: Text('$valor estrellas'),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        calificacionSeleccionada = value!;
                      });
                    },
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

                    final int calificacion = data['calificacion'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(10),
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['director'] ?? 'Sin director'} - ${data['anio'] ?? ''}',
                            ),
                            Text('Género: ${data['genero'] ?? 'Sin género'}'),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < calificacion
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                );
                              }),
                            ),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.indigo,
                              ),
                              onPressed: () =>
                                  editarPelicula(pelicula.id, data),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  eliminarPelicula(pelicula.id),
                            ),
                          ],
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
}