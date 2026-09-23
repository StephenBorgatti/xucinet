object EigenvectorCentrality: TEigenvectorCentrality
  Left = 0
  Top = 0
  Caption = 'Eigenvector Centrality'
  ClientHeight = 354
  ClientWidth = 711
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 22
    Top = 173
    Width = 561
    Height = 42
    Caption = 
      'Note: This routine automatically symmetrizes data. If your data ' +
      'are not symmetric, we suggest using beta centrallity instead. Ho' +
      'wever, if you absolutely insist on using eigenvectors, you can g' +
      'o to Tools|Scaling|Eigenvectors. Be prepared for complex numbers' +
      '.  '
    WordWrap = True
  end
  object GroupBox1: TGroupBox
    Left = 22
    Top = 20
    Width = 573
    Height = 133
    Caption = 'Files'
    TabOrder = 0
    DesignSize = (
      573
      133)
    object SpeedButton1: TSpeedButton
      Left = 532
      Top = 36
      Width = 23
      Height = 22
      Anchors = [akTop, akRight]
      Caption = '...'
      OnClick = SpeedButton1Click
      ExplicitLeft = 488
    end
    object SpeedButton2: TSpeedButton
      Left = 532
      Top = 85
      Width = 23
      Height = 22
      Anchors = [akTop, akRight]
      Caption = '...'
      OnClick = SpeedButton2Click
      ExplicitLeft = 488
    end
    object InputFn: TLabeledEdit
      Left = 21
      Top = 36
      Width = 505
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 73
      EditLabel.Height = 13
      EditLabel.Caption = 'Input Network:'
      TabOrder = 0
      OnChange = InputFnChange
    end
    object OutputFn: TLabeledEdit
      Left = 21
      Top = 86
      Width = 505
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 87
      EditLabel.Height = 13
      EditLabel.Caption = 'Output Measures:'
      TabOrder = 1
    end
  end
  object OKBtn: TBitBtn
    Left = 615
    Top = 43
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
    Left = 615
    Top = 76
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
    Left = 615
    Top = 109
    Width = 73
    Height = 27
    HelpContext = 4275
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 3
    IsControl = True
  end
  object Normalization: TRadioGroup
    Left = 22
    Top = 229
    Width = 185
    Height = 108
    Caption = 'Normalization'
    ItemIndex = 0
    Items.Strings = (
      'Euc. norm = 1'
      'Sum of values = N'
      'Div by max possible'
      'Div by max observed'
      'SSQ = N')
    TabOrder = 4
  end
  object makepositive: TCheckBox
    Left = 240
    Top = 245
    Width = 193
    Height = 17
    Caption = '  Make majority of scores positive'
    Checked = True
    State = cbChecked
    TabOrder = 5
  end
  object ConvertData: TCheckBox
    Left = 240
    Top = 268
    Width = 355
    Height = 17
    Caption = 
      ' Convert data to reciprocals of geodesics prior to computing cen' +
      'trality'
    TabOrder = 6
  end
end
