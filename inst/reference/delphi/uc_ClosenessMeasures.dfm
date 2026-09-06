object ClosenessMeasures: TClosenessMeasures
  Left = 400
  Top = 257
  ActiveControl = Ifn
  Caption = '  Closeness Centrality'
  ClientHeight = 563
  ClientWidth = 697
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object OKBtn: TBitBtn
    Left = 602
    Top = 44
    Width = 73
    Height = 27
    Caption = '&OK'
    Kind = bkOK
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 0
    OnClick = OKBtnClick
    IsControl = True
  end
  object CancelBtn: TBitBtn
    Left = 602
    Top = 77
    Width = 73
    Height = 27
    Caption = '&Cancel'
    Kind = bkCancel
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 1
    IsControl = True
  end
  object HelpBtn: TBitBtn
    Left = 602
    Top = 110
    Width = 73
    Height = 27
    HelpContext = 4142
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 2
    IsControl = True
  end
  object GroupBox1: TGroupBox
    Left = 21
    Top = 22
    Width = 558
    Height = 137
    Caption = 'Files'
    TabOrder = 3
    object SpeedButton1: TSpeedButton
      Left = 17
      Top = 41
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton1Click
    end
    object SpeedButton3: TSpeedButton
      Left = 17
      Top = 90
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton3Click
    end
    object Ifn: TLabeledEdit
      Left = 46
      Top = 42
      Width = 489
      Height = 21
      EditLabel.Width = 73
      EditLabel.Height = 13
      EditLabel.Caption = 'Input Network:'
      TabOrder = 0
      OnChange = IfnChange
    end
    object OutputFn: TLabeledEdit
      Left = 46
      Top = 91
      Width = 489
      Height = 21
      EditLabel.Width = 73
      EditLabel.Height = 13
      EditLabel.Caption = 'Output Scores:'
      TabOrder = 1
      Text = '-Clo'
    end
  end
  object GroupBox2: TGroupBox
    Left = 21
    Top = 178
    Width = 558
    Height = 129
    Caption = 'Freeman options'
    TabOrder = 4
    object FreemanMissing: TRadioGroup
      Left = 23
      Top = 26
      Width = 212
      Height = 87
      Caption = 'Value to assign undefined distances:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -10
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemIndex = 1
      Items.Strings = (
        'N (number of nodes)'
        'Max observed distance plus 1'
        'Missing (ignore unreachables)'
        'Zero (closeness within components)')
      ParentFont = False
      TabOrder = 0
      OnClick = FreemanMissingClick
    end
    object FreemanOutput: TRadioGroup
      Left = 276
      Top = 26
      Width = 255
      Height = 77
      Caption = 'Output options'
      ItemIndex = 2
      Items.Strings = (
        'Sums'
        'Averages'
        'Divide totals into N-1 (Freeman normalization)')
      TabOrder = 1
    end
  end
  object GroupBox3: TGroupBox
    Left = 21
    Top = 450
    Width = 558
    Height = 94
    Caption = 'Valente-Forman options'
    TabOrder = 5
    object ValenteMissing: TRadioGroup
      Left = 23
      Top = 22
      Width = 212
      Height = 57
      Caption = 'Handling undefined distances:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -10
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemIndex = 0
      Items.Strings = (
        'Set reverse distance to zero')
      ParentFont = False
      TabOrder = 0
    end
    object ValenteOutput: TRadioGroup
      Left = 276
      Top = 24
      Width = 255
      Height = 57
      Caption = 'Output options'
      ItemIndex = 1
      Items.Strings = (
        'Averages'
        'Divide averages by diameter')
      TabOrder = 1
    end
  end
  object GroupBox4: TGroupBox
    Left = 21
    Top = 324
    Width = 558
    Height = 107
    Caption = 'Reciprocal-Distance options'
    TabOrder = 6
    object ReciprocalOutput: TRadioGroup
      Left = 276
      Top = 26
      Width = 255
      Height = 57
      Caption = 'Output options'
      ItemIndex = 1
      Items.Strings = (
        'Sums'
        'Averages')
      TabOrder = 0
    end
    object ReciprocalMissing: TRadioGroup
      Left = 23
      Top = 26
      Width = 212
      Height = 72
      Caption = 'Handling undefined distances:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -10
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemIndex = 2
      Items.Strings = (
        'Set distance to N'
        'Set distance to max obs dist plus 1'
        'Set reciprocal distance to zero')
      ParentFont = False
      TabOrder = 1
    end
  end
end
