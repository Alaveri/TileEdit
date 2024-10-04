unit TileInit;

interface

uses
  Dialogs,
  AplObj,
  Desk,
  Actions,
  Veridian,
  AplTypes,
  TileType,
  Controls,
  Combos,
  KeyDrv;

const
  { File Actions }
  acNew = 1001;
  acSave= 1002;
  acSaveAs = 1003;
  acOpen = 1004;
  acExit= 1100;

  { Edit Actions }
  acUndo = 2001;
  acRedo = 2002;
  acCopy = 2003;
  acCut = 2004;
  acPaste = 2005;
  acDelete = 2006;
  acSettings = 2100;

  { Tile Actions }
  acNewTile = 3001;

  { Tab Actions }
  acClose = 4001;
  acCloseAll = 4002;

  { Help Actions }
  acAbout = 5001;
type
  PAboutDialog = ^TAboutDialog;
  PSettingsDialog = ^TSettingsDialog;

  TAboutDialog = object(TDialog)
  private
  public
    TitleLabel: PLabel;
    VersionLabel: PLabel;
    FreeConLabel: PLabel;
    FreeXmsLabel: PLabel;
    Separator: PHorzSeparator;
    constructor Create;
    procedure Init; virtual;
    procedure SetupControls; virtual;
  end;

  TSettingsDialog = object(TDialog)
  private
  public
    Settings: TTileSettings;
    VeridianSettings: TVeridianAppSettings;
    ResolutionLabel: PLabel;
    ResolutionEntry: PDropDownList;
    constructor Create(var ASettings: TTileSettings);
    destructor Free; virtual;
    procedure HandleActionExecute(var AAction: PAction); virtual;
    procedure Init; virtual;
    procedure SetupControls; virtual;
  end;

procedure InitActions(AActionList: PActionList);
procedure InitAppControls(AApp: PVeridianApp);

implementation

uses
  Drawing,
  Common,
  MemDrv,
  Tools,
  GraphDrv,
  ListBox,
  TileApp,
  Strings,
  TabView;

procedure InitAppControls(AApp: PVeridianApp);
var
  menu: PMenu;
  control: PControl;
  helpPanel: PTextControl;
  rect: TRect;
  panel: PTextControl;
begin
  with PTileApp(AApp)^ do begin
    StatusBar^.NewHelpPanel;

    Tools := New(PTools, CreateParent('ToolsPanel', Desktop));
    with Tools^ do begin
      SetBounds(
        -1,
        Menubar^.Height - 1,
        Scale(10),
        Desktop^.Height - Statusbar^.Height - Menubar^.Height + 5
      );
    end;

    menu := MenuBar^.NewMenu('FileMenu', '&File');
    with menu^ do begin
      NewMenuItem('NewMenuItem', acNew);;
      NewSeparator;
      NewMenuItem('OpenMenuItem', acOpen);
      NewSeparator;
      NewMenuItem('SaveMenuItem', acSave);
      NewMenuItem('SaveAsMenuItem', acSaveAs);
      NewSeparator;
      NewMenuItem('CloseMenuItem', acClose);
      NewMenuItem('CloseAllMenuItem', acCloseAll);
      NewSeparator;
      NewMenuItem('ExitMenuItem', acExit);
    end;

    menu := MenuBar^.NewMenu('EditMenu', '&Edit');
    with menu^ do begin
      NewMenuItem('UndoMenuItem', acUndo);
      NewMenuItem('RedoMenuItem', acRedo);
      NewSeparator;
      NewMenuItem('CutMenuItem', acCut);
      NewMenuItem('CopyMenuItem', acCopy);
      NewMenuItem('PasteMenuItem', acPaste);
      NewMenuItem('DeleteMeniItem', acDelete);
      NewSeparator;
      NewMenuItem('Settings', acSettings);
    end;

    menu := MenuBar^.NewMenu('TilesMenu', '&Tile');
    with menu^ do begin
      NewMenuItem('NewTile', acNewTile);
    end;

    menu := MenuBar^.NewMenu('HelpMenu', '&Help');
    with menu^ do begin
      NewMenuItem('AboutMenuItem', acAbout);
    end;

    Tabs := New(PTabView, CreateParent('Tabs', Desktop));
    with Tabs^ do begin
      BorderStyle := bsNone;
      OnTabClosing := @TabClosing;
      OnTabClosed := @TabClosed;
      SetBounds(
        Tools^.Width - 1,
        Menubar^.Height,
        Desktop^.Width - Tools^.Width + 3,
        Desktop^.Height - Statusbar^.Height - Menubar^.Height + 3
      );
    end;
  end;
