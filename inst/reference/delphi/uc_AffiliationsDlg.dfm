object AffiliationsDlg: TAffiliationsDlg
  Left = 124
  Top = 214
  Caption = 'Affiliations: Convert 2-mode to 1-mode data'
  ClientHeight = 351
  ClientWidth = 778
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
  object OKBtn: TBitBtn
    Left = 684
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
    Left = 684
    Top = 76
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
    Left = 684
    Top = 108
    Width = 73
    Height = 27
    HelpContext = 1105
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 2
    IsControl = True
  end
  object GroupBox1: TGroupBox
    Left = 20
    Top = 20
    Width = 637
    Height = 123
    Caption = 'Files:'
    TabOrder = 3
    object SpeedButton1: TSpeedButton
      Left = 556
      Top = 36
      Width = 21
      Height = 20
      Hint = 'Browse files'
      Caption = '...'
      ParentShowHint = False
      ShowHint = True
      OnClick = SpeedButton1Click
    end
    object SpeedButton2: TSpeedButton
      Left = 556
      Top = 82
      Width = 21
      Height = 20
      Hint = 'Browse files'
      Caption = '...'
      ParentShowHint = False
      ShowHint = True
      OnClick = SpeedButton2Click
    end
    object InputFn: TLabeledEdit
      Left = 28
      Top = 36
      Width = 513
      Height = 21
      EditLabel.Width = 67
      EditLabel.Height = 13
      EditLabel.Caption = 'Input Dataset:'
      TabOrder = 0
      OnChange = InputFnChange
    end
    object OutputFn: TLabeledEdit
      Left = 28
      Top = 82
      Width = 513
      Height = 21
      EditLabel.Width = 75
      EditLabel.Height = 13
      EditLabel.Caption = 'Output Dataset:'
      TabOrder = 1
      Text = 'Affiliations'
    end
  end
  object Method: TRadioGroup
    Left = 20
    Top = 242
    Width = 637
    Height = 99
    Caption = 'Method:'
    Columns = 3
    ItemIndex = 0
    Items.Strings = (
      'Sums of cross-products (overlaps)'
      'Sums of cross-minimums'
      'Covariance'
      'Correlation'
      'Matches (counts of same values)'
      'Jaccard (positive matches)'
      'Identity coefficient'
      'Bonacich '#39'72'
      'Max of cross-minimums'
      'Sum(xi*yi)/Min(x+,y+)'
      'Sum of squared differences'
      'Cosine similarity (congruence)'
      'Backbone (SDSM)')
    TabOrder = 4
    OnClick = MethodClick
  end
  object SDSMModel: TRadioGroup
    Left = 672
    Top = 146
    Width = 97
    Height = 63
    Caption = 'SDSM null model:'
    ItemIndex = 0
    Items.Strings = (
      'Logistic'
      'BiCM')
    TabOrder = 9
    Visible = False
  end
  object Mode: TRadioGroup
    Left = 20
    Top = 160
    Width = 91
    Height = 63
    Caption = 'Mode:'
    ItemIndex = 0
    Items.Strings = (
      'Rows'
      'Columns')
    TabOrder = 5
    OnClick = ModeClick
  end
  object Normalization: TRadioGroup
    Left = 132
    Top = 160
    Width = 301
    Height = 63
    Caption = 'Opposite mode normalization:'
    ItemIndex = 0
    Items.Strings = (
      'None'
      'Weight opposite mode inversely by size (row/col totals)')
    TabOrder = 6
  end
  object RecodeMissings: TCheckBox
    Left = 450
    Top = 160
    Width = 207
    Height = 17
    Caption = 'Recode missing values to zeros'
    Checked = True
    State = cbChecked
    TabOrder = 7
  end
  object AlphaEdit: TLabeledEdit
    Left = 450
    Top = 196
    Width = 81
    Height = 21
    EditLabel.Width = 144
    EditLabel.Height = 13
    EditLabel.Caption = 'Alpha (Backbone SDSM only):'
    TabOrder = 8
    Text = '0.05'
  end
end
