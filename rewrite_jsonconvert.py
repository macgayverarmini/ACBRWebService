import re

with open("tools/jsonconvert.pas", "r") as f:
    content = f.read()

# We want to change the class definition
class_search = """  TJSONTools = class
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
  end;"""

class_replace = """  TJSONTools = class
  private
    class procedure PopulateObjectList(AListObj: TObject; AArray: TJSONArray; const Ctx: TRttiContext);
    class function InternalObjToJson(const Obj: TObject; Visited: TList; const Ctx: TRttiContext): TJSONData;
    class function ValueToJson(const Value: TValue; Visited: TList; const Ctx: TRttiContext): TJSONData;
    class procedure InternalJsonToObj(const Json: TJSONObject; const Obj: TObject; const Ctx: TRttiContext);
  public
    class function ObjToJsonString(const Obj: TObject): string;
    class function ObjToJson(const Obj: TObject): TJSONObject;

    class function SafeObjToJson(const Obj: TObject; const ErrorMsg: string = ''): TJSONObject;
    class function SafeObjToJsonString(const Obj: TObject; const ErrorMsg: string = ''): string;

    class procedure JsonStringToObj(const JsonString: string; const Obj: TObject);
    class procedure JsonToObj(const Json: TJSONObject; const Obj: TObject);
  end;"""

content = content.replace(class_search, class_replace)

# PopulateObjectList signature
pop_search = """class procedure TJSONTools.PopulateObjectList(AListObj: TObject; AArray: TJSONArray);
var
  I: Integer;
  LNewItem: TObject;
  Ctx: TRttiContext;
  RttiType: TRttiType;
  RttiMethod: TRttiMethod;
begin"""

pop_replace = """class procedure TJSONTools.PopulateObjectList(AListObj: TObject; AArray: TJSONArray; const Ctx: TRttiContext);
var
  I: Integer;
  LNewItem: TObject;
  RttiType: TRttiType;
  RttiMethod: TRttiMethod;
begin"""

content = content.replace(pop_search, pop_replace)

pop_search2 = """        LNewItem := TCollection(AListObj).Add;
        if Assigned(LNewItem) then
          JsonToObj(TJSONObject(AArray.Items[I]), LNewItem);"""

pop_replace2 = """        LNewItem := TCollection(AListObj).Add;
        if Assigned(LNewItem) then
          InternalJsonToObj(TJSONObject(AArray.Items[I]), LNewItem, Ctx);"""

content = content.replace(pop_search2, pop_replace2)

pop_search3 = """  Ctx := TRttiContext.Create(False);
  try
    RttiType := Ctx.GetType(AListObj.ClassType);
    if not Assigned(RttiType) then Exit;"""

pop_replace3 = """  // ⚡ Bolt optimization: TRttiContext passed directly to avoid O(N) re-creation overhead
  RttiType := Ctx.GetType(AListObj.ClassType);
  if not Assigned(RttiType) then Exit;"""

content = content.replace(pop_search3, pop_replace3)

pop_search4 = """        if AArray.Items[I] is TJSONObject then
        begin
          LNewItem := RttiMethod.Invoke(AListObj, []).AsObject;
          if Assigned(LNewItem) then
            JsonToObj(TJSONObject(AArray.Items[I]), LNewItem);
        end;
      end;
    end;
  finally
    Ctx.Free;
  end;
end;"""

pop_replace4 = """        if AArray.Items[I] is TJSONObject then
        begin
          LNewItem := RttiMethod.Invoke(AListObj, []).AsObject;
          if Assigned(LNewItem) then
            InternalJsonToObj(TJSONObject(AArray.Items[I]), LNewItem, Ctx);
        end;
      end;
    end;
end;"""

content = content.replace(pop_search4, pop_replace4)

# ValueToJson
v2j_search = """class function TJSONTools.ValueToJson(const Value: TValue; Visited: TList): TJSONData;"""
v2j_replace = """class function TJSONTools.ValueToJson(const Value: TValue; Visited: TList; const Ctx: TRttiContext): TJSONData;"""
content = content.replace(v2j_search, v2j_replace)

v2j_search2 = """      begin
        Obj := Value.AsObject;
        Result := InternalObjToJson(Obj, Visited);
      end;"""

v2j_replace2 = """      begin
        Obj := Value.AsObject;
        Result := InternalObjToJson(Obj, Visited, Ctx);
      end;"""
content = content.replace(v2j_search2, v2j_replace2)

# InternalObjToJson
io2j_search = """class function TJSONTools.InternalObjToJson(const Obj: TObject; Visited: TList): TJSONData;
var
  Ctx: TRttiContext;
  RttiType: TRttiType;"""

io2j_replace = """class function TJSONTools.InternalObjToJson(const Obj: TObject; Visited: TList; const Ctx: TRttiContext): TJSONData;
var
  RttiType: TRttiType;"""
content = content.replace(io2j_search, io2j_replace)

io2j_search2 = """    if Obj is TCollection then
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
    end;"""

