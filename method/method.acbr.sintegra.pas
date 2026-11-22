unit method.acbr.sintegra;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  ACBrSintegra,
  ACBrUtil.Strings,
  ACBRDFe.Conversao,
  Variants,
  fpjson,
  jsonconvert,
  jsonparser,
  streamtools,
  Classes, SysUtils;

type
  TACBRBridgeSintegra = class
  private
      fcfg: string;
    facbr: TACBrSintegra;
    procedure CarregaConfig;
  public
      constructor Create(const Cfg: string);
    destructor Destroy;
    override;
    function Sintegra(const jSintegra: TJSONObject): TJSONObject;
    function Gerar(const jSintegra: TJSONObject): TJSONObject;
  end;

  TACBRModelosJSONSintegra = class(TACBRBridgeSintegra)
  public
    function ModelConfig: TJSONObject;
    function ModelGerar: TJSONObject;
  end;

implementation

{ TACBRModelosJSONSintegra }

function TACBRModelosJSONSintegra.ModelConfig: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('FileName', facbr.FileName);
end;

{ TACBRBridgeSintegra }

procedure SanitizarStringsJSON(const AData: TJSONData);
var
  I: Integer;
  LObj: TJSONObject;
  LArr: TJSONArray;
  LChild: TJSONData;
begin
  if not Assigned(AData) then
    Exit;
  case AData.JSONType of
    jtObject:
      begin
        LObj := TJSONObject(AData);
        for I := 0 to LObj.Count - 1 do
        begin
          LChild := LObj.Items[I];
          if Assigned(LChild) then
          begin
            if LChild.JSONType = jtString then
              LChild.AsString := TiraAcentos(LChild.AsString)
            else if LChild.JSONType in [jtObject, jtArray] then
              SanitizarStringsJSON(LChild);
          end;
        end;
      end;
    jtArray:
      begin
        LArr := TJSONArray(AData);
        for I := 0 to LArr.Count - 1 do
        begin
          LChild := LArr.Items[I];
          if Assigned(LChild) then
          begin
            if LChild.JSONType = jtString then
              LChild.AsString := TiraAcentos(LChild.AsString)
            else if LChild.JSONType in [jtObject, jtArray] then
              SanitizarStringsJSON(LChild);
          end;
        end;
      end;
  end;
end;

procedure TACBRBridgeSintegra.CarregaConfig;
var
  O: TJSONObject;
begin
  if fcfg = '' then
    exit;
  O := GetJSON(fcfg) as TJSONObject;
  try
    TJSONTools.JsonToObj(O, facbr);
  finally
    O.Free;
  end;
  fcfg := '';
end;

constructor TACBRBridgeSintegra.Create(const Cfg: string);
begin
  facbr := TACBrSintegra.Create(nil);
  fcfg := Cfg;
end;

destructor TACBRBridgeSintegra.Destroy;
begin
  FreeAndNil(facbr);
  inherited Destroy;
end;

function TACBRBridgeSintegra.Sintegra(const jSintegra: TJSONObject): TJSONObject;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Result.Add('status', 'sucesso');
  Result.Add('message', 'ACBr Sintegra inicializado com sucesso.');
end;

function TACBRBridgeSintegra.Gerar(const jSintegra: TJSONObject): TJSONObject;
const
  ORDEM_90: array[0..16] of string = (
    '50', '51', '53', '54', '55', '56', '60', '61',
    '70', '71', '74', '75', '76', '77', '85', '86', '88'
    );
