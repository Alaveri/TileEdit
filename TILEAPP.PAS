{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
unit TileApp;

interface

uses
  Objects,
  Collects,
  Except,
  GraphApp,
  Graph8,
  GraphDrv,
  Streams,
  KeyDrv,
  Vga8Drv,
  GraphIni,
  Common,
  Desk,
  VeriApp,
  Controls,
  Views,
  Actions,
  Colors,
  Drawing;

type
  PTileApp = ^TTileApp;
  PTileInterfaceColors = ^TTileInterfaceColors;

  TTileInterfaceColors = object(TInterfaceColors)
  private
  public
  end;

  TTileApp = object(TVeridianApp)
  private
  public
    FileMenu: PMenu;
    EditMenu: PMenu;
    EditWindow: PWindow;
    procedure Init; virtual;
    procedure ProcessEvents; virtual;
    procedure InitControls; virtual;
    procedure InitActions;
    procedure InitMenu;
    destructor Free; virtual;
  end;

const
  { File Actions }
  NewActionId = 1001;
  SaveActionId = 1002;
  ExitActionId = 1100;

  { Edit Actions }
  UndoActionId = 2001;

implementation

uses
  MemDrv,
  StrUtils;

procedure NewActionExecute(ASender: PObject); far;
begin
  with PTileApp(Application)^ do begin
    EditWindow := New(PWindow, CreateParent('EditWindow', Desktop));
    EditWindow^.Maximize;
  end;
end;

procedure ExitActionExecute(ASender: PObject); far;
begin
  Application^.Close;
end;

procedure SaveActionExecute(ASender: PObject); far;
begin
  with PTileApp(Application)^ do begin
  end;
end;

procedure TTileApp.InitControls;
var
  rect: TRect;
begin
  inherited InitControls;
  Desktop^.SetupControls;
  Desktop^.GetClientRect(rect);
  InitActions;
  InitMenu;
end;

procedure TTileApp.InitActions;
var
  action: PAction;
begin
  with Desktop^.ActionList^ do begin
    action := New(PAction, Create(NewActionId, '&New Tileset', kyCtrlN, @NewActionExecute));
    action^.SetHelpText('Create a new tileset');
    Add(Action);

    action := New(PAction, Create(ExitActionId, 'E&xit', kyAltX, @ExitActionExecute));
    action^.SetHelpText('Exit this program');
    Add(action);

    action := New(PAction, Create(SaveActionId, '&Save', kyCtrlS, @SaveActionExecute));
    action^.SetHelpText('Save the current file');
    Add(action);

    action := New(PAction, Create(UndoActionId, '&Undo', kyCtrlZ, nil));
    action^.SetHelpText('Undo the previous action');
    Add(action);
  end;
end;

procedure TTileApp.InitMenu;
begin
  FileMenu := Desktop^.MenuBar^.NewMenu('FileMenu', '&File');
  FileMenu^.NewMenuItem('NewMenuItem', NewActionId);
  FileMenu^.NewSeparator;
  FileMenu^.NewMenuItem('SaveMenuItem', SaveActionId);
  FileMenu^.NewSeparator;
  FileMenu^.NewMenuItem('ExitMenuItem', ExitActionId);

  EditMenu := Desktop^.MenuBar^.NewMenu('EditMenu', '&Edit');
  EditMenu^.NewMenuItem('UndoMenuItem', UndoActionId);
end;

procedure TTileApp.Init;
begin
  inherited Init;
end;

destructor TTileApp.Free;
begin
  inherited Free;
end;

procedure TTileApp.ProcessEvents;
begin
  inherited ProcessEvents;
end;

end.