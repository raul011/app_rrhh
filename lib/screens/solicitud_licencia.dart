import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:si2/widgets/comentario_modal.dart';

class SolicitarLicenciaScreen extends StatefulWidget {
  const SolicitarLicenciaScreen({Key? key}) : super(key: key);

  @override
  State<SolicitarLicenciaScreen> createState() =>
      _SolicitarLicenciaScreenState();
}

class _SolicitarLicenciaScreenState extends State<SolicitarLicenciaScreen> {
  String selectedLicencia = 'Vacaciones';
  DateTime fechaInicio = DateTime(2024, 7, 15);
  DateTime fechaFin = DateTime(2024, 7, 19);
  final TextEditingController motivoController = TextEditingController();
  final _instruccionesController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<XFile> _imageFiles = [];

  int get totalDias {
    return fechaFin.difference(fechaInicio).inDays + 1;
  }

  Future<void> _selectDate(BuildContext context, bool isInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInicio ? fechaInicio : fechaFin,
      firstDate: DateTime(2024),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          fechaInicio = picked;
        } else {
          fechaFin = picked;
        }
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF2196F3),
                  ),
                  title: const Text('Tomar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF2196F3),
                  ),
                  title: const Text('Seleccionar de galería'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.grey),
                  title: const Text('Cancelar'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Comprime la imagen al 80% de calidad
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _imageFiles.add(image);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen agregada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _enviarSolicitud() async {
    if (motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un motivo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://tu-backend.com/api/solicitudes'), // Cambia esta URL
      );

      // Agregar campos de texto
      request.fields['tipo_licencia'] = selectedLicencia;
      request.fields['fecha_inicio'] =
          '${fechaInicio.year}-${fechaInicio.month.toString().padLeft(2, '0')}-${fechaInicio.day.toString().padLeft(2, '0')}';
      request.fields['fecha_fin'] =
          '${fechaFin.year}-${fechaFin.month.toString().padLeft(2, '0')}-${fechaFin.day.toString().padLeft(2, '0')}';
      request.fields['total_dias'] = totalDias.toString();
      request.fields['motivo'] = motivoController.text;

      // Agregar imágenes
      for (int i = 0; i < _imageFiles.length; i++) {
        var file = await http.MultipartFile.fromPath(
          'documentos[]', // El nombre del campo en tu backend
          _imageFiles[i].path,
        );
        request.files.add(file);
      }

      // Agregar headers si necesitas autenticación
      // request.headers['Authorization'] = 'Bearer tu_token_aqui';

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      Navigator.pop(context); // Cerrar loading

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Limpiar el formulario
        setState(() {
          motivoController.clear();
          _imageFiles.clear();
          selectedLicencia = 'Vacaciones';
        });
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _instruccionesController.dispose();
    super.dispose();
  }

  void _mostrarComentarioModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color.fromARGB(255, 204, 197, 197),
          child: ComentarioModal(
            controller: _instruccionesController,
            onGuardar: () => Navigator.pop(context),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E4A7B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Solicitar Licencia',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tipo de Licencia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildLicenciaButton(
                      'Vacaciones',
                      Icons.beach_access,
                      selectedLicencia == 'Vacaciones',
                      const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLicenciaButton(
                      'Enfermedad',
                      Icons.medical_services,
                      selectedLicencia == 'Enfermedad',
                      const Color(0xFF80DEEA),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLicenciaButton(
                      'Otro',
                      Icons.help_outline,
                      selectedLicencia == 'Otro',
                      Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Fechas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      'Fecha de Inicio',
                      fechaInicio,
                      () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      'Fecha de Fin',
                      fechaFin,
                      () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Días',
                      style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
                    ),
                    Text(
                      '$totalDias días',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Motivo / Descripción',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _mostrarComentarioModal,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(15),
                    color: const Color.fromARGB(255, 126, 125, 128),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Comentarios',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 236, 228, 228),
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: const Color.fromARGB(255, 245, 243, 243),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Adjuntar Documentos (Opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF80DEEA),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showImageSourceDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            color: const Color(0xFF80DEEA),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Tomar foto o seleccionar',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF546E7A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_imageFiles.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Imágenes adjuntas (${_imageFiles.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: _imageFiles.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_imageFiles[index].path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _enviarSolicitud,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4A7B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Enviar Solicitud',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLicenciaButton(
    String text,
    IconData icon,
    bool isSelected,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLicencia = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE0E0E0),
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF546E7A),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : const Color(0xFF546E7A),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime date, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Color(0xFF2196F3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
