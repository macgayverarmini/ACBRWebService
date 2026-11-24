unit jsonconvert;

{$mode Delphi}{$H+}
{$M+}

interface

uses
  fpjson,
  jsonparser,
  Classes,
  SysUtils,
  resource.strings.global,
  TypInfo,
  RTTI;

type
  { TJSONTools }

  TJSONTools = class
  private
    class procedure PopulateObjectList(AListObj: TObject; AArray: TJSONArray; AOwner: TObject = nil);
    class function InstantiateClassProperty(var Ctx: TRttiContext; const ParentType: TRttiType;
      const Prop: TRttiProperty; const Obj: TObject; const AOwner: TObject): TObject;
    class procedure InternalJsonToObj(const Json: TJSONObject; const Obj: TObject; const AOwner: TObject = nil);
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
  end;

implementation

uses
  {$IFDEF UNIX}
  ffi.manager,
  {$ENDIF}
  Contnrs,
  DateUtils,
  Base64,
  synacode,
  Variants;

function IsPlainStringsInstance(const AObj: TObject): Boolean;
var
  LCls: TClass;
begin
  if not (AObj is TStrings) then
    Exit(False);
  LCls := AObj.ClassType;
  while Assigned(LCls) do
  begin
    { TACBrEMVList / TACBrPIXQRCodeDinamico inherit TStringList internally
      but expose EMV/PIX fields as public RTTI properties. }
    if SameText(LCls.ClassName, 'TACBrEMVList') then
      Exit(False);
    LCls := LCls.ClassParent;
  end;
  Result := True;
end;

function Cp1252ByteToUnicode(const B: Byte): Cardinal;
begin
  case B of
    $80: Result := $20AC;
    $82: Result := $201A;
    $83: Result := $0192;
    $84: Result := $201E;
    $85: Result := $2026;
    $86: Result := $2020;
    $87: Result := $2021;
    $88: Result := $02C6;
    $89: Result := $2030;
    $8A: Result := $0160;
    $8B: Result := $2039;
    $8C: Result := $0152;
    $8E: Result := $017D;
    $91: Result := $2018;
    $92: Result := $2019;
    $93: Result := $201C;
    $94: Result := $201D;
    $95: Result := $2022;
    $96: Result := $2013;
    $97: Result := $2014;
    $98: Result := $02DC;
    $99: Result := $2122;
    $9A: Result := $0161;
    $9B: Result := $203A;
    $9C: Result := $0153;
    $9E: Result := $017E;
    $9F: Result := $0178;
  else
    Result := B;
  end;
end;

function IsValidUtf8Bytes(const ARaw: RawByteString): Boolean;
var
  I, Len: Integer;
  B, B2, B3, B4: Byte;
begin
  Result := True;
  Len := Length(ARaw);
  I := 1;
  while I <= Len do
  begin
    B := Byte(ARaw[I]);
    if B <= $7F then
      Inc(I)
    else if (B and $E0) = $C0 then
    begin
      if (B < $C2) or (I + 1 > Len) then
        Exit(False);
      B2 := Byte(ARaw[I + 1]);
      if (B2 and $C0) <> $80 then
        Exit(False);
      Inc(I, 2);
    end
    else if (B and $F0) = $E0 then
    begin
      if I + 2 > Len then
        Exit(False);
      B2 := Byte(ARaw[I + 1]);
      B3 := Byte(ARaw[I + 2]);
      if ((B2 and $C0) <> $80) or ((B3 and $C0) <> $80) then
        Exit(False);
      if (B = $E0) and (B2 < $A0) then
        Exit(False);
      if (B = $ED) and (B2 >= $A0) then
        Exit(False);
      Inc(I, 3);
    end
    else if (B and $F8) = $F0 then
    begin
      if (B > $F4) or (I + 3 > Len) then
        Exit(False);
      B2 := Byte(ARaw[I + 1]);
      B3 := Byte(ARaw[I + 2]);
      B4 := Byte(ARaw[I + 3]);
      if ((B2 and $C0) <> $80) or ((B3 and $C0) <> $80) or ((B4 and $C0) <> $80) then
        Exit(False);
      if (B = $F0) and (B2 < $90) then
        Exit(False);
      if (B = $F4) and (B2 > $8F) then
        Exit(False);
      Inc(I, 4);
    end
    else
      Exit(False);
  end;
