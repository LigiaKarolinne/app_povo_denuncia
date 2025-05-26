import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

import '../db/db_helper.dart';
import '../models/denuncia_model.dart';

class EditDenunciaScreen extends StatefulWidget {
  final Map<String, dynamic> denunciaMap;

  const EditDenunciaScreen({super.key, required this.denunciaMap});

  @override
  State<EditDenunciaScreen> createState() => _EditDenunciaScreenState();
}

class _EditDenunciaScreenState extends State<EditDenunciaScreen> {
  final _formKey = GlobalKey<FormState>();

   // Controladores para os campos de texto do formulário
  late TextEditingController _tituloController;
  late TextEditingController _descricaoController;
  late TextEditingController _tipoController;
  late TextEditingController _dataHoraController;
  late TextEditingController _enderecoController;

  late Denuncia _denuncia; // Instância do modelo Denuncia carregada a partir dos dados recebidos
  String? _imagemPath; // Caminho da imagem associada à denúncia
  LatLng? _localizacao; // Coordenadas geográficas atuais da denúncia
  GoogleMapController? _mapController; // Controlador do Google Maps para manipulação do mapa


  late DateTime _dataHora;

  @override
  void initState() {
    super.initState();
      // Inicializa o modelo Denuncia a partir do mapa recebido 
    _denuncia = Denuncia.fromMap(widget.denunciaMap);
    
    // Inicializa os controladores com os valores atuais da denúncia
    _tituloController = TextEditingController(text: _denuncia.titulo);
    _descricaoController = TextEditingController(text: _denuncia.descricao);
    _tipoController = TextEditingController(text: _denuncia.tipo);
    _imagemPath = _denuncia.imagemPath;
    _enderecoController = TextEditingController();

    _dataHora = _denuncia.dataHora;
    _dataHoraController = TextEditingController(text: _formatarDataHora(_dataHora));

    _localizacao = LatLng(_denuncia.latitude, _denuncia.longitude);
    _buscarEndereco(_localizacao!);
  
    _enderecoController.addListener(() {
      _atualizarCoordenadasPorEndereco(_enderecoController.text);
    });
  }

  String _formatarDataHora(DateTime dt) {
    return "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
  }

  Future<void> _selecionarDataHora(BuildContext context) async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (dataSelecionada != null) {
      final TimeOfDay? horaSelecionada = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay(hour: _dataHora.hour, minute: _dataHora.minute),
      );

      if (horaSelecionada != null) {
        setState(() {
          _dataHora = DateTime(
            dataSelecionada.year,
            dataSelecionada.month,
            dataSelecionada.day,
            horaSelecionada.hour,
            horaSelecionada.minute,
          );
          _dataHoraController.text = _formatarDataHora(_dataHora);
        });
      }
    }
  }

  Future<void> _buscarEndereco(LatLng coordenadas) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          coordenadas.latitude, coordenadas.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _enderecoController.text =
              '${place.street}, ${place.subLocality}, ${place.locality}';
        });
      }
    } catch (e) {
      debugPrint('Erro ao buscar endereço: $e');
    }
  }
   // Converte o endereço textual para coordenadas geográficas e atualiza o mapa com a nova localização
  Future<void> _atualizarCoordenadasPorEndereco(String endereco) async {
    try {
      List<Location> locations = await locationFromAddress(endereco);
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _localizacao = LatLng(location.latitude, location.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_localizacao!),
        );
      }
    } catch (e) {
      debugPrint('Endereço inválido ou não encontrado: $e');
    }
  }
  
   // Salva as alterações feitas na denúncia atualizando o registro no banco de dados local
  
  Future<void> _salvarDenuncia() async {
    if (_formKey.currentState!.validate()) {
      Denuncia updatedDenuncia = Denuncia(
        id: _denuncia.id,
        titulo: _tituloController.text,
        descricao: _descricaoController.text,
        tipo: _tipoController.text,
        endereco: _enderecoController.text,
        dataHora: _dataHora,  // <-- aqui passa DateTime correto
        imagemPath: _imagemPath ?? '',
        latitude: _localizacao!.latitude,
        longitude: _localizacao!.longitude,

      );

      await DBHelper.instance.atualizarDenuncia(updatedDenuncia);
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _tipoController.dispose();
    _dataHoraController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Denúncia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) =>
                    value!.isEmpty ? 'Informe o título' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 4,
                validator: (value) =>
                    value!.isEmpty ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tipoController,
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dataHoraController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Data e Hora',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _selecionarDataHora(context),
                validator: (value) =>
                    value!.isEmpty ? 'Informe a data e hora' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _enderecoController,
                decoration: const InputDecoration(labelText: 'Endereço'),
              ),
              const SizedBox(height: 16),
              if (_imagemPath != null)
                Image.file(
                  File(_imagemPath!),
                  height: 150,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _localizacao != null
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _localizacao!,
                          zoom: 16,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('denuncia'),
                            position: _localizacao!,
                          ),
                        },
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                      )
                    : const Center(child: Text('Mapa não disponível')),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvarDenuncia,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