end;

procedure InitActions(AActionList: PActionList);
var
  action: PAction;
begin
  with AActionList^ do begin
    action := New(PAction, Create(acNew, '&New Tileset', kyCtrlN));
    action^.SetHelpText('Create a new tileset');
    Add(Action);

    action := New(PAction, Create(acExit, 'E&xit', kyAltX));
    action^.SetHelpText('Exit this program');
    Add(action);

    action := New(PAction, Create(acOpen, '&Open', kyCtrlO));
    action^.SetHelpText('Open an existing file');
    Add(action);

    action := New(PAction, Create(acSave, '&Save', kyCtrlS));
    action^.SetHelpText('Save the current file');
    Add(action);

    action := New(PAction, Create(acSaveAs, 'Save &As', 0));
    action^.SetHelpText('Save as a new file');
    Add(action);

    action := New(PAction, Create(acUndo, '&Undo', kyCtrlZ));
    action^.SetHelpText('Undo the previous action');
    Add(action);

    action := New(PAction, Create(acRedo, '&Redo', kyCtrlY));
    action^.SetHelpText('Redo the previously undone action');
    Add(action);

    action := New(PAction, Create(acAbout, '&About', 0));
    action^.SetHelpText('About this program');
    Add(action);

    action := New(PAction, Create(acCut, 'Cu&t', kyCtrlX));
    action^.SetHelpText('Copy to clipboard and delete');
    Add(action);

    action := New(PAction, Create(acCopy, '&Copy', kyCtrlC));
    action^.SetHelpText('Copy to clipboard');
    Add(action);

    action := New(PAction, Create(acPaste, '&Paste', kyCtrlV));
    action^.SetHelpText('Paste from clipboard');
    Add(action);

    action := New(PAction, Create(acDelete, '&Delete', kyDel));
    action^.SetHelpText('Delete selection');
    Add(action);

    action := New(PAction, Create(acClose, '&Close', kyCtrlF4));
    action^.SetHelpText('Close the active file');
    Add(action);

    action := New(PAction, Create(acCloseAll, 'Close A&ll', 0));
    action^.SetHelpText('Close all files');
    Add(action);

    action := New(PAction, Create(acSettings, '&Settings', 0));
    action^.SetHelpText('Edit program settings');
    Add(action);

    action := New(PAction, Create(acNewTile, 'New &Tile', kyCtrlT));
    action^.SetHelpText('Add a new tile');
    Add(action);
  end;
end;

constructor TSettingsDialog.Create(var ASettings: TTileSettings);
begin
  inherited Create('SettingsDialog', [mbOk, mbCancel]);
  Settings.CreateAssign(ASettings);
  VeridianSettings.CreateAssign(VeridianApp^.Settings);
end;

destructor TSettingsDialog.Free;
begin
  Settings.Free;
end;

procedure TSettingsDialog.Init;
var
  index: integer;
  current: integer;
  mode: PGraphicsMode;
begin
  inherited Init;
  Font := VeridianApp^.SystemFont;
  Width := VeridianApp^.Scale(25);
  Height := VeridianApp^.Scale(18);
  ButtonAlign := haRight;
  DefaultButton := mbOk;
  CancelButton := mbCancel;
  SetTitle('Program Settings');
  ResolutionLabel := New(PLabel, CreateText('ResLabel', 'Screen Resolution: ', @self));
  ResolutionLabel^.AutoSize := true;
  ResolutionEntry := New(PDropDownList, CreateParent('ResEntry', 0, @self));
  ResolutionEntry^.AutoSize := true;
  ResolutionEntry^.MaxItems := 10;
  current := -1;
  for index := 0 to Graph^.Modes.Count - 1 do begin
    mode := Graph^.Modes.GetItem(index);
    if mode = Graph^.Mode then
      current := index;
    ResolutionEntry^.Items^.AddItem(StrPas(mode^.Description), mode);
  end;
  ResolutionEntry^.SetSelectedIndex(current);
