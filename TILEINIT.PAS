unit TileInit;

interface

uses
  Dialogs,
  Objects,
  Desk,
  Actions,
  Veridian,
  AplTypes,
  TileType,
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

  { Tab ACtions }
  acCloseTab = 3001;
  acCloseAllTabs = 3002;

  { Help Actions }
  acAbout = 5001;
type
  PAboutDialog = ^TAboutDialog;
  PSettingsDialog = ^TSettingsDialog;

  TAboutDialog = object(TDialog)
  private
  public
    constructor Create;
    procedure Init; virtual;
    procedure SetupControls; virtual;
  end;

  TSettingsDialog = object(TDialog)
  private
  public
    Settings: TTileSettings;
    VeridianSettings: TVeridianAppSettings;
    constructor Create(var ASettings: TTileSettings);
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
  GraphDrv,
  TileApp,
  Controls,
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

    ToolsPanel := New(PPanel, CreateParent('ToolsPanel', Desktop));
    with ToolsPanel^ do begin
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
      NewMenuItem('ExitMenuAction', acExit);
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

    menu := MenuBar^.NewMenu('TabMenu', '&Tab');
    with Menu^ do begin
      NewMenuItem('CloseTabMenuItem', acCloseTab);
      NewMenuItem('CloseAllTabsMenuItem', acCloseAllTabs);
    end;

    menu := MenuBar^.NewMenu('HelpMenu', '&Help');
    with menu^ do begin
      NewMenuItem('AboutMenuItem', acAbout);
    end;

    Tabs := New(PTabView, CreateParent('Tabs', Desktop));
    with Tabs^ do begin
      BorderStyle := bsNone;
      SetBounds(
        ToolsPanel^.Width - 1,
        Menubar^.Height,
        Desktop^.Width - ToolsPanel^.Width + 3,
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

    action := New(PAction, Create(acCloseTab, '&Close Tab', kyCtrlF4));
    action^.SetHelpText('Close the active tab');
    Add(action);

    action := New(PAction, Create(acCloseAllTabs, 'Close A&ll Tabs', 0));
    action^.SetHelpText('Close all tabs');
    Add(action);

    action := New(PAction, Create(acSettings, '&Settings', 0));
    action^.SetHelpText('Edit program settings');
    Add(action);
  end;
end;

constructor TSettingsDialog.Create(var ASettings: TTileSettings);
begin
  inherited Create('SettingsDialog', [mbOk, mbCancel]);
  Settings.CreateAssign(ASettings);
  VeridianSettings.CreateAssign(VeridianApp^.Settings);
end;

procedure TSettingsDialog.Init;
begin
  inherited Init;
  Font := VeridianApp^.SystemFont;
  Width := VeridianApp^.Scale(25);
  Height := VeridianApp^.Scale(18);
  ButtonAlign := taRight;
  DefaultButton := mbOk;
  CancelButton := mbCancel;
  SetTitle('Program Settings');
end;

procedure TSettingsDialog.SetupControls;
begin
  inherited SetupControls;
  X := CenterX;
  Y := CenterY;
end;

constructor TAboutDialog.Create;
begin
  inherited Create('AboutDialog', [mbOk]);
  X := CenterX;
  Y := CenterY;
end;

procedure TAboutDialog.Init;
var
  control: PLabel;
  currentLabel: PLabel;
  separator: PHorzSeparator;
  currentY: integer;
  currentX: integer;
  labelHeight: integer;
begin
  inherited Init;
  X := CenterX;
  Y := CenterY;
  Font := VeridianApp^.SystemFont;
  Width := VeridianApp^.Scale(20);
  Height := VeridianApp^.Scale(12);
  SetTitle('About');
  ButtonAlign := taCenter;
  labelHeight := Font^.Height;
  currentY := labelHeight;
  currentX := 0;
  SetupControls;

  currentLabel := New(PLabel, CreateParent('TitleLabel', Content));
  with currentLabel^ do begin
    Font := VeridianApp^.SystemFont;
    SetBounds(currentX, currentY, Content^.Width - 1, Font^.Height);
    Autosize := false;
    TextAlign := taCenter;
    SetText('Alaveri Tileset Editor');
  end;

  Inc(currentY, labelHeight);
  currentLabel := New(PLabel, CreateParent('VersionLabel', Content));
  with currentLabel^ do begin
    Font := VeridianApp^.SystemFont;
    SetBounds(currentX, currentY, Content^.Width - 1, Font^.Height);
    Autosize := false;
    TextAlign := taCenter;
    SetText('Version ' + AppVersion);
  end;

  Inc(currentY, labelHeight * 2);
  separator := New(PHorzSeparator, CreateParent('Separator', Content));
  separator^.SetBounds(currentX, currentY, Content^.Width, 1);

  Inc(currentY, labelHeight);
  currentLabel := New(PLabel, CreateParent('FreeConLabel', Content));
  with currentLabel^ do begin
    Font := VeridianApp^.EditorFont;
    Margin := 8;
    SetBounds(currentX, currentY, Content^.Width - 1, Font^.Height);
    Autosize := false;
    TextAlign := taLeft;
    SetText('Free Memory: ' + FormatLong(MemAvail) + ' bytes');
  end;

  Inc(currentY, labelHeight);
  currentLabel := New(PLabel, CreateParent('FreeConLabel', Content));
  with currentLabel^ do begin
    Font := VeridianApp^.EditorFont;
    Margin := 8;
    SetBounds(currentX, currentY, content^.Width - 1, Font^.Height);
    Autosize := false;
    TextAlign := taLeft;
    SetText('Free XMS Memory: ' + FormatLong(Memory.XmsMaxAvail) + ' bytes');
  end;
end;

procedure TAboutDialog.SetupControls;
begin
  inherited SetupControls;
end;

end.