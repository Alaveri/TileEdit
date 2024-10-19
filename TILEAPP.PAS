{$I COMPILER.INC}
unit TileApp;

interface

uses
  AplObj,
  AplTypes,
  Lists,
  Drawing,
  Tilesets,
  Actions,
  Errors,
  Common,
  StrUtils,
  MouseDrv,
  GraphDrv,
  GrDrv8,
  Controls,
  TabView,
  Veridian,
  Desk,
  Views,
  TileType,
  Tools,
  TileInit;

type
  PTileApp = ^TTileApp;

  TTileApp = object(TVeridianApp)
  private
  public
    TileSettings: TTileSettings;
    Tabs: PTabView;
    Tools: PTools;
    function LastOpenPath: string;
    function LastSavePath: string;
    function HandleActionExecute(ASender: PObject; AAction: PAction): boolean; virtual;
    function AddTileset: PTileset;
    function CheckError(ASender: PStatusObject): boolean; virtual;
    procedure Init; virtual;
    procedure InitControls; virtual;
    procedure InitParams;
    procedure NewExecute;
    procedure SaveExecute;
    procedure OpenExecute;
    procedure SaveAsExecute;
    procedure AboutExecute;
    procedure CloseTabExecute;
    procedure CloseAllTabsExecute;
    procedure EditSettingsExecute;
    procedure UpdateActionControl(AControl: PActionControl); virtual;
    procedure SaveFileAs;
    procedure SaveFile;
    procedure CloseFile;
    procedure NewFile;
    procedure OpenFile;
    destructor Free; virtual;
  end;

var
  TileApplication: PTileApp;

procedure TabClosing(ASender: PObject; var AEvent: TTabClosingEvent); far;
procedure TabClosed(ASender: PObject; var AEvent: TTabClosedEvent); far;


implementation

uses
  Strings,
  Dialogs;

procedure TabClosing(ASender: PObject; var AEvent: TTabClosingEvent);
var
  tab: PTab;
begin
  tab := PTab(ASender);
end;

procedure TabClosed(ASender: PObject; var AEvent: TTabClosedEvent);
var
  tab: PTab;
begin
  tab := PTab(ASender);
  FreeAndNil(PTileset(tab^.Data));
end;

procedure TTileApp.UpdateActionControl(AControl: PActionControl);
var
  action: PAction;
  fileOpen: boolean;
begin
  action := AControl^.Action;
  fileOpen := Tabs^.Count > 0;
  case action^.ActionId of
    acSave: action^.Enabled := fileOpen;
    acSaveAs: action^.Enabled := fileOpen;
    acCloseAll: action^.Enabled := fileOpen;
    acClose: action^.Enabled := fileOpen and (Tabs^.TabIndex >= 0);
  end;
end;

function TTileApp.LastOpenPath: string;
begin
  LastOpenPath := IncludeBackslash(StrPas(TileSettings.LastOpenDir)) + '*.til';
end;

function TTileApp.LastSavePath: string;
begin
  LastSavePath := IncludeBackslash(StrPas(TileSettings.LastSaveDir)) + '*.til';
end;

procedure TTileApp.SaveFileAs;
var
  dialog: PFileDialog;
  result: TModalResult;
  currentTab: PTab;
  tileset: PTileset;
begin
  currentTab := Tabs^.CurrentTab;
  tileset := PTileset(Tabs^.CurrentTab^.Data);
  dialog := New(PFileDialog, Create('Save Tileset As', LastSavePath));
  dialog^.Options := [doOverwritePrompt];
  dialog^.DefaultExt := '.til';
  result := dialog^.ShowModal;
  if result = mrOk then begin
    tileset^.SaveToFile(dialog^.Filename);
    if CheckError(tileset) then begin
      TString.Assign(TileSettings.LastSaveDir, ExtractDirectory(tileset^.Filename));
      TileSettings.SaveToFile(SettingsFilename);
      currentTab^.Data := tileset;
      currentTab^.Button^.SetText(FirstUpper(ExtractFullName(tileset^.Filename)));
      currentTab^.Draw;
    end;
  end;
  FreeAndNil(dialog);
end;

function TTileApp.AddTileset: PTileset;
var
  tileset: PTileset;
  tab: PTab;
  name: string;
begin
  tileset := New(PTileset, Create(19, 19));
  if tileset^.Filename = '' then
    name := 'Untitled.til'
  else
    name := tileset^.Filename;
  tab := Tabs^.NewTab(FirstUpper(ExtractFullName(name)));
  tab^.Data := tileset;
  AddTileset := tileset;
end;

