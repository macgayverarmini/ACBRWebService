unit jsonconvert;

{$mode Delphi}{$H+}
{$M+}

interface

uses
  fpjson,
  Horse.HandleException, jsonparser,
  pcnConversaoNFe, pcnConversao,
  Classes, SysUtils,
  resource.strings.global, TypInfo, RTTI;

type
  { TJSONTools }

  TJSONTools = class
  private
    class procedure PopulateObjectList(AListObj: TObject; AArray: TJSONArray; AOwner: TObject = nil);
    class function InternalObjToJson(const Obj: TObject; Visited: TList): TJSONData;
    class function ValueToJson(const Value: TValue; Visited: TList): TJSONData;
  public
    class function ObjToJsonString(const Obj: TObject): string;
    class function ObjToJson(const Obj: TObject): TJSONObject;

    class function SafeObjToJson(const Obj: TObject; const ErrorMsg: string = ''): TJSONObject;
    class function SafeObjToJsonString(const Obj: TObject; const ErrorMsg: string = ''): string;

    class procedure JsonStringToObj(const JsonString: string; const Obj: TObject);
    class procedure JsonToObj(const Json: TJSONObject; const Obj: TObject);

    class function ExtractConfig(O: TJSONObject; const Field: string = ''): string;
    class function ExtractCertificadoPFX(O: TJSONObject): AnsiString;
    class function ReadXMLFromJSON(const jsonData: TJSONObject; const ExtraKeys: array of string): string;
    class function JsonAndFree(AData: TJSONData): string;
    class function VariantToJson(const V: Variant): TJSONData;
    class function TryResolveSpedEnum(ATypeInfo: PTypeInfo; const AStr: string; out AOrd: Integer): Boolean;
  end;

implementation

uses
  Contnrs, DateUtils, Base64, synacode,
  Variants,
  ACBrEFDBlocos,
  ACBrEPCBlocos;

{ TJSONTools }

class procedure TJSONTools.PopulateObjectList(AListObj: TObject; AArray: TJSONArray; AOwner: TObject = nil);
var
  I: Integer;
  LNewItem, LOwnerArg: TObject;
  Ctx: TRttiContext;
  RttiType: TRttiType;
  RttiMethod: TRttiMethod;
  LParams: TRttiParameterArray;
  LParamVal: TValue;
begin
  if not Assigned(AListObj) then Exit;

  if AListObj is TStrings then
  begin
    TStrings(AListObj).Clear;
    for I := 0 to AArray.Count - 1 do
      TStrings(AListObj).Add(AArray.Items[I].AsString);
    Exit;
  end;

  if AListObj is TCollection then
  begin
    TCollection(AListObj).Clear;
    for I := 0 to AArray.Count - 1 do
    begin
      if AArray.Items[I] is TJSONObject then
      begin
        LNewItem := TCollection(AListObj).Add;
        if Assigned(LNewItem) then
          JsonToObj(TJSONObject(AArray.Items[I]), LNewItem);
      end;
    end;
    Exit;
  end;

  Ctx := TRttiContext.Create(False);
  try
    RttiType := Ctx.GetType(AListObj.ClassType);
    if not Assigned(RttiType) then Exit;

    RttiMethod := RttiType.GetMethod('New');
    if not Assigned(RttiMethod) then
      RttiMethod := RttiType.GetMethod('NEW');
    
    if not Assigned(RttiMethod) then
      RttiMethod := RttiType.GetMethod('new');

    if Assigned(RttiMethod) then
    begin
      LParams := RttiMethod.GetParameters;
      if AListObj is TObjectList then
        TObjectList(AListObj).Clear;
      for I := 0 to AArray.Count - 1 do
      begin
        if AArray.Items[I] is TJSONObject then
        begin
          LNewItem := nil;
          if Length(LParams) = 0 then
            LNewItem := RttiMethod.Invoke(AListObj, []).AsObject
          else if Length(LParams) = 1 then
          begin
            LOwnerArg := AOwner;
            if Assigned(LOwnerArg) and Assigned(LParams[0].ParamType) and
               (LParams[0].ParamType is TRttiInstanceType) and
               not (LOwnerArg is TRttiInstanceType(LParams[0].ParamType).MetaclassType) then
              LOwnerArg := nil;
            if Assigned(LParams[0].ParamType) then
              TValue.Make(@LOwnerArg, LParams[0].ParamType.Handle, LParamVal)
            else
              LParamVal := TValue.From<TObject>(LOwnerArg);
            LNewItem := RttiMethod.Invoke(AListObj, [LParamVal]).AsObject;
          end;
          if Assigned(LNewItem) then
            JsonToObj(TJSONObject(AArray.Items[I]), LNewItem);
        end;
      end;
    end;
  finally
    Ctx.Free;
  end;
