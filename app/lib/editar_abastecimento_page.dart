import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditarAbastecimentoPage extends StatefulWidget {
  final Map<String, dynamic> abastecimento;

  const EditarAbastecimentoPage({
    super.key,
    required this.abastecimento,
  });

  @override
  State<EditarAbastecimentoPage> createState() =>
      _EditarAbastecimentoPageState();
}

class _EditarAbastecimentoPageState
    extends State<EditarAbastecimentoPage> {
  late TextEditingController litrosController;
  late TextEditingController valorController;
  late TextEditingController quilometragemController;

  late String combustivel;
  String mensagem = '';

  @override
  void initState() {
    super.initState();

    litrosController = TextEditingController(
      text: widget.abastecimento['litros'].toString(),
    );

    valorController = TextEditingController(
      text: widget.abastecimento['valor_total'].toString(),
    );

    quilometragemController = TextEditingController(
      text: widget.abastecimento['quilometragem'].toString(),
    );

    combustivel = widget.abastecimento['combustivel'].toString();
  }

  Future<void> atualizarAbastecimento() async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:8000/api/abastecimentos.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id': widget.abastecimento['id'],
          'usuario_id': 1,
          'combustivel': combustivel,
          'litros': double.tryParse(
            litrosController.text.replaceAll(',', '.'),
          ),
          'valor_total': double.tryParse(
            valorController.text.replaceAll(',', '.'),
          ),
          'quilometragem': double.tryParse(
            quilometragemController.text.replaceAll(',', '.'),
          ),
          'data_abastecimento':
              widget.abastecimento['data_abastecimento'],
        }),
      );

      final dados = jsonDecode(response.body);

      setState(() {
        mensagem = dados['mensagem'] ?? 'Operação concluída.';
      });

      if (dados['status'] == true && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        mensagem = 'Erro ao conectar com a API.';
      });
    }
  }

  @override
  void dispose() {
    litrosController.dispose();
    valorController.dispose();
    quilometragemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar abastecimento'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: combustivel,
              decoration: const InputDecoration(
                labelText: 'Combustível',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'gasolina',
                  child: Text('Gasolina'),
                ),
                DropdownMenuItem(
                  value: 'etanol',
                  child: Text('Etanol'),
                ),
              ],
              onChanged: (valor) {
                if (valor != null) {
                  setState(() {
                    combustivel = valor;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: litrosController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Litros',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valorController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Valor pago (R\$)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quilometragemController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Quilometragem atual do veículo (km)',
                helperText:
                    'Digite o número que aparece no hodômetro do veículo.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: atualizarAbastecimento,
                child: const Text('Salvar alterações'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              mensagem,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}