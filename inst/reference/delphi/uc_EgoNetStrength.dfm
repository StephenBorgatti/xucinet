object EgoNetStrength: TEgoNetStrength
  Left = 0
  Top = 0
  Caption = '  Ego Network Composition -- Continuous Attributes'
  ClientHeight = 309
  ClientWidth = 732
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
      EditLabel.Width = 124
      EditLabel.Height = 13
      EditLabel.Caption = 'Output Strength Dataset:'
      TabOrder = 4
    end
  end
  object OKBtn: TBitBtn
    Left = 640
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
    HelpContext = 4129
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 3
    IsControl = True
  end
  object EgoNetType: TRadioGroup
    Left = 20
    Top = 196
    Width = 161
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
  object WeightedTies: TRadioGroup
    Left = 198
    Top = 196
    Width = 231
    Height = 97
    Caption = 'Valued tie data'
    ItemIndex = 1
    Items.Strings = (
      'Ignore tie strengths'
      'Treat tie strengths as analytical weights'
      'Multiply tie strength by attrrib value')
    TabOrder = 5
  end
  object FilterOptions: TGroupBox
    Left = 446
    Top = 196
    Width = 175
    Height = 97
    Caption = 'Filter out alters more than ...'
    TabOrder = 6
    object SDabove: TLabeledEdit
      Left = 15
      Top = 30
      Width = 33
      Height = 21
      EditLabel.Width = 105
      EditLabel.Height = 13
      EditLabel.Caption = ' SDs ABOVE the mean'
      LabelPosition = lpRight
      TabOrder = 0
      OnChange = SDaboveChange
    end
    object SDbelow: TLabeledEdit
      Left = 15
      Top = 62
      Width = 33
      Height = 21
      EditLabel.Width = 107
      EditLabel.Height = 13
      EditLabel.Caption = ' SDs BELOW the mean'
      LabelPosition = lpRight
      TabOrder = 1
      OnChange = SDbelowChange
    end
  end
  object FilterAbove: TCheckBox
    Left = 632
    Top = 217
    Width = 81
    Height = 17
    Caption = 'Filter above'
    TabOrder = 7
  end
  object FilterBelow: TCheckBox
    Left = 632
    Top = 263
    Width = 81
    Height = 17
    Caption = 'Filter below'
    TabOrder = 8
  end
  object AndBtn: TRadioButton
    Left = 637
    Top = 240
    Width = 36
    Height = 17
    Caption = 'and'
    TabOrder = 9
  end
  object OrBtn: TRadioButton
    Left = 679
    Top = 240
    Width = 29
    Height = 17
    Caption = 'or'
    Checked = True
    TabOrder = 10
    TabStop = True
  end
end
