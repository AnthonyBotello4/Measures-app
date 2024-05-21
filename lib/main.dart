import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart'; // Asegúrate de que esta importación sea correcta
import 'package:ar_flutter_plugin/datatypes/node_types.dart'; // Asegúrate de que esta importación sea correcta
import 'package:vector_math/vector_math_64.dart' as vector_math;

void main() {
  runApp(const ARMeasurementApp());
}

class ARMeasurementApp extends StatelessWidget {
  const ARMeasurementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Measurement App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ARMeasurementPage(),
    );
  }
}

class ARMeasurementPage extends StatefulWidget {
  const ARMeasurementPage({super.key});

  @override
  _ARMeasurementPageState createState() => _ARMeasurementPageState();
}

class _ARMeasurementPageState extends State<ARMeasurementPage> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;
  ARNode? measurementNode;
  ARAnchor? anchor;
  List<double> distances = [];

  @override
  void dispose() {
    super.dispose();
    arSessionManager.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Measurement App'),
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: onMeasureButtonPressed,
              child: const Text('Measure'),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              distances.isNotEmpty ? 'Distance: ${distances.last.toStringAsFixed(2)} m' : '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onARViewCreated(ARSessionManager arSessionManager, ARObjectManager arObjectManager, ARAnchorManager arAnchorManager, ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: 'Images/triangle.png',
      showWorldOrigin: true,
      handleTaps: false,
    );

    this.arObjectManager.onInitialize();
  }

  Future<void> onMeasureButtonPressed() async {
    if (measurementNode != null) {
      arObjectManager.removeNode(measurementNode!);
      measurementNode = null;
    }

    final anchor = ARPlaneAnchor(transformation: vector_math.Matrix4.identity());
    bool? didAddAnchor = await arAnchorManager.addAnchor(anchor);
    if (didAddAnchor!) {
      this.anchor = anchor;

      final node = ARNode(
        type: NodeType.webGLB,
        uri: "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Duck/glTF-Binary/Duck.glb", // Cambia esto a la URI de tu modelo
        scale: vector_math.Vector3(0.05, 0.05, 0.05),
        position: vector_math.Vector3.zero(),
      );

      bool? didAddNodeToAnchor = await arObjectManager.addNode(node, planeAnchor: anchor);
      if (didAddNodeToAnchor!) {
        setState(() {
          measurementNode = node;
        });

        final distance = calculateDistance(anchor.transformation);
        setState(() {
          distances.add(distance);
        });
      }
    }
  }

  double calculateDistance(vector_math.Matrix4 transformation) {
    final vector_math.Vector3 position = transformation.getTranslation();
    return position.length;
  }
}
