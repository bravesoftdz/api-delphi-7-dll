library meucrediario;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils,
  Classes,
  ActiveX,
  IdBaseComponent,
  IdComponent,
  IdTCPConnection,
  IdTCPClient,
  IdHTTP,
  IdGlobal,
  xmldom,
  XMLIntf,
  msxmldom,
  XMLDoc,
  Variants,
  uLkJSON in 'uLkJSON.pas';

{$R *.res}

function jsonToXml(json : TlkJSONobject): String;
var x, l : Integer;
    base : TlkJSONbase;
    list : TlkJSONlist;
    name : String;
begin
  Result := '';
  for x := 0 to json.Count -1 do
    begin
      Result := Result + '<'+json.NameOf[x]+'>';

      base := json.FieldByIndex[x];
      if (base is TlkJSONobject) then
        begin
          Result := Result + jsonToXml(TlkJSONobject(base));
        end
      else
      if (base is TlkJSONlist) then
        begin
          list := TlkJSONlist(base);
          if (list.Count > 0) then
            begin
              name := json.NameOf[x];
              delete(name, Length(name), 1);
              for l := 0 to list.Count-1 do
                begin
                  if (list.Child[l] <> nil) then
                    begin
                      Result := Result + '<'+name+'>';
                      if (list.Child[l] is TlkJSONobject) then
                        Result := Result + jsonToXml(TlkJSONobject(list.Child[l]));
                      Result := Result + '</'+name+'>';
                    end;
                end;
            end;
        end
      else
        begin
          if (not VarIsNull(base.Value))then
            Result := Result + VarToStr(base.Value)
          else
            Result := Result + '';
        end;

      Result := Result + '</'+json.NameOf[x]+'>';
    end;
end;

function retornoToXml(jsonText: String; erro : Boolean): String; overload;
var json : TlkJSONobject;
begin
  if (Pos('HTTP/1.1 ', jsonText) > 0) or (erro) then
    begin
      if (Pos('HTTP/1.1 ', jsonText) > 0) then
        Result := '<retorno><statusCode>'+Copy(jsonText, 10, 3)+'</statusCode><message>'+Trim(Copy(jsonText, 13, Length(jsonText)))+'</message></retorno>'
      else
        Result := '<retorno><statusCode>500</statusCode><message>'+jsonText+'</message></retorno>'
    end
  else
    begin
      json := TlkJSONobject(TlkJSON.ParseText(jsonText));
      Result := '<retorno><statusCode>200</statusCode><data>'+jsonToXml(json)+'</data></retorno>';
    end;
end;

function retornoToXml(xml: String): String; overload;
begin
  Result := retornoToXml(xml, false);
end;

function getHTTP(token : String) : TIdHTTP;
var IdHTTP : TIdHTTP;
begin
  IdHTTP := TIdHTTP.Create(nil);
  IdHTTP.Request.CustomHeaders.Clear;
  IdHTTP.Request.CustomHeaders.AddValue('x-api-key', token);
  IdHTTP.Request.ContentType := 'application/json';

  Result := IdHTTP;
end;

function invoke(token: PAnsiChar; url: PAnsiChar; method: PAnsiChar; params : PAnsiChar): PAnsiChar; stdcall; export;
var x : Integer;
    urlFunc,  
    retURL,
    retFunc : String;
    IdHTTP1 : TIdHTTP;
    XMLDocument: IXMLDocument;
begin
  CoInitialize(nil);

  try
    // Carrega o XML
    XMLDocument := LoadXMLData(WideString(params));

    // Inicia o Objeto
    IdHTTP1 := getHTTP(token);

    urlFunc := url;
    if (AnsiUpperCase(method) = 'GET') then
      begin

        for x := 0 to XMLDocument.DocumentElement.ChildNodes.Count-1 do
          begin
            if (XMLDocument.DocumentElement.ChildNodes.Get(x).LocalName <> '') then
              begin
                if (urlFunc[Length(urlFunc)] = '/') then
                  delete(urlFunc, Length(urlFunc), 1);
                urlFunc := urlFunc + '/'+XMLDocument.DocumentElement.ChildNodes.Get(x).Text;
              end;
          end;

        retURL := IdHTTP1.Get(urlFunc, IndyTextEncoding_UTF8);
        retFunc := retornoToXml(UTF8Decode(retURL));
      end
    else
      begin
        raise Exception.Create('Method '+method+' Not implemented');
      end;
  except
    on E: Exception do
      begin
        retFunc := retornoToXml(PAnsiChar(E.Message), true);
      end;
  end;

  Result := PAnsiChar(retFunc);
end;

exports invoke index 1;

begin
end.