procedure TTileApp.NewFile;
begin
  AddTileset;
  Tabs^.Visible := true;
  Tabs^.Draw;
end;

procedure TTileApp.SaveFile;
var
  filename: string;
  tileset: PTileset;
  currentTab: PTab;
begin
  currentTab := Tabs^.CurrentTab;
  if not Assigned(currentTab) then
    exit;
  tileset := PTileset(currentTab^.Data);
  filename := tileset^.Filename;
  if filename = '' then begin
    SaveFileAs;
    exit;
  end;
  tileset^.SaveToFile(tileset^.Filename);
  if not CheckError(tileset) then exit;
  TString.Assign(TileSettings.LastSaveDir, ExtractDirectory(tileset^.Filename));
  TileSettings.SaveToFile(SettingsFilename);
end;

procedure TTileApp.CloseFile;
begin
end;

function TTileApp.CheckError(ASender: PStatusObject): boolean;
begin
  CheckError := true;
  if not ASender^.HasException then
    exit;
  CheckError := false;
  Error(ASender, ASender^.Exception^.Code);
  ASender^.ClearException;
end;

procedure TTileApp.OpenFile;
var
  dialog: PFileDialog;
  result: TModalResult;
  tileset: PTileset;
  tab: PTab;
begin
  dialog := New(PFileDialog, Create('Open Tileset', LastOpenPath));
  dialog^.Options := [doFileMustExist];
  dialog^.DefaultExt := '.til';
  result := dialog^.ShowModal;
  if result = mrOk then begin
    tileset := New(PTileset, LoadFromFile(dialog^.Filename));
    if not CheckError(tileset) then begin
      FreeAndNil(tileset);
      exit;
    end;
    TString.Assign(TileSettings.LastOpenDir, ExtractDirectory(tileset^.Filename));
    TileSettings.SaveToFile(SettingsFilename);
    tab := Tabs^.NewTab(ExtractFullName(FirstUpper(tileset^.Filename)));
    tab^.Data := tileset;
    Tabs^.Visible := true;
    Tabs^.Draw;
  end;
  FreeAndNil(dialog);
end;

procedure TTileApp.NewExecute;
begin
  NewFile;
end;

procedure TTileApp.OpenExecute;
begin
  OpenFile;
end;

procedure TTileApp.SaveExecute;
begin
  SaveFile;
end;

procedure TTileApp.SaveAsExecute;
begin
  SaveFileAs;
end;

procedure TTileApp.EditSettingsExecute;
var
  dialog: PSettingsDialog;
  result: TModalResult;
begin
  dialog := New(PSettingsDialog, Create(TileSettings));
  result := dialog^.ShowModal;
  if result = mrOk then begin
    TileSettings.Assign(dialog^.Settings);
    VeridianApp^.Settings.Assign(dialog^.VeridianSettings);
  end;
  FreeAndNil(dialog);
end;

procedure TTileApp.AboutExecute;
var
  dialog: PAboutDialog;
begin
  dialog := New(PAboutDialog, Create);
  dialog^.ShowModal;
  FreeAndNil(dialog);
end;

procedure TTileApp.CloseTabExecute;
begin
  if (Tabs^.TabIndex < 0) or (Tabs^.TabIndex > Tabs^.Count - 1) then
    exit;
  Tabs^.CloseTab(Tabs^.CurrentTab);
end;

procedure TTileApp.CloseAllTabsExecute;
begin
end;

function TTileApp.HandleActionExecute(ASender: PObject; AAction: PAction): boolean;
begin
  if inherited HandleActionExecute(ASender, AAction) then
    exit;
  case AAction^.ActionId of
    acNew: NewExecute;
    acSave: SaveExecute;
    acClose: CloseTabExecute;
    acCloseAll: CloseAllTabsExecute;
    acOpen: OpenExecute;
    acSaveAs: SaveAsExecute;
    acAbout: AboutExecute;
    acSettings: EditSettingsExecute;
    acExit: Close;
  end;
end;

procedure TTileApp.InitParams;
begin
end;

procedure TTileApp.Init;
begin
  inherited Init;
  Desktop^.DrawBackground := true;
  TileSettings.LoadFromFile(SettingsFilename);
end;

procedure TTileApp.InitControls;
var
  width: integer;
  rect: TRect;
begin
  inherited InitControls;
  TileApplication := @self;
  InitParams;
  TileInit.InitActions(Desktop^.ActionList);
  InitAppControls(@self);
  Desktop^.SetupControls;
end;

destructor TTileApp.Free;
begin
  inherited Free;
end;

begin
  TileApplication := nil;
end.