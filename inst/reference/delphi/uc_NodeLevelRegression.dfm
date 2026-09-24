object NodeLevelRegression: TNodeLevelRegression
  Left = 0
  Top = 0
  Caption = '  Node Level Regression'
  ClientHeight = 553
  ClientWidth = 919
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    919
    553)
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 675
    Top = 64
    Width = 221
    Height = 187
    Caption = 'Significance options'
    TabOrder = 0
    object Label3: TLabel
      Left = 8
      Top = 133
      Width = 139
      Height = 13
      Alignment = taRightJustify
      Caption = 'No. of random permutations:'
    end
    object Label4: TLabel
      Left = 29
      Top = 160
      Width = 118
      Height = 13
      Alignment = taRightJustify
      AutoSize = False
      Caption = 'Random Number Seed:'
    end
    object noperms: TEdit
      Left = 159
      Top = 127
      Width = 41
      Height = 21
      TabOrder = 0
      Text = '10000'
    end
    object randomseed: TEdit
      Left = 159
      Top = 154
      Width = 41
      Height = 21
      TabOrder = 1
      Text = '32767'
    end
    object Tails: TRadioGroup
      Left = 13
      Top = 71
      Width = 195
      Height = 42
      Caption = 'p-values'
      Columns = 2
      ItemIndex = 1
      Items.Strings = (
        '1-tailed'
        '2-tailed')
      TabOrder = 2
    end
    object Method: TRadioGroup
      Left = 13
      Top = 22
      Width = 195
      Height = 43
      Caption = 'Method'
      Columns = 2
      ItemIndex = 1
      Items.Strings = (
        'Classical'
        'Y-perm')
      TabOrder = 3
    end
  end
  object OKBtn: TBitBtn
    Left = 675
    Top = 20
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
    Left = 748
    Top = 20
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
    Left = 823
    Top = 20
    Width = 73
    Height = 27
    HelpContext = 3105
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 3
    IsControl = True
  end
  object ProgressBar1: TProgressBar
    Left = 675
    Top = 372
    Width = 221
    Height = 17
    TabOrder = 4
  end
  object GroupBox2: TGroupBox
    Left = 20
    Top = 20
    Width = 637
    Height = 82
    Caption = 'Dependent Variable (Y)'
    TabOrder = 5
    object SpeedButton1: TSpeedButton
      Left = 443
      Top = 44
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton1Click
    end
    object Label1: TLabel
      Left = 482
      Top = 29
      Width = 69
      Height = 13
      Caption = 'Which column:'
    end
    object depfn: TLabeledEdit
      Left = 24
      Top = 44
      Width = 413
      Height = 21
      EditLabel.Width = 186
      EditLabel.Height = 13
      EditLabel.Caption = 'Dataset containing dependent variable'
      TabOrder = 0
      OnChange = depfnChange
    end
    object dep: TComboBox
      Left = 482
      Top = 44
      Width = 129
      Height = 21
      TabOrder = 1
      Text = 'dep'
    end
  end
  object GroupBox3: TGroupBox
    Left = 20
    Top = 114
    Width = 637
    Height = 212
    Anchors = [akLeft, akTop, akRight, akBottom]
    Caption = 'Independent Variables (X vars)'
    TabOrder = 6
    DesignSize = (
      637
      212)
    object Label5: TLabel
      Left = 482
      Top = 21
      Width = 82
      Height = 13
      Caption = 'Which column(s):'
    end
    object SpeedButton4: TSpeedButton
      Left = 443
      Top = 37
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton4Click
    end
    object Label6: TLabel
      Left = 24
      Top = 63
      Width = 45
      Height = 13
      Caption = 'In model:'
    end
    object SpeedButton7: TSpeedButton
      Left = 579
      Top = 100
      Width = 36
      Height = 22
      Caption = 'Clr'
      OnClick = SpeedButton7Click
    end
    object IndepFn: TLabeledEdit
      Left = 26
      Top = 36
      Width = 411
      Height = 21
      EditLabel.Width = 203
      EditLabel.Height = 13
      EditLabel.Caption = 'Dataset containing independent variables:'
      TabOrder = 0
      OnChange = IndepFnChange
    end
    object IndepBox: TComboBox
      Left = 482
      Top = 37
      Width = 85
      Height = 21
      TabOrder = 1
      Text = 'ComboBox1'
    end
    object Button1: TButton
      Left = 579
      Top = 35
      Width = 36
      Height = 25
      Caption = 'Add'
      TabOrder = 2
      OnClick = Button1Click
    end
    object Indepfile: TMemo
      Left = 24
      Top = 83
      Width = 543
      Height = 114
      Anchors = [akLeft, akTop, akRight, akBottom]
      Lines.Strings = (
        'Indepfile')
      ScrollBars = ssVertical
      TabOrder = 3
    end
  end
  object GroupBox4: TGroupBox
    Left = 20
    Top = 337
    Width = 637
    Height = 198
    Caption = 'Outputs'
    TabOrder = 7
    object SpeedButton3: TSpeedButton
      Left = 554
      Top = 122
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton3Click
    end
    object SpeedButton5: TSpeedButton
      Left = 554
      Top = 38
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton5Click
    end
    object SpeedButton6: TSpeedButton
      Left = 554
      Top = 79
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton6Click
    end
    object SpeedButton2: TSpeedButton
      Left = 554
      Top = 162
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton2Click
    end
    object PredFn: TLabeledEdit
      Left = 19
      Top = 122
      Width = 529
      Height = 21
      EditLabel.Width = 128
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Predicted Values:'
      TabOrder = 0
    end
    object Fitfn: TLabeledEdit
      Left = 19
      Top = 79
      Width = 529
      Height = 21
      EditLabel.Width = 135
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Model fit statistics:'
      TabOrder = 1
    end
    object CoefFn: TLabeledEdit
      Left = 19
      Top = 39
      Width = 529
      Height = 21
      EditLabel.Width = 102
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Coefficients'
      TabOrder = 2
    end
    object Resfn: TLabeledEdit
      Left = 19
      Top = 163
      Width = 529
      Height = 21
      EditLabel.Width = 123
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Residual Values:'
      TabOrder = 3
    end
  end
  object Memo1: TMemo
    Left = 675
    Top = 265
    Width = 221
    Height = 88
    Color = clBtnFace
    Lines.Strings = (
      'To enter independent variables, enter a '
      'dataset name, then choose one or more '
      'columns from the dropdown box. Then click '
      'Add. You will see your selections appear '
      'where it says "In Model:"')
    TabOrder = 8
  end
end
