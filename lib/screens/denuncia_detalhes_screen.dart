import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Essa tela mostra os detalhes de uma denúncia específica
class DenunciaDetalhesScreen extends StatelessWidget {
  final Map<String, dynamic>
      denuncia; // aqui a denúncia vem como um mapa com os dados dela

  const DenunciaDetalhesScreen({super.key, required this.denuncia});

  @override
  Widget build(BuildContext context) {
    final double latitude = denuncia['latitude'];
    final double longitude = denuncia['longitude'];
    //  um AppBar com o título "Detalhes da Denúncia" e e um body com todas as informações da denúncia organizadas em colunas
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Denúncia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (denuncia['imagePath'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(denuncia['imagePath']),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Título: ${denuncia['titulo'] ?? 'Não informado'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Descrição: ${denuncia['descricao'] ?? 'Não informada'}'),
            const SizedBox(height: 8),
            Text('Tipo: ${denuncia['tipo'] ?? 'Não informado'}'),
            const SizedBox(height: 8),
            Text(
                'Data: ${denuncia['dataHora']?.toString().split("T").first ?? 'Não informada'}'),
            const SizedBox(height: 16),
            Text('Endereço: ${denuncia['endereco'] ?? 'Não informado'}'),
            const SizedBox(height: 16),
            const Text('Localização no mapa:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Aqui entra o Google Maps com o ponto da denúncia marcado
            SizedBox(
              height: 200,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(latitude, longitude),
                  zoom: 16,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('local'),
                    position: LatLng(latitude,
                        longitude), // foca no ponto vermelho da denúncia
                  ),
                },
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                liteModeEnabled: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
