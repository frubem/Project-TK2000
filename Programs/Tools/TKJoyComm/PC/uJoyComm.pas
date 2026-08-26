unit uJoyComm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls;

type
  TfrmJoyComm = class(TForm)
    sb: TStatusBar;
    Label1: TLabel;
    edtQteTape: TEdit;
    od: TOpenDialog;
    sd: TSaveDialog;
    btnCancelar: TButton;
    Label2: TLabel;
    edtByte: TEdit;
    btnReceberByte: TButton;
    btnEnviarByte: TButton;
    tmrTimeOut: TTimer;
    btnEnviarArquivo: TButton;
    btnReceberArquivo: TButton;
    btnReceberTape: TButton;
    memDebug: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnEnviarByteClick(Sender: TObject);
    procedure btnReceberByteClick(Sender: TObject);
    procedure tmrTimeOutTimer(Sender: TObject);
    procedure btnEnviarArquivoClick(Sender: TObject);
    procedure btnReceberArquivoClick(Sender: TObject);
    procedure btnReceberTapeClick(Sender: TObject);
  private
    { Private declarations }
    EndInicial : Cardinal;
    procedure FazHandShaking;
    function RecebeByte : Byte;
    procedure EnviaByte(Valor : Byte);
  public
    { Public declarations }
    Cancelar : Boolean;
  end;

var
  frmJoyComm: TfrmJoyComm;

implementation

{$R *.dfm}

// ============================================================================
procedure WritePort(PortValue, DataValue:word);
begin
  DataValue := (DataValue*256)+DataValue;
   asm
     Mov ax,DataValue
     Mov dx,PortValue
     Out dx,ax
   end;
end;

// ============================================================================
function ReadPort(PortValue : Word) : Byte;
var
   ReadData : Word;
begin
   asm
     Mov dx,PortValue
     In ax,dx
     Mov ReadData,ax
   end;
  Result := Byte(ReadData);
end;

// ============================================================================
function LerKBOUT : Byte;
var
  B : Byte;
begin
  B := ReadPort(889) and $F8;
  B := (B xor 128) shr 3;
  Result := B;
end;

// ============================================================================
procedure TfrmJoyComm.FazHandShaking;
var
  B : Byte;
begin
  // handshake:
//  tmrTimeOut.Enabled := True;
  while TRUE do begin
    Application.ProcessMessages;
    if Cancelar then Exit;
    B := LerKBOUT;
    if B = $1F then Break;                // 00011111
  end; // while
  WritePort(888, $07);                    // 00000111
  while TRUE do begin
    Application.ProcessMessages;
    if Cancelar then Exit;
    B := LerKBOUT;
    if B = $00 then Break;                // 00000000
  end; // while
  WritePort(888, $00);                    // 00000000
//  tmrTimeOut.Enabled := False;
end;


// ============================================================================
function TfrmJoyComm.RecebeByte : Byte;
var
  I : Integer;
  B : Byte;
  R : Byte;
begin
  R := 0;
  B := 0;
  Result := 0;
  FazHandShaking();
  // Recebe Byte
  for I := 0 to 1 do begin
    while TRUE do begin
      Application.ProcessMessages;
      if Cancelar then Exit;
      B := LerKBOUT;
      if B = $10 then Break; // 00010000
    end; // while
    WritePort(888, $04);     // 00000100
    while TRUE do begin
      Application.ProcessMessages;
      if Cancelar then Exit;
      B := LerKBOUT;
      if (B and $10) = $00 then Break;  // 00010000 00000000
    end; // while
    R := (R shr 4) or ((B and $0F) shl 4);    // 00001111
    WritePort(888, $00);    // 00000000
  end; // for I
  Result := R;
end;

// ============================================================================
procedure TfrmJoyComm.EnviaByte(Valor : Byte);
var
  I : Integer;
  R : Byte;
  B : Byte;
begin
  FazHandShaking();
  // Envia Byte
  for I := 0 to 3 do begin
    while TRUE do begin
      Application.ProcessMessages;
      if Cancelar then Exit;
      B := LerKBOUT;
      if B = $10 then Break;                // 00010000
    end; // while
    R := Valor and $03;                     // 00000011
    Valor := Valor shr 2;
    WritePort(888, $04 or R);               // 000001D1D0
    while TRUE do begin
      Application.ProcessMessages;
      if Cancelar then Exit;
      B := LerKBOUT;
      if (B and $10) = $00 then Break;      // 00010000 00000000
    end; // while
    WritePort(888, $00);                    // 00000000
  end; // for I
