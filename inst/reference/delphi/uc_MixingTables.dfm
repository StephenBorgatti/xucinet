object MixingTables: TMixingTables
  Left = 0
  Top = 0
  Caption = 'MixingTables'
  ClientHeight = 434
  ClientWidth = 715
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  HelpFile = ' Mixing Tables'
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Group: TGroupBox
    Left = 18
    Top = 18
    Width = 589
    Height = 297
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
      Top = 167
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton4Click
    end
    object SpeedButton5: TSpeedButton
      Left = 550
      Top = 211
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton5Click
    end
    object SpeedButton6: TSpeedButton
      Left = 550
      Top = 255
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton6Click
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
      Top = 83
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
    object oFn: TLabeledEdit
      Left = 30
      Top = 125
      Width = 507
      Height = 21
      EditLabel.Width = 152
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Observed mixing table'
      TabOrder = 4
    end
    object efn: TLabeledEdit
      Left = 30
      Top = 167
      Width = 507
      Height = 21
      EditLabel.Width = 150
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Expected mixing table'
      TabOrder = 5
    end
    object dfn: TLabeledEdit
      Left = 30
      Top = 211
      Width = 507
      Height = 21
      EditLabel.Width = 108
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Density table'
      TabOrder = 6
    end
    object rfn: TLabeledEdit
      Left = 30
      Top = 255
      Width = 507
      Height = 21
      EditLabel.Width = 166
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Observed/Expected ratio'
      TabOrder = 7
    end
  end
  object OKBtn: TBitBtn
    Left = 628
    Top = 48
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
    Left = 628
    Top = 81
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
    Left = 628
    Top = 113
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
  object TreatTies: TRadioGroup
    Left = 18
    Top = 329
    Width = 201
    Height = 71
    Caption = 'For undirected networks, treat ties as:'
    ItemIndex = 0
    Items.Strings = (
      'Directed'
      'Undirected')
    TabOrder = 4
  end
  object ExpectedModel: TRadioGroup
    Left = 239
    Top = 329
    Width = 201
    Height = 89
    Caption = 'Model for expected values'
    ItemIndex = 0
    Items.Strings = (
      'Density'
      'Configuration'
      'Fixed outdegree')
    TabOrder = 5
  end
  object AddLabelsBtn: TButton
    Left = 468
    Top = 332
    Width = 120
    Height = 27
    Caption = 'Add Labels'
    TabOrder = 6
    OnClick = AddLabelsBtnClick
  end
end
