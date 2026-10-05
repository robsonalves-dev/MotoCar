import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

class AnpPage extends StatefulWidget {
  const AnpPage({super.key});

  @override
  State<AnpPage> createState() => _AnpPageState();
}

class _AnpPageState extends State<AnpPage> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  String? municipioSelecionado;
  String combustivel = 'Gasolina';

  bool carregandoMunicipios = true;
  bool carregandoPrecos = false;

  String mensagem = '';

  List<String> municipios = [];
  List<dynamic> precos = [];

  Map<String, dynamic>? postoMaisBarato;
  double? economiaMaximaPorLitro;

  final TextEditingController _cidadeController =
      TextEditingController();

  List<String> municipiosFiltrados = [];

  @override
  void initState() {
    super.initState();

    carregarMunicipios();
    _carregarBanner();
  }

  void _carregarBanner() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7540081483916932/8634303873',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

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

  Future<void> carregarMunicipios() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://motocarweb.com.br/backend/api/anp_municipios.php',
        ),
      );

      final dados = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        carregandoMunicipios = false;

        if (dados['status'] == true) {
          municipios = List<String>.from(
            dados['municipios'] ?? [],
          );

          municipiosFiltrados =
              List<String>.from(municipios);

          if (municipios.isNotEmpty) {
            municipioSelecionado = municipios.first;
            _cidadeController.text = municipios.first;
          }

          mensagem = '';
        } else {
          mensagem =
              dados['mensagem'] ??
              'Erro ao carregar municípios.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregandoMunicipios = false;
        mensagem = 'Erro ao conectar com a API.';
      });
    }
  }

  void filtrarMunicipios(String texto) {
    final busca = texto.trim().toLowerCase();

    setState(() {
      if (busca.isEmpty) {
        municipiosFiltrados =
            List<String>.from(municipios);
      } else {
        municipiosFiltrados = municipios.where((municipio) {
          return municipio.toLowerCase().contains(busca);
        }).toList();
      }
    });
  }

  void selecionarMunicipio(String municipio) {
    setState(() {
      municipioSelecionado = municipio;
      _cidadeController.text = municipio;

      precos = [];
      postoMaisBarato = null;
      economiaMaximaPorLitro = null;
      mensagem = '';
    });
  }

  Future<void> abrirMaps(
    Map<String, dynamic> posto,
  ) async {
    final endereco = [
      posto['endereco']?.toString() ?? '',
      posto['numero']?.toString() ?? '',
      posto['bairro']?.toString() ?? '',
      posto['municipio']?.toString() ?? '',
      'SP',
      'Brasil',
    ].where((item) => item.trim().isNotEmpty).join(', ');

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination='
      '${Uri.encodeComponent(endereco)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o Google Maps.',
          ),
        ),
      );
    }
  }

  Future<void> buscarPrecos() async {
    if (municipioSelecionado == null ||
        municipioSelecionado!.isEmpty) {
      setState(() {
        mensagem = 'Informe uma cidade.';
        precos = [];
        postoMaisBarato = null;
        economiaMaximaPorLitro = null;
      });

      return;
    }

    setState(() {
      carregandoPrecos = true;
      mensagem = '';
      precos = [];
      postoMaisBarato = null;
      economiaMaximaPorLitro = null;
    });

    try {
      final municipio = Uri.encodeComponent(
        municipioSelecionado!,
      );

      final combustivelUrl = Uri.encodeComponent(
        combustivel,
      );

      final response = await http.get(
        Uri.parse(
          'https://motocarweb.com.br/backend/api/anp.php'
          '?municipio=$municipio'
          '&combustivel=$combustivelUrl',
        ),
      );

      final dados = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        carregandoPrecos = false;

        if (dados['status'] == true) {
          precos = dados['precos'] ?? [];

          if (dados['posto_mais_barato'] != null) {
            postoMaisBarato =
                Map<String, dynamic>.from(
              dados['posto_mais_barato'],
            );
          }

          economiaMaximaPorLitro =
              dados['economia_maxima_por_litro'] == null
                  ? null
                  : double.tryParse(
                      dados['economia_maxima_por_litro']
                          .toString(),
                    );

          if (precos.isEmpty) {
            mensagem =
                'Nenhum preço encontrado para essa consulta.';
          }
        } else {
          mensagem =
              dados['mensagem'] ??
              'Erro ao consultar os preços.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregandoPrecos = false;
        precos = [];
        postoMaisBarato = null;
        economiaMaximaPorLitro = null;
        mensagem = 'Erro ao conectar com a API.';
      });
    }
  }

  String formatarPreco(dynamic preco) {
    final valor = double.tryParse(
      preco.toString().replaceAll(',', '.'),
    );

    if (valor == null) {
      return '-';
    }

    return valor
        .toStringAsFixed(2)
        .replaceAll('.', ',');
  }

  Widget enderecoPosto(
    Map<String, dynamic> posto,
  ) {
    final endereco =
        posto['endereco']?.toString() ?? '';
    final numero =
        posto['numero']?.toString() ?? '';
    final bairro =
        posto['bairro']?.toString() ?? '';
    final cep =
        posto['cep']?.toString() ?? '';

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        if (endereco.isNotEmpty)
          Text(
            '$endereco${numero.isNotEmpty ? ', $numero' : ''}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),

        if (bairro.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(top: 3),
            child: Text(
              'Bairro: $bairro',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),

        if (cep.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.only(top: 3),
            child: Text(
              'CEP: $cep',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget botaoRota(
    Map<String, dynamic> posto,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () => abrirMaps(posto),
        icon: const Icon(
          Icons.location_on,
          size: 19,
        ),
        label: const Text(
          'Traçar rota',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              const Color(0xFF1565C0),
          side: const BorderSide(
            color: Color(0xFF1565C0),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF1A1A1A),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFEAF2FF),
                borderRadius:
                    BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.local_gas_station,
                color:
                    Color(0xFF1565C0),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Preços dos combustíveis',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar:
          _isBannerAdReady &&
                  _bannerAd != null
              ? SafeArea(
                  child: SizedBox(
                    width: _bannerAd!
                        .size.width
                        .toDouble(),
                    height: _bannerAd!
                        .size.height
                        .toDouble(),
                    child: AdWidget(
                      ad: _bannerAd!,
                    ),
                  ),
                )
              : null,

      body: carregandoMunicipios
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFF1565C0),
              ),
            )
          : RefreshIndicator(
              onRefresh:
                  carregarMunicipios,
              child: ListView(
                padding:
                    const EdgeInsets.all(18),
                children: [
                  const Text(
                    'Preços da ANP',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF171717),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Consulte os preços dos combustíveis por cidade.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Container(
                    padding:
                        const EdgeInsets.all(18),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(
                            0.04,
                          ),
                          blurRadius: 10,
                          offset:
                              const Offset(
                            0,
                            4,
                          ),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller:
                              _cidadeController,
                          onChanged:
                              filtrarMunicipios,
                          decoration:
                              InputDecoration(
                            labelText:
                                'Cidade',
                            hintText:
                                'Digite a cidade...',
                            prefixIcon:
                                const Icon(
                              Icons
                                  .location_on_outlined,
                              color:
                                  Color(
                                0xFF1565C0,
                              ),
                            ),
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                              borderSide:
                                  const BorderSide(
                                color:
                                    Color(
                                  0xFFD8DDE5,
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (_cidadeController
                                .text
                                .isNotEmpty &&
                            municipiosFiltrados
                                .isNotEmpty)
                          Container(
                            margin:
                                const EdgeInsets
                                    .only(
                              top: 6,
                            ),
                            constraints:
                                const BoxConstraints(
                              maxHeight: 180,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white,
                              border:
                                  Border.all(
                                color:
                                    const Color(
                                  0xFFD8DDE5,
                                ),
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                            child:
                                ListView.builder(
                              shrinkWrap: true,
                              itemCount:
                                  municipiosFiltrados
                                      .length,
                              itemBuilder:
                                  (
                                context,
                                index,
                              ) {
                                final municipio =
                                    municipiosFiltrados[
                                        index];

                                return ListTile(
                                  dense: true,
                                  leading:
                                      const Icon(
                                    Icons
                                        .location_on_outlined,
                                    color:
                                        Color(
                                      0xFF1565C0,
                                    ),
                                  ),
                                  title:
                                      Text(
                                    municipio,
                                  ),
                                  onTap: () {
                                    selecionarMunicipio(
                                      municipio,
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                        const SizedBox(
                          height: 16,
                        ),

                        DropdownButtonFormField<
                            String>(
                          initialValue:
                              combustivel,
                          decoration:
                              InputDecoration(
                            labelText:
                                'Combustível',
                            prefixIcon:
                                const Icon(
                              Icons
                                  .local_gas_station,
                              color:
                                  Color(
                                0xFF1565C0,
                              ),
                            ),
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                              borderSide:
                                  const BorderSide(
                                color:
                                    Color(
                                  0xFFD8DDE5,
                                ),
                              ),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value:
                                  'Gasolina',
                              child: Text(
                                'Gasolina',
                              ),
                            ),
                            DropdownMenuItem(
                              value:
                                  'Etanol',
                              child: Text(
                                'Etanol',
                              ),
                            ),
                          ],
                          onChanged:
                              (valor) {
                            if (valor !=
                                null) {
                              setState(() {
                                combustivel =
                                    valor;
                                precos = [];
                                postoMaisBarato =
                                    null;
                                economiaMaximaPorLitro =
                                    null;
                                mensagem = '';
                              });
                            }
                          },
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        SizedBox(
                          width:
                              double.infinity,
                          height: 52,
                          child:
                              ElevatedButton
                                  .icon(
                            onPressed:
                                carregandoPrecos
                                    ? null
                                    : buscarPrecos,
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  const Color(
                                0xFF1565C0,
                              ),
                              foregroundColor:
                                  Colors.white,
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  13,
                                ),
                              ),
                            ),
                            icon:
                                carregandoPrecos
                                    ? const SizedBox(
                                        width:
                                            20,
                                        height:
                                            20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,
                                          color:
                                              Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons
                                            .search,
                                      ),
                            label: Text(
                              carregandoPrecos
                                  ? 'Consultando...'
                                  : 'Buscar preços',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  if (postoMaisBarato !=
                      null)
                    Container(
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(
                          19,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
                                .withOpacity(
                              0.04,
                            ),
                            blurRadius: 10,
                            offset:
                                const Offset(
                              0,
                              4,
                            ),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFFEAF7EE,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    13,
                                  ),
                                ),
                                child:
                                    const Icon(
                                  Icons.star,
                                  color:
                                      Colors.green,
                                ),
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              const Expanded(
                                child: Text(
                                  'Posto mais barato',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        19,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          Text(
                            postoMaisBarato![
                                        'posto']
                                    ?.toString() ??
                                'Posto',
                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          enderecoPosto(
                            postoMaisBarato!,
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Text(
                            '${postoMaisBarato!['municipio'] ?? ''}',
                            style:
                                const TextStyle(
                              color:
                                  Colors.grey,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          Text(
                            'R\$ ${formatarPreco(
                              postoMaisBarato![
                                  'preco'],
                            )}',
                            style:
                                const TextStyle(
                              fontSize: 25,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  Color(
                                0xFF1565C0,
                              ),
                            ),
                          ),

                          if (economiaMaximaPorLitro !=
                              null) ...[
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              'Economia máxima: '
                              'R\$ ${formatarPreco(
                                economiaMaximaPorLitro,
                              )} por litro',
                              style:
                                  const TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color:
                                    Colors.green,
                              ),
                            ),
                          ],

                          const SizedBox(
                            height: 14,
                          ),

                          botaoRota(
                            postoMaisBarato!,
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            'Data da coleta: '
                            '${postoMaisBarato!['data_coleta'] ?? '-'}',
                            style:
                                const TextStyle(
                              color:
                                  Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (postoMaisBarato !=
                      null)
                    const SizedBox(
                      height: 20,
                    ),

                  if (mensagem.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white,
                        borderRadius:
                            BorderRadius
                                .circular(
                          15,
                        ),
                      ),
                      child: Text(
                        mensagem,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              Colors.grey,
                        ),
                      ),
                    ),

                  if (precos.isNotEmpty) ...[
                    const SizedBox(
                      height: 4,
                    ),

                    const Text(
                      'Preços encontrados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 13,
                    ),

                    ...precos.map(
                      (preco) {
                        return Container(
                          margin:
                              const EdgeInsets
                                  .only(
                            bottom: 12,
                          ),
                          padding:
                              const EdgeInsets
                                  .all(14),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              17,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors
                                    .black
                                    .withOpacity(
                                  0.04,
                                ),
                                blurRadius: 9,
                                offset:
                                    const Offset(
                                  0,
                                  3,
                                ),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          const Color(
                                        0xFFEAF2FF,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        13,
                                      ),
                                    ),
                                    child:
                                        const Icon(
                                      Icons
                                          .local_gas_station,
                                      color:
                                          Color(
                                        0xFF1565C0,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 12,
                                  ),

                                  Expanded(
                                    child:
                                        Text(
                                      preco['posto']
                                              ?.toString() ??
                                          'Posto',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        fontSize:
                                            15,
                                      ),
                                    ),
                                  ),

                                  Text(
                                    'R\$ ${formatarPreco(
                                      preco[
                                          'preco'],
                                    )}',
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          16,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color:
                                          Color(
                                        0xFF1565C0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              enderecoPosto(
                                Map<String,
                                    dynamic>.from(
                                  preco,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              Text(
                                '${preco['municipio'] ?? ''} · '
                                '${preco['data_coleta'] ?? '-'}',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.grey,
                                  fontSize:
                                      12,
                                ),
                              ),

                              if (preco[
                                      'economia_por_litro'] !=
                                  null)
                                Padding(
                                  padding:
                                      const EdgeInsets
                                          .only(
                                    top: 5,
                                  ),
                                  child: Text(
                                    'Economiza R\$ '
                                    '${formatarPreco(
                                      preco[
                                          'economia_por_litro'],
                                    )} por litro',
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          11,
                                      color:
                                          Colors.green,
                                    ),
                                  ),
                                ),

                              const SizedBox(
                                height: 12,
                              ),

                              botaoRota(
                                Map<String,
                                    dynamic>.from(
                                  preco,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(
                    height: 25,
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _cidadeController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }
}