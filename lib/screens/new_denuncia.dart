// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/db_helper.dart';
import '../models/denuncia_model.dart';

class NewDenunciaScreen extends StatefulWidget {
  const NewDenunciaScreen({super.key});

  @override
  State<NewDenunciaScreen> createState() => _NewDenunciaScreenState();
}

class _NewDenunciaScreenState extends State<NewDenunciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _enderecoController = TextEditingController();

  DateTime? _dataSelecionada;
  String? _tipoSelecionado;
  File? _imagem;
  LatLng? _localizacaoSelecionada;
  GoogleMapController? _mapController;

  /// Lista de tipos de denúncia disponíveis
  final List<String> _tipos = ['Poluição', 'Violência', 'Abandono', 'Outros'];

  Denuncia? _denunciaExistente; // Denúncia recebida para edição

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Denuncia) {
      _denunciaExistente = args;
      _tituloController.text = args.titulo;
      _descricaoController.text = args.descricao;
      _dataSelecionada = args.dataHora;

      _tipoSelecionado = args.tipo;
      _imagem = File(args.imagemPath);
      _localizacaoSelecionada = LatLng(args.latitude, args.longitude);
      // endereço não está salvo, então não é possível preencher o campo de texto com ele
    }
  }

  void _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (data != null) setState(() => _dataSelecionada = data);
  }

  Future<void> _selecionarImagem(ImageSource origem) async {
    final picker = ImagePicker();
    final imagem = await picker.pickImage(source: origem);
    if (imagem != null) {
      final dir = await getApplicationDocumentsDirectory();
      final nome = p.basename(imagem.path);
      final destino = File('${dir.path}/$nome');
      await File(imagem.path).copy(destino.path);
      setState(() => _imagem = destino);
    }
  }

  Future<void> _salvarDenuncia() async {
    /// Salva ou atualiza a denúncia no banco de dados local
    if (!_formKey.currentState!.validate() ||
        _dataSelecionada == null ||
        _tipoSelecionado == null ||
        _imagem == null ||
        _localizacaoSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Preencha todos os campos e selecione a localização e imagem.'),
        ),
      );
      return;
    }

    final novaDenuncia = Denuncia(
      id: _denunciaExistente
          ?.id, // id para localizar a denúncia no banco de dados
      titulo: _tituloController.text,
      descricao: _descricaoController.text,
      tipo: _tipoSelecionado!,
      endereco: _enderecoController.text,
      imagemPath: _imagem!.path,
      latitude: _localizacaoSelecionada!.latitude,
      longitude: _localizacaoSelecionada!.longitude,
      dataHora: _denunciaExistente?.dataHora ?? DateTime.now(),
    );

    if (_denunciaExistente == null) {
      await DBHelper.instance.inserirDenuncia(novaDenuncia);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Denúncia criada com sucesso!')),
      );
    } else {
      await DBHelper.instance.atualizarDenuncia(novaDenuncia);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Denúncia atualizada com sucesso!')),
      );
    }

    Navigator.pop(context);
  }

  Future<void> _buscarCoordenadasPorEndereco(String endereco) async {
    /// Converte um endereço digitado em coordenadas geográficas
    try {
      List<Location> locais = await locationFromAddress(endereco);
      if (locais.isNotEmpty) {
        final local = locais.first;
        final novaPosicao = LatLng(local.latitude, local.longitude);
        setState(() => _localizacaoSelecionada = novaPosicao);
        _mapController?.animateCamera(CameraUpdate.newLatLng(novaPosicao));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endereço não encontrado.')),
      );
    }
  }

  void _aoTocarNoMapa(LatLng posicao) {
    /// Define a localização ao tocar no mapa
    setState(() => _localizacaoSelecionada = posicao);
  }

  @override
  Widget build(BuildContext context) {
    /// layout da tela
    final isEditando = _denunciaExistente != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditando ? 'Editar Denúncia' : 'Nova Denúncia'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => v!.isEmpty ? 'Informe o título' : null,
              ),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) => v!.isEmpty ? 'Informe a descrição' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _enderecoController,
                      decoration: const InputDecoration(labelText: 'Endereço'),
                      validator: (v) =>
                          v!.isEmpty ? 'Informe o endereço' : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      if (_enderecoController.text.isNotEmpty) {
                        _buscarCoordenadasPorEndereco(_enderecoController.text);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(_dataSelecionada == null
                      ? 'Data não selecionada'
                      : 'Data: ${_dataSelecionada!.day}/${_dataSelecionada!.month}/${_dataSelecionada!.year}'),
                  const Spacer(),
                  TextButton(
                    onPressed: _selecionarData,
                    child: const Text('Selecionar Data'),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _tipoSelecionado,
                items: _tipos.map((tipo) {
                  return DropdownMenuItem(value: tipo, child: Text(tipo));
                }).toList(),
                onChanged: (v) => setState(() => _tipoSelecionado = v),
                decoration:
                    const InputDecoration(labelText: 'Tipo de denúncia'),
                validator: (v) => v == null ? 'Selecione um tipo' : null,
              ),
              const SizedBox(height: 16),
              _imagem == null
                  ? const Text('Nenhuma imagem selecionada')
                  : Image.file(_imagem!, height: 200),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () => _selecionarImagem(ImageSource.camera),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo),
                    onPressed: () => _selecionarImagem(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Toque no mapa para escolher a localização:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 250,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _localizacaoSelecionada ??
                        const LatLng(-15.793889, -47.882778),
                    zoom: 14,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: _aoTocarNoMapa,
                  markers: _localizacaoSelecionada == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('local'),
                            position: _localizacaoSelecionada!,
                          ),
                        },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _salvarDenuncia,
                child:
                    Text(isEditando ? 'Atualizar Denúncia' : 'Salvar Denúncia'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
