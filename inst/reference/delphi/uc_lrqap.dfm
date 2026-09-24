object LogisticQap: TLogisticQap
  Left = 0
  Top = 0
  Caption = '  LR-QAP -- Logistic Regression QAP (Y-permutation)'
  ClientHeight = 555
  ClientWidth = 883
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
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
    Left = 560
    Top = 29
    Width = 23
    Height = 22
    Caption = '...'
    OnClick = SpeedButton1Click
  end
  object Label2: TLabel
    Left = 25
    Top = 62
    Width = 154
    Height = 13
    Caption = 'Independent Variables (dyadic):'
  end
  object SpeedButton2: TSpeedButton
    Left = 560
    Top = 81
    Width = 23
    Height = 22
    Caption = '...'
    OnClick = SpeedButton2Click
  end
  object SpeedButton3: TSpeedButton
    Left = 560
    Top = 513
    Width = 23
    Height = 22
    Caption = '...'
    Visible = False
    OnClick = SpeedButton3Click
  end
  object SpeedButton5: TSpeedButton
    Left = 560
    Top = 418
    Width = 23
    Height = 22
    Caption = '...'
    OnClick = SpeedButton5Click
  end
  object SpeedButton6: TSpeedButton
    Left = 560
    Top = 465
    Width = 23
    Height = 22
    Caption = '...'
    OnClick = SpeedButton6Click
  end
  object Label5: TLabel
    Left = 632
    Top = 208
    Width = 201
    Height = 52
    Caption = 
      'Note: Independent variables can be stacked in a single dataset i' +
      'f no relational effects are being used. Otherwise, enter them as' +
      ' separate datasets'
    WordWrap = True
  end
  object SpeedButton7: TSpeedButton
    Left = 560
    Top = 109
    Width = 23
    Height = 22
    Caption = 'C'
    OnClick = SpeedButton7Click
  end
  object Label6: TLabel
    Left = 25
    Top = 256
    Width = 80
    Height = 13
    Caption = 'Source Network:'
  end
  object Label7: TLabel
    Left = 264
    Top = 256
    Width = 83
    Height = 13
    Caption = 'Relational Effect:'
  end
  object AttribBtn: TSpeedButton
    Left = 560
    Top = 322
    Width = 23
    Height = 22
    Caption = '...'
    OnClick = AttribBtnClick
  end
  object Label8: TLabel
    Left = 25
    Top = 354
    Width = 83
    Height = 13
    Caption = 'Source Attribute:'
  end
  object Label9: TLabel
    Left = 264
    Top = 354
    Width = 112
    Height = 13
    Caption = 'Attribute-based Effect:'
  end
  object InputInd: TMemo
    Left = 25
    Top = 81
    Width = 529
    Height = 163
    ScrollBars = ssVertical
    TabOrder = 1
    WordWrap = False
    OnChange = InputIndChange
  end
  object inputdep: TLabeledEdit
    Left = 25
    Top = 30
    Width = 529
    Height = 21
    EditLabel.Width = 140
    EditLabel.Height = 13
    EditLabel.Caption = 'Dependent Variable (dyadic):'
    TabOrder = 0
    OnChange = inputdepChange
  end
  object GroupBox1: TGroupBox
    Left = 632
    Top = 28
    Width = 221
    Height = 85
    Caption = 'Options:'
    TabOrder = 5
    object Label3: TLabel
      Left = 7
      Top = 27
      Width = 139
      Height = 13
      Alignment = taRightJustify
      Caption = 'No. of random permutations:'
    end
    object Label4: TLabel
      Left = 28
      Top = 56
      Width = 118
      Height = 13
      Alignment = taRightJustify
      AutoSize = False
      Caption = 'Random Number Seed:'
    end
    object noperms: TEdit
      Left = 152
      Top = 21
      Width = 51
      Height = 21
      TabOrder = 0
      Text = '1000'
    end
    object randomseed: TEdit
      Left = 152
      Top = 48
      Width = 51
      Height = 21
      TabOrder = 1
      Text = '32767'
    end
  end
  object PredFn: TLabeledEdit
    Left = 25
    Top = 514
    Width = 529
    Height = 21
    EditLabel.Width = 128
    EditLabel.Height = 13
    EditLabel.Caption = '(Output) Predicted Values:'
    TabOrder = 2
    Visible = False
  end
  object pMethod: TRadioGroup
    Left = 632
    Top = 133
    Width = 111
    Height = 57
    Caption = 'Statistics to Track:'
    ItemIndex = 1
    Items.Strings = (
      'Betas'
      'T-Statistics')
    TabOrder = 6
  end
  object OKBtn: TBitBtn
    Left = 632
    Top = 367
    Width = 73
    Height = 27
    Caption = '&OK'
    Kind = bkOK
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 8
    OnClick = OKBtnClick
    IsControl = True
  end
  object CancelBtn: TBitBtn
    Left = 705
    Top = 368
    Width = 73
    Height = 27
    Caption = '&Cancel'
    Kind = bkCancel
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 7
    IsControl = True
  end
  object HelpBtn: TBitBtn
    Left = 780
    Top = 368
    Width = 73
    Height = 27
    HelpContext = 3111
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 9
    IsControl = True
  end
  object inputindedit: TEdit
    Left = 632
    Top = 485
    Width = 224
    Height = 21
    TabOrder = 10
    Visible = False
  end
  object Fitfn: TLabeledEdit
    Left = 25
    Top = 418
    Width = 529
    Height = 21
    EditLabel.Width = 135
    EditLabel.Height = 13
    EditLabel.Caption = '(Output) Model fit statistics:'
    TabOrder = 3
  end
  object CoefFn: TLabeledEdit
    Left = 25
    Top = 465
    Width = 529
    Height = 21
    EditLabel.Width = 102
    EditLabel.Height = 13
    EditLabel.Caption = '(Output) Coefficients'
    TabOrder = 4
  end
  object StaticText1: TStaticText
    Left = 632
    Top = 208
    Width = 4
    Height = 4
    TabOrder = 11
  end
  object datatype: TRadioGroup
    Left = 632
    Top = 286
    Width = 221
    Height = 65
    Caption = 'Data are:'
    ItemIndex = 1
    Items.Strings = (
      'Symmetric (undirected)'
      'Non-Symmetric (directed)')
    TabOrder = 12
  end
  object ProgressBar1: TProgressBar
    Left = 632
    Top = 407
    Width = 221
    Height = 17
    TabOrder = 13
  end
  object Source: TComboBox
    Left = 25
    Top = 272
    Width = 220
    Height = 21
    TabOrder = 14
    Text = 'Source'
  end
  object Effect: TComboBox
    Left = 264
    Top = 272
    Width = 197
    Height = 21
    TabOrder = 15
    Text = 'Effect'
    Items.Strings = (
      'Reciprocity'
      'Transitivity (Closure)'
      'Cyclicity'
      'Preferential Attachment'
      'Common alters (outgoing)'
      'Common alters (incoming)'
      'Reciprocal distance')
  end
  object AddBtn: TButton
    Left = 479
    Top = 270
    Width = 75
    Height = 25
    Caption = 'Add'
    TabOrder = 16
    OnClick = AddBtnClick
  end
  object attribfn: TLabeledEdit
    Left = 25
    Top = 322
    Width = 529
    Height = 21
    EditLabel.Width = 171
    EditLabel.Height = 13
    EditLabel.Caption = 'Dataset containing node attributes:'
    TabOrder = 17
    OnChange = attribfnChange
  end
  object AttribSource: TComboBox
    Left = 25
    Top = 370
    Width = 220
    Height = 21
    TabOrder = 18
    Text = 'Source'
  end
  object AttribEffect: TComboBox
    Left = 264
    Top = 370
    Width = 197
    Height = 21
    TabOrder = 19
    Text = 'Effect'
    Items.Strings = (
      'of sender'
      'of receiver'
      'homophily (categorical)'
      'homophily (absolute difference)'
      'homophily (difference)'
      'homophily (squared diff)'
      'sum'
      'product')
  end
  object AttribAddBtn: TButton
    Left = 479
    Top = 368
    Width = 75
    Height = 25
    Caption = 'Add'
    TabOrder = 20
    OnClick = AttribAddBtnClick
  end
  object UseParallel: TCheckBox
    Left = 632
    Top = 445
    Width = 97
    Height = 17
    Caption = ' Parallel'
    Checked = True
    State = cbChecked
    TabOrder = 21
  end
  object UseNormalApprox: TCheckBox
    Left = 756
    Top = 445
    Width = 97
    Height = 17
    Caption = 'Normal approx.'
    TabOrder = 22
  end
  object pvalues: TRadioGroup
    Left = 762
    Top = 133
    Width = 94
    Height = 57
    Caption = 'P-values'
    ItemIndex = 1
    Items.Strings = (
      '1-tailed'
      '2-tailed')
    TabOrder = 23
  end
end
