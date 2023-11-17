{$IFDEF debug}
  {$A-,B-,D+,E+,F+,G-,I+,L+,N+,M 16384 0 655360,O-,P+,Q+,R+,S+,T-,V-,X+,Y+}
{$ELSE}
  {$A-,B-,D-,E+,F+,G-,I+,L-,N+,M 16384 0 655360,O-,P+,Q-,R-,S-,T-,V-,X+,Y-}
{$ENDIF}
program TileEdit(input, output);

uses
  GraphIni,
  Apps,
  VeriApp,
  TileApp,
  Objects,
  Globals;

begin
  Application := App;
  Application^.Run;
  FreeAndNil(Application);
end.