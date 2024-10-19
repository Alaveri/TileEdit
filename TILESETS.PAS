{$I COMPILER.INC}
unit Tilesets;

interface

uses
  AplObj,
  AplTypes,
  Streams,
  Compress,
  Lists,
  Common,
  Errors;

const
  TilesetMajorVersion = 1;
  TilesetMinorVersion = 0;
  TilesetSignature = 'TIL';
  DefaultImageListCapacity = 16;

type
  PTileset = ^TTileset;
  PImageList = ^TImageList;

  TTilesetCompression = (tcNone, tcLzw);

  TTilesetHeader = record
    FileTypeSignature: string[3];
    MajorVersion: integer;
    MinorVersion: integer;
    TileWidth: integer;
    TileHeight: integer;
    TileCount: integer;
    Name: string[50];
    Compression: TTilesetCompression;
    Reserved: array[0..189] of byte;
  end;

  TTileset = object(TStatusObject)
  private
  public
    Tiles: PImageList;
    Name: string;
    Filename: string;
    Compression: TTilesetCompression;
    function TileWidth: integer;
    function TileHeight: integer;
    constructor Create(AWidth, AHeight: integer);
    constructor LoadFromFile(const AFilename: string);
    procedure LoadFromStream(AStream: PStream);
    procedure SaveToStream(AStream: PStream);
    procedure SaveToFile(const AFilename: string);
    procedure Init; virtual;
    destructor Free; virtual;
  end;

  TImageList = object(TStatusObject)
  private
    FStream: PMemoryStream;
    FWidth: word;
    FHeight: word;
    FCapacity: integer;
    procedure Grow;
  public
    Count: integer;
    constructor Create(AWidth, AHeight: word);
    constructor CreateCapacity(AWidth, AHeight: word; ACapacity: integer);
    destructor Free; virtual;
    function Stream: PMemoryStream;
    function NewImage: longint;
    function Width: word;
    function Height: word;
    function PositionOf(AIndex: integer): longint;
    procedure NewImageAt(AIndex: integer);
    procedure SetCapacity(ACapacity: integer);
    procedure Init; virtual;
    procedure Swap(AIndex1, AIndex2: integer); virtual;
    procedure Move(AIndex, ANewIndex: integer); virtual;
    procedure Delete(AIndex: integer); virtual;
    procedure Clear; virtual;
  end;

implementation

uses
  Lzw;

constructor TTileset.Create(AWidth, AHeight: integer);
begin
  inherited Create;
  Tiles := New(PImageList, Create(AWidth, AHeight));
  if not Assigned(Tiles) then
    Raise(ecNotEnoughMemory);
end;

function TTileset.TileWidth: integer;
begin
  if not Assigned(Tiles) then
    TileWidth := 0
  else
    TileWidth := Tiles^.Width;
end;

function TTileset.TileHeight: integer;
begin
  if not Assigned(Tiles) then
    TileHeight := 0
  else
    TileHeight := Tiles^.Height;
end;

procedure TTileset.Init;
begin
  inherited Init;
  Tiles := nil;
  Name := '';
  Filename := '';
  Compression := tcLzw;
end;

destructor TTileset.Free;
begin
  FreeAndNil(Tiles);
  inherited Free;
end;

procedure TTileset.LoadFromStream(AStream: PStream);
var
  header: TTilesetHeader;
  lzw: TLzw;
  count: integer;
begin
  AStream^.Read(@header, SizeOf(header));
  if AStream^.HasException then begin
    Raise(AStream^.Exception^.Code);
    exit;
  end;
  if header.FileTypeSignature <> TilesetSignature then begin
    Raise(ecFileInvalidFormat);
    exit;
  end;
  if (header.MajorVersion > TilesetMajorVersion) or
    ((header.MajorVersion = TilesetMajorVersion) and
     (header.MinorVersion > TilesetMinorVersion)) then begin
    Raise(ecFileInvalidVersion);
    exit;
  end;
  Tiles := New(PImageList, Create(header.TileWidth, header.TileHeight));
  if (header.TileCount = 0) or (header.TileWidth <= 0) or (header.TileHeight <= 0) then
    exit;
  if not Assigned(Tiles) then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  if header.Compression = tcLzw then begin
    lzw.Create;
    lzw.DecompressStream(AStream, Tiles^.FStream, 0);
    AStream^.Seek(0, soFromBeginning);
    if lzw.HasException then begin
      Raise(lzw.Exception^.Code);
      FreeAndNil(Tiles);
    end
    else
      Tiles^.Count := header.TileCount;
    lzw.Free;
  end
  else begin
    Tiles^.FStream^.ReadFromStream(AStream, header.TileWidth * header.TileHeight * header.TileCount);
    if Tiles^.FStream^.HasException then begin
      Raise(Tiles^.FStream^.Exception^.Code);
      FreeAndNil(Tiles);
      exit;
    end;
    AStream^.Seek(0, soFromBeginning);
    Tiles^.Count := header.TileCount;
  end;
