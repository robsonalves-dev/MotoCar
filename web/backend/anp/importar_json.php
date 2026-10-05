<?php

if (php_sapi_name() !== 'cli') {
    http_response_code(403);
    exit('Acesso não permitido.');
}

require_once __DIR__ . '/../config.php';

$arquivoJson = __DIR__ . '/revendas_anp.json';

if (!file_exists($arquivoJson)) {
    die("ERRO: revendas_anp.json não encontrado.\n");
}

try {

    echo "Lendo JSON...\n";

    $conteudo = file_get_contents($arquivoJson);

    $dados = json_decode($conteudo, true);

    if (
        !is_array($dados) ||
        !isset($dados['precos']) ||
        !is_array($dados['precos'])
    ) {
        throw new Exception(
            'JSON inválido ou sem registros.'
        );
    }

    $registros = $dados['precos'];

    if (count($registros) === 0) {
        throw new Exception(
            'O JSON não possui registros.'
        );
    }

    echo "Registros encontrados: "
        . count($registros)
        . "\n";

    $pdo->beginTransaction();

    echo "Preparando banco...\n";

    /*
     * Remove os dados antigos.
     *
     * Como a operação está dentro de uma transação,
     * qualquer erro fará o ROLLBACK.
     */

    $pdo->exec(
        "DELETE FROM precos_anp"
    );

    /*
     * INSERT
     *
     * Agora também grava:
     * endereco
     * numero
     * bairro
     * cep
     */

    $sql = "
        INSERT INTO precos_anp
        (
            posto,
            endereco,
            numero,
            bairro,
            cep,
            municipio,
            combustivel,
            preco,
            data_coleta
        )
        VALUES
        (
            :posto,
            :endereco,
            :numero,
            :bairro,
            :cep,
            :municipio,
            :combustivel,
            :preco,
            :data_coleta
        )
    ";

    $stmt = $pdo->prepare($sql);

    $importados = 0;

    foreach ($registros as $registro) {

        /*
         * Dados do posto
         */

        $posto = trim(
            $registro['posto'] ?? ''
        );

        $endereco = trim(
            $registro['endereco'] ?? ''
        );

        $numero = trim(
            $registro['numero'] ?? ''
        );

        $bairro = trim(
            $registro['bairro'] ?? ''
        );

        $cep = trim(
            $registro['cep'] ?? ''
        );

        /*
         * Dados do combustível
         */

        $municipio = trim(
            $registro['municipio'] ?? ''
        );

        $combustivel = trim(
            $registro['combustivel'] ?? ''
        );

        $preco =
            $registro['preco'] ?? null;

        $dataColeta =
            $registro['data_coleta'] ?? null;

        /*
         * Validação
         */

        if (
            $posto === '' ||
            $municipio === '' ||
            $combustivel === '' ||
            $preco === null
        ) {

            throw new Exception(
                "Registro inválido encontrado durante a importação."
            );
        }

        /*
         * Insere no banco
         */

        $stmt->execute([

            'posto' =>
                $posto,

            'endereco' =>
                $endereco,

            'numero' =>
                $numero,

            'bairro' =>
                $bairro,

            'cep' =>
                $cep,

            'municipio' =>
                $municipio,

            'combustivel' =>
                $combustivel,

            'preco' =>
                $preco,

            'data_coleta' =>
                $dataColeta
        ]);

        $importados++;
    }

    /*
     * Confirma a transação
     */

    $pdo->commit();

    echo "\n";
    echo "IMPORTAÇÃO CONCLUÍDA COM SUCESSO!\n";
    echo "Registros importados: "
        . $importados
        . "\n";

} catch (Throwable $e) {

    /*
     * Se ocorrer qualquer erro,
     * desfaz todas as alterações.
     */

    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }

    echo "\n";
    echo "ERRO NA IMPORTAÇÃO!\n";
    echo $e->getMessage() . "\n";
    echo "Os dados anteriores foram mantidos.\n";

    exit(1);
}