end;

class function TJSONTools.SafeObjToJson(const Obj: TObject; const ErrorMsg: string): TJSONObject;
begin
  try
    if Assigned(Obj) then
      Result := ObjToJson(Obj)
    else
    begin
      Result := TJSONObject.Create;
      Result.Add(RSStatusField, RSStatusErro);
      if ErrorMsg <> '' then
        Result.Add(RSMessageField, ErrorMsg)
      else
        Result.Add(RSMessageField, 'Objeto não instanciado');
    end;
  except
    on E: Exception do
    begin
      Result := TJSONObject.Create;
      Result.Add(RSStatusField, RSStatusErro);
      if ErrorMsg <> '' then
        Result.Add(RSMessageField, ErrorMsg + ': ' + E.Message)
      else
        Result.Add(RSMessageField, E.Message);
    end;
  end;
end;

class function TJSONTools.SafeObjToJsonString(const Obj: TObject; const ErrorMsg: string): string;
var
  LJson: TJSONObject;
begin
  LJson := SafeObjToJson(Obj, ErrorMsg);
  try
    Result := LJson.AsJSON;
  finally
    LJson.Free;
  end;
end;

class function TJSONTools.ObjToJsonString(const Obj: TObject): string;
var
  LJson: TJSONObject;
begin
  LJson := ObjToJson(Obj);
  if Assigned(LJson) then
  begin
    try
      Result := LJson.AsJSON;
    finally
      LJson.Free;
    end;
  end
  else
    Result := '{}';
end;

class function TJSONTools.ValueToJson(const Value: TValue; Visited: TList): TJSONData;
var
  Obj: TObject;
  EnumName: string;
begin
  case Value.Kind of
    tkInteger, tkInt64, tkQWord:
      Result := TJSONIntegerNumber.Create(Value.AsInt64);
    tkFloat:
      begin
        if Value.TypeInfo = TypeInfo(TDateTime) then
          Result := TJSONString.Create(FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Value.AsExtended))
        else if Value.TypeInfo = TypeInfo(TDate) then
          Result := TJSONString.Create(FormatDateTime('yyyy-mm-dd', Value.AsExtended))
        else if Value.TypeInfo = TypeInfo(TTime) then
          Result := TJSONString.Create(FormatDateTime('hh:nn:ss', Value.AsExtended))
        else
          Result := TJSONFloatNumber.Create(Value.AsExtended);
      end;
    tkString, tkAString, tkWString, tkUString, tkChar, tkWChar, tkUChar:
      Result := TJSONString.Create(Value.AsString);
    tkEnumeration:
      begin
        if Value.TypeInfo = TypeInfo(Boolean) then
          Result := TJSONBoolean.Create(Value.AsBoolean)
        else
        begin
          EnumName := GetEnumName(Value.TypeInfo, Value.AsOrdinal);
          Result := TJSONString.Create(EnumName);
        end;
      end;
    tkSet:
      begin
        Result := TJSONString.Create(SetToString(Value.TypeInfo, Value.AsOrdinal, True));
      end;
    tkClass:
      begin
        Obj := Value.AsObject;
        Result := InternalObjToJson(Obj, Visited);
      end;
    tkVariant:
      Result := VariantToJson(Value.AsVariant);
  else    Result := TJSONNull.Create;
  end;
end;

