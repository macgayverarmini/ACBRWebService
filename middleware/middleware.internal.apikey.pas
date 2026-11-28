unit middleware.internal.apikey;

{$mode Delphi}{$H+}

interface

uses
  SysUtils,
  Horse,
  Horse.Commons,
  Horse.Exception.Interrupted;

function ConstantTimeEquals(const AProvided, AExpected: RawByteString): Boolean;
function IsHealthcheckExemptRequest(const AMethod: TMethodType; const APathInfo: string): Boolean;
function ShouldFailClosedWhenApiKeyMissing(
  const AExpectedKey, ARuntimeEnv, ARequireApiKey, AAllowUnauthenticatedDev: string
): Boolean;
procedure InternalApiKeyMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

implementation

function ConstantTimeEquals(const AProvided, AExpected: RawByteString): Boolean;
var
  LLenProvided, LLenExpected, I: SizeInt;
  LDiff: Cardinal;
  LBProvided: Byte;
begin
  LLenProvided := Length(AProvided);
  LLenExpected := Length(AExpected);
  if LLenExpected = 0 then
    Exit(False);

  LDiff := Cardinal(LLenProvided xor LLenExpected);
  for I := 1 to LLenExpected do
  begin
    if I <= LLenProvided then
      LBProvided := Byte(AProvided[I])
    else
      LBProvided := 0;
    LDiff := LDiff or Cardinal(LBProvided xor Byte(AExpected[I]));
  end;

  Result := (LDiff = 0);
end;

function NormalizeRequestPath(const APathInfo: string): string;
var
  LPath: string;
begin
  LPath := LowerCase(Trim(APathInfo));
  if LPath = '' then
    Exit('/');
  if LPath[1] <> '/' then
    LPath := '/' + LPath;
  while (Length(LPath) > 1) and (LPath[Length(LPath)] = '/') do
    Delete(LPath, Length(LPath), 1);
  Result := LPath;
end;

function IsHealthcheckExemptRequest(const AMethod: TMethodType; const APathInfo: string): Boolean;
var
  LNormalized: string;
begin
  if not (AMethod in [mtGet, mtHead]) then
    Exit(False);
  LNormalized := NormalizeRequestPath(APathInfo);
  Result := (LNormalized = '/status') or (LNormalized = '/health');
end;

function ShouldFailClosedWhenApiKeyMissing(
  const AExpectedKey, ARuntimeEnv, ARequireApiKey, AAllowUnauthenticatedDev: string
): Boolean;
begin
  if Trim(AExpectedKey) <> '' then
    Exit(False);

  Result :=
    SameText(Trim(ARuntimeEnv), 'production') or
    SameText(Trim(ARuntimeEnv), 'prod') or
    SameText(Trim(ARequireApiKey), 'true') or
    SameText(Trim(ARequireApiKey), '1') or
    SameText(Trim(AAllowUnauthenticatedDev), 'false') or
    SameText(Trim(AAllowUnauthenticatedDev), '0');
end;

procedure InternalApiKeyMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LExpectedKey, LProvidedKey, LRuntimeEnv, LRequireApiKey, LAllowUnauthDev: string;
begin
  if IsHealthcheckExemptRequest(Req.MethodType, Req.PathInfo) then
  begin
    Next();
    Exit;
  end;

  LExpectedKey := Trim(GetEnvironmentVariable('ACBR_INTERNAL_API_KEY'));
  if LExpectedKey = '' then
  begin
    LRuntimeEnv := Trim(GetEnvironmentVariable('ACBR_ENV'));
    if LRuntimeEnv = '' then
      LRuntimeEnv := Trim(GetEnvironmentVariable('APP_ENV'));
    if LRuntimeEnv = '' then
      LRuntimeEnv := Trim(GetEnvironmentVariable('NODE_ENV'));
    LRequireApiKey := Trim(GetEnvironmentVariable('ACBR_REQUIRE_API_KEY'));
    LAllowUnauthDev := Trim(GetEnvironmentVariable('ACBR_ALLOW_UNAUTHENTICATED_DEV'));
    if ShouldFailClosedWhenApiKeyMissing(LExpectedKey, LRuntimeEnv, LRequireApiKey, LAllowUnauthDev) then
    begin
      Res.Status(THTTPStatus.ServiceUnavailable)
         .ContentType(TMimeTypes.ApplicationJSON.ToString)
         .Send('{"status":"erro","error":"ServiceUnavailable: ACBR_INTERNAL_API_KEY is required"}');
      raise EHorseCallbackInterrupted.Create;
    end;
    Next();
    Exit;
  end;

  LProvidedKey := Req.Headers['X-Internal-API-Key'];
  if (LProvidedKey = '') and Assigned(Req.RawWebRequest) then
    LProvidedKey := Trim(Req.RawWebRequest.CustomHeaders.Values['X-Internal-API-Key']);

  if not ConstantTimeEquals(RawByteString(LProvidedKey), RawByteString(LExpectedKey)) then
  begin
    Res.Status(THTTPStatus.Unauthorized)
       .ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send('{"status":"erro","error":"Unauthorized"}');
    raise EHorseCallbackInterrupted.Create;
  end;

  Next();
end;

end.
