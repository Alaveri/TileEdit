{$I COMPILER.INC}
{$M 8192, 0, 655360}
program TileEdit(input, output);

uses
  AplApps,
  GraphApp,
  GraphIni,
  Veridian,
  TileApp;

begin
  TileApplication := New(PTileApp, Create(gdVga8, 640, 480, 8));
  TileApplication^.Run;
  TileApplication^.Free;
end.