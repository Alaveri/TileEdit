{$I COMPILER.INC}
unit TileType;

interface

uses
  AplObj,
  AplTypes,
  Streams,
  Controls;

const
  AppVersion = '0.1.0';

type
  PTileSettings = ^TTileSettings;

  TTileSettings = object(TObject)
  private
  public
    LastOpenDir: PChar;
    LastSaveDir: PChar;
    constructor LoadFromStream(AStream: PStream);
    constructor LoadFromFile(const AFilename: string);
    destructor Free; virtual;
    procedure Init; virtual;
    procedure Assign(var ASource: TObject); virtual;
    procedure SaveToStream(AStream: PStream);
    function SaveToFile(const AFilename: string): boolean;
  end;

function SettingsFilename: string; far;

implementation

uses
  Common,
  Veridian,
  StrUtils;

function SettingsFilename: string;
begin
  SettingsFilename := IncludeBackslash(AppDir) +  'settings.bin';
end;

procedure TTileSettings.Init;
begin
  inherited Init;
  LastOpenDir := nil;
  LastSaveDir := nil;
end;

procedure TTileSettings.Assign(var ASource: TObject);
var
  source: PTileSettings;
begin
  inherited Assign(ASource);
  source := PTileSettings(@ASource);
  TString.Reassign(LastOpenDir, source^.LastOpenDir);
  TString.Reassign(LastSaveDir, source^.LastSaveDir);
end;

constructor TTileSettings.LoadFromStream(AStream: PStream);
var
  len: word;
begin
  inherited Create;
  len := AStream^.ReadWord;
  LastOpenDir := TString.Alloc(len);
  AStream^.Read(PByte(LastOpenDir), len);
  len := AStream^.ReadWord;
  LastSaveDir := TString.Alloc(len);
  AStream^.Read(PByte(LastSaveDir), len);
  VeridianApp^.Settings.LoadFromStream(AStream);
end;

constructor TTileSettings.LoadFromFile(const AFilename: string);
var
  stream: PFileStream;
  success: boolean;
begin
  inherited Create;
  success := false;
  if FileExists(AFilename) then begin
    stream := New(PFileStream, Create(AFilename, fmRead));
    if not Assigned(stream) then
      exit;
    LoadFromStream(stream);
    success := not stream^.HasException;
    FreeAndNil(stream);
  end;
  if not success then begin
    Init;
    LastOpenDir := TString.New(AppDir);
    LastSaveDir := TString.New(AppDir);
  end;
end;

function TTileSettings.SaveToFile(const AFilename: string): boolean;
var
  stream: PFileStream;
begin
  stream := New(PFileStream, Create(AFilename, fmWrite));
  if not Assigned(stream) then
    exit;
  SaveToStream(stream);
  SaveToFile := not stream^.HasException;
  FreeAndNil(stream);
end;

procedure TTileSettings.SaveToStream(AStream: PStream);
var
  len: word;
  start: longint;
begin
  len := TString.Length(LastOpenDir);
  AStream^.WriteWord(len);
  if Assigned(LastOpenDir) then
    AStream^.Write(PByte(LastOpenDir), len);
  len := TString.Length(LastSaveDir);
  AStream^.WriteWord(len);
  if Assigned(LastSaveDir) then
    AStream^.Write(PByte(LastSaveDir), len);
  VeridianApp^.Settings.SaveToStream(AStream);
end;

destructor TTileSettings.Free;
begin
  TString.Free(LastOpenDir);
  TString.Free(LastSaveDir);
end;

end.
