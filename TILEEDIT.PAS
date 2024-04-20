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
  TileApplication := New(PTileApp, Create(gdSVga8, 'SVga640x480x8'));
  TileApplication^.Run;
  TileApplication^.Free;
end.