end;

function EnsureValidUtf8(const S: RawByteString): UTF8String;
var
  I, OutLen: Integer;
  CP: Cardinal;
  OutRaw: RawByteString;
begin
  if S = '' then
    Exit('');
  if IsValidUtf8Bytes(S) then
  begin
    OutRaw := S;
    SetCodePage(OutRaw, CP_UTF8, False);
    Result := OutRaw;
    Exit;
  end;

  SetLength(OutRaw, Length(S) * 3);
  OutLen := 0;
  for I := 1 to Length(S) do
  begin
    CP := Cp1252ByteToUnicode(Byte(S[I]));
    if CP <= $7F then
    begin
      Inc(OutLen);
      OutRaw[OutLen] := AnsiChar(CP);
    end
    else if CP <= $7FF then
    begin
      Inc(OutLen);
      OutRaw[OutLen] := AnsiChar($C0 or ((CP shr 6) and $1F));
      Inc(OutLen);
      OutRaw[OutLen] := AnsiChar($80 or (CP and $3F));
    end
    else
    begin
      Inc(OutLen);
      OutRaw[OutLen] := AnsiChar($E0 or ((CP shr 12) and $0F));
      Inc(OutLen);
      OutRaw[OutLen] := AnsiChar($80 or ((CP shr 6) and $3F));
      Inc(OutLen);
      OutRaw[OutLen] := AnsiChar($80 or (CP and $3F));
    end;
  end;
  SetLength(OutRaw, OutLen);
  SetCodePage(OutRaw, CP_UTF8, False);
  Result := OutRaw;
end;

{ TJSONTools }

class procedure TJSONTools.PopulateObjectList(AListObj: TObject; AArray: TJSONArray; AOwner: TObject);
var
  I: Integer;
  LNewItem, LOwnerArg: TObject;
  Ctx: TRttiContext;
  RttiType: TRttiType;
  LItemRttiType: TRttiInstanceType;
  RttiMethod, LCtorMethod: TRttiMethod;
  LParams, LCtorParams: TRttiParameterArray;
  LParamVal: TValue;
