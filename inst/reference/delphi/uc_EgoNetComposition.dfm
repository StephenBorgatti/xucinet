object EgoNetComposition: TEgoNetComposition
  Left = 0
  Top = 0
  Caption = ' Ego Network Composition'
  ClientHeight = 304
  ClientWidth = 730
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Group: TGroupBox
    Left = 20
    Top = 14
    Width = 601
    Height = 167
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
    object SpeedButton2: TSpeedButton
      Left = 550
      Top = 80
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton2Click
    end
    object Label1: TLabel
      Left = 370
      Top = 64
      Width = 52
      Height = 13
      Caption = 'Dimension:'
    end
    object Label2: TLabel
      Left = 440
      Top = 64
      Width = 30
      Height = 13
      Caption = 'Value:'
    end
    object SpeedButton3: TSpeedButton
      Left = 550
      Top = 125
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
    object InputAttrFn: TLabeledEdit
      Left = 32
      Top = 80
      Width = 327
      Height = 21
      EditLabel.Width = 116
      EditLabel.Height = 13
      EditLabel.Caption = 'Input Attribute dataset:'
      TabOrder = 1
      OnChange = InputAttrFnChange
    end
    object Dimension: TComboBox
      Left = 370
      Top = 80
      Width = 61
      Height = 21
      ItemIndex = 0
      TabOrder = 2
      Text = 'Column'
      OnChange = DimensionChange
      Items.Strings = (
        'Column'
        'Row')
    end
    object DimensionValue: TComboBox
      Left = 440
      Top = 80
      Width = 99
      Height = 21
      TabOrder = 3
      Text = 'DimensionValue'
    end
    object OutputFn: TLabeledEdit
      Left = 30
      Top = 126
      Width = 507
      Height = 21
      EditLabel.Width = 128
      EditLabel.Height = 13
      EditLabel.Caption = 'Output Measures Dataset:'
      TabOrder = 4
    end
  end
  object OKBtn: TBitBtn
    Left = 640
    Top = 42
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
    Left = 640
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
    Left = 640
    Top = 106
    Width = 73
    Height = 27
    HelpContext = 4128
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 3
    IsControl = True
  end
  object EgoNetType: TRadioGroup
    Left = 20
    Top = 190
    Width = 191
    Height = 97
    Caption = 'Definition of Ego Network'
    ItemIndex = 0
    Items.Strings = (
      'Both incoming and outgoing ties'
      'Outgoing ties only'
      'Incoming ties only'
      'Reciprocal ties only')
    TabOrder = 4
  end
  object IgnoreOwn: TCheckBox
    Left = 248
    Top = 206
    Width = 211
    Height = 17
    Hint = 
      'e.g., when calculating heterogeneity of alters w/ respect to dep' +
      'artment, ignore ego'#39's own dept'
    Caption = ' Ignore ego'#39's own category'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 5
  end
end
