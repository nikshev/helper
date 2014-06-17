program HelperProject;

uses
  Forms,
  Helper in 'Helper.pas' {Form1},
  FindPathUnit in 'FindPathUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
