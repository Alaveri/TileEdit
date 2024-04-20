{$I COMPILER.INC}
unit TileApp;

interface

uses
  Objects,
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
  TileInit;

type
  PTileApp = ^TTileApp;

  TTileApp = object(TVeridianApp)
  private
  public
    Tabs: PTabView;
    LastOpenDir: string;
    LastSaveDir: string;
    function LastOpenPath: string;
    function LastSavePath: string;
    function HandleActionExecute(ASender: PObject; AAction: PAction): boolean; virtual;
    function AddTileset: PTileset;
    function CheckError(ASender: PExceptionObject): boolean;
    function CheckAlloc(APointer: pointer): boolean;
    procedure Init; virtual;
    procedure InitControls; virtual;
    procedure InitParams;
    procedure NewExecute;
    procedure SaveExecute;
    procedure OpenExecute;
    procedure SaveAsExecute;
    procedure AboutExecute;
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
  Dialogs,
  AplTypes;

procedure TTileApp.UpdateActionControl(AControl: PActionControl);
var
  action: PAction;
  fileOpen: boolean;
begin
  action := AControl^.Action;
  fileOpen := Tabs^.Controls^.Count > 0;
  case action^.ActionId of
    acSave: action^.Enabled := fileOpen;
    acSaveAs: action^.Enabled := fileOpen;
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
  if not CheckAlloc(dialog) then exit;
  dialog^.Options := [];
  result := dialog^.ShowModal;
  if result = mrOk then begin
    tileset^.SaveToFile(dialog^.Filename);
    CheckError(tileset);
  end;
  Desktop^.Controls^.Remove(dialog);
end;

function TTileApp.AddTileset: PTileset;
var
  tileset: PTileset;
  tab: PTab;
begin
  tileset := New(PTileset, Create);
  if not CheckAlloc(tileset) then exit;
  tab := Tabs^.NewTab;
  if not CheckAlloc(tab) then begin
    FreeAndNil(tileset);
    exit;
  end;
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
  LastSaveDir := ExtractDirectory(tileset^.Filename);
end;

procedure TTileApp.CloseFile;
begin
end;

function TTileApp.CheckAlloc(APointer: pointer): boolean;
begin
  CheckAlloc := true;
  if Assigned(APointer) then
    exit;
  CheckAlloc := false;
  Error(@self, ecNotEnoughMemory);
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
  if not CheckAlloc(dialog) then exit;
  result := dialog^.ShowModal;
  if result = mrOk then begin
    tileset := New(PTileset, Create);
    if not CheckAlloc(tileset) then exit;
    tileset^.LoadFromFile(dialog^.Filename);
    if not CheckError(tileset) then begin
      FreeAndNil(tileset);
      exit;
    end;
    tab := Tabs^.NewTab;
    if not CheckAlloc(tab) then begin
      FreeAndNil(tileset);
      exit;
    end;
    tab^.Data := tileset;
    LastOpenDir := ExtractDirectory(tileset^.Filename);
    Tabs^.Visible := true;
    Tabs^.Draw;
  end;
  Desktop^.Controls^.Remove(dialog);
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

procedure TTileApp.AboutExecute;
var
  dialog: PAboutDialog;
begin
  dialog := New(PAboutDialog, Create);
  if not CheckAlloc(dialog) then exit;
  dialog^.ShowModal;
  Desktop^.Controls^.Remove(dialog);
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
    acExit: Close;
  end;
end;

procedure TTileApp.InitParams;
begin
end;

procedure TTileApp.Init;
begin
  inherited Init;
  Tabs := New(PTabView, CreateParent('Tabs', Desktop));
  Tabs^.BorderStyle := bsNone;
  Tabs^.Visible := false;
  Tabs^.SetBounds(
    0,
    Desktop^.Menubar^.Height,
    Desktop^.MenuBar^.Width,
    Desktop^.Height - Desktop^.Statusbar^.Height - Desktop^.Menubar^.Height + 3
  );
  LastOpenDir := GetCurrentDirectory;
  LastSaveDir := GetCurrentDirectory;
end;

procedure TTileApp.InitControls;
var
  width: integer;
  rect: TRect;
begin
  inherited InitControls;
  TileApplication := @self;
  InitParams;
  InitActions;
  InitAppControls;
  Desktop^.SetupControls;
end;

destructor TTileApp.Free;
begin
  inherited Free;
end;

begin
  TileApplication := nil;

end.