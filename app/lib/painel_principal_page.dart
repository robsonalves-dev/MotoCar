import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'calculos_page.dart';
import 'rotas_page.dart';
import 'veiculo_page.dart';
import 'abastecimento_page.dart';
import 'historico_viagens_page.dart';
import 'analise_historico_page.dart';
import 'anp_page.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'configuracoes_page.dart';

class PainelPrincipalPage extends StatefulWidget {
  const PainelPrincipalPage({super.key});

  @override
  State<PainelPrincipalPage> createState() =>
      _PainelPrincipalPageState();
}

class _PainelPrincipalPageState extends State<PainelPrincipalPage> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  bool carregando = true;

  int indiceMenu = 0;

  String nomeUsuario = '';
  String veiculoNome = 'Nenhum veículo cadastrado';
  String combustivel = '-';

  double custoKm = 0;
  double custoMensal = 0;
  double custoViagem = 0;

  String ultimoPosto = '-';
  String ultimoCombustivel = '-';
  String ultimoValor = '-';
  String ultimaData = '-';

  int quantidadeAbastecimentos = 0;

  @override
void initState() {
  super.initState();

  _carregarBanner();

  carregarPainel();
}

void _carregarBanner() {
  _bannerAd = BannerAd(
    adUnitId: 'ca-app-pub-7540081483916932/8634303873',
    size: AdSize.banner,
    request: const AdRequest(),
    listener: BannerAdListener(
      onAdLoaded: (ad) {
        setState(() {
          _isBannerAdReady = true;
        });
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
      },
    ),
  )..load();
}

  Future<void> carregarPainel() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final usuarioId = prefs.getInt('usuario_id');
      final nomeSalvo = prefs.getString('usuario_nome') ?? '';

      setState(() {
        nomeUsuario = nomeSalvo;
      });

      if (usuarioId == null) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/login',
        );

        return;
      }

      final calculosResponse = await http.get(
        Uri.parse(
          'https://motocarweb.com.br/backend/api/calculos.php?usuario_id=$usuarioId',
        ),
      );

      final abastecimentosResponse = await http.get(
        Uri.parse(
          'https://motocarweb.com.br/backend/api/abastecimentos_lista.php?usuario_id=$usuarioId',
        ),
      );

      if (calculosResponse.statusCode == 200) {
        final dadosCalculos = jsonDecode(
          calculosResponse.body,
        );

        if (dadosCalculos is Map) {
          final veiculo = dadosCalculos['veiculo'];

          if (veiculo != null) {
            veiculoNome =
                '${veiculo['marca'] ?? ''} ${veiculo['modelo'] ?? ''}'
                    .trim();

            if (veiculoNome.isEmpty) {
              veiculoNome = 'Veículo cadastrado';
            }

            combustivel =
                veiculo['combustivel']?.toString() ?? '-';
          }

          custoKm = double.tryParse(
                dadosCalculos['custo_km']?.toString() ?? '0',
              ) ??
              0;

          custoMensal = double.tryParse(
                dadosCalculos['custo_mensal']?.toString() ?? '0',
              ) ??
              0;

          custoViagem = double.tryParse(
                dadosCalculos['custo_viagem']?.toString() ?? '0',
              ) ??
              0;
        }
      }

      if (abastecimentosResponse.statusCode == 200) {
        final dadosAbastecimentos = jsonDecode(
          abastecimentosResponse.body,
        );

        List lista = [];

        if (dadosAbastecimentos is List) {
          lista = dadosAbastecimentos;
        } else if (dadosAbastecimentos is Map) {
          if (dadosAbastecimentos['abastecimentos'] is List) {
            lista = dadosAbastecimentos['abastecimentos'];
          } else if (dadosAbastecimentos['dados'] is List) {
            lista = dadosAbastecimentos['dados'];
          }
        }

        quantidadeAbastecimentos = lista.length;

        if (lista.isNotEmpty) {
          final ultimo = lista.first;

          ultimoPosto =
              ultimo['posto']?.toString() ??
                  ultimo['nome_posto']?.toString() ??
                  '-';

          ultimoCombustivel =
              ultimo['combustivel']?.toString() ?? '-';

          final valor = ultimo['valor'] ??
              ultimo['valor_total'] ??
              ultimo['preco'];

          if (valor != null) {
            final valorNumero =
                double.tryParse(valor.toString()) ?? 0;

            ultimoValor =
                'R\$ ${valorNumero.toStringAsFixed(2).replaceAll('.', ',')}';
          } else {
            ultimoValor = '-';
          }

          ultimaData =
              ultimo['data']?.toString() ??
                  ultimo['created_at']?.toString() ??
                  ultimo['data_abastecimento']?.toString() ??
                  '-';
        }
      }

      if (!mounted) return;

      setState(() {
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao carregar painel: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String dinheiro(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget cardResumo({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

void abrirAba(int indice) {
  Widget pagina;

  switch (indice) {
    case 0:
      pagina = const RotasPage();
      break;

    case 1:
      pagina = const VeiculoPage();
      break;

    case 2:
      pagina = AbastecimentoPage();
      break;

    case 3:
      pagina = const CalculosPage();
      break;

    default:
      return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => pagina),
  );
}

  @override
  Widget build(BuildContext context) {
  return Scaffold(
  backgroundColor: const Color(0xFFF5F7FA),

  // MENU HAMBÚRGUER
  appBar: AppBar(
    elevation: 0,
    backgroundColor: Colors.white,
    foregroundColor: const Color(0xFF1A1A1A),

    leading: Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
    ),

    title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.directions_car,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'MotoCar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 21,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: carregarPainel,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () async {
              final prefs =
                  await SharedPreferences.getInstance();

              await prefs.remove('usuario_id');
              await prefs.remove('usuario_nome');

              if (!mounted) return;

              Navigator.pushReplacementNamed(
                context,
                '/login',
              );
            },
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 5),
        ],
      ),

            drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'MotoCar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Rotas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RotasPage(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico de viagens'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistoricoViagensPage(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Análise do histórico'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AnaliseHistoricoPage(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.local_gas_station),
              title: const Text('Preços ANP'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnpPage(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConfiguracoesPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      body: carregando
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1565C0),
              ),
            )
          : RefreshIndicator(
              onRefresh: carregarPainel,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
  'Olá, $nomeUsuario! 👋',
  style: const TextStyle(
    fontSize: 27,
    fontWeight: FontWeight.bold,
    color: Color(0xFF171717),
  ),
),

const SizedBox(height: 5),

const Text(
  'Confira as informações do seu veículo.',
  style: TextStyle(
    fontSize: 14,
    color: Colors.grey,
  ),
),

const SizedBox(height: 20),

if (_isBannerAdReady && _bannerAd != null)
  Center(
    child: SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    ),
  ),

const SizedBox(height: 20),

Container(
  width: double.infinity,
  padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1565C0),
                            Color(0xFF1976D2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.blue.withOpacity(0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color:
                                  Colors.white.withOpacity(0.18),
                              borderRadius:
                                  BorderRadius.circular(17),
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: Colors.white,
                              size: 31,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Meu veículo',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  veiculoNome,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  'Combustível: $combustivel',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Resumo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 13),

                    Row(
                      children: [
                        cardResumo(
                          icon: Icons.speed,
                          titulo: 'Custo por km',
                          valor: dinheiro(custoKm),
                        ),
                        const SizedBox(width: 12),
                        cardResumo(
                          icon: Icons.calendar_month,
                          titulo: 'Custo mensal',
                          valor: dinheiro(custoMensal),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        cardResumo(
                          icon: Icons.route,
                          titulo: 'Custo viagem',
                          valor: dinheiro(custoViagem),
                        ),
                        const SizedBox(width: 12),
                        cardResumo(
                          icon: Icons.local_gas_station,
                          titulo: 'Abastecimentos',
                          valor:
                              quantidadeAbastecimentos.toString(),
                        ),
                      ],
                    ),

                                        const SizedBox(height: 26),

                    const Text(
                      'Último abastecimento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 13),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(19),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(19),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF7EE),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.local_gas_station,
                                  color: Colors.green,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ultimoPosto,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ultimoCombustivel,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                ultimoValor,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          const Divider(),

                          const SizedBox(height: 4),

                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                ultimaData,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: indiceMenu,
        onTap: abrirAba,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
  icon: Icon(Icons.route_outlined),
  activeIcon: Icon(Icons.route),
  label: 'Rotas',
),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car),
            label: 'Veículo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station_outlined),
            activeIcon: Icon(Icons.local_gas_station),
            label: 'Abastecer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: 'Cálculos',
          ),
        ],
      ),
    );
  }
}