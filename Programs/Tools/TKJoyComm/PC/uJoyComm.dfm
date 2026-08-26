object frmJoyComm: TfrmJoyComm
  Left = 114
  Top = 133
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'JoyComm para TK2000'
  ClientHeight = 248
  ClientWidth = 417
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 4
    Top = 80
    Width = 106
    Height = 13
    Caption = 'Quantidade de Tapes:'
  end
  object Label2: TLabel
    Left = 4
    Top = 8
    Width = 107
    Height = 13
    Caption = 'Byte Recebido/enviar:'
  end
  object sb: TStatusBar
    Left = 0
    Top = 229
    Width = 417
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object edtQteTape: TEdit
    Left = 116
    Top = 76
    Width = 73
    Height = 21
    TabOrder = 1
    Text = '1'
  end
  object btnCancelar: TButton
    Left = 300
    Top = 72
    Width = 93
    Height = 25
    Caption = 'Cancelar'
    TabOrder = 2
    OnClick = btnCancelarClick
  end
  object edtByte: TEdit
    Left = 116
    Top = 4
    Width = 73
    Height = 21
    TabOrder = 3
    Text = '0'
  end
  object btnReceberByte: TButton
    Left = 200
    Top = 4
    Width = 93
    Height = 25
    Caption = 'Receber Byte'
    TabOrder = 4
    OnClick = btnReceberByteClick
  end
  object btnEnviarByte: TButton
    Left = 300
    Top = 4
    Width = 93
    Height = 25
    Caption = 'Enviar Byte'
    TabOrder = 5
    OnClick = btnEnviarByteClick
  end
  object btnEnviarArquivo: TButton
    Left = 300
    Top = 36
    Width = 93
    Height = 25
    Caption = 'Enviar Arquivo'
    TabOrder = 6
    OnClick = btnEnviarArquivoClick
  end
  object btnReceberArquivo: TButton
    Left = 200
    Top = 36
    Width = 93
    Height = 25
    Caption = 'Receber Arquivo'
    TabOrder = 7
    OnClick = btnReceberArquivoClick
  end
  object btnReceberTape: TButton
    Left = 200
    Top = 72
    Width = 93
    Height = 25
    Caption = 'Receber Tape'
    TabOrder = 8
    OnClick = btnReceberTapeClick
  end
  object memDebug: TMemo
    Left = 8
    Top = 112
    Width = 405
    Height = 113
    ScrollBars = ssVertical
    TabOrder = 9
  end
  object od: TOpenDialog
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 92
    Top = 36
  end
  object sd: TSaveDialog
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 52
    Top = 36
  end
  object tmrTimeOut: TTimer
    Enabled = False
    Interval = 10000
    OnTimer = tmrTimeOutTimer
    Left = 12
    Top = 36
  end
end