io2j_replace2 = """    if Obj is TCollection then
    begin
      ArrJson := TJSONArray.Create;
      for i := 0 to TCollection(Obj).Count - 1 do
      begin
        ArrJson.Add(InternalObjToJson(TCollection(Obj).Items[i], Visited, Ctx));
      end;
      Exit(ArrJson);
    end;

    if Obj is TObjectList then
    begin
      ArrJson := TJSONArray.Create;
      for i := 0 to TObjectList(Obj).Count - 1 do
      begin
        ArrJson.Add(InternalObjToJson(TObjectList(Obj).Items[i], Visited, Ctx));
      end;
      Exit(ArrJson);
    end;

    if Obj is TList then
    begin
      ArrJson := TJSONArray.Create;
      for i := 0 to TList(Obj).Count - 1 do
      begin
        ItemObj := TObject(TList(Obj).Items[i]);
        ArrJson.Add(InternalObjToJson(ItemObj, Visited, Ctx));
      end;
      Exit(ArrJson);
    end;"""
content = content.replace(io2j_search2, io2j_replace2)


io2j_search3 = """    ObjJson := TJSONObject.Create;

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
    end;"""

io2j_replace3 = """    ObjJson := TJSONObject.Create;

    // ⚡ Bolt optimization: reuse TRttiContext passed via Ctx instead of creating a new one per iteration
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
            ObjJson.Add(Prop.Name, ValueToJson(Val, Visited, Ctx));
          except
          end;
        end;
      end;
    end;"""
content = content.replace(io2j_search3, io2j_replace3)


# ObjToJson
o2j_search = """class function TJSONTools.ObjToJson(const Obj: TObject): TJSONObject;
var
  Visited: TList;
  Data: TJSONData;
begin
  if Obj = nil then
    Exit(nil);

  Visited := TList.Create;
  try
    Data := InternalObjToJson(Obj, Visited);"""

o2j_replace = """class function TJSONTools.ObjToJson(const Obj: TObject): TJSONObject;
var
  Visited: TList;
  Data: TJSONData;
  Ctx: TRttiContext;
begin
  if Obj = nil then
    Exit(nil);

  Visited := TList.Create;
  Ctx := TRttiContext.Create(False);
  try
    Data := InternalObjToJson(Obj, Visited, Ctx);"""
content = content.replace(o2j_search, o2j_replace)


o2j_search2 = """      Result := TJSONObject.Create;
      Data.Free;
    end;
  finally
    Visited.Free;
  end;
end;"""

o2j_replace2 = """      Result := TJSONObject.Create;
      Data.Free;
    end;
  finally
    Ctx.Free;
    Visited.Free;
  end;
end;"""
content = content.replace(o2j_search2, o2j_replace2)

# JsonToObj -> rename to InternalJsonToObj and create public JsonToObj
j2o_search = """class procedure TJSONTools.JsonToObj(const Json: TJSONObject; const Obj: TObject);
var
  Ctx: TRttiContext;
  RttiType: TRttiType;"""

j2o_replace = """class procedure TJSONTools.JsonToObj(const Json: TJSONObject; const Obj: TObject);
var
  Ctx: TRttiContext;
begin
  if (Json = nil) or (Obj = nil) then Exit;
  Ctx := TRttiContext.Create(False);
  try
    InternalJsonToObj(Json, Obj, Ctx);
  finally
    Ctx.Free;
  end;
end;

class procedure TJSONTools.InternalJsonToObj(const Json: TJSONObject; const Obj: TObject; const Ctx: TRttiContext);
var
  RttiType: TRttiType;"""
content = content.replace(j2o_search, j2o_replace)

j2o_search2 = """  if (Json = nil) or (Obj = nil) then Exit;

  Ctx := TRttiContext.Create(False);
  try
    RttiType := Ctx.GetType(Obj.ClassType);"""

j2o_replace2 = """  // ⚡ Bolt optimization: rely on injected TRttiContext
  RttiType := Ctx.GetType(Obj.ClassType);"""
content = content.replace(j2o_search2, j2o_replace2)

j2o_search3 = """          if Assigned(ObjRef) then
          begin
            if JsonVal is TJSONObject then
              JsonToObj(TJSONObject(JsonVal), ObjRef)
            else if JsonVal is TJSONArray then
              PopulateObjectList(ObjRef, TJSONArray(JsonVal));
          end;"""

j2o_replace3 = """          if Assigned(ObjRef) then
          begin
            if JsonVal is TJSONObject then
              InternalJsonToObj(TJSONObject(JsonVal), ObjRef, Ctx)
            else if JsonVal is TJSONArray then
              PopulateObjectList(ObjRef, TJSONArray(JsonVal), Ctx);
          end;"""
content = content.replace(j2o_search3, j2o_replace3)

j2o_search4 = """        end;
      end;
    end;
  finally
    Ctx.Free;
  end;
end;"""

j2o_replace4 = """        end;
      end;
    end;
end;"""
content = content.replace(j2o_search4, j2o_replace4)

with open("tools/jsonconvert.pas", "w") as f:
    f.write(content)
