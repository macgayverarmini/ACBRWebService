# Rule for New Method Units

This rule guides the creation of new business logic units inside the `method/` directory.

## 1. File Naming Convention

Follow the pattern: `method.<group>.<feature>.pas`
-   `<group>`: The main feature area (e.g., `acbr`, `system`).
-   `<feature>`: The specific functionality (e.g., `nfe`, `utils`).

## 2. Unit Structure

Each unit should define a primary class that encapsulates the feature's logic.

```pascal
unit method.acbr.exemplo;

interface

uses
  Classes, SysUtils,
  fpjson, jsonparser, jsonconvert,
  // Project-specific resources
  resource.strings.global,
  resource.strings.msg,
  // Add required ACBr units here
  ACBrNFe;

type
  { TACBRBridgeExemplo }
  TACBRBridgeExemplo = class
  private
    // Declare private fields, like ACBr components
    // fACBr: TACBrComponent;
  public
    // Public methods that will be called by the routes
    function ExecuteSuaFuncao(const jParams: TJSONObject): TJSONObject;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TACBRBridgeExemplo }

constructor TACBRBridgeExemplo.Create;
begin
  inherited Create;
  // Instantiate ACBr components here
  // fACBr := TACBrComponent.Create(nil);
end;

destructor TACBRBridgeExemplo.Destroy;
begin
  // Free all created components
  // fACBr.Free;
  inherited Destroy;
end;

function TACBRBridgeExemplo.ExecuteSuaFuncao(const jParams: TJSONObject): TJSONObject;
var
  // Declare local variables, like helper objects
  // MeuObjeto: TMeuObjeto;
begin
  Result := TJSONObject.Create;
  // MeuObjeto := TMeuObjeto.Create;

  try
    // 1. Deserialize JSON input to a Pascal object if needed
    // TJSONTools.JsonToObj(jParams, MeuObjeto);

    // 2. Execute business logic using ACBr components
    // ...

    // 3. Serialize the successful result object to JSON
    Result := TJSONObject(TJSONTools.ObjToJson(/* seu objeto de retorno */));
    Result.Add(RSStatusField, RSStatusOK);

  except
    on E: Exception do
    begin
      // In case of error, create a standard error response
      Result.Clear;
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Error processing request: ' + E.Message);
    end;
  end;
  finally
    // 4. Free any locally created objects
    // MeuObjeto.Free;
  end;
end;

end.
```

## Key Principles

-   **Encapsulation:** All logic for a feature should be within its class.
-   **Error Handling:** Always use `try...except` to handle potential errors and return a consistent JSON error message.
-   **Memory Management:** Use `try...finally` to prevent memory leaks, ensuring all created objects are freed.
-   **JSON First:** Methods should communicate primarily via JSON objects.
