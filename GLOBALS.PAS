unit Globals;

interface

uses
  TileApp,
  GraphIni;

var
  App: PTileApp;

implementation

uses
  MemDrv;

begin
  App := New(PTileApp, Create(gdSVga256, 'SVga640x480x8'));
end.