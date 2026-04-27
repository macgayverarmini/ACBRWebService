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
    class procedure PopulateObjectList(AListObj: TObject; AArray: TJSONArray);
    class function InternalObjToJson(const Obj: TObject; Visited: TList): TJSONData;
    class function ValueToJson(const Value: TValue; Visited: TList): TJSONData;
  public
    class function ObjToJsonString(const Obj: TObject): string;
    class function ObjToJson(const Obj: TObject): TJSONObject;

    class function SafeObjToJson(const Obj: TObject; const ErrorMsg: string = ''): TJSONObject;
    class function SafeObjToJsonString(const Obj: TObject; const ErrorMsg: string = ''): string;

    class procedure JsonStringToObj(const JsonString: string; const Obj: TObject);
    class procedure JsonToObj(const Json: TJSONObject; const Obj: TObject);
  end;

implementation

uses
  Contnrs, DateUtils;

type
  TNewItemFunc = function: TObject of object;

{ TJSONTools }

class procedure TJSONTools.PopulateObjectList(AListObj: TObject; AArray: TJSONArray);
var
  LMethod: TMethod;
  LNewFunc: TNewItemFunc;
  LNewItem: TObject;
  I: Integer;
begin
  if not Assigned(AListObj) then Exit;

  if AListObj is TStrings then
  begin
    TStrings(AListObj).Clear;
    for I := 0 to AArray.Count - 1 do
      TStrings(AListObj).Add(AArray.Items[I].AsString);
    Exit;
  end;

  LMethod.Code := AListObj.MethodAddress('New');
  LMethod.Data := AListObj;

  if Assigned(LMethod.Code) then
  begin
    LNewFunc := TNewItemFunc(LMethod);
    
    for I := 0 to AArray.Count - 1 do
    begin
      if AArray.Items[I] is TJSONObject then
      begin
        LNewItem := LNewFunc();
        if Assigned(LNewItem) then
        begin
          JsonToObj(TJSONObject(AArray.Items[I]), LNewItem);
        end;
      end;
    end;
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
              Val := Prop.GetValue(Obj);
              ObjJson.Add(Prop.Name, ValueToJson(Val, Visited));
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
var
  Ctx: TRttiContext;
  RttiType: TRttiType;
  Prop: TRttiProperty;
  i: Integer;
  Val: TValue;
  JsonVal: TJSONData;
  PropStr: string;
  ObjRef: TObject;
  EnumVal: Integer;
  LDate: TDateTime;
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
      if JsonVal.IsNull then Continue;

      Prop := RttiType.GetProperty(PropStr);
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
              PopulateObjectList(ObjRef, TJSONArray(JsonVal));
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
                  if JsonVal is TJSONString then
                  begin
                    if TryISO8601ToDate(JsonVal.AsString, LDate) then
                      Prop.SetValue(Obj, TValue.From<Extended>(LDate))
                    else
                      Prop.SetValue(Obj, TValue.From<Extended>(StrToDateTimeDef(JsonVal.AsString, 0)));
                  end
                  else if JsonVal is TJSONNumber then
                    Prop.SetValue(Obj, TValue.From<Extended>(JsonVal.AsFloat));
                end;
              tkString, tkUString, tkAString, tkWString, tkChar, tkWChar, tkUChar:
                Prop.SetValue(Obj, TValue.From<string>(JsonVal.AsString));
              tkEnumeration:
                if Prop.PropertyType.Handle = TypeInfo(Boolean) then
                  Prop.SetValue(Obj, TValue.From<Boolean>(JsonVal.AsBoolean))
                else
                begin
                  EnumVal := GetEnumValue(Prop.PropertyType.Handle, JsonVal.AsString);
                  if EnumVal >= 0 then
                    Prop.SetValue(Obj, TValue.FromOrdinal(Prop.PropertyType.Handle, EnumVal));
                end;
              tkSet:
                begin
                  EnumVal := StringToSet(Prop.PropertyType.Handle, JsonVal.AsString);
                  Prop.SetValue(Obj, TValue.FromOrdinal(Prop.PropertyType.Handle, EnumVal));
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

end.
