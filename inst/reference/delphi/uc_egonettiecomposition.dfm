object EgonetTieComposition: TEgonetTieComposition
  Left = 183
  Top = 154
  Caption = ' Egonet Tie Composition'
  ClientHeight = 365
  ClientWidth = 730
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  PixelsPerInch = 96
  TextHeight = 13
  object OKBtn: TBitBtn
    Left = 610
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
    Left = 610
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
    Left = 610
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
    Top = 20
    Width = 568
    Height = 135
    Caption = 'Files'
    TabOrder = 3
    object ifnbrowse: TSpeedButton
      Left = 533
      Top = 42
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = ifnbrowseClick
    end
    object ofnbrowse: TSpeedButton
      Left = 533
      Top = 92
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = ofnbrowseClick
    end
    object Ifn: TLabeledEdit
      Left = 16
      Top = 43
      Width = 507
      Height = 21
      EditLabel.Width = 153
      EditLabel.Height = 13
      EditLabel.Caption = 'Input (multi-relational) network:'
      TabOrder = 0
      OnChange = IfnChange
    end
    object ofn: TLabeledEdit
      Left = 16
      Top = 92
      Width = 507
      Height = 21
      EditLabel.Width = 73
      EditLabel.Height = 13
      EditLabel.Caption = 'Output Scores:'
      TabOrder = 1
      Text = '-etc'
    end
  end
  object GroupBox2: TGroupBox
    Left = 21
    Top = 172
    Width = 568
    Height = 173
    Caption = 'Options'
    TabOrder = 4
    object Label1: TLabel
      Left = 190
      Top = 44
      Width = 83
      Height = 13
      Caption = 'Ties have values '
    end
    object WhichTies: TRadioGroup
      Left = 27
      Top = 28
      Width = 148
      Height = 125
      Hint = 'Which alters should be counted in the ego network'
      Caption = 'Which ties matter?'
      ItemIndex = 1
      Items.Strings = (
        'Both in and out'
        'Undirected (OR)'
        'Outgoing only'
        'Incoming only'
        'Reciprocated'
        'Recip and x(i,j) = x(j,i)')
      TabOrder = 0
    end
    object DiagonalOk: TCheckBox
      Left = 188
      Top = 78
      Width = 117
      Height = 17
      Caption = ' Include ties to self'
      TabOrder = 1
    end
    object ValidOperator: TComboBox
      Left = 274
      Top = 42
      Width = 141
      Height = 21
      ItemIndex = 5
      TabOrder = 2
      Text = 'Not equal to'
      Items.Strings = (
        'Greater than'
        'Greater than or = to'
        'Equal to '
        'Less than or == to'
        'Less than'
        'Not equal to')
    end
    object ValidValue: TLabeledEdit
      Left = 430
      Top = 42
      Width = 53
      Height = 21
      EditLabel.Width = 30
      EditLabel.Height = 13
      EditLabel.Caption = 'Value:'
      TabOrder = 3
      Text = '0'
    end
  end
end
