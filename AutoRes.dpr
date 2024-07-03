program AutoRes;

{$R 'res.res' 'res.rc'}

uses
  Forms,
  uAutoRes in 'uAutoRes.pas' {frmAutoRes},
  uJson in 'uJson.pas',
  superobject,
  EncdDecd in 'EncdDecd.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  if RunFromCLI() then
    Exit;
  Application.CreateForm(TfrmAutoRes, frmAutoRes);
  Application.Run;
end.