begin
  if not Assigned(AListObj) then
    Exit;

  if IsPlainStringsInstance(AListObj) then
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
          InternalJsonToObj(TJSONObject(AArray.Items[I]), LNewItem, AListObj);
      end;
    end;
    Exit;
  end;

  Ctx := TRttiContext.Create(False);
  try
    RttiType := Ctx.GetType(AListObj.ClassType);
    if not Assigned(RttiType) then
      Exit;

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
               LParams[0].ParamType.IsInstance and
               not (LOwnerArg is LParams[0].ParamType.AsInstance.MetaclassType) then
              LOwnerArg := nil;
            if Assigned(LParams[0].ParamType) then
              TValue.Make(@LOwnerArg, LParams[0].ParamType.Handle, LParamVal)
            else
              LParamVal := TValue.From<TObject>(LOwnerArg);
            LNewItem := RttiMethod.Invoke(AListObj, [LParamVal]).AsObject;
          end;
          if Assigned(LNewItem) then
            InternalJsonToObj(TJSONObject(AArray.Items[I]), LNewItem, AListObj);
        end;
      end;
    end
    else if AListObj is TObjectList then
    begin
      RttiMethod := RttiType.GetMethod('Add');
      if Assigned(RttiMethod) then
      begin
        LParams := RttiMethod.GetParameters;
        if (Length(LParams) = 1) and Assigned(LParams[0].ParamType) and
           LParams[0].ParamType.IsInstance then
        begin
          LItemRttiType := LParams[0].ParamType.AsInstance;
          if LItemRttiType.MetaclassType = TObject then
            Exit;
          LCtorMethod := LItemRttiType.GetMethod('Create');
          TObjectList(AListObj).Clear;
          for I := 0 to AArray.Count - 1 do
          begin
            if AArray.Items[I] is TJSONObject then
            begin
              LNewItem := nil;
              if Assigned(LCtorMethod) then
              begin
                if LCtorMethod.MethodKind = mkConstructor then
                begin
                  LCtorParams := LCtorMethod.GetParameters;
                  if Length(LCtorParams) = 0 then
                    LNewItem := LCtorMethod.Invoke(LItemRttiType.MetaclassType, []).AsObject
                  else if (Length(LCtorParams) = 1) and (AOwner <> nil) and
                          Assigned(LCtorParams[0].ParamType) and
                          LCtorParams[0].ParamType.IsInstance and
                          (AOwner is LCtorParams[0].ParamType.AsInstance.MetaclassType) then
                  begin
                    LOwnerArg := AOwner;
                    TValue.Make(@LOwnerArg, LCtorParams[0].ParamType.Handle, LParamVal);
                    LNewItem := LCtorMethod.Invoke(LItemRttiType.MetaclassType, [LParamVal]).AsObject;
                  end;
                end;
              end
              else
                LNewItem := LItemRttiType.MetaclassType.Create;
              if Assigned(LNewItem) then
              begin
                InternalJsonToObj(TJSONObject(AArray.Items[I]), LNewItem, AListObj);
                TObjectList(AListObj).Add(LNewItem);
              end;
            end;
          end;
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
      Result := TJSONString.Create(EnsureValidUtf8(Value.AsString));
    tkBool:
      Result := TJSONBoolean.Create(Value.AsBoolean);
    tkEnumeration:
      begin
        if Value.TypeInfo = TypeInfo(Boolean) then
          Result := TJSONBoolean.Create(Value.AsBoolean)
        else
        begin
          EnumName := GetEnumName(Value.TypeInfo, Value.AsOrdinal);
          Result := TJSONString.Create(EnsureValidUtf8(EnumName));
        end;
      end;
    tkSet:
      Result := TJSONString.Create(EnsureValidUtf8(SetToString(Value.TypeInfo, Value.AsOrdinal, True)));
    tkClass:
      begin
        Obj := Value.AsObject;
        Result := InternalObjToJson(Obj, Visited);
      end;
    tkVariant:
      Result := VariantToJson(Value.AsVariant);
  else
    Result := TJSONNull.Create;
  end;
end;

class function TJSONTools.InternalObjToJson(const Obj: TObject; Visited: TList): TJSONData;
var
  Ctx: TRttiContext;
  RttiType: TRttiType;
  Props: TRttiPropertyArray;
  Prop: TRttiProperty;
  I: Integer;
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

  if IsPlainStringsInstance(Obj) then
  begin
    ArrJson := TJSONArray.Create;
    for I := 0 to TStrings(Obj).Count - 1 do
      ArrJson.Add(EnsureValidUtf8(TStrings(Obj)[I]));
    Exit(ArrJson);
  end;

  if Obj is TCollection then
  begin
    ArrJson := TJSONArray.Create;
    for I := 0 to TCollection(Obj).Count - 1 do
      ArrJson.Add(InternalObjToJson(TCollection(Obj).Items[I], Visited));
    Exit(ArrJson);
  end;

  if Obj is TObjectList then
  begin
    ArrJson := TJSONArray.Create;
    for I := 0 to TObjectList(Obj).Count - 1 do
      ArrJson.Add(InternalObjToJson(TObjectList(Obj).Items[I], Visited));
    Exit(ArrJson);
  end;

  if Obj is TList then
  begin
    ArrJson := TJSONArray.Create;
    for I := 0 to TList(Obj).Count - 1 do
    begin
      ItemObj := TObject(TList(Obj).Items[I]);
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
      for I := 0 to Length(Props) - 1 do
      begin
        Prop := Props[I];
        if (not Prop.IsClassProperty) and Prop.IsReadable and
           (Prop.Visibility in [mvPublic, mvPublished]) and Assigned(Prop.PropertyType) then
        begin
          try
            if (Prop.PropertyType.TypeKind = tkVariant) and Assigned(Prop.Handle) then
              ObjJson.Add(Prop.Name, VariantToJson(GetVariantProp(Obj, PPropInfo(Prop.Handle))))
            else if Prop.PropertyType.TypeKind in [
              tkInteger, tkInt64, tkQWord, tkFloat,
              tkString, tkAString, tkWString, tkUString, tkChar, tkWChar, tkUChar,
              tkBool, tkEnumeration, tkSet, tkClass
            ] then
            begin
              Val := Prop.GetValue(Obj);
              ObjJson.Add(Prop.Name, ValueToJson(Val, Visited));
            end
            else
              ObjJson.Add(Prop.Name, TJSONNull.Create);
          except
          end;
        end;
      end;
    end;
  finally
    Ctx.Free;
  end;

  Result := ObjJson;
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

