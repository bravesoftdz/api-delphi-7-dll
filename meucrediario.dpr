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
var IdHTTP1: TIdHTTP;
    XMLDocument: IXMLDocument;

function jsonToXml(json : TlkJSONobject): String;
var x, l : Integer;
    base : TlkJSONbase;
    list : TlkJSONlist;
    name : String;
begin
  result := '';
  for x := 0 to json.Count -1 do
    begin
      result := result + '<'+json.NameOf[x]+'>';

      base := json.FieldByIndex[x];
      if (base is TlkJSONobject) then
        begin
          result := result + jsonToXml(TlkJSONobject(base));
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
                  result := result + '<'+name+'>';
                  result := result + jsonToXml(TlkJSONobject(list.Child[l]));
                  result := result + '</'+name+'>';                  
                end;
            end;
        end
      else
        begin
          if (not VarIsNull(base.Value))then
            result := result + VarToStr(base.Value)
          else
            result := result + '';
        end;
        
      result := result + '</'+json.NameOf[x]+'>';
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

function invoke(token: WideString; url: WideString; method: WideString; params : WideString): WideString; stdcall; export;
var x : Integer;
    retorno : String;
begin
  CoInitialize(nil);
  try
    try
      XMLDocument := LoadXMLData(params);

      IdHTTP1 := TIdHTTP.Create(nil);
      IdHTTP1.Request.CustomHeaders.Clear;
      IdHTTP1.Request.CustomHeaders.AddValue('x-api-key', token);
      IdHTTP1.Request.ContentType := 'application/json';

      if (AnsiUpperCase(method) = 'GET') then
        begin
          for x := 0 to XMLDocument.DocumentElement.ChildNodes.Count-1 do
            begin
              if (XMLDocument.DocumentElement.ChildNodes.Get(x).LocalName <> '') then
                begin
                  if (url[Length(url)] = '/') then
                    delete(url, Length(url), 1);
                  url := url + '/'+XMLDocument.DocumentElement.ChildNodes.Get(x).Text;
                end;
            end;

          retorno := IdHTTP1.Get(url, IndyTextEncoding_UTF8);
          result := retornoToXml(UTF8Decode(retorno));
        end
      else
        begin
          raise Exception.Create('Method '+method+' Not implemented');
        end;
    except
      on E: Exception do
        begin
          result := retornoToXml(E.Message, true);
        end;
    end;
  finally
    if (IdHTTP1 <> nil) then
      IdHTTP1.Free;
  end;
end;

exports invoke index 1;

begin
end.
