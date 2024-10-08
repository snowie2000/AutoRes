object frmAutoRes: TfrmAutoRes
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Auto Resolution'
  ClientHeight = 345
  ClientWidth = 492
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    492
    345)
  PixelsPerInch = 96
  TextHeight = 13
  object grp1: TGroupBox
    Left = 8
    Top = 8
    Width = 476
    Height = 57
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Target resolution'
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 0
    ExplicitWidth = 481
    DesignSize = (
      476
      57)
    object lbl1: TLabel
      Left = 16
      Top = 24
      Width = 54
      Height = 13
      Caption = 'Resolution:'
    end
    object lbl11: TLabel
      Left = 260
      Top = 24
      Width = 21
      Height = 13
      Anchors = [akTop, akRight]
      Caption = 'DPI:'
      ExplicitLeft = 328
    end
    object cbbRes: TComboBox
      Left = 96
      Top = 21
      Width = 145
      Height = 21
      Style = csDropDownList
      TabOrder = 0
    end
    object cbbDPI: TComboBox
      Left = 300
      Top = 21
      Width = 145
      Height = 21
      Style = csDropDownList
      Anchors = [akTop, akRight]
      TabOrder = 1
      ExplicitLeft = 305
    end
  end
  object grp2: TGroupBox
    Left = 8
    Top = 75
    Width = 476
    Height = 98
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Exit action'
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 1
    ExplicitWidth = 481
    DesignSize = (
      476
      98)
    object lbl12: TLabel
      Left = 16
      Top = 58
      Width = 54
      Height = 13
      Caption = 'Resolution:'
      Enabled = False
    end
    object lbl111: TLabel
      Left = 260
      Top = 58
      Width = 21
      Height = 13
      Anchors = [akTop, akRight]
      Caption = 'DPI:'
      Enabled = False
      ExplicitLeft = 328
    end
    object rbRevert: TRadioButton
      Left = 16
      Top = 24
      Width = 145
      Height = 17
      Caption = 'Revert to initial state'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = rbKeepClick
    end
    object rbKeep: TRadioButton
      Left = 163
      Top = 24
      Width = 115
      Height = 17
      Caption = 'Keep target state'
      TabOrder = 1
      OnClick = rbKeepClick
    end
    object rbCustom: TRadioButton
      Left = 293
      Top = 24
      Width = 177
      Height = 17
      Caption = 'Change to specific resolution'
      TabOrder = 2
      OnClick = rbCustomClick
    end
    object cbbRes1: TComboBox
      Left = 96
      Top = 55
      Width = 145
      Height = 21
      Style = csDropDownList
      Enabled = False
      TabOrder = 3
    end
    object cbbDPI1: TComboBox
      Left = 300
      Top = 55
      Width = 145
      Height = 21
      Style = csDropDownList
      Anchors = [akTop, akRight]
      Enabled = False
      TabOrder = 4
      ExplicitLeft = 305
    end
  end
  object grp3: TGroupBox
    Left = 8
    Top = 184
    Width = 477
    Height = 114
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Application'
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 2
    ExplicitWidth = 482
    DesignSize = (
      477
      114)
    object lbl2: TLabel
      Left = 16
      Top = 24
      Width = 56
      Height = 13
      Caption = 'Application:'
    end
    object lbl3: TLabel
      Left = 16
      Top = 53
      Width = 59
      Height = 13
      Caption = 'Parameters:'
    end
    object lbl4: TLabel
      Left = 16
      Top = 82
      Width = 41
      Height = 13
      Caption = 'Workdir:'
    end
    object edtApp: TEdit
      Left = 96
      Top = 21
      Width = 272
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      ExplicitWidth = 277
    end
    object btn1: TButton
      Left = 374
      Top = 18
      Width = 71
      Height = 24
      Anchors = [akRight]
      Caption = 'Browse...'
      TabOrder = 1
      OnClick = btn1Click
      ExplicitLeft = 379
    end
    object edtParam: TEdit
      Left = 96
      Top = 50
      Width = 349
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 2
      ExplicitWidth = 354
    end
    object edtDir: TEdit
      Left = 96
      Top = 79
      Width = 349
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 3
      ExplicitWidth = 354
    end
  end
  object btnOk: TButton
    Left = 325
    Top = 312
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Save'
    Default = True
    TabOrder = 3
    OnClick = btnOkClick
    ExplicitLeft = 330
    ExplicitTop = 316
  end
  object btnClose: TButton
    Left = 409
    Top = 312
    Width = 75
    Height = 25
    Anchors = []
    Caption = 'Close'
    TabOrder = 4
    OnClick = btnCloseClick
    ExplicitLeft = 414
    ExplicitTop = 316
  end
end
