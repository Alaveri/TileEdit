{$I COMPILER.INC}
unit Tools;

interface

uses
  Controls,
  Tilesets;

type
  PTools = ^TTools;

  TTools = object(TPanel)
  private
  public
    Tileset: PTileset;
    procedure Init; virtual;
    procedure SeupControls; virtual;
    procedure SetTileset(ATileset: PTileset);
    destructor Free; virtual;
  end;

implementation

uses
  Veridian,
  Desk;

procedure TTools.Init;
begin
  inherited Init;
  Tileset := nil;
  Font := VeridianApp^.Fonts^.GetItemById('seattle');
  ForeColor := Desktop^.Colors^.Window;
  BackColor := Desktop^.Colors^.WindowBack;
end;

procedure TTools.SeupControls;
begin
  inherited SetupControls;

end;

procedure TTools.SetTileset(ATileset: PTileset);
begin
  Tileset := ATileset;
  SetupControls;
  Draw;
end;

destructor TTools.Free;
begin
  inherited Free;
end;

end.