class function TJSONTools.InstantiateClassProperty(var Ctx: TRttiContext;
  const ParentType: TRttiType; const Prop: TRttiProperty;
  const Obj: TObject; const AOwner: TObject): TObject;
var
  LFactoryName: string;
  LFactoryMethod, LCtor, LM: TRttiMethod;
  LOwnerType: TRttiType;
  LInstType: TRttiInstanceType;
  LMethods: TRttiMethodArray;
  LParams: TRttiParameterArray;
  LCreated, LOwnerArg: TObject;
  LPropVal, LParamVal: TValue;
  I: Integer;
begin
  Result := nil;
  if (not Assigned(Prop)) or (not Assigned(Prop.PropertyType)) or
     (not Prop.PropertyType.IsInstance) then
    Exit;

  LFactoryName := Prop.Name + 'New';
  if Assigned(ParentType) then
  begin
    LFactoryMethod := ParentType.GetMethod(LFactoryName);
    if Assigned(LFactoryMethod) and (Length(LFactoryMethod.GetParameters) = 0) and
       Assigned(LFactoryMethod.ReturnType) and LFactoryMethod.ReturnType.IsInstance then
    begin
      LCreated := LFactoryMethod.Invoke(Obj, []).AsObject;
      Result := Prop.GetValue(Obj).AsObject;
      if (not Assigned(Result)) and Assigned(LCreated) and Prop.IsWritable then
      begin
        TValue.Make(@LCreated, Prop.PropertyType.Handle, LPropVal);
        Prop.SetValue(Obj, LPropVal);
        Result := LCreated;
      end;
      if Assigned(Result) then
        Exit;
    end;
  end;

  if Assigned(AOwner) then
  begin
    LOwnerType := Ctx.GetType(AOwner.ClassType);
    if Assigned(LOwnerType) then
    begin
      LFactoryMethod := LOwnerType.GetMethod(LFactoryName);
      if Assigned(LFactoryMethod) and (Length(LFactoryMethod.GetParameters) = 0) and
         Assigned(LFactoryMethod.ReturnType) and LFactoryMethod.ReturnType.IsInstance then
      begin
        LCreated := LFactoryMethod.Invoke(AOwner, []).AsObject;
        Result := Prop.GetValue(Obj).AsObject;
        if (not Assigned(Result)) and Assigned(LCreated) and Prop.IsWritable then
        begin
          TValue.Make(@LCreated, Prop.PropertyType.Handle, LPropVal);
          Prop.SetValue(Obj, LPropVal);
          Result := LCreated;
        end;
        if Assigned(Result) then
          Exit;
      end;
    end;
  end;

  if not Prop.IsWritable then
    Exit;

  LInstType := Prop.PropertyType.AsInstance;
  if (LInstType.MetaclassType = TObject) or
     LInstType.MetaclassType.InheritsFrom(TComponent) or
     LInstType.MetaclassType.InheritsFrom(TStrings) or
     LInstType.MetaclassType.InheritsFrom(TCollection) then
    Exit;

  LCtor := nil;
  LMethods := LInstType.GetMethods;
  for I := 0 to Length(LMethods) - 1 do
  begin
    LM := LMethods[I];
    if (LM.MethodKind = mkConstructor) and SameText(LM.Name, 'Create') then
    begin
      LParams := LM.GetParameters;
      if Length(LParams) = 0 then
      begin
        LCtor := LM;
        Break;
      end
      else if (not Assigned(LCtor)) and (Length(LParams) = 1) and
              Assigned(LParams[0].ParamType) and LParams[0].ParamType.IsInstance and
              (Obj is LParams[0].ParamType.AsInstance.MetaclassType) then
        LCtor := LM;
    end;
  end;

  LCreated := nil;
  if Assigned(LCtor) then
  begin
    LParams := LCtor.GetParameters;
    if Length(LParams) = 0 then
      LCreated := LCtor.Invoke(LInstType.MetaclassType, []).AsObject
    else
    begin
      LOwnerArg := Obj;
      TValue.Make(@LOwnerArg, LParams[0].ParamType.Handle, LParamVal);
      LCreated := LCtor.Invoke(LInstType.MetaclassType, [LParamVal]).AsObject;
    end;
  end
  else
    LCreated := LInstType.MetaclassType.Create;

  if Assigned(LCreated) then
  begin
    TValue.Make(@LCreated, Prop.PropertyType.Handle, LPropVal);
    Prop.SetValue(Obj, LPropVal);
    Result := LCreated;
  end;
