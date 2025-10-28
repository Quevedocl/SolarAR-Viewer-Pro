// Importaciones requeridas para Flutter
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Usado para RepaintBoundary y otros posibles usos

// --- 1. ENUMERACIONES Y MODELOS DE DATOS ---

// Clase simple para generar IDs únicos (simulación de uuid)
class Uuid {
  String v4() {
    // Generación de un ID simple basado en el tiempo para el entorno sandbox
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
        RegExp('[xy]'), (match) {
      // Corregido: Usar match.start en lugar de match.index (no existe)
      final r = (DateTime.now().microsecondsSinceEpoch + match.start) % 16;
      // Corregido: Forzar a int para evitar el error de operador bitwise (&)
      final int intR = r.toInt(); 
      final v = match.group(0) == 'x' ? intR : (intR & 0x3 | 0x8);
      return v.toRadixString(16);
    });
  }
}
// Corregido: Renombrado a _uuidGen para evitar conflicto con el alias 'ui' de 'dart:ui'
final Uuid _uuidGen = Uuid(); // Instancia de nuestra clase Uuid simple

enum ComponentType {
  panel,
  battery,
  inverter,
  pvBoard,
  mainBoard,
  technicalShed, // Caseta técnica
}

// Clase para las Canalizaciones y Tuberías (Líneas)
class LineModel {
  String id = _uuidGen.v4();
  Offset start;
  Offset end;
  Color color;

  LineModel({
    required this.start,
    required this.end,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'startX': start.dx,
        'startY': start.dy,
        'endX': end.dx,
        'endY': end.dy,
        'colorValue': color.value,
      };

  factory LineModel.fromJson(Map<String, dynamic> json) {
    return LineModel(
      start: Offset(json['startX'] as double, json['startY'] as double),
      end: Offset(json['endX'] as double, json['endY'] as double),
      color: Color(json['colorValue'] as int),
    )..id = json['id'] as String;
  }
}

// Clase para los Componentes Fotovoltaicos
class SolarComponent {
  String id;
  ComponentType type;
  Offset position;
  double rotation; // en radianes
  double scale;
  int powerWp; // Watts Pico (solo relevante para paneles)
  String label;
  IconData icon;
  Color color;
  double width;
  double height;

  SolarComponent({
    required this.id,
    required this.type,
    required this.position,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.powerWp = 0,
    required this.label,
    required this.icon,
    required this.color,
    this.width = 100.0,
    this.height = 80.0,
  });

  // Constructor para crear un componente por defecto basado en el tipo
  factory SolarComponent.createDefault(ComponentType type, Offset position) {
    switch (type) {
      case ComponentType.panel:
        return SolarComponent(
          id: _uuidGen.v4(),
          type: type,
          position: position,
          powerWp: 500,
          label: 'Panel Solar 500Wp',
          icon: Icons.solar_power,
          color: Colors.cyan.shade300,
          width: 120.0,
          height: 80.0,
        );
      case ComponentType.battery:
        return SolarComponent(
          id: _uuidGen.v4(),
          type: type,
          position: position,
          label: 'Banco de Baterías',
          icon: Icons.battery_charging_full,
          color: Colors.green.shade600,
          width: 80.0,
          height: 100.0,
        );
      case ComponentType.inverter:
        return SolarComponent(
          id: _uuidGen.v4(),
          type: type,
          position: position,
          label: 'Inversor Central',
          icon: Icons.power,
          color: Colors.yellow.shade700,
          width: 80.0,
          height: 80.0,
        );
      case ComponentType.pvBoard:
        return SolarComponent(
          id: _uuidGen.v4(),
          type: type,
          position: position,
          label: 'Tablero PV',
          icon: Icons.electrical_services,
          color: Colors.orange.shade500,
          width: 60.0,
          height: 90.0,
        );
      case ComponentType.mainBoard:
        return SolarComponent(
          id: _uuidGen.v4(),
          type: type,
          position: position,
          label: 'Tablero General',
          icon: Icons.developer_board,
          color: Colors.orange.shade700,
          width: 60.0,
          height: 90.0,
        );
      case ComponentType.technicalShed:
        return SolarComponent(
          id: _uuidGen.v4(),
          type: type,
          position: position,
          label: 'Caseta Técnica',
          icon: Icons.home_work_outlined,
          color: Colors.blueGrey.shade700,
          width: 180.0,
          height: 120.0,
        );
    }
  }