class function TJSONTools.InternalObjToJson(const Obj: TObject; Visited: TList): TJSONData;
var
  Ctx: TRttiContext;
  RttiType: TRttiType;
  Props: TRttiPropertyArray;
  Prop: TRttiProperty;
  i: Integer;
  Val: TValue;
  ObjJson: TJSONObject;
  ArrJson: TJSONArray;
  ItemObj: TObject;
begin
  if Obj = nil then
    Exit(TJSONNull.Create);

  if Visited.IndexOf(Obj) >= 0 then
    Exit(TJSONNull.Create);

  Visited.Add(Obj);
  try
    if Obj is TStrings then
    begin
      ArrJson := TJSONArray.Create;
      for i := 0 to TStrings(Obj).Count - 1 do
        ArrJson.Add(TStrings(Obj)[i]);
      Exit(ArrJson);
    end;

    if Obj is TCollection then
    begin
      ArrJson := TJSONArray.Create;
      for i := 0 to TCollection(Obj).Count - 1 do
      begin
        ArrJson.Add(InternalObjToJson(TCollection(Obj).Items[i], Visited));
      end;
      Exit(ArrJson);
    end;

    if Obj is TObjectList then
    begin
      ArrJson := TJSONArray.Create;
      for i := 0 to TObjectList(Obj).Count - 1 do
      begin
        ArrJson.Add(InternalObjToJson(TObjectList(Obj).Items[i], Visited));
      end;
      Exit(ArrJson);
    end;
    
    if Obj is TList then
    begin
      ArrJson := TJSONArray.Create;
      for i := 0 to TList(Obj).Count - 1 do
      begin
        ItemObj := TObject(TList(Obj).Items[i]);
        ArrJson.Add(InternalObjToJson(ItemObj, Visited));
      end;
      Exit(ArrJson);
    end;

    ObjJson := TJSONObject.Create;
    
    Ctx := TRttiContext.Create(False);
    try
      RttiType := Ctx.GetType(Obj.ClassType);
      if Assigned(RttiType) then
      begin
        Props := RttiType.GetProperties;
        for i := 0 to Length(Props) - 1 do
        begin
          Prop := Props[i];
          if Prop.IsReadable and (Prop.Visibility in [mvPublic, mvPublished]) then
          begin
            try
              if (Prop.PropertyType.TypeKind = tkVariant) and Assigned(Prop.Handle) then
                ObjJson.Add(Prop.Name, VariantToJson(GetVariantProp(Obj, PPropInfo(Prop.Handle))))
              else
              begin
                Val := Prop.GetValue(Obj);
                ObjJson.Add(Prop.Name, ValueToJson(Val, Visited));
              end;
            except
            end;
          end;
        end;
      end;
    finally
      Ctx.Free;
    end;

    Result := ObjJson;

  finally
  end;
end;

class function TJSONTools.ObjToJson(const Obj: TObject): TJSONObject;
var
  Visited: TList;
  Data: TJSONData;
begin
  if Obj = nil then
    Exit(nil);

  Visited := TList.Create;
  try
    Data := InternalObjToJson(Obj, Visited);
    if Data is TJSONObject then
      Result := TJSONObject(Data)
    else if Data is TJSONArray then
    begin
      Result := TJSONObject.Create;
      Result.Add('items', Data);
    end
    else
    begin
      Result := TJSONObject.Create; 
      Data.Free;
    end;
  finally
    Visited.Free;
  end;
end;

class procedure TJSONTools.JsonStringToObj(const JsonString: string; const Obj: TObject);
var
  Json: TJSONData;
begin
  Json := GetJSON(JsonString);
  if Assigned(Json) then
  begin
    try
      if Json is TJSONObject then
        JsonToObj(TJSONObject(Json), Obj);
    finally
      Json.Free;
    end;
  end;
end;

class procedure TJSONTools.JsonToObj(const Json: TJSONObject; const Obj: TObject);
const
  ACBrEnumPrefixes: array[0..14] of string = (
    'cst', 'csosn', 'oe', 'dbi', 'dbis', 'mdi', 'pis', 'cof', 'ipi',
    'tm', 'cp', 'ia', 'te', 'ta', 'td'
  );
