<?php

if (php_sapi_name() !== 'cli') {
    http_response_code(403);
    exit('Acesso não permitido.');
}

require_once __DIR__ . '/../../vendor/autoload.php';

use PhpOffice\PhpSpreadsheet\IOFactory;
use PhpOffice\PhpSpreadsheet\Shared\Date;

$arquivoXlsx = __DIR__ . '/revendas_anp.xlsx';
$arquivoJson = __DIR__ . '/revendas_anp.json';
$arquivoTemp = __DIR__ . '/revendas_anp.tmp.json';

if (!file_exists($arquivoXlsx)) {
    die("ERRO: arquivo revendas_anp.xlsx não encontrado.\n");
}

function normalizarCombustivel(string $produto): ?string
{
    $produto = mb_strtolower(trim($produto), 'UTF-8');

    if (strpos($produto, 'gasolina') !== false) {
        return 'gasolina';
    }

    if (strpos($produto, 'etanol') !== false) {
        return 'etanol';
    }

    if (strpos($produto, 'diesel') !== false) {
        return 'diesel';
    }

    return null;
}

function converterPreco($valor): ?float
{
    if ($valor === null || $valor === '') {
        return null;
    }

    if (is_numeric($valor)) {
        return round((float)$valor, 3);
    }

    $valor = trim((string)$valor);
    $valor = str_replace('.', '', $valor);
    $valor = str_replace(',', '.', $valor);

    return is_numeric($valor)
        ? round($valor, 3)
        : null;
}

function converterData($valor): ?string
{
    if ($valor instanceof DateTimeInterface) {
        return $valor->format('Y-m-d');
    }

    if (is_numeric($valor)) {
        try {
            return Date::excelToDateTimeObject(
                (float)$valor
            )->format('Y-m-d');
        } catch (Throwable $e) {
            return null;
        }
    }

    $valor = trim((string)$valor);

    if ($valor === '') {
        return null;
    }

    $formatos = [
        'd/m/Y',
        'd/m/Y H:i:s',
        'Y-m-d',
        'Y-m-d H:i:s'
    ];

    foreach ($formatos as $formato) {
        $data = DateTime::createFromFormat(
            $formato,
            $valor
        );

        if ($data !== false) {
            return $data->format('Y-m-d');
        }
    }

    return null;
}

try {

    echo "Lendo planilha ANP...\n";

    $planilha = IOFactory::load($arquivoXlsx);
    $aba = $planilha->getActiveSheet();
    $ultimaLinha = $aba->getHighestRow();

    echo "Linhas encontradas: {$ultimaLinha}\n";

    $registros = [];

    for ($linha = 11; $linha <= $ultimaLinha; $linha++) {

        // FANTASIA
        $posto = trim(
            (string)$aba->getCell("C{$linha}")->getValue()
        );

        // Se FANTASIA estiver vazia, usa RAZÃO SOCIAL
        if ($posto === '') {
            $posto = trim(
                (string)$aba->getCell("B{$linha}")->getValue()
            );
        }

        $endereco = trim(
            (string)$aba->getCell("D{$linha}")->getValue()
        );

        $numero = trim(
            (string)$aba->getCell("E{$linha}")->getValue()
        );

        $bairro = trim(
            (string)$aba->getCell("G{$linha}")->getValue()
        );

        $cep = trim(
            (string)$aba->getCell("H{$linha}")->getValue()
        );

        $municipio = trim(
            (string)$aba->getCell("I{$linha}")->getValue()
        );

        $produto = trim(
            (string)$aba->getCell("L{$linha}")->getValue()
        );

        $preco = converterPreco(
            $aba->getCell("N{$linha}")->getValue()
        );

        $dataColeta = converterData(
            $aba->getCell("O{$linha}")->getValue()
        );

        if (
            $posto === '' ||
            $municipio === '' ||
            $produto === ''
        ) {
            continue;
        }

        $combustivel = normalizarCombustivel($produto);

        if ($combustivel === null) {
            continue;
        }

        if ($preco === null || $preco <= 0) {
            continue;
        }

        $registros[] = [
            'posto' => $posto,
            'endereco' => $endereco,
            'numero' => $numero,
            'bairro' => $bairro,
            'cep' => $cep,
            'municipio' => $municipio,
            'combustivel' => $combustivel,
            'preco' => $preco,
            'data_coleta' => $dataColeta
        ];
    }

    if (empty($registros)) {
        throw new Exception(
            'Nenhum registro válido encontrado na planilha.'
        );
    }

    $dados = [
        'fonte' => 'ANP',
        'gerado_em' => date('Y-m-d H:i:s'),
        'total' => count($registros),
        'precos' => $registros
    ];

    $json = json_encode(
        $dados,
        JSON_PRETTY_PRINT |
        JSON_UNESCAPED_UNICODE |
        JSON_UNESCAPED_SLASHES
    );

    if ($json === false) {
        throw new Exception('Erro ao gerar JSON.');
    }

    if (file_put_contents($arquivoTemp, $json) === false) {
        throw new Exception(
            'Não foi possível criar o arquivo temporário.'
        );
    }

    if (!rename($arquivoTemp, $arquivoJson)) {
        @unlink($arquivoTemp);

        throw new Exception(
            'Não foi possível finalizar o arquivo JSON.'
        );
    }

    echo "SUCESSO!\n";
    echo "Registros convertidos: "
        . count($registros)
        . "\n";

    echo "Arquivo criado: "
        . $arquivoJson
        . "\n";

} catch (Throwable $e) {

    @unlink($arquivoTemp);

    echo "ERRO: "
        . $e->getMessage()
        . "\n";

    exit(1);
}