var
  tamanho, i, k, m, countInChunk, total90Lines, totalFileLines, cntTipo: integer;
  isTempFile, retirarAcentos: boolean;
  jData, jClean, jObj, jItem: TJSONObject;
  jNode: TJSONData;
  jArr: TJSONArray;
  sl: TStringList;
  tipo2, prefix90, suffix90, chunkBody, cnpj10, ie10: string;
  activeTipos: array[0..16] of string;
  activeCounts: array[0..16] of integer;
  activeLen: integer;
  r50: TRegistro50;
  r51: TRegistro51;
  r53: TRegistro53;
  r54: TRegistro54;
  r55: TRegistro55;
  r56: TRegistro56;
  r60M: TRegistro60M;
  r60A: TRegistro60A;
  r60D: TRegistro60D;
  r60I: TRegistro60I;
  r60R: TRegistro60R;
  r61: TRegistro61;
  r61R: TRegistro61R;
  r70: TRegistro70;
  r71: TRegistro71;
  r74: TRegistro74;
  r75: TRegistro75;
  r76: TRegistro76;
  r77: TRegistro77;
  r85: TRegistro85;
  r86: TRegistro86;
  r88Ean: TRegistro88Ean;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  try
    try
      isTempFile := False;
      if facbr.FileName = '' then
      begin
        isTempFile := True;
        facbr.FileName := ExtractFilePath(ParamStr(0))+
          Format('sintegra_%d_%d.txt', [GetTickCount64, Random(1000000)]);
      end;

      jData := jSintegra;
      if Assigned(jSintegra) then
      begin
        jNode := jSintegra.Find('sintegra');
        if Assigned(jNode) and (jNode is TJSONObject) then
          jData := TJSONObject(jNode);
      end;

      jClean := nil;
      if Assigned(jData) then
      begin
        jClean := TJSONObject(jData.Clone);
        retirarAcentos := jClean.Get('RetirarAcentos', True);
        if Assigned(jSintegra) and (jSintegra <> jData) then
          retirarAcentos := jSintegra.Get('RetirarAcentos', retirarAcentos);
        if retirarAcentos then
          SanitizarStringsJSON(jClean);
        jData := jClean;
      end;

      try
      facbr.LimparRegistros;

      // Mapeamento Generico das Propriedades (Registro10, Registro11, flags)
      TJSONTools.JsonToObj(jData, facbr);

      if Assigned(jData) then
      begin
        jNode := jData.Find('Registro10');
        if Assigned(jNode) and (jNode is TJSONObject) then
        begin
          jObj := TJSONObject(jNode);
          if (facbr.Registro10.NaturezaInformacoes = '') and (jObj.Get('CodigoNatureza', '') <> '') then
            facbr.Registro10.NaturezaInformacoes := jObj.Get('CodigoNatureza', '');
          if (facbr.Registro10.FinalidadeArquivo = '') and (jObj.Get('CodigoFinalidade', '') <> '') then
            facbr.Registro10.FinalidadeArquivo := jObj.Get('CodigoFinalidade', '');
          if (facbr.Registro10.Telefone = '') and (jObj.Get('Fax', '') <> '') then
            facbr.Registro10.Telefone := jObj.Get('Fax', '');
          if (facbr.Registro10.Estado = '') and (jObj.Get('UF', '') <> '') then
            facbr.Registro10.Estado := jObj.Get('UF', '');
          if (facbr.Registro10.Inscricao = '') and (jObj.Get('InscricaoEstadual', '') <> '') then
            facbr.Registro10.Inscricao := jObj.Get('InscricaoEstadual', '');
        end;

        jNode := jData.Find('Registro11');
        if Assigned(jNode) and (jNode is TJSONObject) then
        begin
          jObj := TJSONObject(jNode);
          if (facbr.Registro11.Endereco = '') and (jObj.Get('Logradouro', '') <> '') then
            facbr.Registro11.Endereco := jObj.Get('Logradouro', '');
          if (facbr.Registro11.Responsavel = '') and (jObj.Get('Contato', '') <> '') then
            facbr.Registro11.Responsavel := jObj.Get('Contato', '');
        end;

        jNode := jData.Find('Registros50');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            jItem := TJSONObject(jArr.Items[i]);
            r50 := TRegistro50.Create;
            TJSONTools.JsonToObj(jItem, r50);
            if (r50.Inscricao = '') and (jItem.Get('InscricaoEstadual', '') <> '') then
              r50.Inscricao := jItem.Get('InscricaoEstadual', '');
            if (r50.EmissorDocumento = '') and (jItem.Get('Emitente', '') <> '') then
              r50.EmissorDocumento := jItem.Get('Emitente', '');
            facbr.Registros50.Add(r50);
          end;
        end;

        jNode := jData.Find('Registros51');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            jItem := TJSONObject(jArr.Items[i]);
            r51 := TRegistro51.Create;
            TJSONTools.JsonToObj(jItem, r51);
            if (r51.Estado = '') and (jItem.Get('UF', '') <> '') then
              r51.Estado := jItem.Get('UF', '');
            if (r51.Inscricao = '') and (jItem.Get('InscricaoEstadual', '') <> '') then
              r51.Inscricao := jItem.Get('InscricaoEstadual', '');
            r51.DataDocumento := Trunc(r51.DataDocumento)+(i * 1.0E-8);
            facbr.Registros51.Add(r51);
          end;
        end;

        jNode := jData.Find('Registros53');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            jItem := TJSONObject(jArr.Items[i]);
            r53 := TRegistro53.Create;
            TJSONTools.JsonToObj(jItem, r53);
            if (r53.Estado = '') and (jItem.Get('UF', '') <> '') then
              r53.Estado := jItem.Get('UF', '');
            if (r53.Emitente = '') and (jItem.Get('EmissorDocumento', '') <> '') then
              r53.Emitente := jItem.Get('EmissorDocumento', '');
            if (r53.Inscricao = '') and (jItem.Get('InscricaoEstadual', '') <> '') then
              r53.Inscricao := jItem.Get('InscricaoEstadual', '');
            facbr.Registros53.Add(r53);
          end;
        end;

        jNode := jData.Find('Registros54');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            r54 := TRegistro54.Create;
            TJSONTools.JsonToObj(TJSONObject(jArr.Items[i]), r54);
            facbr.Registros54.Add(r54);
          end;
        end;

        jNode := jData.Find('Registros55');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            jItem := TJSONObject(jArr.Items[i]);
            r55 := TRegistro55.Create;
            TJSONTools.JsonToObj(jItem, r55);
            if (r55.CNPJ = '') and (jItem.Get('CPFCNPJ', '') <> '') then
              r55.CNPJ := jItem.Get('CPFCNPJ', '');
            facbr.Registros55.Add(r55);
          end;
        end;

        jNode := jData.Find('Registros56');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            r56 := TRegistro56.Create;
            TJSONTools.JsonToObj(TJSONObject(jArr.Items[i]), r56);
            facbr.Registros56.Add(r56);
          end;
        end;

        jNode := jData.Find('Registros60M');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            r60M := TRegistro60M.Create;
            TJSONTools.JsonToObj(TJSONObject(jArr.Items[i]), r60M);
            facbr.Registros60M.Add(r60M);
          end;
        end;

        jNode := jData.Find('Registros60A');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            jItem := TJSONObject(jArr.Items[i]);
            r60A := TRegistro60A.Create;
            TJSONTools.JsonToObj(jItem, r60A);
            if (r60A.StAliquota = '') and (jItem.Get('Aliquota', '') <> '') then
              r60A.StAliquota := jItem.Get('Aliquota', '');
            facbr.Registros60A.Add(r60A);
          end;
        end;

        jNode := jData.Find('Registros60D');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            jItem := TJSONObject(jArr.Items[i]);
            r60D := TRegistro60D.Create;
            TJSONTools.JsonToObj(jItem, r60D);
            if (r60D.StAliquota = '') and (jItem.Get('Aliquota', '') <> '') then
              r60D.StAliquota := jItem.Get('Aliquota', '');
            facbr.Registros60D.Add(r60D);
          end;
        end;

        jNode := jData.Find('Registros60I');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            jItem := TJSONObject(jArr.Items[i]);
            r60I := TRegistro60I.Create;
            TJSONTools.JsonToObj(jItem, r60I);
            if (r60I.StAliquota = '') and (jItem.Get('Aliquota', '') <> '') then
              r60I.StAliquota := jItem.Get('Aliquota', '');
            facbr.Registros60I.Add(r60I);
          end;
        end;

        jNode := jData.Find('Registros60R');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            jItem := TJSONObject(jArr.Items[i]);
            r60R := TRegistro60R.Create;
            TJSONTools.JsonToObj(jItem, r60R);
            if (r60R.Aliquota = '') and (jItem.Get('StAliquota', '') <> '') then
              r60R.Aliquota := jItem.Get('StAliquota', '');
            if (r60R.Qtd = 0) and (jItem.Get('Quantidade', 0.0) <> 0) then
              r60R.Qtd := jItem.Get('Quantidade', 0.0);
            facbr.Registros60R.Add(r60R);
          end;
        end;

        jNode := jData.Find('Registros61');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            r61 := TRegistro61.Create;
            TJSONTools.JsonToObj(TJSONObject(jArr.Items[i]), r61);
            facbr.Registros61.Add(r61);
          end;
        end;

        jNode := jData.Find('Registros61R');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            jItem := TJSONObject(jArr.Items[i]);
            r61R := TRegistro61R.Create;
            TJSONTools.JsonToObj(jItem, r61R);
            if (r61R.Qtd = 0) and (jItem.Get('Quantidade', 0.0) <> 0) then
              r61R.Qtd := jItem.Get('Quantidade', 0.0);
            facbr.Registros61R.Add(r61R);
          end;
        end;

        jNode := jData.Find('Registros70');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            r70 := TRegistro70.Create;
            TJSONTools.JsonToObj(TJSONObject(jArr.Items[i]), r70);
            r70.DataDocumento := Trunc(r70.DataDocumento)+(i * 1.0E-8);
            facbr.Registros70.Add(r70);
          end;
        end;

        jNode := jData.Find('Registros71');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            r71 := TRegistro71.Create;
            TJSONTools.JsonToObj(TJSONObject(jArr.Items[i]), r71);
            facbr.Registros71.Add(r71);
          end;
        end;

        jNode := jData.Find('Registros74');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            r74 := TRegistro74.Create;
            TJSONTools.JsonToObj(TJSONObject(jArr.Items[i]), r74);
            facbr.Registros74.Add(r74);
          end;
        end;

        jNode := jData.Find('Registros75');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            r75 := TRegistro75.Create;
            TJSONTools.JsonToObj(TJSONObject(jArr.Items[i]), r75);
            facbr.Registros75.Add(r75);
          end;
        end;

        jNode := jData.Find('Registros76');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            r76 := TRegistro76.Create;
            TJSONTools.JsonToObj(TJSONObject(jArr.Items[i]), r76);
            facbr.Registros76.Add(r76);
          end;
        end;

        jNode := jData.Find('Registros77');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            r77 := TRegistro77.Create;
            TJSONTools.JsonToObj(TJSONObject(jArr.Items[i]), r77);
            facbr.Registros77.Add(r77);
          end;
        end;

        jNode := jData.Find('Registros85');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            r85 := TRegistro85.Create;
            TJSONTools.JsonToObj(TJSONObject(jArr.Items[i]), r85);
            facbr.Registros85.Add(r85);
          end;
        end;

        jNode := jData.Find('Registros86');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            r86 := TRegistro86.Create;
            TJSONTools.JsonToObj(TJSONObject(jArr.Items[i]), r86);
            facbr.Registros86.Add(r86);
          end;
        end;

        jNode := jData.Find('Registros88Ean');
        if Assigned(jNode) and (jNode is TJSONArray) then
        begin
          jArr := TJSONArray(jNode);
          for i := 0 to jArr.Count - 1 do
            if jArr.Items[i] is TJSONObject then
          begin
            r88Ean := TRegistro88Ean.Create;
            TJSONTools.JsonToObj(TJSONObject(jArr.Items[i]), r88Ean);
            facbr.Registros88Ean.Add(r88Ean);
          end;
        end;
      end;

      // Gera o arquivo do Sintegra
      try
        facbr.GeraArquivo;
      except
        on E: Exception do
          if (Pos('Registro: 90', E.Message) = 0) or (not FileExists(facbr.FileName)) then
            raise;
      end;

      // Normaliza os Registros 90 gerados para garantir linhas de 126 colunas
      // (ate 9 tipos por linha de detalhe + linha final dedicada 99) e contagem de 60R/61R
      if FileExists(facbr.FileName) then
      begin
        sl := TStringList.Create;
        try
          sl.LoadFromFile(facbr.FileName);
          while (sl.Count > 0) and (Copy(sl[sl.Count - 1], 1, 2) = '90') do
            sl.Delete(sl.Count - 1);

          cnpj10 := '';
          ie10 := '';
          if (sl.Count > 0) and (Copy(sl[0], 1, 2) = '10') and (Length(sl[0]) >= 30) then
          begin
            cnpj10 := Copy(sl[0], 3, 14);
            ie10 := Copy(sl[0], 17, 14);
          end;

          if (cnpj10 <> '') and (ie10 <> '') then
          begin
            activeLen := 0;
            for k := Low(ORDEM_90) to High(ORDEM_90) do
            begin
              tipo2 := ORDEM_90[k];
              cntTipo := 0;
              for m := 0 to sl.Count - 1 do
                if Copy(sl[m], 1, 2) = tipo2 then
                  Inc(cntTipo);
              if cntTipo > 0 then
              begin
                activeTipos[activeLen] := tipo2;
                activeCounts[activeLen] := cntTipo;
                Inc(activeLen);
              end;
            end;

            if activeLen > 0 then
              total90Lines := ((activeLen - 1) div 9)+2
            else
                total90Lines := 1;
            if total90Lines > 9 then
              suffix90 := '9'
            else
                suffix90 := IntToStr(total90Lines);

            prefix90 := '90' + cnpj10 + ie10;
            k := 0;
            while k<activeLen do
            begin
              chunkBody := '';
              countInChunk := 0;
              while (k<activeLen) and (countInChunk<9) do
              begin
                chunkBody := chunkBody + Copy(activeTipos[k]+'  ', 1, 2)+Format('%.8d', [activeCounts[k]]);
                Inc(k);
                Inc(countInChunk);
              end;
              sl.Add(prefix90 + chunkBody + StringOfChar(' ', 95 - Length(chunkBody))+suffix90);
            end;

            totalFileLines := sl.Count + 1;
            chunkBody := '99' + Format('%.8d', [totalFileLines]);
            sl.Add(prefix90 + chunkBody + StringOfChar(' ', 95 - Length(chunkBody))+suffix90);

            sl.LineBreak := #13#10;
            sl.SaveToFile(facbr.FileName);
          end;
        finally
          sl.Free;
        end;
      end;

      Result.Add('status', 'sucesso');
      Result.Add('message', 'Sintegra gerado com sucesso.');
      Result.Add('arquivo', facbr.FileName);
      if FileExists(facbr.FileName) then
      begin
        Result.Add('arquivo_base64', FileToStringBase64(facbr.FileName, isTempFile, tamanho));
        Result.Add('tamanho', tamanho);
      end;
      finally
        jClean.Free;
      end;
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add('message', 'Erro ao gerar Sintegra: ' + E.Message);
      end;
    end;
  finally
  end;
