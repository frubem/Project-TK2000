program JoyComm;

uses
  Forms,
  uJoyComm in 'uJoyComm.pas' {frmJoyComm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmJoyComm, frmJoyComm);
  Application.Run;
end.