var
  Ctx: TRttiContext;
  RttiType: TRttiType;
  Prop: TRttiProperty;
  i, PIdx: Integer;
  Val: TValue;
  JsonVal: TJSONData;
  PropStr, SVal: string;
  ObjRef: TObject;
  EnumVal: Integer;
  LDate: TDateTime;
  LOk: Boolean;
  LTe: TpcnTpEvento;
  LTypeData: PTypeData;  LFloat: Double;
  LValCode: Integer;
begin
  if (Json = nil) or (Obj = nil) then Exit;

  Ctx := TRttiContext.Create(False);
  try
    RttiType := Ctx.GetType(Obj.ClassType);
    if not Assigned(RttiType) then Exit;

    for i := 0 to Json.Count - 1 do
    begin
      PropStr := Json.Names[i];
      JsonVal := Json.Items[i];
      Prop := RttiType.GetProperty(PropStr);
      if JsonVal.IsNull then
      begin
        if Assigned(Prop) and Prop.IsWritable and
           (Prop.PropertyType.TypeKind = tkVariant) and Assigned(Prop.Handle) then
          SetVariantProp(Obj, PPropInfo(Prop.Handle), Null);
        Continue;
      end;
      if Assigned(Prop) then
      begin
        if Prop.PropertyType.TypeKind = tkClass then
        begin
          Val := Prop.GetValue(Obj);
          ObjRef := Val.AsObject;
          if Assigned(ObjRef) then
          begin
            if JsonVal is TJSONObject then
              JsonToObj(TJSONObject(JsonVal), ObjRef)
            else if JsonVal is TJSONArray then
              PopulateObjectList(ObjRef, TJSONArray(JsonVal), Obj);
          end;
        end
        else if Prop.IsWritable then
        begin
          try
            case Prop.PropertyType.TypeKind of
              tkInteger, tkInt64, tkQWord:
                Prop.SetValue(Obj, TValue.From<Int64>(JsonVal.AsInt64));
              tkFloat:
                begin
                  if (Prop.PropertyType.Handle = TypeInfo(TDateTime)) or
                     (Prop.PropertyType.Handle = TypeInfo(TDate)) then
                  begin
                    if JsonVal is TJSONString then
                    begin
                      SVal := Trim(JsonVal.AsString);
                      LOk := (Length(SVal) > 10) and
                             ((Pos('+', Copy(SVal, 11, MaxInt)) > 0) or
                              (Pos('-', Copy(SVal, 11, MaxInt)) > 0));
                      if TryISO8601ToDate(SVal, LDate, not LOk) then
                        Prop.SetValue(Obj, TValue.From<Extended>(LDate))
                      else
                        Prop.SetValue(Obj, TValue.From<Extended>(StrToDateTimeDef(SVal, 0)));
                    end
                    else if JsonVal is TJSONNumber then
                      Prop.SetValue(Obj, TValue.From<Extended>(JsonVal.AsFloat));
                  end
                  else
                  begin
                    if JsonVal is TJSONString then
                    begin
                      SVal := Trim(JsonVal.AsString);
                      System.Val(StringReplace(SVal, ',', '.', [rfReplaceAll]), LFloat, LValCode);
                      if LValCode = 0 then
                        Prop.SetValue(Obj, TValue.From<Extended>(LFloat))
                      else
                        Prop.SetValue(Obj, TValue.From<Extended>(StrToFloatDef(SVal, 0)));
                    end
                    else if JsonVal is TJSONNumber then
                      Prop.SetValue(Obj, TValue.From<Extended>(JsonVal.AsFloat));
                  end;
                end;
              tkString, tkUString, tkAString, tkWString, tkChar, tkWChar, tkUChar:
                if JsonVal is TJSONObject then
                begin
                  if TJSONObject(JsonVal).Get('Cnpj', '') <> '' then
                    Prop.SetValue(Obj, TValue.From<string>(TJSONObject(JsonVal).Get('Cnpj', '')))
                  else if TJSONObject(JsonVal).Get('CNPJ', '') <> '' then
                    Prop.SetValue(Obj, TValue.From<string>(TJSONObject(JsonVal).Get('CNPJ', '')))
                  else if TJSONObject(JsonVal).Get('Cpf', '') <> '' then
                    Prop.SetValue(Obj, TValue.From<string>(TJSONObject(JsonVal).Get('Cpf', '')))
                  else if TJSONObject(JsonVal).Get('CPF', '') <> '' then
                    Prop.SetValue(Obj, TValue.From<string>(TJSONObject(JsonVal).Get('CPF', '')));
                end
                else
                  Prop.SetValue(Obj, TValue.From<string>(JsonVal.AsString));
              tkEnumeration:
                if Prop.PropertyType.Handle = TypeInfo(Boolean) then
                begin
                  if JsonVal is TJSONBoolean then
                    Prop.SetValue(Obj, TValue.From<Boolean>(JsonVal.AsBoolean))
                  else if JsonVal is TJSONNumber then
                    Prop.SetValue(Obj, TValue.From<Boolean>(JsonVal.AsInteger <> 0))
                  else
                    Prop.SetValue(Obj, TValue.From<Boolean>(SameText(JsonVal.AsString, 'true') or (JsonVal.AsString = '1')));
                end
                else
                begin
                  SVal := Trim(JsonVal.AsString);
                  EnumVal := GetEnumValue(Prop.PropertyType.Handle, SVal);                  if (EnumVal < 0) and not (JsonVal is TJSONNumber) then
                  begin
                    if not TryResolveSpedEnum(Prop.PropertyType.Handle, SVal, EnumVal) then
                      EnumVal := -1;
                  end;
                  if (EnumVal < 0) and (Prop.PropertyType.Handle = TypeInfo(TpcnTpEvento)) and (SVal <> '') then
                  begin
                    LTe := StrToTpEventoNFe(LOk, SVal);
                    if LOk then
                      EnumVal := Ord(LTe);
                  end;
                  if (EnumVal < 0) and (SVal <> '') then
                  begin
                    if SameText(Copy(SVal, 1, 2), 'md') then
                      EnumVal := GetEnumValue(Prop.PropertyType.Handle, 'mo' + Copy(SVal, 3, Length(SVal) - 2))
                    else if SameText(Copy(SVal, 1, 2), 'mo') then
                      EnumVal := GetEnumValue(Prop.PropertyType.Handle, 'md' + Copy(SVal, 3, Length(SVal) - 2))
                    else if SameText(SVal, 'crtSimplesNacionalExcesso') then
                      EnumVal := GetEnumValue(Prop.PropertyType.Handle, 'crtSimplesExcessoReceita')
                    else if SameText(SVal, 'crtSimplesExcessoReceita') then
                      EnumVal := GetEnumValue(Prop.PropertyType.Handle, 'crtSimplesNacionalExcesso')
                    else if SameText(SVal, 'crtMEI') then
                      EnumVal := GetEnumValue(Prop.PropertyType.Handle, 'crtSimplesNacionalMEI')
                    else if SameText(SVal, 'crtSimplesNacionalMEI') then
                      EnumVal := GetEnumValue(Prop.PropertyType.Handle, 'crtMEI');
                  end;
                  if (EnumVal < 0) and (SVal <> '') then
                  begin
                    for PIdx := Low(ACBrEnumPrefixes) to High(ACBrEnumPrefixes) do
                    begin
                      EnumVal := GetEnumValue(Prop.PropertyType.Handle, ACBrEnumPrefixes[PIdx] + SVal);
                      if EnumVal >= 0 then
                        Break;
                    end;
                  end;
                  if (EnumVal < 0) and (JsonVal is TJSONNumber) then
                    EnumVal := JsonVal.AsInteger;
                  if (EnumVal < 0) and (SVal <> '') then
                  begin
                    if not TryStrToInt(SVal, EnumVal) then
                      EnumVal := -1;
                  end;
                  LTypeData := GetTypeData(Prop.PropertyType.Handle);
                  if (EnumVal >= 0) and (not Assigned(LTypeData) or
                     ((EnumVal >= LTypeData^.MinValue) and (EnumVal <= LTypeData^.MaxValue))) then
                    Prop.SetValue(Obj, TValue.FromOrdinal(Prop.PropertyType.Handle, EnumVal));
                end;
              tkSet:
                begin
                  EnumVal := StringToSet(Prop.PropertyType.Handle, JsonVal.AsString);
                  Prop.SetValue(Obj, TValue.FromOrdinal(Prop.PropertyType.Handle, EnumVal));
                end;              tkVariant:
                if Assigned(Prop.Handle) then
                begin
                  if JsonVal is TJSONNumber then
                    SetVariantProp(Obj, PPropInfo(Prop.Handle), Double(JsonVal.AsFloat))
                  else if JsonVal is TJSONBoolean then
                    SetVariantProp(Obj, PPropInfo(Prop.Handle), JsonVal.AsBoolean)
                  else
                  begin
                    SVal := Trim(JsonVal.AsString);
                    if SVal = '' then
                      SetVariantProp(Obj, PPropInfo(Prop.Handle), Null)
                    else
                    begin
                      System.Val(StringReplace(SVal, ',', '.', [rfReplaceAll]), LFloat, LValCode);
                      if LValCode = 0 then
                        SetVariantProp(Obj, PPropInfo(Prop.Handle), LFloat)
                      else
                        SetVariantProp(Obj, PPropInfo(Prop.Handle), JsonVal.AsString);
                    end;
                  end;
                end;
            end;
          except
          end;
        end;
      end;
    end;
  finally
    Ctx.Free;
  end;
