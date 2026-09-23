object LouvainMethod: TLouvainMethod
  Left = 0
  Top = 0
  Caption = ' Louvain Community Detection'
  ClientHeight = 359
  ClientWidth = 730
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    730
    359)
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 19
    Top = 17
    Width = 588
    Height = 176
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Files'
    TabOrder = 0
    DesignSize = (
      588
      176)
    object Inputfnbtn: TSpeedButton
      Left = 538
      Top = 38
      Width = 22
      Height = 22
      Anchors = [akTop, akRight]
      Caption = '...'
      OnClick = InputfnbtnClick
      ExplicitLeft = 428
    end
    object evalbtn: TSpeedButton
      Left = 538
      Top = 128
      Width = 22
      Height = 22
      Anchors = [akTop, akRight]
      Caption = '...'
      OnClick = evalbtnClick
    end
    object SpeedButton1: TSpeedButton
      Left = 538
      Top = 82
      Width = 22
      Height = 22
      Anchors = [akTop, akRight]
      Caption = '...'
      OnClick = evalbtnClick
    end
    object Label1: TLabel
      Left = 408
      Top = 66
      Width = 70
      Height = 13
      Caption = 'Which column?'
    end
    object InputFn: TLabeledEdit
      Left = 28
      Top = 39
      Width = 504
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 114
      EditLabel.Height = 13
      EditLabel.Caption = 'Input Network Dataset:'
      TabOrder = 0
      OnChange = InputFnChange
    end
    object Outputfn: TLabeledEdit
      Left = 28
      Top = 129
      Width = 504
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 90
      EditLabel.Height = 13
      EditLabel.Caption = '(Output) Partitions'
      TabOrder = 1
      Text = 'LouvainPart'
    end
    object StartingPartitionFn: TLabeledEdit
      Left = 28
      Top = 83
      Width = 371
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 163
      EditLabel.Height = 13
      EditLabel.Caption = '(Optional input) Starting partition:'
      TabOrder = 2
      OnChange = StartingPartitionFnChange
    end
    object StartingCol: TComboBox
      Left = 408
      Top = 83
      Width = 124
      Height = 21
      TabOrder = 3
      Text = 'StartingCol'
    end
  end
  object OKBtn: TBitBtn
    Left = 634
    Top = 28
    Width = 71
    Height = 27
    Anchors = [akTop, akRight]
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
    Left = 634
    Top = 61
    Width = 71
    Height = 27
    Anchors = [akTop, akRight]
    Caption = '&Cancel'
    Kind = bkCancel
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 2
    IsControl = True
  end
  object HelpBtn: TBitBtn
    Left = 634
    Top = 94
    Width = 71
    Height = 27
    HelpContext = 4105
    Anchors = [akTop, akRight]
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 3
    IsControl = True
  end
  object GroupBox2: TGroupBox
    Left = 19
    Top = 212
    Width = 588
    Height = 128
    Caption = 'Options'
    TabOrder = 4
    object MaxPartitions: TLabeledEdit
      Left = 28
      Top = 44
      Width = 121
      Height = 21
      EditLabel.Width = 72
      EditLabel.Height = 13
      EditLabel.Caption = 'Max partitions:'
      TabOrder = 0
    end
    object symmetrize: TRadioGroup
      Left = 180
      Top = 12
      Width = 185
      Height = 109
      Caption = 'For directed data:'
      ItemIndex = 1
      Items.Strings = (
        'Do not symmetrize'
        'Maximum/union'
        'Minimum/intersection'
        'Average'
        'Sum')
      TabOrder = 1
    end
  end
end
