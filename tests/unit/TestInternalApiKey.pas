unit TestInternalApiKey;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  Horse.Commons,
  middleware.internal.apikey;

type
  TTestInternalApiKey = class(TTestCase)
  published
    procedure TestConstantTimeEquals_ExactMatch;
    procedure TestConstantTimeEquals_DifferentValueSameLength;
    procedure TestConstantTimeEquals_DifferentLengthsAndEmpty;
    procedure TestHealthcheckExemption_OnlyExactStatusOrHealthGetHead;
    procedure TestShouldFailClosedWhenApiKeyMissing_ProductionAndRequireFlags;
  end;

implementation

procedure TTestInternalApiKey.TestConstantTimeEquals_ExactMatch;
begin
  AssertTrue(ConstantTimeEquals('acbr-internal-secret-2026', 'acbr-internal-secret-2026'));
end;

procedure TTestInternalApiKey.TestConstantTimeEquals_DifferentValueSameLength;
begin
  AssertFalse(ConstantTimeEquals('acbr-internal-secret-2025', 'acbr-internal-secret-2026'));
  AssertFalse(ConstantTimeEquals('Acbr-internal-secret-2026', 'acbr-internal-secret-2026'));
end;

procedure TTestInternalApiKey.TestConstantTimeEquals_DifferentLengthsAndEmpty;
begin
  AssertFalse(ConstantTimeEquals('', 'acbr-internal-secret-2026'));
  AssertFalse(ConstantTimeEquals('acbr-internal-secret-2026', ''));
  AssertFalse(ConstantTimeEquals('', ''));
  AssertFalse(ConstantTimeEquals('acbr-internal-secret-2026-extra', 'acbr-internal-secret-2026'));
  AssertFalse(ConstantTimeEquals('short', 'acbr-internal-secret-2026'));
end;

procedure TTestInternalApiKey.TestHealthcheckExemption_OnlyExactStatusOrHealthGetHead;
begin
  AssertTrue(IsHealthcheckExemptRequest(mtGet, '/status'));
  AssertTrue(IsHealthcheckExemptRequest(mtGet, '/health'));
  AssertTrue(IsHealthcheckExemptRequest(mtHead, '/health/'));
  AssertFalse(IsHealthcheckExemptRequest(mtPost, '/status'));
  AssertFalse(IsHealthcheckExemptRequest(mtPost, '/nfe/status'));
  AssertFalse(IsHealthcheckExemptRequest(mtGet, '/modelo/nfe/status'));
  AssertFalse(IsHealthcheckExemptRequest(mtGet, '/nfe/pdf/35260112345678000199550010000000011000000015'));
end;

procedure TTestInternalApiKey.TestShouldFailClosedWhenApiKeyMissing_ProductionAndRequireFlags;
begin
  AssertTrue(ShouldFailClosedWhenApiKeyMissing('', 'production', '', ''));
  AssertTrue(ShouldFailClosedWhenApiKeyMissing('', 'PRODUCTION', '', ''));
  AssertTrue(ShouldFailClosedWhenApiKeyMissing('', 'prod', '', ''));
  AssertTrue(ShouldFailClosedWhenApiKeyMissing('', 'development', 'true', ''));
  AssertTrue(ShouldFailClosedWhenApiKeyMissing('', '', '1', ''));
  AssertTrue(ShouldFailClosedWhenApiKeyMissing('', 'development', '', 'false'));
  AssertFalse(ShouldFailClosedWhenApiKeyMissing('', 'development', '', ''));
  AssertFalse(ShouldFailClosedWhenApiKeyMissing('acbr-internal-secret-2026', 'production', 'true', 'false'));
end;

initialization
  RegisterTest(TTestInternalApiKey);
end.
