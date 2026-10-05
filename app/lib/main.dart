import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'painel_principal_page.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
  await MobileAds.instance.initialize();
}

  final prefs = await SharedPreferences.getInstance();

final usuarioId = prefs.getInt('usuario_id');
final usuarioNome = prefs.getString('usuario_nome');

debugPrint('MOTOCAR - ID SALVO: $usuarioId');
debugPrint('MOTOCAR - NOME SALVO: $usuarioNome');

final rotaInicial =
    usuarioId != null && usuarioId > 0 ? '/home' : '/login';

    debugPrint('DIAGNOSTICO - ID: $usuarioId');
debugPrint('DIAGNOSTICO - NOME: $usuarioNome');
debugPrint('DIAGNOSTICO - ROTA: $rotaInicial');

  runApp(MotoCarApp(rotaInicial: rotaInicial));
}

class MotoCarApp extends StatelessWidget {
  final String rotaInicial;

  const MotoCarApp({
    super.key,
    required this.rotaInicial,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MotoCar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
      ),
      initialRoute: rotaInicial,
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const PainelPrincipalPage(),
        '/veiculos': (context) => const VeiculosPage(),
        '/abastecimentos': (context) =>
            const AbastecimentosPage(),
        '/calculos': (context) => const CalculosPage(),
        '/postos': (context) => const PostosPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MotoCar'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Olá! 👋',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('O que você deseja fazer?'),
          const SizedBox(height: 25),
          _botao(context, '🚗  Meus veículos', '/veiculos'),
          _botao(
            context,
            '⛽  Abastecimentos',
            '/abastecimentos',
          ),
          _botao(context, '🧮  Cálculos', '/calculos'),
          _botao(context, '📍  Postos', '/postos'),
        ],
      ),
    );
  }

  Widget _botao(
    BuildContext context,
    String texto,
    String rota,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 58,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, rota);
          },
          child: Text(
            texto,
            style: const TextStyle(fontSize: 17),
          ),
        ),
      ),
    );
  }
}

class VeiculosPage extends StatefulWidget {
  const VeiculosPage({super.key});

  @override
  State<VeiculosPage> createState() => _VeiculosPageState();
}

class _VeiculosPageState extends State<VeiculosPage> {
  final marcaController = TextEditingController();
  final modeloController = TextEditingController();
  final anoController = TextEditingController();
  final consumoController = TextEditingController();

  String tipo = 'carro';
  String combustivel = 'flex';
  String mensagem = '';

  Future<void> salvarVeiculo() async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://localhost:8000/api/veiculos.php',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'usuario_id': 1,
          'tipo': tipo,
          'marca': marcaController.text,
          'modelo': modeloController.text,
          'ano': anoController.text.isEmpty
              ? null
              : int.tryParse(anoController.text),
          'combustivel': combustivel,
          'consumo_medio': consumoController.text.isEmpty
              ? null
              : double.tryParse(
                  consumoController.text.replaceAll(',', '.'),
                ),
        }),
      );

      final dados = jsonDecode(response.body);

      setState(() {
        mensagem =
            dados['mensagem']?.toString() ??
            'Veículo salvo.';
      });
    } catch (_) {
      setState(() {
        mensagem = 'Erro ao conectar com a API.';
      });
    }
  }

  @override
  void dispose() {
    marcaController.dispose();
    modeloController.dispose();
    anoController.dispose();
    consumoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu veículo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Cadastrar veículo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),

            DropdownButtonFormField<String>(
              value: tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'carro',
                  child: Text('Carro'),
                ),
                DropdownMenuItem(
                  value: 'moto',
                  child: Text('Moto'),
                ),
              ],
              onChanged: (valor) {
                setState(() {
                  tipo = valor!;
                });
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: marcaController,
              decoration: const InputDecoration(
                labelText: 'Marca',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: modeloController,
              decoration: const InputDecoration(
                labelText: 'Modelo',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: anoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ano',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: combustivel,
              decoration: const InputDecoration(
                labelText: 'Combustível',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'flex',
                  child: Text('Flex'),
                ),
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
                setState(() {
                  combustivel = valor!;
                });
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: consumoController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Consumo médio (km/l)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: salvarVeiculo,
                child: const Text('SALVAR VEÍCULO'),
              ),
            ),

            const SizedBox(height: 15),

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

class AbastecimentosPage extends StatelessWidget {
  const AbastecimentosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abastecimentos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Registrar abastecimento',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          const TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Litros',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 15),

          const TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Preço por litro',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 15),

          const TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quilometragem',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text(
                'SALVAR ABASTECIMENTO',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CalculosPage extends StatelessWidget {
  const CalculosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _card(
            'Custo por km',
            'Calcule quanto seu veículo gasta por km.',
          ),
          _card(
            'Custo mensal',
            'Veja uma estimativa do gasto mensal.',
          ),
          _card(
            'Custo de viagem',
            'Calcule o custo de uma viagem.',
          ),
          _card(
            'Gasolina x Etanol',
            'Compare qual combustível compensa.',
          ),
        ],
      ),
    );
  }

  Widget _card(
    String titulo,
    String descricao,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: const Icon(Icons.calculate),
        title: Text(titulo),
        subtitle: Text(descricao),
        trailing: const Icon(
          Icons.arrow_forward_ios,
        ),
      ),
    );
  }
}

class PostosPage extends StatelessWidget {
  const PostosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Postos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Postos próximos',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _posto(
            'Posto Exemplo',
            'Gasolina R\$ 6,19',
          ),

          _posto(
            'Posto Central',
            'Gasolina R\$ 6,29',
          ),

          _posto(
            'Posto Avenida',
            'Etanol R\$ 4,19',
          ),
        ],
      ),
    );
  }

  Widget _posto(
    String nome,
    String preco,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(
          Icons.local_gas_station,
        ),
        title: Text(nome),
        subtitle: Text(preco),
        trailing: const Icon(
          Icons.location_on,
        ),
      ),
    );
  }
}

class HistoricoPage extends StatelessWidget {
  const HistoricoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Histórico de abastecimentos',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: Icon(Icons.history),
              title: Text(
                'Nenhum abastecimento',
              ),
              subtitle: Text(
                'Os abastecimentos registrados '
                'aparecerão aqui.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}