end;

class function TJSONTools.ExtractConfig(O: TJSONObject; const Field: string): string;
var
  CfgData: TJSONData;
  LField: string;
begin
  Result := '';
  if not Assigned(O) then
    Exit;
  if Field <> '' then
    LField := Field
  else
    LField := RSConfigField;
  CfgData := O.Extract(LField);
  if Assigned(CfgData) then
  begin
    try
      Result := CfgData.AsJSON;
    finally
      CfgData.Free;
    end;
  end;
end;

class function TJSONTools.ExtractCertificadoPFX(O: TJSONObject): AnsiString;
var
  LCertJson: TJSONData;
  LCertObj: TJSONObject;
  LPFXB64: string;
begin
  Result := '';
  if not Assigned(O) then
    Exit;
  LCertJson := O.Find('Certificados');
  if Assigned(LCertJson) and (LCertJson is TJSONObject) then
  begin
    LCertObj := TJSONObject(LCertJson);
    LPFXB64 := LCertObj.Get('DadosPFXBase64', '');
    if LPFXB64 = '' then
      LPFXB64 := LCertObj.Get('DadosPFX', '');
    if LPFXB64 <> '' then
      Result := synacode.DecodeBase64(LPFXB64);
  end;
end;

class function TJSONTools.ReadXMLFromJSON(const jsonData: TJSONObject; const ExtraKeys: array of string): string;
const
  DefaultKeys: array[0..3] of string = (RSXmlKey, RSXMLField, 'XMLEvento', 'xml_evento');