end;

constructor TTileset.LoadFromFile(const AFilename: string);
var
  stream: PFileStream;
begin
  inherited Create;
  stream := New(PFileStream, Create(AFilename, fmRead));
  if not Assigned(stream) then begin;
    Raise(ecNotEnoughMemory);
    exit;
  end;
  LoadFromStream(stream);
  if stream^.HasException then
    Raise(stream^.Exception^.Code)
  else
    Filename := AFilename;
  FreeAndNil(stream);
end;

procedure TTileset.SaveToStream(AStream: PStream);
var
  header: TTilesetHeader;
  lzw: TLzw;
  count: integer;
begin
  count := 0;
  if Assigned(Tiles) then
    count := Tiles^.Count;
  FillChar(header, SizeOf(header), 0);
  header.FileTypeSignature := TilesetSignature;
  header.MajorVersion := TilesetMajorVersion;
  header.MinorVersion := TilesetMinorVersion;
  header.TileWidth := TileWidth;
  header.TileHeight := TileHeight;
  header.TileCount := count;
  header.Name := name;
  header.Compression := Compression;
  AStream^.Write(@header, SizeOf(header));
  if count = 0 then
    exit;
  if Compression = tcLzw then begin
    lzw.Create;
    lzw.CompressStream(Tiles^.FStream, AStream, Tiles^.FWidth * Tiles^.FHeight * count);
    if lzw.HasException then
      Raise(lzw.Exception^.Code);
    lzw.Free;
  end
  else begin
    Tiles^.FStream^.WriteToStream(AStream, Tiles^.FWidth * Tiles^.FHeight * count);
    if Tiles^.FStream^.HasException then begin
      Raise(Tiles^.FStream^.Exception^.Code);
      Tiles^.FStream^.ClearException;
    end;
  end;
end;

procedure TTileset.SaveToFile(const AFilename: string);
var
  stream: PFileStream;
begin
  stream := New(PFileStream, Create(AFilename, fmWrite));
  if not Assigned(stream) then begin;
    Raise(ecNotEnoughMemory);
    exit;
  end;
  SaveToStream(stream);
  if stream^.HasException then
    Raise(stream^.Exception^.Code);
  Filename := AFilename;
  FreeAndNil(stream);
end;

constructor TImageList.Create(AWidth, AHeight: word);
begin
  inherited Create;
  CreateCapacity(AWidth, AHeight, DefaultImageListCapacity);
end;

constructor TImageList.CreateCapacity(AWidth, AHeight: word; ACapacity: integer);
begin
  inherited Create;
  FStream := nil;
  FWidth  := AWidth;
  FHeight := AHeight;
  FCapacity := 0;
  SetCapacity(ACapacity);
end;

procedure TImageList.Init;
begin
  inherited Init;
  FWidth := 0;
  FHeight := 0;
  Count := 0;
  FStream := nil;
  FCapacity := 0;
end;

function TImageList.Width: word;
begin
  Width := FWidth;
end;

function TImageList.Height: word;
begin
  Height := FHeight;
end;

destructor TImageList.Free;
begin
  FreeAndNil(FStream);
  inherited Free;
end;

function TImageList.Stream: PMemoryStream;
begin
  Stream := FStream;
end;

procedure TImageList.SetCapacity(ACapacity: integer);
var
  newStream: PMemoryStream;
  max: word;
  dataSize: longint;
  oldSize: longint;
  position: longint;
  error: TException;
begin
  if FCapacity = ACapacity then
    exit;
  if ACapacity > ListBufferSize then begin
    Raise(ecListCapacityOverflow);
    exit;
  end;
  dataSize := FWidth * FHeight * ACapacity;
  if not Assigned(FStream) then begin
    FStream := New(PMemoryStream, Create(dataSize));
    if (FStream = nil) or (FStream^.HasException) then begin
      Raise(ecNotEnoughMemory);
      FreeAndNil(FStream);
      exit;
    end;
    FStream^.Fill(dataSize, 0);
    FStream^.Seek(0, soFromBeginning);
    FCapacity := ACapacity;
    exit;
  end;
  newStream := New(PMemoryStream, Create(dataSize));
  if (newStream = nil) or (newStream^.HasException) then begin
    Raise(ecNotEnoughMemory);
    FreeAndNil(newStream);
    exit;
  end;
  oldSize := FWidth * FHeight * FCapacity;
  if ACapacity > FCapacity then begin
    position := FStream^.Position;
    FStream^.Seek(0, soFromBeginning);
    newStream^.Seek(0, soFromBeginning);
    FStream^.WriteToStream(newStream, oldSize);
    FreeAndNil(FStream);
    newStream^.Seek(position, soFromBeginning);
  end;
  FStream := newStream;
  FCapacity := ACapacity;
  if Count > FCapacity then
    Count := FCapacity;
