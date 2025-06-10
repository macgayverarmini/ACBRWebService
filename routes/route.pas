unit route;

{$mode Delphi}

interface

uses
  Classes, SysUtils;

type

  { TRoute }

  TRoute = class
  public
     class procedure regRouter; virtual; abstract;
  end;


implementation

{ TRoute }


end.

