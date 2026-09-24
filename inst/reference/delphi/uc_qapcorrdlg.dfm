object qapcorrdlg: Tqapcorrdlg
  Left = 258
  Top = 172
  Caption = 'QAP Correlation'
  ClientHeight = 501
  ClientWidth = 677
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 24
    Top = 8
    Width = 533
    Height = 185
    Caption = 'Matrices to Correlate:'
    TabOrder = 0
    object Memo1: TMemo
      Left = 28
      Top = 28
      Width = 485
      Height = 117
      TabOrder = 0
      WordWrap = False
    end
    object BrowseBtn: TButton
      Left = 176
      Top = 151
      Width = 75
      Height = 25
      Caption = 'Browse'
      TabOrder = 1
      OnClick = BrowseBtnClick
    end
    object Button2: TButton
      Left = 296
      Top = 151
      Width = 75
      Height = 25
      Caption = 'Clear'
      TabOrder = 2
      OnClick = Button2Click
    end
  end
  object GroupBox2: TGroupBox
    Left = 24
    Top = 208
    Width = 533
    Height = 85
    Caption = 'Parameters'
    TabOrder = 1
    object pNumPerm: TLabeledEdit
      Left = 28
      Top = 44
      Width = 121
      Height = 21
      EditLabel.Width = 116
      EditLabel.Height = 13
      EditLabel.Caption = 'Number of Permutations:'
      TabOrder = 0
      Text = '5000'
    end
    object pRandomSeed: TLabeledEdit
      Left = 180
      Top = 44
      Width = 121
      Height = 21
      EditLabel.Width = 111
      EditLabel.Height = 13
      EditLabel.Caption = 'Random Number Seed:'
      TabOrder = 1
      Text = '32767'
    end
    object pType: TRadioGroup
      Left = 320
      Top = 16
      Width = 193
      Height = 61
      Caption = 'Type of analysis to run:'
      ItemIndex = 0
      Items.Strings = (
        'Fast: no missing values allowed'
        'Detailed (missing values ok)')
      TabOrder = 2
    end
  end
  object OKBtn: TBitBtn
    Left = 580
    Top = 32
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
    Left = 580
    Top = 64
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
    Left = 580
    Top = 96
    Width = 73
    Height = 27
    HelpContext = 3102
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 4
    IsControl = True
  end
  object pTails: TRadioGroup
    Left = 24
    Top = 299
    Width = 533
    Height = 47
    Caption = 'Tails:'
    Columns = 2
    ItemIndex = 1
    Items.Strings = (
      '1-tailed (reports p for r>0 and p for r<0 separately)'
      '2-tailed (|perm| >= |obs|)')
    TabOrder = 7
  end
  object GroupBox3: TGroupBox
    Left = 24
    Top = 358
    Width = 533
    Height = 125
    Caption = 'Output Files:'
    TabOrder = 5
    object Label1: TLabel
      Left = 20
      Top = 24
      Width = 129
      Height = 13
      Caption = 'Save permutation statistics:'
    end
    object Label2: TLabel
      Left = 20
      Top = 68
      Width = 123
      Height = 13
      Caption = 'Save qap measures table:'
    end
    object SpeedButton1: TSpeedButton
      Left = 484
      Top = 40
      Width = 23
      Height = 22
      Caption = '...'
      Enabled = False
      OnClick = SpeedButton1Click
    end
    object SpeedButton2: TSpeedButton
      Left = 484
      Top = 84
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton2Click
    end
    object pPermStats: TCheckBox
      Left = 24
      Top = 40
      Width = 21
      Height = 21
      Enabled = False
      TabOrder = 0
      OnClick = pPermStatsClick
    end
    object pResults: TCheckBox
      Left = 20
      Top = 84
      Width = 21
      Height = 21
      Checked = True
      State = cbChecked
      TabOrder = 1
      OnClick = pResultsClick
    end
    object pPermStatsFn: TEdit
      Left = 48
      Top = 40
      Width = 425
      Height = 21
      Enabled = False
      TabOrder = 2
      Visible = False
      OnChange = pPermStatsFnChange
    end
    object pResultsFn: TEdit
      Left = 48
      Top = 84
      Width = 425
      Height = 21
      TabOrder = 3
      Text = 'QAP Correlation Results'
      OnChange = pResultsFnChange
    end
  end
  object Parallel: TCheckBox
    Left = 580
    Top = 466
    Width = 73
    Height = 17
    Caption = ' Parallel'
    Checked = True
    State = cbChecked
    TabOrder = 6
  end
end
