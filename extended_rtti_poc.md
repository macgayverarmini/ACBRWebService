# FPC 3.3.1 Extended RTTI — Prova de Conceito

> **Data**: 2026-04-23  
> **Ambiente**: FPC 3.3.1 trunk (commit `g399bf4a0cb`), Windows x86_64  
> **Projeto**: ACBRWebService (`c:\NFMonitor\src`)

## Problema Original

O `TJSONStreamer` do `fpjsonrtti` usa `TPropInfoList` (TypInfo antigo) que **só enxerga propriedades `published`**. As classes ACBr (TNFe, TCTe, etc.) declaram a maioria das propriedades como `public`, fazendo com que a serialização retorne `{}`.

Solução anterior: Script Python (`script_altera_acbr.py`) que hackeia 47 arquivos-fonte da ACBr, movendo propriedades para `published` e injetando `{$M+}`.

## Descobertas no Fonte do FPC

### Arquivo: `C:\fpcupdeluxe\fpcsrc\packages\rtl-objpas\src\inc\rtti.pp`

```pascal
// Linha 66-72: Controle global de visibilidade
Const
  DefaultUsePublishedOnly = Not TObject.SystemHasExtendedRTTI;  // dotted units
  DefaultUsePublishedOnly = True;                                // non-dotted (padrão)

Var
  GlobalUsePublishedOnly : Boolean = DefaultUsePublishedOnly;
```

```pascal
// Linha 338-339: Construtor com controle explícito
class function Create: TRttiContext; static;                    // usa GlobalUsePublishedOnly
class function Create(aUsePublishedOnly : Boolean): TRttiContext; static;  // controle direto
```

```pascal
// Linha 6752-6755: Resolução condicional de propriedades
if fUsePublishedOnly then
  ResolveClassicDeclaredProperties    // ← só published (TypInfo legado)
else
  ResolveExtendedDeclaredProperties;  // ← TODAS as propriedades (Extended RTTI)
```

### Arquivo: `C:\fpcupdeluxe\fpcsrc\packages\fcl-json\src\fpjsonrtti.pp`

```pascal
// Linha 863: TJSONStreamer.ObjectToJSON usa TypInfo (só published)
PIL := TPropInfoList.Create(AObject, tkProperties);  // ← LIMITAÇÃO
```

### Pré-requisito: `-dENABLE_DELPHI_RTTI`

O Extended RTTI precisa ser habilitado na compilação do FPC com a flag `-dENABLE_DELPHI_RTTI`. No fpcupdeluxe, isso é feito via:

```ini
# C:\fpcupdeluxe\fpcupdeluxe.ini
EnableRTTI=1
```

**Nosso FPC JÁ está compilado com essa flag.**

## Teste de Prova de Conceito

### Código-fonte

```pascal
program test_rtti;
{$mode objfpc}{$H+}
uses SysUtils, Classes, RTTI, TypInfo;

type
  // Classe SEM {$M+}, propriedades PUBLIC (simula ACBr original)
  TMyClass = class(TObject)
  private
    FName: String;
    FAge: Integer;
    FActive: Boolean;
  public
    property Name: String read FName write FName;
    property Age: Integer read FAge write FAge;
    property Active: Boolean read FActive write FActive;
  end;

var
  Ctx: TRttiContext;
  RttiType: TRttiType;
  Props: TRttiPropertyArray;
  Obj: TMyClass;
  i: Integer;
begin
  // Test 1: Contexto padrão (UsePublishedOnly=True)
  Ctx := TRttiContext.Create;
  RttiType := Ctx.GetType(TMyClass);
  Props := RttiType.GetProperties;
  WriteLn('Default: ', Length(Props), ' properties');  // → 0

  // Test 2: Contexto Extended (UsePublishedOnly=False)
  Ctx := TRttiContext.Create(False);
  RttiType := Ctx.GetType(TMyClass);
  Props := RttiType.GetProperties;
  WriteLn('Extended: ', Length(Props), ' properties');  // → 3

  // Test 3: GetValue funciona
  Obj := TMyClass.Create;
  Obj.Name := 'Test';
  Obj.Age := 42;
  for i := 0 to Length(Props) - 1 do
    WriteLn('  ', Props[i].Name, ' = ', Props[i].GetValue(Obj).ToString);
end.
```

### Resultados

```
=== Test 1: TRttiContext.Create (default) ===
TMyClass properties (default context): 0
  (none found)

=== Test 2: TRttiContext.Create(False) - Extended ===
TMyClass properties (extended): 3
  - Name Vis=2 (mvPublic)
  - Age Vis=2 (mvPublic)
  - Active Vis=2 (mvPublic)

=== Test 3: TMyClassM ($M+) extended ===
TMyClassM properties (extended): 3
  - Name Vis=2
  - Age Vis=2
  - NamePub Vis=3 (mvPublished)

=== Test 4: GetValue ===
  Name = Test
  Age = 42
  Active = True

=== Test 5: Fields ===
TMyClass fields (extended): 4
  - FName Vis=0 (mvPrivate)
  - FAge Vis=0 (mvPrivate)
  - FActive Vis=0 (mvPrivate)
  - _MonitorData Vis=0 (herdado de TObject)
```

## Conclusões

| Aspecto | Resultado |
|---------|-----------|
| `TRttiContext.Create(False)` vê `public` | ✅ Sim |
| Funciona SEM `{$M+}` | ✅ Sim |
| `GetValue` retorna valores reais | ✅ Sim |
| Campos `private` visíveis (Fields) | ✅ Sim |
| Visibilidade (`TMemberVisibility`) | `0=private, 1=protected, 2=public, 3=published` |

## Impacto

- **Script Python**: Pode ser **completamente eliminado**
- **Fontes ACBr**: Podem voltar ao **estado original** (sem hacks)
- **Serialização**: `ObjToJson` deve ser reescrito para usar `TRttiContext` ao invés de `TJSONStreamer`
- **Filtro recomendado**: Serializar apenas `Visibility in [mvPublic, mvPublished]`

## Referências

- Fonte RTTI: `C:\fpcupdeluxe\fpcsrc\packages\rtl-objpas\src\inc\rtti.pp` (8895 linhas)
- Fonte fpjsonrtti: `C:\fpcupdeluxe\fpcsrc\packages\fcl-json\src\fpjsonrtti.pp`
- Config fpcupdeluxe: `C:\fpcupdeluxe\fpcupdeluxe.ini` → `EnableRTTI=1`
- Exemplo FPC: `C:\fpcupdeluxe\fpcsrc\packages\fcl-web\examples\jsonrpc\rtti\`
- Teste PoC: `C:\Users\macga\.gemini\antigravity\brain\d17df8eb-d629-4b08-8996-d828da995ca2\scratch\test_rtti.pas`
