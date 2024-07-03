unit uAutoRes;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, Generics.Collections,
  ExtCtrls;

type
  TRes = record
    nHeight, nWidth: Integer;
    nBits: Integer;
    nDPI: Integer;
  end;

  TCmd = record
    app: string;
    param: string;
    workdir: string;
    target: record
      dpi, height, width, depth: Integer;
    end;
    restore: record
      mode, dpi, height, width, depth: Integer;
    end;
  end;

  TfrmAutoRes = class(TForm)
    grp1: TGroupBox;
    lbl1: TLabel;
    cbbRes: TComboBox;
    lbl11: TLabel;
    cbbDPI: TComboBox;
    grp2: TGroupBox;
    rbRevert: TRadioButton;
    rbKeep: TRadioButton;
    rbCustom: TRadioButton;
    lbl12: TLabel;
    cbbRes1: TComboBox;
    cbbDPI1: TComboBox;
    lbl111: TLabel;
    grp3: TGroupBox;
    lbl2: TLabel;
    lbl3: TLabel;
    lbl4: TLabel;
    edtApp: TEdit;
    btn1: TButton;
    edtParam: TEdit;
    edtDir: TEdit;
    btnOk: TButton;
    btnClose: TButton;
    procedure FormCreate(Sender: TObject);
    procedure rbCustomClick(Sender: TObject);
    procedure rbKeepClick(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    { Private declarations }
    FResolutions: TArray<TRes>;
    procedure InitRes;
    procedure InitDPI;
    function CreateShortcut(sFilename: string): Boolean;
  public
    { Public declarations }
  end;

var
  frmAutoRes: TfrmAutoRes;

function RunFromCLI(): Boolean;

implementation

uses
  ShlObj, ActiveX, ComObj, superobject, uJson, EncdDecd, ShellAPI, SHDocVw, TlHelp32;

{$R *.dfm}

const
  SWC_DESKTOP = 8;
  IID_IServiceProvider: TGUID = '{64736444-DBCF-11CE-A3F5-00AA0044DEEE}';
  ENUM_CURRENT_SETTINGS = -1;
  SPI_SETLOGICALDPIOVERRIDE = $009F;
  SPI_GETLOGICALDPIOVERRIDE = $009E;
  DpiVals: array[0..11] of DWORD = (100, 125, 150, 175, 200, 225, 250, 300, 350, 400, 450, 500);

procedure FindDesktopFolderView(const RIID: TGUID; var PPV);
var
  ShellWindows: IShellWindows;
  Browser: IShellBrowser;
  Disp: IDispatch;
  ServiceProvider: IServiceProvider;
  View: IShellView;
  Loc: OleVariant;
  Empty: OleVariant;
  Wnd: Integer;
begin
  OleCheck(CoCreateInstance(CLASS_ShellWindows, nil, CLSCTX_ALL, IShellWindows, ShellWindows));

  Loc := CSIDL_DESKTOP;
  VarClear(Empty);
  Disp := ShellWindows.FindWindowSW(Loc, Empty, SWC_DESKTOP, Wnd, SWFO_NEEDDISPATCH);

  OleCheck(Disp.QueryInterface(IServiceProvider, ServiceProvider));
  OleCheck(ServiceProvider.QueryService(SID_STopLevelBrowser, IShellBrowser, Browser));
  OleCheck(Browser.QueryActiveShellView(View));
  OleCheck(View.QueryInterface(RIID, PPV));
end;

procedure GetDesktopAutomationObject(const RIID: TGUID; var PPV);
var
  SV: IShellView;
  DispView: IDispatch;
begin
  FindDesktopFolderView(IShellView, SV);
  OleCheck(SV.GetItemObject(SVGIO_BACKGROUND, IDispatch, Pointer(DispView)));
  OleCheck(DispView.QueryInterface(RIID, PPV));
end;

procedure ShellExecuteFromExplorer(const AFile: WideString; const AParameters: WideString = ''; const ADirectory:
  WideString = ''; const AOperation: WideString = ''; const AShowCmd: Cardinal = SW_SHOWNORMAL);
var
  FolderView: IShellFolderViewDual;
  DispShell: IDispatch;
  ShellDispatch: IShellDispatch2;
begin
  GetDesktopAutomationObject(IShellFolderViewDual, FolderView);
  OleCheck(FolderView.get_Application(DispShell));
  OleCheck(DispShell.QueryInterface(IShellDispatch2, ShellDispatch));
  OleCheck(ShellDispatch.ShellExecute(PWideChar(AFile), AParameters, ADirectory, AOperation, AShowCmd));
end;

function SnapShotProcessIdList(): TArray<TProcessEntry32>;
var
  hSnapshot: THandle;
  Entry: TProcessEntry32;
  ProcessList: TList<TProcessEntry32>;  // To store process IDs
begin
  ProcessList := TList<TProcessEntry32>.Create;
  try
    hSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if hSnapshot <> 0 then
    begin
      Entry.dwSize := SizeOf(Entry);
      if Process32First(hSnapshot, Entry) then
      begin
        repeat
          ProcessList.Add(Entry);
        until not Process32Next(hSnapshot, Entry);
      end;
      CloseHandle(hSnapshot);
    end;
    Result := ProcessList.ToArray();
  finally
    ProcessList.Free;
  end;
end;

procedure waitForPID(pid: DWORD);
var
  hProcess: THandle;
begin
  hProcess := OpenProcess(SYNCHRONIZE, false, pid);
  if hProcess <> 0 then
  begin
    WaitForSingleObject(hProcess, INFINITE);
    CloseHandle(hProcess);
  end
  else
  begin
    repeat
      Sleep(3000);
      hProcess := OpenProcess(SYNCHRONIZE, false, pid);
    until GetLastError <> ERROR_ACCESS_DENIED;
    if hProcess <> 0 then
      CloseHandle(hProcess);
  end;
end;

procedure changeDisplayResolution(nHeight, nWidth: Integer);
var
  DevMode: TDevMode;
  I: Integer;
  DP: TDisplayDevice;
begin
  // Fill the DevMode structure with current settings (important)
  FillChar(DevMode, SizeOf(DevMode), 0);
  FillChar(DP, sizeof(DP), 0);
  DevMode.dmSize := SizeOf(TDevMode);
  DP.cb := sizeof(DP);

//  for I := 0 to 99 do
//  begin
//    if (not EnumDisplayDevices(nil, I, DP, EDD_GET_DEVICE_INTERFACE_NAME)) then
//      break;

  EnumDisplaySettings(nil, DWORD(ENUM_CURRENT_SETTINGS), DevMode);

  // Set the new width and height in DevMode
  DevMode.dmPelsWidth := nWidth;
  DevMode.dmPelsHeight := nHeight;
  DevMode.dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;

  // Attempt to change the display settings
  if ChangeDisplaySettingsEx(nil, DevMode, 0, 0, nil) = DISP_CHANGE_SUCCESSFUL then
//      ShowMessage('Screen resolution changed successfully!')  // This might not happen due to lack of privileges

  else
    ShowMessage('Failed to change screen resolution!');
//  end;
end;

function getRecommandedDPI(): Integer;
var
  dpi: Integer;
  retval: Boolean;
begin
  Result := -1;
  dpi := 0;
  retval := SystemParametersInfo(SPI_GETLOGICALDPIOVERRIDE, 0, @dpi, 1);

  if (retval) then
  begin
    Result := DpiVals[dpi *  - 1];
  end;
end;

procedure changeDPI(DPI: Integer);
var
  recommendedDpi, oldIndex, newIndex: Integer;
  I: Integer;
begin
  recommendedDpi := getRecommandedDPI();
  if recommendedDpi > 0 then
  begin
    for I := Low(DpiVals) to High(DpiVals) do
    begin
      if DpiVals[I] = DPI then
        newIndex := I;
      if DpiVals[I] = recommendedDpi then
        oldIndex := I;
    end;
  end;
  SystemParametersInfo(SPI_SETLOGICALDPIOVERRIDE, newIndex - oldIndex, nil, SPIF_UPDATEINIFILE);
end;

function RunFromCLI(): Boolean;
var
  sCmd, sApp: string;
  cmd: TCmd;
  res: TRes;
  listBefore, listAfter: TArray<TProcessEntry32>;
  idSet: TDictionary<DWORD, Boolean>;
  I: Integer;
  targetPid: DWORD;
  bShouldWait, bShouldChange: Boolean;
begin
  Result := False;
  if not FindCmdLineSwitch('cmd', sCmd) then
    Exit;
  FillChar(cmd, sizeof(cmd), 0);
  sCmd := DecodeString(sCmd);
  JsonSerializer<TCmd>.FromJson(sCmd, cmd);
  if not FileExists(cmd.app) then
  begin
    MessageBox(0, PChar('"' + cmd.app + '" not found'), 'AutoRes', MB_OK or MB_ICONERROR);
    Exit;
  end;
  Result := True;
  bShouldWait := True;
  targetPid := 0;
  sApp := UpperCase(ExtractFileName(cmd.app));

  // check current resolution
  res.nHeight := Screen.Height;
  res.nWidth := Screen.Width;
  res.nDPI := Round(Screen.PixelsPerInch * 100 / 96);
  bShouldChange := (res.nHeight <> cmd.target.height) or (res.nWidth <> cmd.target.width) or (res.nDPI <> cmd.target.dpi);
  bShouldWait := (cmd.restore.mode <> 1) and bShouldChange;
  if bShouldChange then
  begin
    if res.nDPI <> cmd.target.dpi then
      changeDPI(cmd.target.dpi);
    changeDisplayResolution(cmd.target.height, cmd.target.width);
  end;
  // we are already at the optimal resolution, just launch the application and exit;
  if not bShouldWait then
  begin
    ShellExecuteFromExplorer(cmd.app, cmd.param, cmd.workdir);
    Exit;
  end;

  listBefore := SnapShotProcessIdList();
  ShellExecuteFromExplorer(cmd.app, cmd.param, cmd.workdir);
  listAfter := SnapShotProcessIdList();
  // find the newly created processid
  idSet := TDictionary<DWORD, Boolean>.Create;
  try
    for I := Low(listBefore) to High(listBefore) do
      idSet.Add(listBefore[I].th32ProcessID, true);
    for I := Low(listAfter) to High(listAfter) do
      if idSet.ContainsKey(listAfter[I].th32ProcessID) then
        Continue
      else if UpperCase(listAfter[I].szExeFile) = sApp then
      begin
        targetPid := listAfter[I].th32ProcessID;
        Break;
      end;
  finally
    idSet.Free;
  end;
  if targetPid <> 0 then
    waitForPID(targetPid);

  //time to restore
  case cmd.restore.mode of
    0:
      begin
        if cmd.target.dpi <> cmd.restore.dpi then
          changeDPI(res.nDPI);
        changeDisplayResolution(res.nHeight, res.nWidth);
      end;
    2:
      begin
        if res.nDPI <> cmd.target.dpi then
          changeDPI(res.nDPI);
        changeDisplayResolution(cmd.restore.height, cmd.restore.width);
      end;
  end;
end;

function makeResString(const res: TRes): string;
begin
  Result := Format('%d ¡Á %d @%dbit', [res.nWidth, res.nHeight, res.nBits]);
end;

function getAllResolutions(): TArray<TRes>;
var
  cnt, i: Integer;
  DevMode: TDevMode;
  DP: TDisplayDevice;
  modes: TList<TRes>;
  res: TRes;
  s: string;
  resSet: TDictionary<string, Boolean>;
begin
  modes := TList<TRes>.Create;
  resSet := TDictionary<string, Boolean>.Create;
  try
    cnt := 0;
    DP.cb := sizeof(DP);
    while EnumDisplayDevices(nil, cnt, DP, 0) do  // Loop through all monitors
    begin
    // Extract monitor name from DevMode.DeviceName
      if DP.DeviceName[0] = #0 then
        break;

    // Loop through display modes for the current monitor
      i := 0;
      DevMode.dmSize := sizeof(DevMode);
      while EnumDisplaySettings(DP.DeviceName, i, DevMode) do
      begin
        res.nWidth := DevMode.dmPelsWidth;
        res.nHeight := DevMode.dmPelsHeight;
        res.nBits := DevMode.dmBitsPerPel;
        s := makeResString(res);
        if not resSet.ContainsKey(s) then
        begin
          modes.Add(res);
          resSet.Add(s, true);
        end;
        Inc(i);
      end;
      Inc(cnt);
    end;
    Result := modes.ToArray;
  finally
    modes.Free;
    resSet.Free;
  end;
end;

function getCurrentResolution(): TRes;
begin
  Result.nHeight := Screen.Height;
  Result.nWidth := Screen.Width;
end;

function CreateLink(const TargetFile, PathLink, Desc, Param, Icon: string): Boolean;
var
  IObject: IUnknown;
  SLink: IShellLink;
  PFile: IPersistFile;
begin
  CoInitialize(nil);
  try
    DeleteFile(PathLink);
    IObject := CreateComObject(CLSID_ShellLink);
    SLink := IObject as IShellLink;
    PFile := IObject as IPersistFile;
    with SLink do
    begin
      SetArguments(PChar(Param));
      SetDescription(PChar(Desc));
      SetPath(PChar(TargetFile));
      SetWorkingDirectory(PChar(ExtractFileDir(TargetFile)));
      SetIconLocation(PChar(Icon), 0);
    end;
    Result := Succeeded(PFile.Save(PWChar(WideString(PathLink)), FALSE));
  finally
    CoUninitialize();
  end;
end;

procedure TfrmAutoRes.btn1Click(Sender: TObject);
begin
  with TOpenDialog.Create(nil) do
  try
    Filter := 'Executable|*.exe';
    Options := Options + [ofFileMustExist];
    if Execute() then
    begin
      edtApp.Text := filename;
      edtDir.Text := ExtractFileDir(filename);
    end;
  finally
    Free;
  end;
end;

procedure TfrmAutoRes.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmAutoRes.btnOkClick(Sender: TObject);
begin
  if cbbRes.ItemIndex < 0 then
  begin
    MessageBox(Handle, 'Select target resolution before saving', 'AutoRes', MB_OK or MB_ICONWARNING);
    Exit;
  end;
  if cbbDPI.ItemIndex < 0 then
  begin
    MessageBox(Handle, 'Select target DPI before saving', 'AutoRes', MB_OK or MB_ICONWARNING);
    Exit;
  end;
  if rbCustom.Checked and ((cbbDPI1.ItemIndex < 0) or (cbbDPI1.ItemIndex < 0)) then
  begin
    MessageBox(Handle, 'Complete restore action settings before saving', 'AutoRes', MB_OK or MB_ICONWARNING);
    Exit;
  end;
  with TSaveDialog.Create(nil) do
  try
    Filter := 'Shortcut|*.lnk';
    Options := Options + [ofOverwritePrompt, ofHideReadOnly, ofNoNetworkButton, ofOverwritePrompt];
    if Execute() then
    begin
      CreateShortcut(filename);
      MessageBox(Handle, 'Shortcut created successfully!', 'AutoRes', MB_OK or MB_ICONINFORMATION);
    end;
  finally
    Free;
  end;
end;

function TfrmAutoRes.CreateShortcut(sFilename: string): Boolean;
var
  cmd: TCmd;
  json, b64: string;
begin
  if ExtractFileExt(sFilename) = '' then
    sFilename := sFilename + '.lnk';
// serialize all data
  FillChar(cmd, sizeof(cmd), 0);
  cmd.app := edtApp.Text;
  cmd.param := edtParam.Text;
  cmd.workdir := edtDir.Text;
  with cmd.target, FResolutions[Integer(cbbRes.Items.Objects[cbbRes.ItemIndex])] do
  begin
    height := nHeight;
    width := nWidth;
    depth := nBits;
    dpi := Integer(cbbDPI.Items.Objects[cbbDPI.ItemIndex]);
  end;

  if rbRevert.Checked then
    cmd.restore.mode := 0;
  if rbKeep.Checked then
    cmd.restore.mode := 1;
  if rbCustom.Checked then
    cmd.restore.mode := 2;

  if cmd.restore.mode = 2 then
    with cmd.restore, FResolutions[Integer(cbbRes1.Items.Objects[cbbRes1.ItemIndex])] do
    begin
      height := nHeight;
      width := nWidth;
      depth := nBits;
      dpi := Integer(cbbDPI1.Items.Objects[cbbDPI1.ItemIndex]);
    end;

  json := JsonSerializer<TCmd>.ToJson(cmd).AsJSon();
  b64 := EncodeString(json);
  Result := CreateLink(Application.ExeName, sFilename, '', '-cmd ' + b64, cmd.app);
end;

procedure TfrmAutoRes.FormCreate(Sender: TObject);
begin
  InitRes();
  InitDPI();
end;

procedure TfrmAutoRes.InitDPI;
var
  I: Integer;
  dpi, current: Integer;
begin
  current := Round(Screen.PixelsPerInch * 100 / 96);
  for I := 0 to 10 do
  begin
    dpi := 100 + I * 25;
    cbbDPI.Items.AddObject(IntToStr(dpi) + '%', Pointer(dpi));
    cbbDPI1.Items.AddObject(IntToStr(dpi) + '%', Pointer(dpi));
    if current = dpi then
    begin
      cbbDPI.ItemIndex := I;
      cbbDPI1.ItemIndex := I;
    end;
  end;
end;

procedure TfrmAutoRes.InitRes;
var
  I: Integer;
  current: TRes;
begin
  FResolutions := getAllResolutions();
  current := getCurrentResolution();
  for I := High(FResolutions) downto Low(FResolutions) do
  begin
    cbbRes.Items.AddObject(makeResString(FResolutions[I]), Pointer(I));
    cbbRes1.Items.AddObject(makeResString(FResolutions[I]), Pointer(I));
    if (FResolutions[I].nHeight = current.nHeight) and (FResolutions[I].nWidth = current.nWidth) then
    begin
      cbbRes.ItemIndex := Length(FResolutions) - I - 1;
      cbbRes1.ItemIndex := Length(FResolutions) - I - 1;
    end;
  end;
end;

procedure TfrmAutoRes.rbCustomClick(Sender: TObject);
begin
  cbbRes1.Enabled := True;
  cbbDPI1.Enabled := True;
  lbl12.Enabled := True;
  lbl111.Enabled := True;
end;

procedure TfrmAutoRes.rbKeepClick(Sender: TObject);
begin
  cbbRes1.Enabled := false;
  cbbDPI1.Enabled := false;
  lbl12.Enabled := false;
  lbl111.Enabled := false;
end;

end.

