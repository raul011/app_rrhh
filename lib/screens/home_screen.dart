import 'package:flutter/material.dart';
import 'package:si2/screens/login_screen.dart';
import 'package:si2/screens/perfil_usuario.dart';
import 'package:si2/screens/registroAsistencia_screen.dart';
import 'package:si2/services/session_service.dart';
import 'package:si2/screens/solicitud_licencia.dart';

class HomeScreen extends StatefulWidget {
  // const HomeScreen({super.key, required this.userRole}); //  Constructor modificado
  HomeScreen({super.key}); //  Constructor modificado

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _cargarSesion() async {
    final token = await SessionService.obtenerToken();
    final user = await SessionService.obtenerUsuario();
    final nombre = await SessionService.obtenerNombre();

    print('Sesión cargada: $token, $user , $nombre');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sistema de rrhh',
          style: TextStyle(fontWeight: FontWeight.w300),
          textAlign: TextAlign.center,
        ),
        //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        backgroundColor: const Color.fromARGB(255, 30, 38, 85),
        foregroundColor: Colors.white, //  Color del texto y los iconos
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00D9D9)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
            onSelected: (value) async {
              if (value == 'perfil') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PerfilUsuarioScreen(),
                  ),
                );
              } else if (value == 'logout') {
                // Borrar la sesión
                await SessionService.limpiarSesion();
                // Navegar a la pantalla de login y eliminar el historial de rutas
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                }
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'perfil',
                    child: ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Ver Perfil'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Cerrar Sesión'),
                    ),
                  ),
                ],
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 11, 22, 37), // Color de fondo

      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 10), // Espacio entre tarjetas
          _buildMenuCard(
            context,
            icon: Icons.event,
            title: 'Asistencia',
            subtitle: 'Registra tu asistencia',
            onTap: () {
              _cargarSesion();

              Navigator.push(
                context, // Cambia ReservationsScreen() por CardFieldTest()
                MaterialPageRoute(builder: (context) => LocationHomePage()),
                //  MaterialPageRoute(builder: (context) => PaymentScreen()),
              );
            },
            color1: const Color.fromARGB(255, 15, 202, 177),
            color2: const Color.fromARGB(255, 20, 125, 200),
          ),

          _buildMenuCard(
            context,
            icon: Icons.event,
            title: 'Licencia',
            subtitle: 'Solicita tu licencia',
            onTap: () {
              _cargarSesion();

              Navigator.push(
                context, // Cambia ReservationsScreen() por CardFieldTest()
                MaterialPageRoute(
                  builder: (context) => SolicitarLicenciaScreen(),
                ),
                //  MaterialPageRoute(builder: (context) => PaymentScreen()),
              );
            },
            color1: const Color.fromARGB(255, 15, 202, 177),
            color2: const Color.fromARGB(255, 20, 125, 200),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color1, // 👈 primer color
    required Color color2, // 👈 segundo color
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          leading: Icon(icon, size: 40, color: Colors.white),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Colors.white70),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
