{$I COMPILER.INC}
unit TileType;

interface

uses
  AplObj,
  AplTypes,
  Controls;

const
  AppVersion = '0.1.0';

type
  PTileSettings = ^TTileSettings;

  TTileSettings = object(TObject)
  private
  public
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
  end;

implementation

procedure TTileSettings.Init;
begin
  inherited Init;
end;

procedure TTileSettings.Assign(var ASource: TObject);
var
  source: PTileSettings;
begin
  inherited Assign(ASource);
  source := PTileSettings(@ASource);
end;

end.
