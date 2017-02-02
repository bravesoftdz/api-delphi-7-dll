## Codigo fonte da DLL para conexao na API MeuCrediario
DLL utilizada para chamar funcoes do MeuCrediario, os parametros devem ser enviados em XML e serao recebidos em XML.

## Função da DLL
A dll possui uma função que unica que converte XML para JSON, depois envia a solicitação para a API, converte o retorno de JSON para XML.

A declaração da função é a seguinte:
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

## Exemplo da Consulta de cliente em java.
```
public class App {
    
   public interface simpleDLL extends Library {
        simpleDLL INSTANCE = (simpleDLL) Native.loadLibrary("C:\\path\\meucrediario.dll", simpleDLL.class);
        String invoke(String token, String url, String method, String params);
    }
   
    public static void main(String[] args) {
        simpleDLL dll = simpleDLL.INSTANCE;
        
        System.out.println(dll.invoke("TOKEN_ACESSO",
                "https://api.meucrediario.com.br/v1/cliente", 
                "GET", 
                "<params><cpf>12312312387</cpf></params>"));
    }
}
```