var
  LXmlValue: string;
  I: Integer;
begin
  LXmlValue := '';
  if Assigned(jsonData) then
  begin
    for I := Low(DefaultKeys) to High(DefaultKeys) do
    begin
      LXmlValue := jsonData.Get(DefaultKeys[I], '');
      if LXmlValue <> '' then
        Break;
    end;
    if LXmlValue = '' then
    begin
      for I := Low(ExtraKeys) to High(ExtraKeys) do
      begin
        LXmlValue := jsonData.Get(ExtraKeys[I], '');
        if LXmlValue <> '' then
          Break;
      end;
    end;
  end;

  if LXmlValue = '' then
    raise Exception.Create('O campo "xml" não foi informado ou está vazio no JSON.');

  LXmlValue := Trim(LXmlValue);

  if Copy(LXmlValue, 1, 1) = '<' then
    Result := LXmlValue
  else
  begin
    try
      Result := DecodeStringBase64(LXmlValue);
    except
      on E: Exception do
        raise Exception.Create('Erro ao decodificar XML Base64: ' + E.Message);
    end;
  end;
end;

class function TJSONTools.JsonAndFree(AData: TJSONData): string;
begin
  Result := '{}';
  if Assigned(AData) then
  begin
    try
      Result := AData.AsJSON;
    finally
      AData.Free;
    end;
  end;
