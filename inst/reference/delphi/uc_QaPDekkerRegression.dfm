object QapDeckerRegression: TQapDeckerRegression
  Left = 0
  Top = 0
  Caption = 'MR-QAP via Double-Dekker Semi-Partialing'
  ClientHeight = 617
  ClientWidth = 754
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 20
    Top = 25
    Width = 3
    Height = 13
  end
  object SpeedButton1: TSpeedButton
    Left = 619
    Top = 29
    Width = 23
    Height = 22
    Caption = '...'
    OnClick = SpeedButton1Click
  end
  object Label2: TLabel
    Left = 25
    Top = 46
    Width = 154
    Height = 13
    Caption = 'Independent Variables (dyadic):'
  end
  object SpeedButton2: TSpeedButton
    Left = 619
    Top = 81
    Width = 23
    Height = 22
    Caption = '...'
    OnClick = SpeedButton2Click
  end
  object SpeedButton7: TSpeedButton
    Left = 619
    Top = 109
    Width = 23
    Height = 22
    Caption = 'C'
    OnClick = SpeedButton7Click
  end
  object Label5: TLabel
    Left = 625
    Top = 220
    Width = 121
    Height = 99
    Margins.Left = 6
    Caption = 
      'Note: Independent variables can be stacked in a single dataset i' +
      'f no relational effects are being used. Otherwise, enter them as' +
      ' separate datasets'
    WordWrap = True
  end
  object InputInd: TMemo
    Left = 25
    Top = 65
    Width = 582
    Height = 108
    ScrollBars = ssVertical
    TabOrder = 0
    WordWrap = False
    OnChange = InputIndChange
  end
  object inputdep: TLabeledEdit
    Left = 25
    Top = 20
    Width = 582
    Height = 21
    EditLabel.Width = 140
    EditLabel.Height = 13
    EditLabel.Caption = 'Dependent Variable (dyadic):'
    TabOrder = 1
    OnChange = inputdepChange
  end
  object OKBtn: TBitBtn
    Left = 660
    Top = 30
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
    Left = 660
    Top = 63
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
    Left = 660
    Top = 96
    Width = 73
    Height = 27
    HelpContext = 3105
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 4
    IsControl = True
  end
  object inputindedit: TEdit
    Left = 217
    Top = 41
    Width = 224
    Height = 21
    TabOrder = 5
    Visible = False
  end
  object StaticText1: TStaticText
    Left = 634
    Top = 210
    Width = 4
    Height = 4
    TabOrder = 6
  end
  object ProgressBar1: TProgressBar
    Left = 625
    Top = 339
    Width = 121
    Height = 17
    TabOrder = 7
  end
  object GroupBox2: TGroupBox
    Left = 25
    Top = 183
    Width = 582
    Height = 146
    Caption = 'Structural effects'
    TabOrder = 8
    object Label6: TLabel
      Left = 28
      Top = 18
      Width = 80
      Height = 13
      Caption = 'Source Network:'
    end
    object Label7: TLabel
      Left = 264
      Top = 18
      Width = 83
      Height = 13
      Caption = 'Relational Effect:'
    end
    object AttribBtn: TSpeedButton
      Left = 530
      Top = 75
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = AttribBtnClick
    end
    object Label8: TLabel
      Left = 25
      Top = 99
      Width = 83
      Height = 13
      Caption = 'Source Attribute:'
    end
    object Label9: TLabel
      Left = 264
      Top = 99
      Width = 112
      Height = 13
      Caption = 'Attribute-based Effect:'
    end
    object Source: TComboBox
      Left = 25
      Top = 34
      Width = 220
      Height = 21
      TabOrder = 0
      Text = 'Source'
    end
    object Effect: TComboBox
      Left = 264
      Top = 34
      Width = 197
      Height = 21
      TabOrder = 1
      Text = 'Effect'
      Items.Strings = (
        'Reciprocity'
        'Transitivity (Closure)'
        'Cyclicity'
        'Preferential Attachment'
        'AIC out'
        'AIC in'
        'Reciprocal distance')
    end
    object AddBtn: TButton
      Left = 478
      Top = 34
      Width = 75
      Height = 25
      Caption = 'Add'
      TabOrder = 2
      OnClick = AddBtnClick
    end
    object attribfn: TLabeledEdit
      Left = 25
      Top = 74
      Width = 499
      Height = 21
      EditLabel.Width = 171
      EditLabel.Height = 13
      EditLabel.Caption = 'Dataset containing node attributes:'
      TabOrder = 3
      OnChange = attribfnChange
    end
    object AttribSource: TComboBox
      Left = 25
      Top = 113
      Width = 220
      Height = 21
      TabOrder = 4
      Text = 'Source'
    end
    object AttribEffect: TComboBox
      Left = 264
      Top = 113
      Width = 197
      Height = 21
      ItemIndex = 1
      TabOrder = 5
      Text = 'of receiver'
      Items.Strings = (
        'of sender'
        'of receiver'
        'homophily (categorical)'
        'homophily (absolute difference)'
        'homophily (difference)'
        'homophily (squared diff)'
        'sum'
        'product'
        'count in dyad')
    end
    object AttribAddBtn: TButton
      Left = 478
      Top = 110
      Width = 75
      Height = 25
      Caption = 'Add'
      TabOrder = 6
      OnClick = AttribAddBtnClick
    end
  end
  object GroupBox3: TGroupBox
    Left = 25
    Top = 339
    Width = 582
    Height = 127
    Caption = 'Permutations'
    TabOrder = 9
    DesignSize = (
      582
      127)
    object PartitionBtn: TSpeedButton
      Left = 530
      Top = 38
      Width = 23
      Height = 22
      Caption = '..'
      OnClick = PartitionBtnClick
    end
    object Label10: TLabel
      Left = 24
      Top = 71
      Width = 139
      Height = 13
      Alignment = taRightJustify
      Caption = 'No. of random permutations:'
    end
    object Label11: TLabel
      Left = 45
      Top = 100
      Width = 118
      Height = 13
      Alignment = taRightJustify
      AutoSize = False
      Caption = 'Random Number Seed:'
    end
    object PartitionFn: TLabeledEdit
      Left = 25
      Top = 38
      Width = 499
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 340
      EditLabel.Height = 13
      EditLabel.Caption = 
        'Optional partition -- permutations will be performed only within' +
        ' classes:'
      TabOrder = 0
    end
    object noperms: TEdit
      Left = 175
      Top = 65
      Width = 41
      Height = 21
      TabOrder = 1
      Text = '5000'
    end
    object randomseed: TEdit
      Left = 175
      Top = 92
      Width = 41
      Height = 21
      TabOrder = 2
      Text = '32767'
    end
    object pMethod: TRadioGroup
      Left = 239
      Top = 65
      Width = 123
      Height = 52
      Anchors = [akTop, akRight]
      Caption = 'Statistics to Track:'
      ItemIndex = 1
      Items.Strings = (
        'Betas'
        'T-Statistics')
      TabOrder = 3
    end
    object UseParallel: TCheckBox
      Left = 437
      Top = 15
      Width = 97
      Height = 17
      Caption = ' Parallel'
      Checked = True
      State = cbChecked
      TabOrder = 4
    end
  end
  object GroupBox1: TGroupBox
    Left = 25
    Top = 477
    Width = 582
    Height = 124
    Caption = 'Output datasets'
    TabOrder = 10
    DesignSize = (
      582
      124)
    object SpeedButton3: TSpeedButton
      Left = 252
      Top = 34
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton3Click
    end
    object SpeedButton4: TSpeedButton
      Left = 526
      Top = 35
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton4Click
    end
    object SpeedButton5: TSpeedButton
      Left = 252
      Top = 80
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton5Click
    end
    object SpeedButton6: TSpeedButton
      Left = 526
      Top = 79
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton6Click
    end
    object dlg_efn: TLabeledEdit
      Left = 24
      Top = 34
      Width = 222
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 128
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Predicted Values:'
      TabOrder = 0
    end
    object dlg_rfn: TLabeledEdit
      Left = 299
      Top = 35
      Width = 221
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 94
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Residuals:'
      TabOrder = 1
    end
    object ModelFitFn: TLabeledEdit
      Left = 24
      Top = 80
      Width = 221
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 135
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Model fit statistics:'
      TabOrder = 2
    end
    object CoefficientsFn: TLabeledEdit
      Left = 298
      Top = 81
      Width = 222
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 102
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Coefficients'
      TabOrder = 3
    end
  end
  object pvalues: TRadioGroup
    Left = 660
    Top = 140
    Width = 73
    Height = 57
    Caption = 'P-values'
    ItemIndex = 1
    Items.Strings = (
      '1-tailed'
      '2-tailed')
    TabOrder = 11
  end
end