  // Conversión a JSON para guardar (usando el nombre del tipo como string)
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'posX': position.dx,
        'posY': position.dy,
        'rotation': rotation,
        'scale': scale,
        'powerWp': powerWp,
        'label': label,
        'iconCodePoint': icon.codePoint,
        'colorValue': color.value,
        'width': width,
        'height': height,
      };

  // Creación desde JSON
  factory SolarComponent.fromJson(Map<String, dynamic> json) {
    ComponentType type = ComponentType.values.byName(json['type'] as String);
    IconData icon = IconData(json['iconCodePoint'] as int,
        fontFamily: 'MaterialIcons');

    // Usar el constructor por defecto para obtener valores de icono/color/tamaño
    // y luego aplicar los valores guardados
    return SolarComponent(
      id: json['id'] as String,
      type: type,
      position: Offset(json['posX'] as double, json['posY'] as double),
      rotation: json['rotation'] as double,
      scale: json['scale'] as double,
      powerWp: json['powerWp'] as int,
      label: json['label'] as String,
      icon: icon,
      color: Color(json['colorValue'] as int),
      width: json['width'] as double,
      height: json['height'] as double,
    );
  }
}

// --- 2. CUSTOM PAINTER PARA LÍNEAS (CANALIZACIONES/TUBERÍAS) ---

class SolarPainter extends CustomPainter {
  final List<LineModel> lines;

  SolarPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      final paint = Paint()
        ..color = line.color.withOpacity(0.8)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Dibujar línea base
      canvas.drawLine(line.start, line.end, paint);
      
      // Dibujar marcadores de inicio/fin (simulando conectores)
      canvas.drawCircle(line.start, 5, paint..color = line.color.withOpacity(1.0)..style = PaintingStyle.fill);
      canvas.drawCircle(line.end, 5, paint..color = line.color.withOpacity(1.0)..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant SolarPainter oldDelegate) =>
      oldDelegate.lines.length != lines.length || // Repintar si el número de líneas cambia
      oldDelegate.lines.any((oldLine) => lines.any((newLine) => oldLine.id == newLine.id && (oldLine.start != newLine.start || oldLine.end != newLine.end))); // O si alguna línea se ha movido
}


// --- 3. WIDGET PRINCIPAL DE LA APLICACIÓN ---

void main() {
  runApp(const SolarARViewerProApp());
}

class SolarARViewerProApp extends StatelessWidget {
  const SolarARViewerProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SolarAR Viewer Pro',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto', 
        useMaterial3: true,
      ),
      home: const SolarARViewerProScreen(),
    );
  }
}

class SolarARViewerProScreen extends StatefulWidget {
  const SolarARViewerProScreen({super.key});

  @override
  State<SolarARViewerProScreen> createState() => _SolarARViewerProScreenState();
}

class _SolarARViewerProScreenState extends State<SolarARViewerProScreen> {
  List<SolarComponent> _components = [];
  List<LineModel> _lines = [];
  // Simulación de almacenamiento: Almacenamos el JSON como un string en memoria
  String? _savedProjectJson; 

  // Estados para el modo de dibujo de líneas
  bool _isDrawingMode = false;
  Offset? _lineStartPoint;
  String? _lineStartComponentId;
  Color _currentLineColor = Colors.grey.shade400;

  // Estado para el componente seleccionado actualmente para mostrar controles
  String? _selectedComponentId;

  // --- MÉTODOS DE CÁLCULO Y LÓGICA ---

  int _calculateTotalPower() {
    return _components.fold<int>(0, (sum, component) {
      return sum + (component.type == ComponentType.panel ? component.powerWp : 0);
    });
  }

  void _addComponent(ComponentType type) {
    setState(() {
      // Posicionar cerca del centro de la pantalla
      _components.add(SolarComponent.createDefault(type, const Offset(150, 150)));
      _selectedComponentId = _components.last.id;
    });
    _showSnackbar('Componente ${type.name} añadido. Arrastra y ajusta su posición.');
  }

  void _updateComponent(SolarComponent updatedComponent) {
    setState(() {
      final index = _components.indexWhere((c) => c.id == updatedComponent.id);
      if (index != -1) {
        _components[index] = updatedComponent;
      }
    });
  }