end;


class function TJSONTools.VariantToJson(const V: Variant): TJSONData;
begin
  if VarIsNull(V) or VarIsEmpty(V) then
    Result := TJSONNull.Create
  else if VarIsType(V, varBoolean) then
    Result := TJSONBoolean.Create(Boolean(V))
  else if VarIsNumeric(V) then
    Result := TJSONFloatNumber.Create(Double(V))
  else
    Result := TJSONString.Create(VarToStr(V));
end;



class function TJSONTools.TryResolveSpedEnum(ATypeInfo: PTypeInfo; const AStr: string; out AOrd: Integer): Boolean;
begin
  Result := True;
  AOrd := -1;
  try
    if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrVersaoLeiauteSPEDFiscal) then
      AOrd := Ord(ACBrEFDBlocos.StrToCodVer(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrCodFin) then
      AOrd := Ord(ACBrEFDBlocos.StrToCodFin(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrIndPerfil) then
      AOrd := Ord(ACBrEFDBlocos.StrToIndPerfil(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrIndAtiv) then
      AOrd := Ord(ACBrEFDBlocos.StrToIndAtiv(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrIndMov) then
      AOrd := Ord(ACBrEFDBlocos.StrToIndMov(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrTipoItem) then
      AOrd := Ord(ACBrEFDBlocos.StrToTipoItem(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrIndOper) then
      AOrd := Ord(ACBrEFDBlocos.StrToIndOper(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrIndEmit) then
      AOrd := Ord(ACBrEFDBlocos.StrToIndEmit(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrCodSit) then
      AOrd := Ord(ACBrEFDBlocos.StrToCodSit(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrIndPgto) then
      AOrd := Ord(ACBrEFDBlocos.StrToIndPgto(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrIndFrt) then
      AOrd := Ord(ACBrEFDBlocos.StrToIndFrt(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrIndMovFisica) then
      AOrd := Ord(ACBrEFDBlocos.StrToIndMovFisica(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrApuracaoIPI) then
      AOrd := Ord(ACBrEFDBlocos.StrToApuracaoIPI(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrMotInv) then
      AOrd := Ord(ACBrEFDBlocos.StrToMotInv(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrIndProp) then
      AOrd := Ord(ACBrEFDBlocos.StrToIndProp(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrIndEstoque) then
      AOrd := Ord(ACBrEFDBlocos.StrToIndEst(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrIndTipoLeiaute) then
      AOrd := Ord(ACBrEFDBlocos.StrToIndTipoLeiaute(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrTpLigacao) then
      AOrd := Ord(ACBrEFDBlocos.StrToTpLigacao(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrGrupoTensao) then
      AOrd := Ord(ACBrEFDBlocos.StrToGrupoTensao(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrTpAssinante) then
      AOrd := Ord(ACBrEFDBlocos.StrToTpAssinante(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrDispositivo) then
      AOrd := Ord(ACBrEFDBlocos.StrToDispositivo(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrOrigemProcesso) then
      AOrd := Ord(ACBrEFDBlocos.StrToOrigemProcesso(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrIndicadorObrigacao) then
      AOrd := Ord(ACBrEFDBlocos.StrToIndicadorObrigacao(AStr))
    else if ATypeInfo = TypeInfo(ACBrEFDBlocos.TACBrIndicadorProcesso) then
      AOrd := Ord(ACBrEFDBlocos.StrToIndicadorProcesso(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrCodVer) then
      AOrd := Ord(ACBrEPCBlocos.StrToCodVer(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrTipoEscrit) then
      AOrd := Ord(ACBrEPCBlocos.StrToTipoEscrit(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndSitEsp) then
    begin
      if AStr = '' then
        AOrd := Ord(ACBrEPCBlocos.indNenhum)
      else
        AOrd := Ord(ACBrEPCBlocos.StrToIndSitEsp(AStr));
    end
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndNatPJ) then
    begin
      if AStr = '' then
        AOrd := Ord(ACBrEPCBlocos.indNatPJNenhum)
      else
        AOrd := Ord(ACBrEPCBlocos.StrToIndNatPJ(AStr));
    end
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndAtiv) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndAtiv(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndMov) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndMov(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrCodIncTrib) then
      AOrd := Ord(ACBrEPCBlocos.StrToCodIncTrib(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndAproCred) then
    begin
      if AStr = '' then
        AOrd := Ord(ACBrEPCBlocos.indMetodoApropriacaoDireta)
      else
        AOrd := Ord(ACBrEPCBlocos.StrToIndAproCred(AStr));
    end
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrCodTipoCont) then
      AOrd := Ord(ACBrEPCBlocos.StrToCodTipoCont(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndRegCum) then
    begin
      if AStr = '' then
        AOrd := Ord(ACBrEPCBlocos.codRegimeCaixa)
      else
        AOrd := Ord(ACBrEPCBlocos.StrToIndRegCum(AStr));
    end
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrTipoItem) then
      AOrd := Ord(ACBrEPCBlocos.StrToTipoItem(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrNaturezaConta) then
      AOrd := Ord(ACBrEPCBlocos.StrToNaturezaConta(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndCTA) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndCTA(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndTipoOper) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndTipoOper(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndOper) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndOper(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndEmit) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndEmit(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrEmitente) then
      AOrd := Ord(ACBrEPCBlocos.StrToEmitente(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrCodSit) then
      AOrd := Ord(ACBrEPCBlocos.StrToCodSit(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrCodSitF) then
      AOrd := Ord(ACBrEPCBlocos.StrToCodSitF(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndPgto) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndPgto(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndFrt) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndFrt(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrNaturezaFrtContratado) then
      AOrd := Ord(ACBrEPCBlocos.StrToNaturezaFrtContratado(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndMovFisica) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndMovFisica(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrApuracaoIPI) then
      AOrd := Ord(ACBrEPCBlocos.StrToApuracaoIPI(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrNatBcCred) then
      AOrd := Ord(ACBrEPCBlocos.StrToNatBcCred(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndOrigCred) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndOrigCred(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrCstPis) then
      AOrd := Ord(ACBrEPCBlocos.StrToCstPis(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrCstCofins) then
      AOrd := Ord(ACBrEPCBlocos.StrToCstCofins(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrCstPisCofins) then
      AOrd := Ord(ACBrEPCBlocos.StrToCstPisCofins(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrCstIcms) then
      AOrd := Ord(ACBrEPCBlocos.StrToCstIcms(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrCstIpi) then
      AOrd := Ord(ACBrEPCBlocos.StrToCstIpi(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrLocalExecServico) then
      AOrd := Ord(ACBrEPCBlocos.StrToLocalExecServico(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndEscrituracao) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndEscrituracao(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrOrigemProcesso) then
      AOrd := Ord(ACBrEPCBlocos.StrToOrigemProcesso(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndTpOperacaoReceita) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndTpOperacaoReceita(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndNatRetFonte) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndNatRetFonte(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndCredOri) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndCredOri(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndDescCred) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndDescCred(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrCodCont) then
      AOrd := Ord(ACBrEPCBlocos.StrToCodCont(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrIndAJ) then
      AOrd := Ord(ACBrEPCBlocos.StrToIndAJ(AStr))
    else if ATypeInfo = TypeInfo(ACBrEPCBlocos.TACBrCodAj) then
      AOrd := Ord(ACBrEPCBlocos.StrToCodAj(AStr))
    else
      Result := False;
  except
    Result := False;
    AOrd := -1;
  end;
end;


end.
