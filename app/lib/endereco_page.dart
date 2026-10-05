import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EnderecoPage extends StatefulWidget {
  const EnderecoPage({super.key});

  @override
  State<EnderecoPage> createState() => _EnderecoPageState();
}

class _EnderecoPageState extends State<EnderecoPage> {
  final enderecoController = TextEditingController();

  bool carregando = false;
  String mensagem = '';

  double? latitude;
  double? longitude;
  String? enderecoEncontrado;

  Future<void> buscarEndereco() async {
    final endereco = enderecoController.text.trim();

    if (endereco.isEmpty) {
      setState(() {
        mensagem = 'Informe um endereço.';
        latitude = null;
        longitude = null;
        enderecoEncontrado = null;
      });
      return;
    }

    setState(() {
      carregando = true;
      mensagem = '';
      latitude = null;
      longitude = null;
      enderecoEncontrado = null;
    });

    try {
      final enderecoUrl = Uri.encodeComponent(endereco);

      final response = await http.get(
        Uri.parse(
          'http://localhost:8000/api/geocodificar.php'
          '?endereco=$enderecoUrl',
        ),
      );

      final dados = jsonDecode(response.body);

      if (!mounted) {
        return;
      }

      if (dados['status'] == true) {
        setState(() {
          carregando = false;
          enderecoEncontrado = dados['endereco']?.toString();
          latitude = double.tryParse(
            dados['latitude'].toString(),
          );
          longitude = double.tryParse(
            dados['longitude'].toString(),
          );
        });
      } else {
        setState(() {
          carregando = false;
          mensagem =
              dados['mensagem'] ??
              'Endereço não encontrado.';
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        carregando = false;
        mensagem = 'Erro ao conectar com a API.';
      });
    }
  }

  @override
  void dispose() {
    enderecoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localizar endereço'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Localizar endereço',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: enderecoController,
              decoration: const InputDecoration(
                labelText: 'Endereço',
                hintText: 'Ex.: Limeira, SP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    carregando ? null : buscarEndereco,
                child: carregando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Localizar'),
              ),
            ),

            const SizedBox(height: 24),

            if (enderecoEncontrado != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Local encontrado',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(enderecoEncontrado!),
                      const SizedBox(height: 12),
                      Text(
                        'Latitude: ${latitude ?? '-'}',
                      ),
                      Text(
                        'Longitude: ${longitude ?? '-'}',
                      ),
                    ],
                  ),
                ),
              ),

            if (mensagem.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                mensagem,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}