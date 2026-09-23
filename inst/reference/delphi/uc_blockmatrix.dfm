object blockmatrix: Tblockmatrix
  Left = 0
  Top = 0
  Caption = ' Block - Aggregate matrix by partition'
  ClientHeight = 381
  ClientWidth = 786
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnDeactivate = FormDeactivate
  PixelsPerInch = 96
  TextHeight = 13
  object OKBtn: TBitBtn
    Left = 689
    Top = 72
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
    Left = 689
    Top = 105
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
    Left = 689
    Top = 138
    Width = 73
    Height = 27
    HelpContext = 3990
    Kind = bkHelp
    Margin = 2
    NumGlyphs = 2
    Spacing = -1
    TabOrder = 2
    IsControl = True
  end
  object GroupBox1: TGroupBox
    Left = 18
    Top = 14
    Width = 647
    Height = 205
    Caption = 'Files'
    TabOrder = 3
    DesignSize = (
      647
      205)
    object Label9: TLabel
      Left = 19
      Top = 20
      Width = 70
      Height = 13
      Alignment = taRightJustify
      Caption = 'Input dataset:'
    end
    object inputfnspeedbutton: TSpeedButton
      Left = 519
      Top = 35
      Width = 20
      Height = 20
      Anchors = [akTop, akRight]
      Caption = '...'
      OnClick = inputfnspeedbuttonClick
    end
    object Label2: TLabel
      Left = 19
      Top = 62
      Width = 300
      Height = 13
      Alignment = taRightJustify
      Caption = 'Dataset containing Row Partition (which defines set of nodes):'
    end
    object RowSpeedButton: TSpeedButton
      Left = 386
      Top = 77
      Width = 20
      Height = 20
      Anchors = [akTop, akRight]
      Caption = '...'
      OnClick = RowSpeedButtonClick
    end
    object Label3: TLabel
      Left = 19
      Top = 105
      Width = 305
      Height = 13
      Alignment = taRightJustify
      Caption = 'Dataset containing Column Partition (defining groups of nodes):'
    end
    object ColumnSpeedButton: TSpeedButton
      Left = 386
      Top = 121
      Width = 20
      Height = 20
      Anchors = [akTop, akRight]
      Caption = '...'
      OnClick = ColumnSpeedButtonClick
    end
    object SpeedButton2: TSpeedButton
      Left = 519
      Top = 76
      Width = 16
      Height = 21
      Anchors = [akTop, akRight]
      Caption = 'C'
      OnClick = SpeedButton2Click
    end
    object SpeedButton4: TSpeedButton
      Left = 538
      Top = 77
      Width = 16
      Height = 21
      Anchors = [akTop, akRight]
      Caption = 'I'
      OnClick = SpeedButton4Click
    end
    object SpeedButton5: TSpeedButton
      Left = 519
      Top = 120
      Width = 16
      Height = 21
      Anchors = [akTop, akRight]
      Caption = 'C'
      OnClick = SpeedButton5Click
    end
    object SpeedButton6: TSpeedButton
      Left = 538
      Top = 120
      Width = 16
      Height = 21
      Anchors = [akTop, akRight]
      Caption = 'I'
      OnClick = SpeedButton6Click
    end
    object SpeedButton1: TSpeedButton
      Left = 519
      Top = 167
      Width = 20
      Height = 20
      Anchors = [akTop, akRight]
      Caption = '...'
      OnClick = SpeedButton1Click
    end
    object InputFn: TEdit
      Left = 19
      Top = 35
      Width = 494
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      OnChange = InputFnChange
    end
    object RowFn: TEdit
      Left = 19
      Top = 78
      Width = 361
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
      OnChange = RowFnChange
    end
    object ColFn: TEdit
      Left = 19
      Top = 124
      Width = 361
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 2
      OnChange = ColFnChange
    end
    object RowLabels: TComboBox
      Left = 419
      Top = 76
      Width = 94
      Height = 21
      Anchors = [akTop, akRight]
      TabOrder = 3
      Text = 'RowLabels'
      OnChange = RowLabelsChange
    end
    object ColLabels: TComboBox
      Left = 419
      Top = 120
      Width = 94
      Height = 21
      Anchors = [akTop, akRight]
      TabOrder = 4
      Text = 'ColLabels'
      OnChange = ColLabelsChange
    end
    object Outputfn: TLabeledEdit
      Left = 19
      Top = 167
      Width = 494
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 78
      EditLabel.Height = 13
      EditLabel.Caption = 'Output dataset:'
      TabOrder = 5
    end
    object Button2: TButton
      Left = 560
      Top = 77
      Width = 73
      Height = 21
      Anchors = [akTop, akRight]
      Caption = 'Value Labels'
      TabOrder = 6
      OnClick = Button2Click
    end
    object Button4: TButton
      Left = 560
      Top = 120
      Width = 73
      Height = 21
      Anchors = [akTop, akRight]
      Caption = 'Value Labels'
      TabOrder = 7
      OnClick = Button4Click
    end
  end
  object GroupBox3: TGroupBox
    Left = 18
    Top = 238
    Width = 647
    Height = 129
    Caption = 'Options'
    TabOrder = 4
    object Diagonal: TCheckBox
      Left = 19
      Top = 22
      Width = 173
      Height = 17
      Alignment = taLeftJustify
      Caption = 'Utilize diagonal (reflexive ties)'
      TabOrder = 0
    end
    object Button1: TButton
      Left = 19
      Top = 48
      Width = 87
      Height = 25
      Caption = 'Select groups'
      TabOrder = 1
      Visible = False
      OnClick = Button1Click
    end
    object MatchBy: TRadioGroup
      Left = 230
      Top = 24
      Width = 163
      Height = 57
      Caption = 'Match attributes by ...'
      ItemIndex = 1
      Items.Strings = (
        'Position'
        'Row/Column label')
      TabOrder = 2
    end
    object Method: TRadioGroup
      Left = 436
      Top = 18
      Width = 185
      Height = 95
      Caption = 'Method'
      Columns = 2
      ItemIndex = 0
      Items.Strings = (
        'Average'
        'Count > 0'
        'Maximum'
        'Minimum'
        'Std Deviation'
        'Sum')
      TabOrder = 3
    end
  end
  object OpenTextFileDialog1: TOpenTextFileDialog
    Left = 708
    Top = 220
  end
end
