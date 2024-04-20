{$I COMPILER.INC}
unit Tilesets;

interface

uses
  Objects,
  Streams,
  Compress,
  Lists,
  Common,
  Errors;

type
  PTile = ^TTile;
  PTileset = ^TTileset;
  PTileList = ^TTileList;

  TTile = object(TObject)
  private
  public
    Data: PByte;
    Width, Height: integer;
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TTilesetCompression = (tcNone, tcLzw);

  TTileset = object(TExceptionObject)
  private
  public
    Compression: TTilesetCompression;
    Tiles: PTileList;
    Name: string;
    Filename: string;
    procedure LoadFromStream(AStream: PStream);
    procedure LoadFromFile(const AFilename: string);
    procedure SaveToStream(AStream: PStream);
    procedure SaveToFile(const AFilename: string);
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TTileList = object(TObjectList)
  private
  public
    function IndexOf(AItem: PTile): integer;
    function Add(AItem: PTile): integer;
    function GetItem(AIndex: integer): PTile;
    function SetItem(AIndex: integer; AItem: PTile): boolean;
    function GetNewObject: PObject; virtual;
    procedure Insert(AIndex: integer; AItem: PTile);
  end;

implementation

procedure TTile.Init;
begin
  inherited Init;
end;

destructor TTile.Free;
begin
  inherited Free;
end;

procedure TTileset.Init;
begin
  inherited Init;
  Tiles := New(PTileList, Create);
  Name := '';
  Filename := '';
end;

destructor TTileset.Free;
begin
  FreeAndNil(Tiles);
  inherited Free;
end;

procedure TTileset.LoadFromStream(AStream: PStream);
begin
end;

procedure TTileset.LoadFromFile(const AFilename: string);
begin
  Filename := AFilename;
end;

procedure TTileset.SaveToStream(AStream: PStream);
begin
end;

procedure TTileset.SaveToFile(const AFilename: string);
begin
end;

function TTileList.IndexOf(AItem: PTile): integer;
begin
  IndexOf := inherited IndexOf(AItem);
end;

function TTileList.Add(AItem: PTile): integer;
begin
  Add := inherited Add(AItem);
end;

function TTileList.GetItem(AIndex: integer): PTile;
begin
  GetItem := PTile(inherited GetItem(AIndex));
end;

function TTileList.SetItem(AIndex: integer; AItem: PTile): boolean;
begin
  SetItem := inherited SetItem(AIndex, AItem);
end;

function TTileList.GetNewObject: PObject;
begin
  GetNewObject := New(PTile, Create);
end;

procedure TTileList.Insert(AIndex: integer; AItem: PTile);
begin
  inherited Insert(AIndex, AItem);
end;

end.