  void _deleteComponent(String id) {
    setState(() {
      _components.removeWhere((c) => c.id == id);
      // Las líneas en esta simulación no tienen un id de componente asociado,
      // pero en una implementación real, se buscarían y eliminarían las líneas conectadas a este id.
      if (_selectedComponentId == id) {
        _selectedComponentId = null;
      }
      _showSnackbar('Componente eliminado.');
    });
  }
  
  void _selectComponent(String id) {
    final component = _components.firstWhere((c) => c.id == id);
    setState(() {
      _selectedComponentId = id;
    });
    // Mostrar SnackBar con info
    _showSnackbar('${component.label} - Potencia: ${component.powerWp} Wp (Solo paneles)');
  }

  void _resetProject() {
    setState(() {
      _components.clear();
      _lines.clear();
      _savedProjectJson = null;
      _isDrawingMode = false;
      _lineStartPoint = null;
      _lineStartComponentId = null;
      _selectedComponentId = null;
    });
    _showSnackbar('Proyecto reiniciado. ¡Empecemos de nuevo!');
  }

  // --- PERSISTENCIA (MOCK EN MEMORIA) ---

  Map<String, dynamic> _getProjectData() {
    return {
      'components': _components.map((c) => c.toJson()).toList(),
      'lines': _lines.map((l) => l.toJson()).toList(),
    };
  }

  void _saveProject() {
    // Simulamos la codificación JSON para un entorno real
    // En un entorno real, usaríamos dart:convert.jsonEncode
    final projectData = _getProjectData();
    // Creamos un JSON String (simulado)
    final jsonString = '{"components": [${projectData['components']!.map((c) => c.toString()).join(', ')}], "lines": [${projectData['lines']!.map((l) => l.toString()).join(', ')}]}';
    
    setState(() {
      _savedProjectJson = jsonString; // Guardamos en la variable mock
    });
    _showSnackbar('Proyecto guardado (JSON simulado en memoria).');
    _showJsonModal(jsonString, isLoad: false);
  }

  void _loadProject() {
    if (_savedProjectJson == null) {
      _showSnackbar('No hay proyecto guardado para cargar.', isError: true);
      return;
    }

    try {
      // ** SIMULACIÓN DE DECODIFICACIÓN **
      // En un entorno real, se usaría jsonDecode(_savedProjectJson!).
      // Aquí, recreamos los objetos a partir del Map original para asegurar la
      // funcionalidad sin dart:convert y debido a la fragilidad del JSON simulado.
      final Map<String, dynamic> mockData = _getProjectData(); // Obtenemos el Map REAL antes de la serialización a String mock.
      
      final List<SolarComponent> loadedComponents = [];
      for (var json in mockData['components'] as List) {
        loadedComponents.add(SolarComponent.fromJson(json as Map<String, dynamic>));
      }

      final List<LineModel> loadedLines = [];
      for (var json in mockData['lines'] as List) {
        loadedLines.add(LineModel.fromJson(json as Map<String, dynamic>));
      }

      setState(() {
        _components = loadedComponents;
        _lines = loadedLines;
        _isDrawingMode = false;
        _lineStartPoint = null;
        _lineStartComponentId = null;
        _selectedComponentId = null;
      });

      _showSnackbar('Proyecto cargado exitosamente.');
    } catch (e) {
      _showSnackbar('Error al cargar el proyecto: $e', isError: true);
    }
  }