end;

procedure TImageList.Grow;
var
  newCapacity: integer;
begin
  if FCapacity >= 64 then
    newCapacity := (FCapacity * 3) div 2
  else if FCapacity >= 8 then
    newCapacity := FCapacity + 16
  else
    newCapacity := FCapacity + 4;
  SetCapacity(newCapacity);
end;

function TImageList.NewImage: longint;
begin
  if Count + 1 > FCapacity then begin
    Grow;
    if HasException then
      exit;
  end;
  Inc(Count);
  NewImage := Count - 1;
end;

procedure TImageList.NewImageAt(AIndex: integer);
var
  newIndex: integer;
begin
  newIndex := NewImage;
  Move(newIndex, AIndex);
end;

function TImageList.PositionOf(AIndex: integer): longint;
begin
  PositionOf := FWidth * FHeight * AIndex;
end;

procedure TImageList.Swap(AIndex1, AIndex2: integer);
var
  ptr1, ptr2: PByte;
  pos1, pos2: longint;
  size: integer;
begin
  if (Count < 2) or (AIndex1 < 0) or (AIndex2 < 0)
    or (AIndex1 > Count - 1) or (AIndex2 > Count - 1) or
    (AIndex1 = AIndex2) then
    exit;
  size := FWidth * FHeight;
  GetMem(ptr1, size);
  if not Assigned(ptr1) then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  GetMem(ptr2, size);
  if not Assigned(ptr2) then begin
    FreeMem(ptr1, size);
    Raise(ecNotEnoughMemory);
    exit;
  end;

  pos1 := PositionOf(AIndex1);
  pos2 := PositionOf(AIndex2);

  FStream^.Seek(pos1, soFromBeginning);
  FStream^.Read(ptr1, size);

  FStream^.Seek(pos2, soFromBeginning);
  FStream^.Read(ptr2, size);

  FStream^.Seek(pos1, soFromBeginning);
  FStream^.Write(ptr2, size);

  FStream^.Seek(pos2, soFromBeginning);
  FStream^.Write(ptr1, size);

  FreeMem(ptr1, size);
  FreeMem(ptr2, size);
end;

procedure TImageList.Move(AIndex, ANewIndex: integer);
var
  pos: longint;
  size: integer;
  ptr, newPtr: PByte;
  index: integer;
begin
  if AIndex = ANewIndex then
    exit;
  if (AIndex < 0) or (AIndex > Count - 1) then
    exit;
  if (ANewIndex < 0) or (ANewIndex > Count - 1) then
    exit;

  size := FWidth * FHeight;
  GetMem(ptr, size);
  if not Assigned(ptr) then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  GetMem(newPtr, size);
  if not Assigned(newPtr) then begin
    FreeMem(ptr, size);
    Raise(ecNotEnoughMemory);
    exit;
  end;

  pos := PositionOf(AIndex);
  FStream^.Seek(pos, soFromBeginning);
  FStream^.Read(ptr, size);
  Delete(AIndex);

  for index := Count - 1 downto ANewIndex do begin
    pos := PositionOf(index);
    FStream^.Seek(pos, soFromBeginning);
    FStream^.Read(newPtr, size);
    pos := PositionOf(index + 1);
    FStream^.Write(newPtr, size);
  end;
  pos := PositionOf(AIndex);
  FStream^.Seek(pos, soFromBeginning);
  FStream^.Write(Ptr, 0);

  FreeMem(ptr, size);
  FreeMem(newPtr, size);
end;

procedure TImageList.Delete(AIndex: integer);
var
  pos: longint;
  size: integer;
  ptr: PByte;
  index: integer;
begin
  if (AIndex < 0) or (AIndex > Count - 1) then
    exit;
  pos := PositionOf(AIndex);
  size := FWidth * FHeight;
  if AIndex = Count - 1 then begin
    FStream^.Seek(pos, soFromBeginning);
    FStream^.Fill(size, 0);
    Dec(Count);
    exit;
  end;

  GetMem(ptr, size);
  if not Assigned(ptr) then begin
    Raise(ecNotEnoughMemory);
    exit;
  end;
  for index := AIndex + 1 to Count - 1 do begin
    pos := PositionOf(index);
    FStream^.Seek(pos, soFromBeginning);
    FStream^.Read(ptr, size);
    pos := PositionOf(index - 1);
    FStream^.Write(ptr, size);
  end;
  pos := PositionOf(Count - 1);
  FStream^.Seek(pos, soFromBeginning);
  FStream^.Fill(size, 0);
  Dec(Count);

  FreeMem(ptr, size);
end;

procedure TImageList.Clear;
begin
  FreeAndNil(FStream);
  Count := 0;
  FCapacity := 0;
end;

end.
