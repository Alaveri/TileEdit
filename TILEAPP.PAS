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
  TileInit;

type
  PTileApp = ^TTileApp;

  TTileApp = object(TVeridianApp)
  private
  public
    TileSettings: TTileSettings;
    Tabs: PTabView;
    ToolsPanel: PPanel;
    LastOpenDir: string;
    LastSaveDir: string;
    function LastOpenPath: string;
    function LastSavePath: string;
    function HandleActionExecute(ASender: PObject; AAction: PAction): boolean; virtual;
    function AddTileset: PTileset;
    function CheckError(ASender: PExceptionObject): boolean;
    procedure Init; virtual;
    procedure InitControls; virtual;
    procedure InitParams;
    procedure NewExecute;
    procedure SaveExecute;
    procedure OpenExecute;
    procedure SaveAsExecute;
    procedure AboutExecute;
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

implementation

uses
  Dialogs;

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
    acCloseAllTabs: action^.Enabled := fileOpen;
    acCloseTab: action^.Enabled := fileOpen and (Tabs^.TabIndex >= 0);
  end;
end;

function TTileApp.LastOpenPath: string;
begin
  LastOpenPath := IncludeBackslash(LastOpenDir) + '*.til';
end;

function TTileApp.LastSavePath: string;
begin
  LastSavePath := IncludeBackslash(LastSaveDir) + '*.til';
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
    CheckError(tileset);
  end;
  FreeAndNil(dialog);
end;

function TTileApp.AddTileset: PTileset;
var
  tileset: PTileset;
  tab: PTab;
  name: string;
begin
{  tileset := New(PTileset, Create);
  if tileset^.Filename = '' then
    name := 'Untitled.til'
  else
    name := tileset^.Filename;
  tab := Tabs^.NewTab(FirstUpper(ExtractFullName(name)));
  tab^.Data := tileset;
  AddTileset := tileset;}
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
  LastSaveDir := ExtractDirectory(tileset^.Filename);
end;

procedure TTileApp.CloseFile;
begin
end;

function TTileApp.CheckError(ASender: PExceptionObject): boolean;
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
    tab := Tabs^.NewTab(ExtractFullName(FirstUpper(tileset^.Filename)));
    tab^.Data := tileset;
    LastOpenDir := ExtractDirectory(tileset^.Filename);
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

function TTileApp.HandleActionExecute(ASender: PObject; AAction: PAction): boolean;
begin
  if inherited HandleActionExecute(ASender, AAction) then
    exit;
  case AAction^.ActionId of
    acNew: NewExecute;
    acSave: SaveExecute;
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
  LastOpenDir := GetCurrentDirectory;
  LastSaveDir := GetCurrentDirectory;
  Desktop^.DrawBackground := false;
  TileSettings.Create;
end;

procedure TTileApp.InitControls;
var
  width: integer;
  rect: TRect;
begin
  inherited InitControls;
  TileApplication := @self;
  InitParams;
  InitActions(Desktop^.ActionList);
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