end;

procedure TSettingsDialog.SetupControls;
var
  yPos: integer;
  xPos: integer;
  spacing: integer;
  rect: TRect;
begin
  inherited SetupControls;
  GetContentBounds(rect);
  X := CenterX;
  Y := CenterY;
  xPos := rect.X + VeridianApp^.Scale(1);
  yPos := rect.Y + Font^.Height;
  spacing := Font^.Height + 2 * BorderWidth;

  ResolutionLabel^.X := xPos;
  ResolutionLabel^.Y := yPos;
  Inc(yPos, spacing);

  ResolutionEntry^.X := xPos;
  ResolutionEntry^.Y := yPos;
  Inc(yPos, spacing);
end;

procedure TSettingsDialog.HandleActionExecute(var AAction: PAction);
var
  mode: PGraphicsMode;
  item: PListItem;
begin
  if AAction^.ModalResult = mrCancel then begin
    Close;
    exit;
  end;
  item := ResolutionEntry^.SelectedItem;
  mode := PGraphicsMode(item^.Value);
  if mode <> Graph^.Mode then begin
    ShowMessage('Graphics Mode Change', 'New graphics mode will be applied after restart.');
  end;
  Close;
end;

constructor TAboutDialog.Create;
begin
  inherited Create('AboutDialog', [mbOk]);
end;

procedure TAboutDialog.SetupControls;
var
  currentY: integer;
  currentX: integer;
  labelHeight: integer;
  rect: TRect;
begin
  inherited SetupControls;
  X := CenterX;
  Y := CenterY;
  labelHeight := Font^.Height;
  GetContentBounds(rect);

  currentX := rect.X;
  currentY := rect.Y + labelHeight;

  TitleLabel^.SetBounds(currentX, currentY, rect.Width - 1, Font^.Height);
  Inc(currentY, labelHeight);

  VersionLabel^.SetBounds(currentX, currentY, rect.Width - 1, Font^.Height);
  Inc(currentY, labelHeight * 2);

  Separator^.SetBounds(currentX, currentY, rect.Width, 1);
  Inc(currentY, labelHeight);

  FreeConLabel^.SetBounds(currentX, currentY, rect.Width - 1, Font^.Height);
  Inc(currentY, labelHeight);

  FreeXmsLabel^.SetBounds(currentX, currentY, rect.Width - 1, Font^.Height);
end;

procedure TAboutDialog.Init;
begin
  inherited Init;
  Width := VeridianApp^.Scale(20);
  Height := VeridianApp^.Scale(12);
  SetTitle('About');
  ButtonAlign := haCenter;

  TitleLabel := New(PLabel, CreateParent('TitleLabel', @self));
  with TitleLabel^ do begin
    Font := VeridianApp^.SystemFont;
    Autosize := false;
    TextAlign := haCenter;
    SetText('Alaveri Tileset Editor');
  end;

  VersionLabel := New(PLabel, CreateParent('VersionLabel', @self));
  with VersionLabel^ do begin
    Font := VeridianApp^.SystemFont;
    Autosize := false;
    TextAlign := haCenter;
    SetText('Version ' + AppVersion);
  end;

  Separator := New(PHorzSeparator, CreateParent('Separator', @self));

  FreeConLabel := New(PLabel, CreateParent('FreeConLabel', @self));
  with FreeConLabel^ do begin
    Font := VeridianApp^.Fonts^.GetItemById('seattle');
    Margin := 8;
    Autosize := false;
    TextAlign := haLeft;
    SetText('Free Memory: ' + FormatLong(MemAvail) + ' bytes');
  end;

  FreeXmsLabel := New(PLabel, CreateParent('FreeXmsLabel', @self));
  with FreeXmsLabel^ do begin
    Font := VeridianApp^.Fonts^.GetItemById('seattle');
    Margin := 8;
    Autosize := false;
    TextAlign := haLeft;
    SetText('Free XMS Memory: ' + FormatLong(Memory.XmsMaxAvail) + ' bytes');
  end;
end;

end.