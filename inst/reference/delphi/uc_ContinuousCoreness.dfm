object ContinuousCorenessDlg: TContinuousCorenessDlg
  Left = 0
  Top = 0
  Caption = ' Continuous Core/Periphery Model (Borgatti & Everett 1999)'
  ClientHeight = 424
  ClientWidth = 739
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Group: TGroupBox
    Left = 22
    Top = 22
    Width = 601
    Height = 257
    Caption = 'Files'
    TabOrder = 0
    object btnInput: TSpeedButton
      Left = 550
      Top = 34
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = btnInputClick
    end
    object btnOutput: TSpeedButton
      Left = 550
      Top = 80
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = btnOutputClick
    end
    object btnPartition: TSpeedButton
      Left = 550
      Top = 126
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = btnPartitionClick
    end
    object btnConcentration: TSpeedButton
      Left = 550
      Top = 172
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = btnConcentrationClick
    end
    object btnExpected: TSpeedButton
      Left = 550
      Top = 218
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = btnExpectedClick
    end
    object InputFn: TLabeledEdit
      Left = 32
      Top = 34
      Width = 507
      Height = 21
      EditLabel.Width = 114
      EditLabel.Height = 13
      EditLabel.Caption = 'Input Network Dataset:'
      TabOrder = 0
      OnChange = InputFnChange
    end
    object OutputFn: TLabeledEdit
      Left = 32
      Top = 80
      Width = 507
      Height = 21
      EditLabel.Width = 127
      EditLabel.Height = 13
      EditLabel.Caption = 'Output Coreness Dataset:'
      TabOrder = 1
    end
    object PartitionFn: TLabeledEdit
      Left = 32
      Top = 126
      Width = 507
      Height = 21
      EditLabel.Width = 122
      EditLabel.Height = 13
      EditLabel.Caption = 'Output Partition Dataset:'
      TabOrder = 2
    end
    object ConcentrationFn: TLabeledEdit
      Left = 32
      Top = 172
      Width = 507
      Height = 21
      EditLabel.Width = 150
      EditLabel.Height = 13
      EditLabel.Caption = 'Output Concentration Dataset:'
      TabOrder = 3
    end
    object ExpectedFn: TLabeledEdit
      Left = 32
      Top = 218
      Width = 507
      Height = 21
      EditLabel.Width = 161
      EditLabel.Height = 13
      EditLabel.Caption = 'Output Expected Values Dataset:'
      TabOrder = 4
    end
  end
  object Options: TGroupBox
    Left = 22
    Top = 295
    Width = 601
    Height = 100
    Caption = 'Options'
    TabOrder = 1
    object MaxIteration: TLabeledEdit
      Left = 32
      Top = 42
      Width = 90
      Height = 21
      EditLabel.Width = 96
      EditLabel.Height = 13
      EditLabel.Caption = 'Max # of iterations:'
      TabOrder = 0
      Text = '100'
    end
    object chkDiagValid: TCheckBox
      Left = 168
      Top = 44
      Width = 160
      Height = 17
      Hint = 
        'If checked, the diagonal is treated as data and fitted directly.' +
        ' If unchecked (default), the diagonal is ignored and estimated a' +
        's communalities (minres).'
      Caption = 'Diagonal values valid'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
    end
    object chkPosOnly: TCheckBox
      Left = 360
      Top = 44
      Width = 180
      Height = 17
      Hint = 'Report absolute values of coreness scores.'
      Caption = 'Prevent negative coreness'
      Checked = True
      ParentShowHint = False
      ShowHint = True
      State = cbChecked
      TabOrder = 2
    end
  end
  object OKBtn: TBitBtn
    Left = 646
    Top = 61
    Width = 73
    Height = 27
    Caption = '&OK'
    Kind = bkOK
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 2
    OnClick = OKBtnClick
    IsControl = True
  end
  object CancelBtn: TBitBtn
    Left = 646
    Top = 93
    Width = 73
    Height = 27
    Caption = '&Cancel'
    Kind = bkCancel
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 3
    IsControl = True
  end
  object HelpBtn: TBitBtn
    Left = 646
    Top = 126
    Width = 73
    Height = 27
    HelpContext = 4127
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 4
    IsControl = True
  end
end
