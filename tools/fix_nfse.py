import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix GET handlers
    get_pattern = r'''procedure (GetModelo\w+)\(Req: THorseRequest; Res: THorseResponse; Next: TNextProc\);
var
  Ac: TACBRModelosJSONNFSe;
begin
  Ac := TACBRModelosJSONNFSe\.Create\(RSEmptyString\);
  try
    Res\.Send<TJSONObject>\(AC\.(Model\w+)\);
  finally
    Ac\.Free;
  end;
end;'''
    
    def get_repl(m):
        return f'''procedure {m.group(1)}(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    LJson := AC.{m.group(2)};
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;'''

    content = re.sub(get_pattern, get_repl, content)

    # Fix POST handlers
    post_pattern = r'''procedure (Post\w+)\(Req: THorseRequest; Res: THorseResponse; Next: TNextProc\);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  O := GetJSON\(Req\.Body\) as TJSONObject;
  Ac := TACBRBridgeNFSe\.Create\(O\.Extract\(RSConfigField\)\.AsJSON\);
  try
    Res\.ContentType\(TMimeTypes\.ApplicationJSON\.ToString\)\.Send<TJSONObject>\(Ac\.(\w+)\(O\)\);
  finally
    O\.Free;
    Ac\.Free;
  end;
end;'''

    def post_repl(m):
        return f'''procedure {m.group(1)}(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    LJson := Ac.{m.group(2)}(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;'''

    content = re.sub(post_pattern, post_repl, content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_file(r'c:\NFMonitor\src\routes\route.acbr.nfse.pas')
