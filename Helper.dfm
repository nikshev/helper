object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Helper'
  ClientHeight = 364
  ClientWidth = 479
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 466
    Height = 65
    Caption = #1048#1089#1093#1086#1076#1085#1099#1077' '#1076#1072#1085#1085#1099#1077
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    object Edit1: TEdit
      Left = 16
      Top = 24
      Width = 385
      Height = 24
      ReadOnly = True
      TabOrder = 0
      Text = 'F:\Eugene\NewWork\Razrabotka\'#1059#1095#1077#1073#1072'\N6\01032012\EURUSD15.csv'
    end
    object Button1: TButton
      Left = 407
      Top = 24
      Width = 41
      Height = 25
      Caption = '...'
      TabOrder = 1
      OnClick = Button1Click
    end
  end
  object GroupBox2: TGroupBox
    Left = 2
    Top = 79
    Width = 469
    Height = 241
    Caption = #1056#1077#1079#1091#1083#1100#1090#1072#1090#1099
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    object Memo1: TMemo
      Left = 16
      Top = 32
      Width = 432
      Height = 185
      TabOrder = 0
    end
  end
  object Button5: TButton
    Left = 192
    Top = 326
    Width = 75
    Height = 25
    Caption = #1057#1058#1040#1056#1058
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    OnClick = Button5Click
  end
  object OpenDialog1: TOpenDialog
    Filter = '*.csv|*.csv|*.*|*.*'
    Left = 24
    Top = 32
  end
  object OpenDialog2: TOpenDialog
    Filter = '*.csv|*.csv|*.*|*.*'
    Left = 16
    Top = 24
  end
  object OpenDialog3: TOpenDialog
    Filter = '*.csv|*.csv|*.*|*.*'
    Left = 48
    Top = 24
  end
  object OpenDialog4: TOpenDialog
    Filter = '*.csv|*.csv|*.*|*.*'
    Left = 88
    Top = 32
  end
  object ADOConnection1: TADOConnection
    ConnectionString = 
      'Provider=Microsoft.Jet.OLEDB.4.0;Data Source=F:\Eugene\NewWork\R' +
      'azrabotka\'#1059#1095#1077#1073#1072'\N6\01032012\db2.mdb;Persist Security Info=False'
    LoginPrompt = False
    Mode = cmShareDenyNone
    Provider = 'Microsoft.Jet.OLEDB.4.0'
    Left = 80
    Top = 24
  end
  object ADOQuery1: TADOQuery
    Connection = ADOConnection1
    Parameters = <>
    Left = 120
    Top = 24
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 60
    OnTimer = Timer1Timer
    Left = 96
    Top = 72
  end
end
