object CategoricalCorePeriphery: TCategoricalCorePeriphery
  Left = 0
  Top = 0
  Caption = 'Categorical Core/Periphery Model'
  ClientHeight = 317
  ClientWidth = 658
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 22
    Top = 20
    Width = 519
    Height = 131
    Caption = 'Files'
    TabOrder = 0
    object SpeedButton1: TSpeedButton
      Left = 479
      Top = 35
      Width = 22
      Height = 21
      Caption = '...'
      OnClick = SpeedButton1Click
    end
    object SpeedButton3: TSpeedButton
      Left = 479
      Top = 83
      Width = 22
      Height = 22
      Caption = '...'
      OnClick = SpeedButton3Click
    end
    object InputFn: TLabeledEdit
      Left = 20
      Top = 35
      Width = 453
      Height = 21
      EditLabel.Width = 112
      EditLabel.Height = 13
      EditLabel.Caption = 'Input network dataset:'
      TabOrder = 0
      OnChange = InputFnChange
    end
    object Outputfn: TLabeledEdit
      Left = 20
      Top = 83
      Width = 453
      Height = 21
      EditLabel.Width = 81
      EditLabel.Height = 13
      EditLabel.Caption = 'Output partition:'
      TabOrder = 1
    end
  end
  object GroupBox2: TGroupBox
    Left = 22
    Top = 172
    Width = 519
    Height = 125
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Options'
    TabOrder = 1
    object ExcludeDiagonal: TCheckBox
      Left = 20
      Top = 91
      Width = 107
      Height = 13
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = 'Exclude ties to self'
      Checked = True
      State = cbChecked
      TabOrder = 0
    end
    object RandomStarts: TLabeledEdit
      Left = 153
      Top = 28
      Width = 51
      Height = 21
      Hint = 'More starts get better results, but take more time'
      EditLabel.Width = 127
      EditLabel.Height = 13
      EditLabel.Caption = 'Number of random starts: '
      LabelPosition = lpLeft
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      Text = '20'
    end
    object MaxIterations: TLabeledEdit
      Left = 153
      Top = 58
      Width = 51
      Height = 21
      Hint = 
        'In principle, setting this too low could result in poor solution' +
        's. In practice, you rarely need to change this'
      EditLabel.Width = 127
      EditLabel.Height = 13
      EditLabel.Caption = 'Max number of iterations: '
      LabelPosition = lpLeft
      TabOrder = 2
      Text = '500'
    end
    object CoreToPeriphery: TLabeledEdit
      Left = 434
      Top = 26
      Width = 51
      Height = 21
      Hint = 
        'If set to 0, would be consistent with status structure (if ties ' +
        'are directed)'
      EditLabel.Width = 204
      EditLabel.Height = 13
      EditLabel.Caption = 'Desired density for core to periphery ties: '
      LabelPosition = lpLeft
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      Text = 'NA'
    end
    object PeripheryToCore: TLabeledEdit
      Left = 434
      Top = 60
      Width = 51
      Height = 21
      Hint = 
        'If set to 1, would be consistent with status hierarchy (if ties ' +
        'are directed)'
      EditLabel.Width = 204
      EditLabel.Height = 13
      EditLabel.Caption = 'Desired density for periphery to core ties: '
      LabelPosition = lpLeft
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      Text = 'NA'
    end
    object quickanddirty: TCheckBox
      Left = 226
      Top = 92
      Width = 207
      Height = 17
      Caption = 'Quick and dirty - for large matrices'
      TabOrder = 5
    end
  end
  object CancelBtn: TBitBtn
    Left = 562
    Top = 64
    Width = 73
    Height = 27
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = '&Cancel'
    Kind = bkCancel
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 2
    IsControl = True
  end
  object OKBtn: TBitBtn
    Left = 562
    Top = 33
    Width = 73
    Height = 27
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = '&OK'
    Kind = bkOK
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 3
    OnClick = OKBtnClick
    IsControl = True
  end
  object HelpBtn: TBitBtn
    Left = 562
    Top = 96
    Width = 73
    Height = 27
    HelpContext = 4235
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 4
    IsControl = True
  end
end
