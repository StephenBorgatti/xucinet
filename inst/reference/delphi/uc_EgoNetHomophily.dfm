object EgoNetHomophily: TEgoNetHomophily
  Left = 0
  Top = 0
  Caption = 'Egonet Homophily for Categorical Attributes'
  ClientHeight = 365
  ClientWidth = 731
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
    Left = 22
    Top = 20
    Width = 601
    Height = 211
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
    object SpeedButton4: TSpeedButton
      Left = 550
      Top = 172
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton4Click
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
      EditLabel.Width = 117
      EditLabel.Height = 13
      EditLabel.Caption = 'Input Attribute Dataset:'
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
    object TablesFn: TLabeledEdit
      Left = 30
      Top = 173
      Width = 507
      Height = 21
      EditLabel.Width = 113
      EditLabel.Height = 13
      EditLabel.Caption = 'Output Tables Dataset:'
      TabOrder = 5
    end
  end
  object OKBtn: TBitBtn
    Left = 642
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
  object EgoNetType: TRadioGroup
    Left = 22
    Top = 252
    Width = 201
    Height = 97
    Caption = 'Definition of Ego Network'
    ItemIndex = 1
    Items.Strings = (
      'Both incoming and outgoing ties'
      'Outgoing ties only'
      'Incoming ties only'
      'Reciprocal ties only')
    TabOrder = 4
  end
  object ProgressBar1: TProgressBar
    Left = 242
    Top = 252
    Width = 381
    Height = 22
    TabOrder = 5
  end
end