end;

// ============================================================================
procedure TfrmJoyComm.FormCreate(Sender: TObject);
begin
  WritePort(888,0);
end;

// ============================================================================
procedure TfrmJoyComm.btnCancelarClick(Sender: TObject);
begin
  sb.SimpleText := 'Cancelado';
  Cancelar := True;
end;

// ============================================================================
procedure TfrmJoyComm.btnEnviarByteClick(Sender: TObject);
begin
  sb.SimpleText := 'Enviando Byte';
  Cancelar := False;
  EnviaByte(StrToInt(edtByte.Text));
end;

// ============================================================================
procedure TfrmJoyComm.btnReceberByteClick(Sender: TObject);
begin
  sb.SimpleText := 'Recebendo Byte';
  Cancelar := False;
  edtByte.Text := IntToStr(RecebeByte);
end;

// ============================================================================
procedure TfrmJoyComm.tmrTimeOutTimer(Sender: TObject);
begin
  sb.SimpleText := 'Cancelado';
  Cancelar := True;
  tmrTimeOut.Enabled := False;
end;

// ============================================================================
procedure TfrmJoyComm.btnEnviarArquivoClick(Sender: TObject);
var
  Arq     : File of Byte;
  Buffer  : PChar;
  Tamanho : Cardinal;
  Cont    : Cardinal;
begin
  EndInicial := StrToInt(InputBox('Enviar Arquivo', 'Endereço Inicial (decimal)', IntToStr(EndInicial)));
  if od.Execute then
  begin
    FileMode := 0; // ler
    AssignFile(Arq, od.FileName);
    Reset(Arq);
    Tamanho := FileSize(Arq);
    Buffer := AllocMem(Tamanho);
    BlockRead(Arq, Buffer^, Tamanho);
    CloseFile(Arq);
    sb.SimpleText := 'Enviando Arquivo';
    Cancelar := False;
    EnviaByte((Tamanho-1) and $FF);
    EnviaByte(((Tamanho-1) shr 8) and $FF);
    EnviaByte(EndInicial and $FF);
    EnviaByte((EndInicial shr 8) and $FF);
    for Cont := 0 to Tamanho-1 do
    begin
        EnviaByte(Byte(Buffer[Cont]));
    end;
    FreeMem(Buffer);
    sb.SimpleText := 'Arquivo enviado com sucesso';
  end;
end;

// ============================================================================
procedure TfrmJoyComm.btnReceberArquivoClick(Sender: TObject);
var
  Arq     : File of Byte;
  Buffer  : PChar;
  Tamanho : Cardinal;
  Cont    : Cardinal;
begin
  sb.SimpleText := 'Recebendo Arquivo';
  Cancelar := False;
  Tamanho := RecebeByte;
  Tamanho := Tamanho or (RecebeByte shl 8);
  Buffer := AllocMem(Tamanho+1);
  for Cont := 0 to Tamanho-1 do
  begin
    Buffer[Cont] := Char(RecebeByte);
  end;
  if sd.Execute then
  begin
    FileMode := 1; // gravar
    AssignFile(Arq, sd.FileName);
    Rewrite(Arq);
    BlockWrite(Arq, Buffer^, Tamanho);
    CloseFile(Arq);
    sb.SimpleText := 'Arquivo recebido com sucesso';
  end;
  FreeMem(Buffer);
end;

// ============================================================================
procedure TfrmJoyComm.btnReceberTapeClick(Sender: TObject);
var
  Arq     : File of Byte;
  Buffer  : PChar;
  Tamanho : Cardinal;
  Cont    : Cardinal;
  ContTap : Cardinal;
begin
  ContTap := StrToInt(edtQteTape.Text);
  sb.SimpleText := 'Recebendo '+edtQteTape.Text+' Arquivo(s)';
  Cancelar := False;
  EnviaByte(ContTap);
  Tamanho := RecebeByte;
  Tamanho := Tamanho or (RecebeByte shl 8);
  Buffer := AllocMem(Tamanho+1);
  for Cont := 0 to Tamanho-1 do
  begin
    Buffer[Cont] := Char(RecebeByte);
  end;
  if sd.Execute then
  begin
    FileMode := 1; // gravar
    AssignFile(Arq, sd.FileName);
    Rewrite(Arq);
    BlockWrite(Arq, Buffer^, Tamanho);
    CloseFile(Arq);
    sb.SimpleText := 'Arquivo recebido com sucesso';
  end;
  FreeMem(Buffer);
end;
// ============================================================================

end.