end;

function TACBRModelosJSONSintegra.ModelGerar: TJSONObject;
begin
  facbr.LimparRegistros;
  facbr.Registros50.Add(TRegistro50.Create);
  facbr.Registros51.Add(TRegistro51.Create);
  facbr.Registros53.Add(TRegistro53.Create);
  facbr.Registros54.Add(TRegistro54.Create);
  facbr.Registros55.Add(TRegistro55.Create);
  facbr.Registros56.Add(TRegistro56.Create);
  facbr.Registros60M.Add(TRegistro60M.Create);
  facbr.Registros60A.Add(TRegistro60A.Create);
  facbr.Registros60D.Add(TRegistro60D.Create);
  facbr.Registros60I.Add(TRegistro60I.Create);
  facbr.Registros60R.Add(TRegistro60R.Create);
  facbr.Registros61.Add(TRegistro61.Create);
  facbr.Registros61R.Add(TRegistro61R.Create);
  facbr.Registros70.Add(TRegistro70.Create);
  facbr.Registros71.Add(TRegistro71.Create);
  facbr.Registros74.Add(TRegistro74.Create);
  facbr.Registros75.Add(TRegistro75.Create);
  facbr.Registros76.Add(TRegistro76.Create);
  facbr.Registros77.Add(TRegistro77.Create);
  facbr.Registros85.Add(TRegistro85.Create);
  facbr.Registros86.Add(TRegistro86.Create);
  facbr.Registros88Ean.Add(TRegistro88Ean.Create);
  Result := TJSONObject.Create;
  Result.Add('sintegra', TJSONTools.ObjToJson(facbr));
  facbr.LimparRegistros;
end;


end.
