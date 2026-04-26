unit jsonconvert;

{$mode Delphi}{$H+}
{$M+}

interface

uses
  fpjson,
  Horse.HandleException, jsonparser,
  pcnConversaoNFe, pcnConversao,
  Classes, SysUtils, fpjsonrtti,
  resource.strings.global, TypInfo, RTTI;

type
  { TJSONTools }

  TJSONTools = class
  private
    class procedure HandleRestoreProperty(Sender: TObject; AObject: TObject;
      Info: PPropInfo; AValue: TJSONData; var Handled: Boolean);
    class procedure PopulateObjectList(AObject: TObject; const APropName: string;
      AArray: TJSONArray);
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

class procedure TJSONTools.PopulateObjectList(AObject: TObject;
  const APropName: string; AArray: TJSONArray);
var
  LPropInfo: PPropInfo;
  LListObj: TObject;
  LMethod: TMethod;
  LNewFunc: TNewItemFunc;
  LNewItem: TObject;
  I: Integer;
begin
  LPropInfo := GetPropInfo(AObject, APropName);
  if Assigned(LPropInfo) and (LPropInfo^.PropType^.Kind = tkClass) then
  begin
    LListObj := GetObjectProp(AObject, LPropInfo);
    if Assigned(LListObj) then
    begin
      LMethod.Code := LListObj.MethodAddress('New');
      LMethod.Data := LListObj;

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
  end;
end;

class procedure TJSONTools.HandleRestoreProperty(Sender: TObject;
  AObject: TObject; Info: PPropInfo; AValue: TJSONData; var Handled: Boolean);
begin
  if (AValue is TJSONArray) and (Info^.PropType^.Kind = tkClass) then
  begin
    PopulateObjectList(AObject, Info^.Name, TJSONArray(AValue));
    Handled := True;
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
        // FPC does not easily tell if it's TDateTime from TValue.Kind alone without TypeInfo check
        // But let's assume if it's tkFloat, it's a float. 
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
        // Basic set to string representation
        Result := TJSONString.Create(SetToString(Value.TypeInfo, Value.AsOrdinal, True));
      end;
    tkClass:
      begin
        Obj := Value.AsObject;
        Result := InternalObjToJson(Obj, Visited);
      end;
  else
    // Fallback for unknown types
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

  // Check for recursion
  if Visited.IndexOf(Obj) >= 0 then
    Exit(TJSONNull.Create); // Or maybe some indicator of cyclic ref

  Visited.Add(Obj);
  try
    // Handle special classes
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

    // TObjectList (Contnrs) / TACBrObjectList handling
    if Obj is TObjectList then
    begin
      ArrJson := TJSONArray.Create;
      for i := 0 to TObjectList(Obj).Count - 1 do
      begin
        ArrJson.Add(InternalObjToJson(TObjectList(Obj).Items[i], Visited));
      end;
      Exit(ArrJson);
    end;
    
    // Also TList (just in case TACBrObjectList inherits from it differently in some versions)
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

    // Standard object
    ObjJson := TJSONObject.Create;
    
    Ctx := TRttiContext.Create(False); // Use Extended RTTI to see all public properties
    try
      RttiType := Ctx.GetType(Obj.ClassType);
      if Assigned(RttiType) then
      begin
        Props := RttiType.GetProperties;
        for i := 0 to Length(Props) - 1 do
        begin
          Prop := Props[i];
          // Only process readable public/published properties
          if Prop.IsReadable and (Prop.Visibility in [mvPublic, mvPublished]) then
          begin
            try
              Val := Prop.GetValue(Obj);
              ObjJson.Add(Prop.Name, ValueToJson(Val, Visited));
            except
              // Ignore properties that fail to evaluate (e.g. some indexed properties if caught here)
            end;
          end;
        end;
      end;
    finally
      Ctx.Free;
    end;

    Result := ObjJson;

  finally
    // Visited.Remove(Obj); // Do not remove to prevent any traversal to already visited nodes
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
      Result := TJSONObject.Create; // Fallback
      Data.Free;
    end;
  finally
    Visited.Free;
  end;
end;

class procedure TJSONTools.JsonStringToObj(const JsonString: string; const Obj: TObject);
var
  Streamer: TJSONDeStreamer;
begin
  Streamer := TJSONDeStreamer.Create(nil);
  try
    Streamer.Options := [jdoIgnorePropertyErrors];
    Streamer.OnRestoreProperty := HandleRestoreProperty;
    Streamer.JSONToObject(JsonString, Obj);
  finally
    FreeAndNil(Streamer);
  end;
end;

class procedure TJSONTools.JsonToObj(const Json: TJSONObject; const Obj: TObject);
var
  Streamer: TJSONDeStreamer;
begin
  Streamer := TJSONDeStreamer.Create(nil);
  try
    Streamer.Options := [jdoIgnorePropertyErrors];
    Streamer.OnRestoreProperty := HandleRestoreProperty;
    Streamer.JSONToObject(Json, Obj);
  finally
    FreeAndNil(Streamer);
  end;
end;

end.
