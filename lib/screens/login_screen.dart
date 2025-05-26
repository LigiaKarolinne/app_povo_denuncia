import 'package:flutter/material.dart';

import '../db/db_helper.dart'; 
import '../models/user_model.dart'; 
import 'feed_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores de texto para os campos de e-mail e senha
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  // Define se o modo atual é login (true) ou cadastro (false)
  bool isLogin = true;

  
  get dbHelper => DBHelper.instance;

  // Alterna entre as telas de login e cadastro
  void alternarModo() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  // Função responsável por autenticar ou cadastrar um usuário
  void autenticarOuCadastrar() async {
    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    // Validação simples: impede campos vazios
    if (email.isEmpty || senha.isEmpty) {
      mostrarMensagem("Preencha todos os campos.");
      return;
    }

    if (isLogin) {
      // Caso esteja no modo login, tenta autenticar o usuário
      final usuario = await dbHelper.autenticar(email, senha);
      if (usuario != null) {
        mostrarMensagem("Login realizado com sucesso!");
        Navigator.pushReplacement(
          // Redireciona para o feed, substituindo a tela atual
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const FeedScreen()),
        );
      } else {
        mostrarMensagem("Credenciais inválidas."); // Usuário/senha incorretos
      }
    } else {
      // Caso esteja no modo cadastro, verifica se o e-mail já está cadastrado
      final existente = await dbHelper.buscarPorEmail(email);
      if (existente != null) {
        mostrarMensagem("Usuário já existe.");
        return;
      }

      // Cadastra o novo usuário
      final novoUsuario = User(email: email, senha: senha);
      await dbHelper.cadastrarUsuario(novoUsuario);
      mostrarMensagem("Cadastro realizado com sucesso!");

      // Volta para o modo login após cadastro
      setState(() => isLogin = true);
    }
  }

  // Exibe uma mensagem temporária no app (Snackbar)
  void mostrarMensagem(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Define o título do app bar com base no modo atual
      appBar: AppBar(title: Text(isLogin ? "Login" : "Cadastro")),

      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
          
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),

          
            TextField(
              controller: senhaController,
              obscureText: true, 
              decoration: const InputDecoration(labelText: 'Senha'),
            ),

            const SizedBox(height: 20),

            // Botão de ação (entrar ou cadastrar)
            ElevatedButton(
              onPressed: autenticarOuCadastrar,
              child: Text(isLogin ? "Entrar" : "Cadastrar"),
            ),

            // Botão de alternância entre login e cadastro
            TextButton(
              onPressed: alternarModo,
              child: Text(isLogin
                  ? "Não tem conta? Cadastre-se"
                  : "Já tem conta? Faça login"),
            ),
          ],
        ),
      ),
    );
  }
}
