object GirvanNewman: TGirvanNewman
  Left = 0
  Top = 0
  Caption = ' Girvan-Newman Clustering'
  ClientHeight = 254
  ClientWidth = 754
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 24
    Top = 16
    Width = 610
    Height = 124
    Caption = 'Files'
    TabOrder = 0
    object SpeedButton1: TSpeedButton
      Left = 566
      Top = 34
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton1Click
    end
    object SpeedButton5: TSpeedButton
      Left = 566
      Top = 78
      Width = 23
      Height = 22
      Caption = '...'
      OnClick = SpeedButton5Click
    end
    object SpeedButton2: TSpeedButton
      Left = 566
      Top = 126
      Width = 23
      Height = 22
      Caption = '...'
    end
    object InputFn: TLabeledEdit
      Left = 24
      Top = 34
      Width = 530
      Height = 21
      EditLabel.Width = 70
      EditLabel.Height = 13
      EditLabel.Caption = 'Input dataset:'
      TabOrder = 0
      OnChange = InputFnChange
    end
    object OutputFn: TLabeledEdit
      Left = 24
      Top = 78
      Width = 530
      Height = 21
      EditLabel.Width = 178
      EditLabel.Height = 13
      EditLabel.Caption = 'Output dataset containing partitions:'
      TabOrder = 1
    end
  end
  object BitBtn1: TBitBtn
    Left = 658
    Top = 33
    Width = 75
    Height = 27
    Kind = bkOK
    NumGlyphs = 2
    TabOrder = 1
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 658
    Top = 66
    Width = 75
    Height = 27
    Kind = bkCancel
    NumGlyphs = 2
    TabOrder = 2
  end
  object HelpBtn: TBitBtn
    Left = 658
    Top = 99
    Width = 75
    Height = 27
    HelpContext = 4119
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 3
    IsControl = True
  end
  object GroupBox2: TGroupBox
    Left = 24
    Top = 156
    Width = 610
    Height = 75
    Caption = 'Options'
    TabOrder = 4
    object Label1: TLabel
      Left = 22
      Top = 34
      Width = 172
      Height = 13
      Caption = 'Output partitions with no more than'
    end
    object Label3: TLabel
      Left = 233
      Top = 34
      Width = 41
      Height = 13
      Caption = 'clusters.'
    end
    object MaxClus: TEdit
      Left = 200
      Top = 31
      Width = 27
      Height = 21
      Hint = 'Maximum number of clusters'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      Text = '10'
    end
  end
end