end;

class procedure TJSONTools.JsonToObj(const Json: TJSONObject; const Obj: TObject);
begin
  InternalJsonToObj(Json, Obj, nil);
end;

class procedure TJSONTools.InternalJsonToObj(const Json: TJSONObject; const Obj: TObject; const AOwner: TObject);
var
  Ctx: TRttiContext;
  RttiType: TRttiType;
  Prop: TRttiProperty;
  I: Integer;
  Val, LPropVal: TValue;
  JsonVal: TJSONData;
  PropStr, SVal: string;
  ObjRef, LNilObj: TObject;
  EnumVal: Integer;
  LDate: TDateTime;
  LOk: Boolean;
  LTypeData: PTypeData;
  LFloat: Double;
  LValCode: Integer;
begin
  if (Json = nil) or (Obj = nil) then
    Exit;

  Ctx := TRttiContext.Create(False);
  try
    RttiType := Ctx.GetType(Obj.ClassType);
    if not Assigned(RttiType) then
      Exit;

    for I := 0 to Json.Count - 1 do
    begin
      PropStr := Json.Names[I];
      JsonVal := Json.Items[I];
      Prop := RttiType.GetProperty(PropStr);
      if JsonVal.IsNull then
      begin
        if Assigned(Prop) and (not Prop.IsClassProperty) and Prop.IsWritable then
        begin
          if (Prop.PropertyType.TypeKind = tkVariant) and Assigned(Prop.Handle) then
            SetVariantProp(Obj, PPropInfo(Prop.Handle), Null)
          else if Prop.PropertyType.TypeKind = tkClass then
          begin
            ObjRef := Prop.GetValue(Obj).AsObject;
            if Assigned(ObjRef) and
               not (ObjRef is TComponent) and
               not (ObjRef is TStrings) and
               not (ObjRef is TCollection) and
               not (ObjRef is TObjectList) and
               not (ObjRef is TList) then
            begin
              LNilObj := nil;
              TValue.Make(@LNilObj, Prop.PropertyType.Handle, LPropVal);
              Prop.SetValue(Obj, LPropVal);
              ObjRef.Free;
            end;
          end;
        end;
        Continue;
      end;

      if Assigned(Prop) and (not Prop.IsClassProperty) then
      begin
        if Prop.PropertyType.TypeKind = tkClass then
        begin
          Val := Prop.GetValue(Obj);
          ObjRef := Val.AsObject;
          if (not Assigned(ObjRef)) and (JsonVal is TJSONObject) then
            ObjRef := InstantiateClassProperty(Ctx, RttiType, Prop, Obj, AOwner);
          if Assigned(ObjRef) then
          begin
            if JsonVal is TJSONObject then
              InternalJsonToObj(TJSONObject(JsonVal), ObjRef, Obj)
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
                     (Prop.PropertyType.Handle = TypeInfo(TDate)) or
                     (Prop.PropertyType.Handle = TypeInfo(TTime)) then
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
                begin
                  if not (JsonVal is TJSONObject) and not (JsonVal is TJSONArray) then
                    Prop.SetValue(Obj, TValue.From<string>(JsonVal.AsString));
                end;
              tkBool:
                begin
                  if JsonVal is TJSONBoolean then
                    LOk := JsonVal.AsBoolean
                  else if JsonVal is TJSONNumber then
                    LOk := (JsonVal.AsInteger <> 0)
                  else
                    LOk := SameText(JsonVal.AsString, 'true') or (JsonVal.AsString = '1');
                  Prop.SetValue(Obj, TValue.FromOrdinal(Prop.PropertyType.Handle, Ord(LOk)));
                end;
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
                  EnumVal := -1;
                  if JsonVal is TJSONNumber then
                    EnumVal := JsonVal.AsInteger
                  else
                  begin
                    SVal := Trim(JsonVal.AsString);
                    if SVal <> '' then
                      EnumVal := GetEnumValue(Prop.PropertyType.Handle, SVal);
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
                end;
              tkVariant:
                if Assigned(Prop.Handle) then
                begin
                  if JsonVal.IsNull then
                    SetVariantProp(Obj, PPropInfo(Prop.Handle), Null)
                  else if JsonVal is TJSONNumber then
                  begin
                    if TJSONNumber(JsonVal).NumberType = ntFloat then
                      SetVariantProp(Obj, PPropInfo(Prop.Handle), Double(JsonVal.AsFloat))
                    else
                      SetVariantProp(Obj, PPropInfo(Prop.Handle), JsonVal.AsInt64);
                  end
                  else if JsonVal is TJSONBoolean then
                    SetVariantProp(Obj, PPropInfo(Prop.Handle), JsonVal.AsBoolean)
                  else if JsonVal is TJSONString then
                  begin
                    if JsonVal.AsString = '' then
                      SetVariantProp(Obj, PPropInfo(Prop.Handle), Null)
                    else
                      SetVariantProp(Obj, PPropInfo(Prop.Handle), JsonVal.AsString);
                  end;
                end;
            else
              ;
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
  LPFXRaw: RawByteString;
begin
  Result := '';
  if not Assigned(O) then
    Exit;
  LCertJson := O.Find('Certificados');
  if Assigned(LCertJson) and (LCertJson is TJSONObject) then
  begin
    LCertObj := TJSONObject(LCertJson);
    LPFXRaw := LCertObj.Get('DadosPFX', '');
    if LPFXRaw = '' then
      LPFXRaw := LCertObj.Get('DadosPFXBase64', '');
    if LPFXRaw <> '' then
    begin
      if LPFXRaw[1] = #$30 then
        Result := LPFXRaw
      else
        Result := synacode.DecodeBase64(Trim(LPFXRaw));
    end;
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
  else if VarIsOrdinal(V) then
    Result := TJSONInt64Number.Create(Int64(V))
  else if VarIsNumeric(V) then
    Result := TJSONFloatNumber.Create(Double(V))
  else
    Result := TJSONString.Create(EnsureValidUtf8(VarToStr(V)));
end;

end.