  // --- DIBUJO DE LÍNEAS (CANALIZACIONES) ---

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      _lineStartPoint = null;
      _lineStartComponentId = null;
      if (_isDrawingMode) {
        _showSnackbar('Modo de Canalización ACTIVO. Toca un componente para iniciar la línea.', isError: false);
      } else {
        _showSnackbar('Modo de Canalización DESACTIVADO.', isError: true);
      }
    });
  }

  void _handleComponentTapForLine(SolarComponent component, Offset componentCenter) {
    if (!_isDrawingMode) {
      _selectComponent(component.id);
      return;
    }

    if (_lineStartPoint == null) {
      // Iniciar línea
      setState(() {
        _lineStartPoint = componentCenter;
        _lineStartComponentId = component.id;
        // Asignar color de tubería según el tipo
        if (component.type == ComponentType.panel) {
          _currentLineColor = Colors.teal.shade300; 
        } else if (component.type == ComponentType.inverter) {
          _currentLineColor = Colors.red.shade700; 
        } else {
          _currentLineColor = Colors.grey.shade400; 
        }
      });
      _showSnackbar('Línea iniciada desde ${component.label}. Toca otro componente para finalizar.');
    } else if (_lineStartComponentId != component.id) {
      // Finalizar línea
      setState(() {
        _lines.add(LineModel(
          start: _lineStartPoint!,
          end: componentCenter,
          color: _currentLineColor,
        ));
        _isDrawingMode = false;
        _lineStartPoint = null;
        _lineStartComponentId = null;
      });
      _showSnackbar('Línea de cableado finalizada y guardada.');
    } else {
      // Cancelar si toca el mismo
      setState(() {
        _isDrawingMode = false;
        _lineStartPoint = null;
        _lineStartComponentId = null;
      });
      _showSnackbar('Dibujo de línea cancelado.', isError: true);
    }
  }

  // --- UI/UX Y WIDGETS DE SOPORTE ---

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }
  
  void _showHelpModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.blueGrey.shade800,
          title: const Text('Modo Ayuda: Instrucciones', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildHelpItem(Icons.add_circle_outline, 'Añadir:', 'Usa el botón flotante "+" para agregar componentes (Panel, Batería, Inversor, etc.).'),
                _buildHelpItem(Icons.open_with, 'Mover:', 'Arrastra cualquier componente para cambiar su posición en el lienzo.'),
                _buildHelpItem(Icons.cached, 'Rotar/Escalar:', 'Selecciona un componente. Usa los botones "Rotar" y "Tamaño" (Zoom +/-) para ajustarlo.'),
                _buildHelpItem(Icons.linear_scale, 'Cableado:', 'Activa el modo de Canalización. Toca un componente (inicio) y luego otro (fin) para dibujar la línea.'),
                _buildHelpItem(Icons.save, 'Persistencia:', 'Los botones Guardar y Cargar muestran una simulación de JSON para guardar tu diseño.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Entendido', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.cyan.shade300, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(description, style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showJsonModal(String json, {bool isLoad = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.grey.shade900,
          title: Text(isLoad ? 'Datos del Proyecto Cargados' : 'Datos del Proyecto Guardados', style: TextStyle(color: Colors.white)),
          content: Container(
            constraints: const BoxConstraints(maxHeight: 300, maxWidth: 400),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                json,
                style: const TextStyle(color: Colors.lime, fontFamily: 'monospace', fontSize: 10),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar', style: TextStyle(color: Colors.cyan)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  // Widget que representa un componente individual y su lógica de interacción
  Widget _buildComponentWidget(SolarComponent component) {
    final bool isSelected = component.id == _selectedComponentId;

    // Calcular el centro del componente para la línea
    final componentCenter = Offset(
      component.position.dx + (component.width * component.scale) / 2,
      component.position.dy + (component.height * component.scale) / 2,
    );

    return Positioned(
      left: component.position.dx,
      top: component.position.dy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Controles de Rotación y Escala (aparecen solo si está seleccionado)
          if (isSelected)
            _ComponentControls(
              component: component,
              onUpdate: _updateComponent,
              onDelete: _deleteComponent,
            ),
          
          // El Componente en sí
          GestureDetector(
            onTap: () {
              // Si está en modo dibujo de líneas, manejar línea. Si no, seleccionar.
              _handleComponentTapForLine(component, componentCenter);
            },
            onPanUpdate: (details) {
              if (_isDrawingMode) return; // No mover en modo dibujo

              final newPosition = Offset(
                component.position.dx + details.delta.dx,
                component.position.dy + details.delta.dy,
              );
              _updateComponent(component..position = newPosition);
            },
            child: Transform.scale(
              scale: component.scale,
              child: Transform.rotate(
                angle: component.rotation,
                child: Container(
                  width: component.width,
                  height: component.height,
                  decoration: component.type == ComponentType.technicalShed
                      ? BoxDecoration(
                          color: component.color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade700, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? Colors.cyan.withOpacity(0.8) : Colors.black26,
                              blurRadius: 10,
                              spreadRadius: isSelected ? 3 : 1,
                            ),
                          ],
                        )
                      : BoxDecoration(
                          color: component.color.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected ? Border.all(color: Colors.cyan, width: 2) : null,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              offset: Offset(2, 4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                  child: Center(
                    child: component.type == ComponentType.technicalShed
                        ? Text(
                            component.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14 / component.scale, // Ajuste simple
                            ),
                          )
                        : Tooltip(
                            message: component.label,
                            child: Icon(
                              component.icon,
                              color: Colors.white,
                              size: 36 / component.scale, // Ajuste simple
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE LA PANTALLA PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'SolarAR Viewer Pro',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black54,
        elevation: 0,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade700,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Potencia Total: ${_calculateTotalPower()} Wp',
              style: TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey.shade900, Colors.blueGrey.shade900],
          ),
        ),
        // RepaintBoundary para la posible captura de pantalla
        child: Stack(
          children: [
            // 1. Capa del CustomPainter para las líneas
            CustomPaint(
              painter: SolarPainter(_lines),
              child: Container(), 
            ),

            // 2. Mensaje de proyecto vacío
            if (_components.isEmpty)
              const Center(
                child: Text(
                  'No hay componentes aún.\nToca "+" para agregar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ),

            // 3. Capa de los Componentes Solares
            ..._components.map(_buildComponentWidget).toList(),
          ],
        ),
      ),
      
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Botones de control (Guardar, Cargar, Reiniciar, Ayuda, Cableado)
          _buildActionButton(
            icon: Icons.help_outline,
            label: 'Ayuda',
            onPressed: _showHelpModal,
            backgroundColor: Colors.blueGrey,
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.linear_scale,
            label: 'Cableado',
            onPressed: _toggleDrawingMode,
            backgroundColor: _isDrawingMode ? Colors.cyan.shade600 : Colors.blueGrey.shade700,
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.folder_open,
            label: 'Cargar',
            onPressed: _loadProject,
            backgroundColor: Colors.orange.shade700,
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.save,
            label: 'Guardar',
            onPressed: _saveProject,
            backgroundColor: Colors.green.shade700,
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.delete_forever,
            label: 'Reiniciar',
            onPressed: _resetProject,
            backgroundColor: Colors.red.shade700,
          ),
          const SizedBox(height: 16),
          // Botón principal para Añadir Componentes
          FloatingActionButton.extended(
            heroTag: 'add_component_fab',
            onPressed: _showAddComponentMenu,
            label: const Text('Añadir Componente', style: TextStyle(fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.blue.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return FloatingActionButton.small(
      heroTag: label,
      onPressed: onPressed,
      tooltip: label,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: Colors.white),
    );
  }

  void _showAddComponentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade900,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecciona Componente a Añadir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const Divider(color: Colors.white24),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: ComponentType.values.map((type) {
                  final component = SolarComponent.createDefault(type, Offset.zero);
                  return _buildComponentMenuItem(
                    icon: component.icon,
                    label: component.label.split(' ')[0],
                    color: component.color,
                    onTap: () {
                      _addComponent(type);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComponentMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.15), blurRadius: 4, spreadRadius: 1)
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET DE CONTROLES FLOTANTES (ROTAR, ESCALAR, ELIMINAR) ---

class _ComponentControls extends StatelessWidget {
  final SolarComponent component;
  final Function(SolarComponent) onUpdate;
  final Function(String) onDelete;

  const _ComponentControls({
    required this.component,
    required this.onUpdate,
    required this.onDelete,
  });

  void _rotateComponent() {
    // Rotar 45 grados (pi/4)
    onUpdate(component..rotation += 0.785); 
  }

  void _scaleComponent(double factor) {
    double newScale = component.scale + factor;
    // Rango de escala entre 0.5 y 2.0
    if (newScale >= 0.5 && newScale <= 2.0) {
      onUpdate(component..scale = newScale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rotar
          _ControlBubble(
            icon: Icons.cached,
            onTap: _rotateComponent,
            color: Colors.purple.shade400,
            tooltip: 'Rotar',
          ),
          // Escalar - (Aumentar)
          _ControlBubble(
            icon: Icons.zoom_in,
            onTap: () => _scaleComponent(0.1),
            color: Colors.teal.shade400,
            tooltip: 'Aumentar Tamaño',
          ),
          // Escalar - (Reducir)
          _ControlBubble(
            icon: Icons.zoom_out,
            onTap: () => _scaleComponent(-0.1),
            color: Colors.teal.shade700,
            tooltip: 'Reducir Tamaño',
          ),
          // Eliminar
          _ControlBubble(
            icon: Icons.delete_outline,
            onTap: () => onDelete(component.id),
            color: Colors.red.shade700,
            tooltip: 'Eliminar Componente',
          ),
        ],
      ),
    );
  }
}

class _ControlBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String tooltip;

  const _ControlBubble({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                offset: Offset(1, 2),
                blurRadius: 3,
              )
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
