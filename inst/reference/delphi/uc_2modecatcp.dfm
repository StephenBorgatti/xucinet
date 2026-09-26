object twomodecatcp: Ttwomodecatcp
  Left = 0
  Top = 0
  Caption = ' 2-mode Categorical Core/Periphery Model'
  ClientHeight = 352
  ClientWidth = 716
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object OKBtn: TBitBtn
    Left = 625
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
    Left = 625
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
    Left = 625
    Top = 109
    Width = 73
    Height = 27
    HelpContext = 4380
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 2
    IsControl = True
  end
  object GroupBox1: TGroupBox
    Left = 18
    Top = 24
    Width = 593
    Height = 165
    Caption = 'Files'
    TabOrder = 3
    DesignSize = (
      593
      165)
    object inputfnspeedbutton: TSpeedButton
      Left = 557
      Top = 36
      Width = 20
      Height = 20
      Anchors = [akTop, akRight]
      Caption = '...'
      OnClick = inputfnspeedbuttonClick
    end
    object SpeedButton1: TSpeedButton
      Left = 557
      Top = 82
      Width = 20
      Height = 20
      Anchors = [akTop, akRight]
      Caption = '...'
      OnClick = SpeedButton1Click
    end
    object SpeedButton2: TSpeedButton
      Left = 557
      Top = 128
      Width = 20
      Height = 20
      Anchors = [akTop, akRight]
      Caption = '...'
      OnClick = SpeedButton2Click
    end
    object ifn: TLabeledEdit
      Left = 24
      Top = 36
      Width = 527
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 119
      EditLabel.Height = 13
      EditLabel.Caption = '(Input) 2-mode network:'
      TabOrder = 0
      OnChange = ifnChange
    end
    object rfn: TLabeledEdit
      Left = 24
      Top = 81
      Width = 527
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 113
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Row Partition:'
      TabOrder = 1
    end
    object cfn: TLabeledEdit
      Left = 24
      Top = 128
      Width = 527
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 107
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Col Partition:'
      TabOrder = 2
    end
  end
  object GroupBox2: TGroupBox
    Left = 18
    Top = 214
    Width = 593
    Height = 119
    Caption = 'Options for Genetic Algorithm'
    TabOrder = 4
    object MaxIterations: TLabeledEdit
      Left = 24
      Top = 38
      Width = 121
      Height = 21
      Hint = 'Bigger is better'
      EditLabel.Width = 84
      EditLabel.Height = 13
      EditLabel.Caption = 'Max generations:'
      NumbersOnly = True
      TabOrder = 0
      Text = '1000'
    end
    object PopulationSize: TLabeledEdit
      Left = 24
      Top = 82
      Width = 121
      Height = 21
      Hint = 'Bigger is better'
      EditLabel.Width = 75
      EditLabel.Height = 13
      EditLabel.Caption = 'Population size:'
      NumbersOnly = True
      TabOrder = 1
      Text = '250'
    end
    object StopAfter: TLabeledEdit
      Left = 186
      Top = 38
      Width = 121
      Height = 21
      Hint = 'Bigger is better'
      EditLabel.Width = 233
      EditLabel.Height = 13
      EditLabel.Caption = 'Stop after ___ generations with no improvement'
      NumbersOnly = True
      TabOrder = 2
      Text = '2'
    end
    object AuxiliaryGens: TLabeledEdit
      Left = 186
      Top = 82
      Width = 121
      Height = 21
      Hint = 'Bigger is better'
      EditLabel.Width = 115
      EditLabel.Height = 13
      EditLabel.Caption = 'Max auxiliary iterations:'
      NumbersOnly = True
      TabOrder = 3
      Text = '6'
    end
  end
end
