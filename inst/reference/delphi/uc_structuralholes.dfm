object StructuralHolesDlg: TStructuralHolesDlg
  Left = 1
  Top = 109
  Caption = ' Structural Holes'
  ClientHeight = 360
  ClientWidth = 685
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnActivate = FormActivate
  OnKeyPress = FormKeyPress
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 18
    Top = 18
    Width = 529
    Height = 175
    Shape = bsFrame
    IsControl = True
  end
  object Label9: TLabel
    Left = 89
    Top = 41
    Width = 65
    Height = 13
    Alignment = taRightJustify
    Caption = 'Input dataset:'
  end
  object Label4: TLabel
    Left = 33
    Top = 150
    Width = 121
    Height = 20
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'Node-level measures:'
  end
  object SpeedButton1: TSpeedButton
    Left = 507
    Top = 36
    Width = 20
    Height = 21
    Hint = 'Browse files'
    Caption = '...'
    ParentShowHint = False
    ShowHint = True
    OnClick = SpeedButton1Click
  end
  object SpeedButton2: TSpeedButton
    Left = 507
    Top = 147
    Width = 20
    Height = 21
    Hint = 'Browse files'
    Caption = '...'
    ParentShowHint = False
    ShowHint = True
    OnClick = SpeedButton2Click
  end
  object Label1: TLabel
    Left = 18
    Top = 100
    Width = 136
    Height = 20
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'Output dyadic redundancy:'
  end
  object SpeedButton3: TSpeedButton
    Left = 507
    Top = 91
    Width = 20
    Height = 21
    Hint = 'Browse files'
    Caption = '...'
    ParentShowHint = False
    ShowHint = True
    OnClick = SpeedButton3Click
  end
  object Label2: TLabel
    Left = 18
    Top = 124
    Width = 136
    Height = 20
    Alignment = taRightJustify
    AutoSize = False
    Caption = 'Output dyadic constraint:'
  end
  object SpeedButton4: TSpeedButton
    Left = 507
    Top = 120
    Width = 20
    Height = 21
    Hint = 'Browse files'
    Caption = '...'
    ParentShowHint = False
    ShowHint = True
    OnClick = SpeedButton4Click
  end
  object Label5: TLabel
    Left = 115
    Top = 68
    Width = 39
    Height = 13
    Alignment = taRightJustify
    Caption = 'Method:'
  end
  object OKBtn: TBitBtn
    Left = 565
    Top = 36
    Width = 73
    Height = 26
    Kind = bkOK
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 0
    OnClick = OKBtnClick
    IsControl = True
  end
  object CancelBtn: TBitBtn
    Left = 565
    Top = 68
    Width = 73
    Height = 27
    Kind = bkCancel
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 1
    IsControl = True
  end
  object HelpBtn: TBitBtn
    Left = 565
    Top = 104
    Width = 73
    Height = 26
    HelpContext = 4126
    Caption = 'Help'
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 2
    IsControl = True
  end
  object InputFn: TEdit
    Left = 160
    Top = 36
    Width = 341
    Height = 21
    TabOrder = 3
    OnChange = InputFnChange
  end
  object OutputFn: TEdit
    Left = 160
    Top = 147
    Width = 341
    Height = 21
    TabOrder = 4
    Text = '-SH'
  end
  object OutputRFn: TEdit
    Left = 160
    Top = 91
    Width = 341
    Height = 21
    TabOrder = 5
    Text = '-DR'
  end
  object OutputCFn: TEdit
    Left = 160
    Top = 119
    Width = 341
    Height = 21
    TabOrder = 6
    Text = '-DC'
  end
  object pMethod: TComboBox
    Left = 160
    Top = 63
    Width = 341
    Height = 21
    ItemIndex = 1
    TabOrder = 7
    Text = 'Ego network model -- ties beyond egonet have no effect'
    OnChange = pMethodChange
    Items.Strings = (
      'Whole network model -- includes alter ties outside of egonet'
      'Ego network model -- ties beyond egonet have no effect')
  end
  object EgoNetDefinition: TRadioGroup
    Left = 18
    Top = 212
    Width = 165
    Height = 113
    Caption = 'How to define ego net:'
    ItemIndex = 2
    Items.Strings = (
      'Outgoing ties only'
      'Incoming ties only'
      'Union - either kind'
      'Intersection - Reciprocated')
    TabOrder = 8
  end
  object ProgressBar1: TProgressBar
    Left = 0
    Top = 344
    Width = 685
    Height = 16
    Align = alBottom
    TabOrder = 9
  end
  object DiagonalValid: TCheckBox
    Left = 565
    Top = 252
    Width = 97
    Height = 17
    Caption = 'Diagonal valid'
    TabOrder = 10
  end
  object GroupBox1: TGroupBox
    Left = 210
    Top = 212
    Width = 149
    Height = 113
    Caption = 'Constraint Measure'
    TabOrder = 11
    object ConstraintIso: TLabeledEdit
      Left = 14
      Top = 36
      Width = 121
      Height = 21
      EditLabel.Width = 66
      EditLabel.Height = 13
      EditLabel.Caption = 'Set isolates to'
      TabOrder = 0
      Text = 'NA'
    end
    object ConstraintPendant: TLabeledEdit
      Left = 14
      Top = 78
      Width = 121
      Height = 21
      Hint = 'Pendants are nodes with 1 tie'
      EditLabel.Width = 78
      EditLabel.Height = 13
      EditLabel.Caption = 'Set pendants to '
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      Text = 'NA'
    end
  end
  object Effsizegroup: TGroupBox
    Left = 386
    Top = 212
    Width = 161
    Height = 113
    Caption = 'Effective Size Measure'
    TabOrder = 12
    object EffectiveIso: TLabeledEdit
      Left = 14
      Top = 36
      Width = 121
      Height = 21
      EditLabel.Width = 66
      EditLabel.Height = 13
      EditLabel.Caption = 'Set isolates to'
      TabOrder = 0
      Text = '0'
    end
    object EffectivePendant: TLabeledEdit
      Left = 14
      Top = 78
      Width = 121
      Height = 21
      Hint = 'Pendants are nodes with 1 tie'
      EditLabel.Width = 78
      EditLabel.Height = 13
      EditLabel.Caption = 'Set pendants to '
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      Text = '1'
    end
  end
  object SymmetrizeBox: TCheckBox
    Left = 565
    Top = 280
    Width = 97
    Height = 31
    Caption = 'Symmetrize by sum ala Burt'
    Checked = True
    State = cbChecked
    TabOrder = 13
    WordWrap = True
  end
  object Normalization: TLabeledEdit
    Left = 565
    Top = 225
    Width = 97
    Height = 21
    EditLabel.Width = 63
    EditLabel.Height = 13
    EditLabel.Caption = 'Normalization'
    TabOrder = 14
    Visible = False
  end
end
