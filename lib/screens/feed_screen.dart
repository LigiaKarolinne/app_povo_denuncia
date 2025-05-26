import 'dart:io';
import 'package:flutter/material.dart';

import '../db/db_helper.dart'; 
import 'denuncia_detalhes_screen.dart'; 
import 'new_denuncia.dart'; 
import 'edit_denuncia.dart'; 

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> _reports = []; // Lista que armazena as denúncias

  // Função que busca as denúncias no banco de dados
  void _loadReports() async {
    final data = await DBHelper.instance.getReports(); // Busca todas as denúncias salvas
    setState(() {
      _reports = data; // Atualiza a interface com os dados
    });
  }

  // Função para deslogar e voltar para a tela inicial
  void _logout() {
    Navigator.of(context).pushReplacementNamed('/'); // Volta para a tela de login
  }

  @override
  void initState() {
    super.initState();
    _loadReports(); // Carrega os dados ao abrir a tela
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Denúncias'),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            // Abre diálogo para confirmar logout
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Sair'),
                content: const Text('Deseja realmente sair da conta?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), // Fecha o diálogo
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: _logout, // Executa logout
                    child: const Text('Sair'),
                  ),
                ],
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/user.png'), // Ícone de perfil
            ),
          ),
        ),
      ),

      // Se não houver denúncias, mostra uma mensagem. Caso contrário, exibe uma lista.
      body: _reports.isEmpty
          ? const Center(child: Text('Nenhuma denúncia cadastrada.'))
          : ListView.builder(
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final report = _reports[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: report['imagemPath'] != null
                        ? Image.file(
                            File(report['imagemPath']), // Mostra a imagem da denúncia
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.report), // Ícone padrão

                    title: Text(report['titulo'] ?? 'Sem título'), // Título da denúncia
                    subtitle: Text(report['descricao'] ?? 'Sem descrição'), // Descrição

                    // Ao clicar no card, abre um menu com opções
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) {
                          return Wrap(
                            children: [
                              // Opção de visualizar detalhes
                              ListTile(
                                leading: const Icon(Icons.visibility),
                                title: const Text('Ver detalhes'),
                                onTap: () {
                                  Navigator.pop(context); // Fecha o menu
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DenunciaDetalhesScreen(
                                        denuncia: report, // Passa os dados da denúncia
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Opção de editar denúncia
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text('Editar'),
                                onTap: () {
                                  Navigator.pop(context); // Fecha o menu
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditDenunciaScreen(
                                        denunciaMap: report, // Passa a denúncia para edição
                                      ),
                                    ),
                                  ).then((_) => _loadReports()); // Recarrega os dados após editar
                                },
                              ),

                              // Opção de excluir denúncia
                              ListTile(
                                leading: const Icon(Icons.delete),
                                title: const Text('Excluir'),
                                onTap: () {
                                  Navigator.pop(context); // Fecha o menu
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Confirmar exclusão'),
                                      content: const Text(
                                          'Você deseja realmente excluir a denúncia?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context); // Cancela
                                          },
                                          child: const Text('Não'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            Navigator.pop(context); 
                                            await DBHelper.instance
                                                .deletarDenuncia(report['id']); 
                                            _loadReports(); // Atualiza a lista
                                            // Exibe mensagem de sucesso
                                            // ignore: use_build_context_synchronously
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text('Denúncia excluída'),
                                              ),
                                            );
                                          },
                                          child: const Text('Sim'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),

      // Botão flutuante para criar uma nova denúncia
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewDenunciaScreen()),
          );
          _loadReports(); // Recarrega a lista após adicionar uma nova denúncia
        },
        child: const Icon(Icons.add), // Ícone para adicionar uma denúncia
      ),
    );
  }
}


