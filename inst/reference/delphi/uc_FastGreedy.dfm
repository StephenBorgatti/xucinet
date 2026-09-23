object FastGreedy: TFastGreedy
  Left = 0
  Top = 0
  Caption = ' FastGreedy'
  ClientHeight = 244
  ClientWidth = 736
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Group: TGroupBox
    Left = 22
    Top = 20
    Width = 601
    Height = 123
    Caption = 'Files'
    TabOrder = 0
    object SpeedButton1: TSpeedButton
      Left = 550
      Top = 33
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton1Click
    end
    object SpeedButton3: TSpeedButton
      Left = 550
      Top = 81
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton3Click
    end
    object InputNetFn: TLabeledEdit
      Left = 32
      Top = 34
      Width = 507
      Height = 21
      EditLabel.Width = 114
      EditLabel.Height = 13
      EditLabel.Caption = 'Input Network Dataset:'
      TabOrder = 0
      OnChange = InputNetFnChange
    end
    object OutputFn: TLabeledEdit
      Left = 30
      Top = 82
      Width = 509
      Height = 21
      EditLabel.Width = 122
      EditLabel.Height = 13
      EditLabel.Caption = 'Output Partition Dataset:'
      TabOrder = 1
    end
  end
  object OKBtn: TBitBtn
    Left = 642
    Top = 41
    Width = 73
    Height = 27
    Caption = '&OK'
    Kind = bkOK
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 1
    OnClick = OKBtnClick
    IsControl = True
  end
  object CancelBtn: TBitBtn
    Left = 642
    Top = 74
    Width = 73
    Height = 27
    Caption = '&Cancel'
    Kind = bkCancel
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 2
    IsControl = True
  end
  object HelpBtn: TBitBtn
    Left = 642
    Top = 106
    Width = 73
    Height = 27
    HelpContext = 4127
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 3
    IsControl = True
  end
  object InitialPartition: TRadioGroup
    Left = 22
    Top = 164
    Width = 185
    Height = 61
    Caption = 'Initial Partition'
    ItemIndex = 1
    Items.Strings = (
      'Identity'
      'Clique-based')
    TabOrder = 4
  end
end
