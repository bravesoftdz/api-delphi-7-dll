## Codigo fonte da DLL para conexao na API MeuCrediario
DLL utilizada para chamar funcoes do MeuCrediario, os parametros devem ser enviados em XML e serao recebidos em XML.

## Fun��o da DLL
A dll possui uma fun��o que unica que converte XML para JSON, depois envia a solicita��o para a API, converte o retorno de JSON para XML.

A declara��o da fun��o � a seguinte:
```
function invoke(token: WideString; url: WideString; method: WideString; params: WideString): WideString;
```

## Exemplo Consulta de cliente.
```
invoke('TOKEN_ACESSO',
       'https://api.meucrediario.com.br/v1/cliente',
       'GET',
       '<params><cpf>12312312387</cpf></params>');
```

