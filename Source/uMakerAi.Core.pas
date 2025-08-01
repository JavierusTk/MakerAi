// IT License
//
// Copyright (c) <year> <copyright holders>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// o use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// HE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// Nombre: Gustavo Enr�quez
// Redes Sociales:
// - Email: gustavoeenriquez@gmail.com
// - Telegram: +57 3128441700
// - LinkedIn: https://www.linkedin.com/in/gustavo-enriquez-3937654a/
// - Youtube: https://www.youtube.com/@cimamaker3945
// - GitHub: https://github.com/gustavoeenriquez/
//
// --------- CAMBIOS --------------------
// 04/11/2024 - adiciona el manejo de TAiMediaFile.detail para identificar la calidad de analisis de una imagen
// 04/11/2024 - Se corrige error de asignaci�n en TAiMediaFile.LoadFromBase64

unit uMakerAi.Core;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Threading, System.Variants, System.Net.Mime, System.IOUtils,
  System.Generics.Collections, System.NetEncoding, System.JSON,
  System.StrUtils, System.Net.URLClient, System.Net.HttpClient,
  System.Net.HttpClientComponent, REST.JSON, REST.Types, REST.Client;

Type

  TAiToolsFunction = Class;

  TAiImageSize = (TiaSize256, TiaSize512, TiaSize1024, TiaSize1024_1792, TiaSize1792_1024);
  TAiImageResponseFormat = (tiaRUrl, tiaRB64);
  TAiImageAStyleFormat = (tiaStyleVivid, tiaStyleNatural);

  TAiFileCategory = (Tfc_Text, Tfc_Image, Tfc_Audio, Tfc_Video, Tfc_Document, //
    Tfc_WebSearch, Tfc_CalcSheet, Tfc_Presentation, Tfc_CompressFile, Tfc_Web, //
    Tfc_GraphicDesign, tfc_textFile, Tfc_Unknow); //

  TAiFileCategories = set of TAiFileCategory;

  TAiChatMediaSupport = (Tcm_Text, Tcm_Image, Tcm_Audio, Tcm_Video, Tcm_Document, tcm_WebSearch, Tcm_CalcSheet, Tcm_Presentation,
    Tcm_CompressFile, Tcm_Web, Tcm_GraphicDesign);

  TAiChatMediaSupports = set of TAiChatMediaSupport;

  // Tipo de evento para manejar errores
  TAiErrorEvent = procedure(Sender: TObject; const ErrorMsg: string; Exception: Exception; const AResponse: IHTTPResponse) of object;


  // Se utiliza especialmente en OpenAi en la transcripci�n

  TAiTranscriptionResponseFormat = (trfText, trfJson, trfSrt, trfVtt, trfVerboseJson);

  // Enum para la granularidad de los timestamps
  TAiTimestampGranularity = (tsgNone, tsgWord, tsgSegment);
  TAiTimestampGranularities = set of TAiTimestampGranularity;

  TAiMediaFiles = Class;

  // Clase utilizada para el manejo de archivos de medios como audio, im�genes e incluso otros medios como pdf, etc.
  TAiMediaFile = Class
  Private
    Ffilename: String;
    FUrlMedia: String;
    FFileType: String;
    FContent: TMemoryStream;
    FFullFileName: String;
    FTranscription: String;
    FProcesado: Boolean;
    FDetail: String;
    FIdAudio: String;
    // FCloudUri: String;
    FCloudState: String;
    FCloudName: String;
    FCacheName: String;
    FIdFile: String;
    FMediaFiles: TAiMediaFiles;
    function GetBase64: String;
    procedure SetBase64(const Value: String);
    procedure Setfilename(const Value: String);
    procedure SetUrlMedia(const Value: String);
    function GetBytes: Integer;
    procedure SetFullFileName(const Value: String);
    function GetMimeType: String;
    function GetFileCategory: TAiFileCategory;
    procedure SetTranscription(const Value: String);
    procedure SetProcesado(const Value: Boolean);
    procedure SetDetail(const Value: String);
    procedure SetIdAudio(const Value: String);
    procedure SetCacheName(const Value: String);
    procedure SetIdFile(const Value: String);
    procedure SetMediaFiles(const Value: TAiMediaFiles);
  Protected
    Procedure DownloadFileFromUrl(Url: String); Virtual;
    function GetContent: TMemoryStream; Virtual;
  Public
    Constructor Create;
    Destructor Destroy; Override;
    Procedure LoadFromfile(aFileName: String); Virtual;
    Procedure LoadFromUrl(aUrl: String); Virtual;
    Procedure LoadFromBase64(aFileName, aBase64: String); Virtual;
    Procedure LoadFromStream(aFileName: String; Stream: TMemoryStream); Virtual;
    Procedure SaveToFile(aFileName: String); Virtual;
    Procedure Clear; Virtual;
    Property filename: String read Ffilename write Setfilename;
    Property bytes: Integer read GetBytes;
    Property Content: TMemoryStream read GetContent;
    Property FileCategory: TAiFileCategory read GetFileCategory;
    // Uri de donde se encuentra el archivo para ser subido al modelo
    Property UrlMedia: String read FUrlMedia write SetUrlMedia;

    // Propiedad para almacenar la URI del archvio ya subido al modelo, id que retorna la API, es la url temporal que asinga el modelo
    // Property CloudUri: String read FCloudUri write SetCloudUri;
    Property CloudState: String read FCloudState write FCloudState;
    // Nombre del archivo con que fue guardado dentro del modelo disponible para la API
    Property CloudName: String read FCloudName write FCloudName;
    // Nombre del archivo guardado como cach� dentro de la api, es posible preguntar entre varias iteracciones del chat
    Property CacheName: String read FCacheName write SetCacheName;

    // El Id con el que se identifica el archivo en el servidor
    Property IdFile: String read FIdFile write SetIdFile;
    // Guarda la URI de archivo generado por la API para almacenar el audio que ya gener� el modelo
    Property IdAudio: String read FIdAudio write SetIdAudio;
    Property Base64: String read GetBase64 write SetBase64;
    Property FullFileName: String read FFullFileName write SetFullFileName;
    Property MimeType: String read GetMimeType;
    // Propiedad que se pasa con el archivo de media, en la imagen con OpenAi  indica si se analiza en detalle o "high" o en baja resoluci�n "low"
    // En la transcripci�n va el otro formato si lo hay,  ej.  el json que genera el formato VTS
    Property Detail: String read FDetail write SetDetail;
    // Transcription- Si el archivo adjunto se procesa por separado aqu� se guarda lo que retorna el modelo correspondiente
    Property Transcription: String read FTranscription write SetTranscription;
    Property Procesado: Boolean read FProcesado write SetProcesado;
    Property MediaFiles: TAiMediaFiles read FMediaFiles write SetMediaFiles;
  End;

  // Conjunto de archivos para su manejo en el chat
  TAiMediaFilesArray = Array of TAiMediaFile;

  TAiMediaFiles = Class(TObjectList<TAiMediaFile>)
  Private
  Protected
  Public
    // Si el modelo nomaneja este tipo de media failes, se pueden preprocesar en el evento del chat
    // y el texto del proceso se adiciona al prompt, y aqu� ya no se tendr�an en cuenta
    Function GetMediaList(aFilters: TAiFileCategories; aProcesado: Boolean = False): TAiMediaFilesArray;
    // = (Tfc_Image, Tfc_Audio, Tfc_Video, Tfc_Document, Tfc_Text, Tfc_CalcSheet, Tfc_Presentation, Tfc_CompressFile, Tfc_Web, Tfc_Aplication, Tfc_DiskImage, Tfc_GraphicDesign, Tfc_Unknow); :
  End;

  // Clase de manejo de los metadatos que se pasan al api del chat de los llm
  TAiMetadata = Class(TDictionary<String, String>)
  Private
    function GetAsText: String;
    procedure SetAsText(const Value: String);
    function GetJSonText: String;
    procedure SetJsonText(const Value: String);
  Protected
  Public
    Function ToJSon: TJSONObject;
    Property AsText: String Read GetAsText Write SetAsText;
    Property JsonText: String Read GetJSonText Write SetJsonText;
  End;

  // Clase que maneja las funciones de los tools
  TAiToolsFunction = class(TObject)
    id: string;
    Tipo: string;
    name: string;
    Description: String;
    Arguments: string;
    Params: TStringList;
    &Function: string;
    Response: String;
    Body: TJSONObject;
    Metadata: TAiMetadata;
    AskMsg: TObject;
    ResMsg: TObject;

    Constructor Create;
    Destructor Destroy; Override;
    Procedure ParseFunction(JObj: TJSONObject);
    Procedure Assign(aSource: TAiToolsFunction);
  end;

  TAiToolsFunctions = Class(TDictionary<String, TAiToolsFunction>)
  Private
  Protected
    procedure ValueNotify(const Value: TAiToolsFunction; Action: TCollectionNotification); override;
  Public
    Function ToOutputJSon: TJSonArray;
    Function ToFunctionsJSon: TJSonArray;
    Procedure AddFunction(aBody: String); Overload;
    Procedure AddFunction(aBody: TJSONObject); Overload;
  End;

  TAiWebSearchItem = Class
    &type: String;
    start_index: Integer;
    end_index: Integer;
    Url: String;
    title: String;
  End;

  TAiWebSearchArray = Class(TObjectList<TAiWebSearchItem>);

  TAiWebSearch = Class
    &type: String;
    text: String;
    annotations: TAiWebSearchArray;
    Constructor Create;
  End;

  // Ejecuta un comando en el shel del sistema operativo correspondiente, Falta implementar bien en MACOS solo Linux, Windows y MACOS
procedure RunCommand(const Command: string);

// Convierte un audio de un formato a otro utilizando ffmpeg, debe estar instalado en la m�quina
procedure ConvertAudioFileFormat(Origen: TMemoryStream; filename: String; out Destino: TMemoryStream; out DestinoFileName: String);

// Partiendo de la extensi�n del archivo obtiene la categoria TAiFileCategori
function GetContentCategory(FileExtension: string): TAiFileCategory;

// Obtiene el mime de un archivo basado en la extensi�n .mp3 o mp3
function GetMimeTypeFromFileName(FileExtension: string): string;

// Convierte un stream en Base64
function StreamToBase64(Stream: TMemoryStream): String;

// convierte una lista de valores Key1=Value1  en una lista de parametros de query de una URL
function GetParametrosURL(Parametros: TStringList): string;

implementation

{$IFDEF LINUX}

uses uLinuxUtils;
{$ENDIF}
{$IFDEF MSWINDOWS}

uses ShellAPI, WinApi.Windows;
{$ENDIF}
{$REGION 'Utilidades varias' }

procedure RunCommand(const Command: string);
begin

{$IFDEF LINUX}
  TLinuxUtils.RunCommandLine(Command);
{$ENDIF}
{$IFDEF MSWINDOWS}
  ShellExecute(0, nil, 'cmd.exe', PChar('/C ' + Command), nil, SW_HIDE);
{$ENDIF}
end;

procedure ConvertAudioFileFormat(Origen: TMemoryStream; filename: String; out Destino: TMemoryStream; out DestinoFileName: String);
Var
  FOrigen, FDestino: String;
  CommandLine: String;
begin
  Destino := Nil;
  DestinoFileName := '';
  filename := LowerCase(filename);
  FDestino := ChangeFileExt(filename, '.mp3');

  FOrigen := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetTempPath, filename);
  FDestino := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetTempPath, FDestino);

  Origen.Position := 0;
  Origen.SaveToFile(FOrigen);

  CommandLine := 'ffmpeg -i ' + FOrigen + ' ' + FDestino;

  RunCommand(CommandLine);

  Destino := TMemoryStream.Create;
  Destino.LoadFromfile(FDestino);
  Destino.Position := 0;
  DestinoFileName := ExtractFileName(FDestino);

  TFile.Delete(FOrigen);
  TFile.Delete(FDestino);
end;

function GetParametrosURL(Parametros: TStringList): string;
var
  i: Integer;
begin
  Result := '';
  if Assigned(Parametros) and (Parametros.Count > 0) then
  begin
    Result := '?';
    for i := 0 to Parametros.Count - 1 do
    begin
      Result := Result + Parametros.Names[i] + '=' + Parametros.ValueFromIndex[i];
      if i < Parametros.Count - 1 then
        Result := Result + '&';
    end;
  end;
end;

function StreamToBase64(Stream: TMemoryStream): String;
begin
  Stream.Position := 0;
  Result := TNetEncoding.Base64.EncodeBytesToString(Stream.Memory, Stream.Size);
end;

function GetMimeTypeFromFileName(FileExtension: string): string;
begin
  FileExtension := LowerCase(Trim(StringReplace(FileExtension, '.', '', [rfReplaceAll])));

  if SameText(FileExtension, 'mp3') then
    Result := 'audio/mpeg'
  else if SameText(FileExtension, 'mp4') then
    Result := 'video/mp4'
  else if SameText(FileExtension, 'mpeg') then
    Result := 'video/mpeg'
  else if SameText(FileExtension, 'mpga') then
    Result := 'audio/mpeg'
  else if SameText(FileExtension, 'm4a') then
    Result := 'audio/mp4'
  else if SameText(FileExtension, 'ogg') then
    Result := 'audio/ogg'
  else if SameText(FileExtension, 'wav') then
    Result := 'audio/wav'
  else if SameText(FileExtension, 'webm') then
    Result := 'video/webm'
  else if SameText(FileExtension, 'txt') then
    Result := 'text/plain'
  else if SameText(FileExtension, 'html') then
    Result := 'text/html'
  else if SameText(FileExtension, 'htm') then
    Result := 'text/html'
  else if SameText(FileExtension, 'css') then
    Result := 'text/css'
  else if SameText(FileExtension, 'csv') then
    Result := 'text/csv'
  else if SameText(FileExtension, 'xml') then
    Result := 'application/xml'
  else if SameText(FileExtension, 'json') then
    Result := 'application/json'
  else if SameText(FileExtension, 'pdf') then
    Result := 'application/pdf'
  else if SameText(FileExtension, 'zip') then
    Result := 'application/zip'
  else if SameText(FileExtension, 'gzip') then
    Result := 'application/gzip'
  else if SameText(FileExtension, 'tar') then
    Result := 'application/x-tar'
  else if SameText(FileExtension, 'rar') then
    Result := 'application/vnd.rar'
  else if SameText(FileExtension, 'exe') then
    Result := 'application/vnd.microsoft.portable-executable'
  else if SameText(FileExtension, 'gif') then
    Result := 'image/gif'
  else if SameText(FileExtension, 'jpeg') then
    Result := 'image/jpeg'
  else if SameText(FileExtension, 'jpg') then
    Result := 'image/jpeg'
  else if SameText(FileExtension, 'png') then
    Result := 'image/png'
  else if SameText(FileExtension, 'bmp') then
    Result := 'image/bmp'
  else if SameText(FileExtension, 'svg') then
    Result := 'image/svg+xml'
  else if SameText(FileExtension, 'ico') then
    Result := 'image/vnd.microsoft.icon'
  else if SameText(FileExtension, 'tiff') then
    Result := 'image/tiff'
  else if SameText(FileExtension, 'tif') then
    Result := 'image/tiff'
  else if SameText(FileExtension, 'avi') then
    Result := 'video/x-msvideo'
  else if SameText(FileExtension, 'mov') then
    Result := 'video/quicktime'
  else if SameText(FileExtension, 'wmv') then
    Result := 'video/x-ms-wmv'
  else if SameText(FileExtension, 'flv') then
    Result := 'video/x-flv'
  else if SameText(FileExtension, '3gp') then
    Result := 'video/3gpp'
  else if SameText(FileExtension, 'mkv') then
    Result := 'video/x-matroska'
  else
    Result := 'application/octet-stream'; // Tipo de contenido predeterminado para otras extensiones
end;

{ 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'svg', 'webp' Result := 'Imagen'
  'mp3', 'wav', 'flac', 'aac', 'ogg', 'wma', 'm4a'   Result := 'Audio'
  'avi', 'mp4', 'mkv', 'mov', 'wmv', 'flv', 'webm'   Result := 'Video'
  'doc', 'docx', 'pdf', 'odt', 'rtf', 'tex'     Result := 'Documento'
  'txt', 'md', 'rtf'     Result := 'Texto'
  'xls', 'xlsx', 'ods', 'csv'  Result := 'Hoja de C�lculo'
  'ppt', 'pptx', 'odp'   Result := 'Presentaci�n'
  'zip', 'rar', 'tar', 'gz', 'bz2', '7z', 'xz'   Result := 'Archivo comprimido'
  'html', 'htm', 'xml', 'json', 'css', 'js'   Result := 'Web'
  'exe', 'msi', 'bat', 'sh', 'bin', 'cmd'   Result := 'Aplicaci�n'
  'iso', 'img'   Result := 'Imagen de Disco'
  'psd', 'ai'    Result := 'Dise�o Gr�fico'
  Result := 'Desconocido';
}

function GetContentCategory(FileExtension: string): TAiFileCategory;
begin
  FileExtension := LowerCase(Trim(StringReplace(ExtractFileName(FileExtension), '.', '', [rfReplaceAll])));

  if (FileExtension = 'jpg') or (FileExtension = 'jpeg') or (FileExtension = 'png') or (FileExtension = 'gif') or (FileExtension = 'bmp') or
    (FileExtension = 'tiff') or (FileExtension = 'svg') or (FileExtension = 'webp') then
    Result := Tfc_Image
  else if (FileExtension = 'mp3') or (FileExtension = 'wav') or (FileExtension = 'flac') or (FileExtension = 'aac') or
    (FileExtension = 'ogg') or (FileExtension = 'wma') or (FileExtension = 'm4a') then
    Result := Tfc_Audio
  else if (FileExtension = 'avi') or (FileExtension = 'mp4') or (FileExtension = 'mkv') or (FileExtension = 'mov') or
    (FileExtension = 'wmv') or (FileExtension = 'flv') or (FileExtension = 'webm') then
    Result := Tfc_Video
  else if (FileExtension = 'doc') or (FileExtension = 'docx') or (FileExtension = 'pdf') or (FileExtension = 'odt') or
    (FileExtension = 'rtf') or (FileExtension = 'tex') then
    Result := Tfc_Document
  else if (FileExtension = 'txt') or (FileExtension = 'md') or (FileExtension = 'rtf') then
    Result := Tfc_Text
  else if (FileExtension = 'xls') or (FileExtension = 'xlsx') or (FileExtension = 'ods') or (FileExtension = 'csv') then
    Result := Tfc_CalcSheet
  else if (FileExtension = 'ppt') or (FileExtension = 'pptx') or (FileExtension = 'odp') then
    Result := Tfc_Presentation
  else if (FileExtension = 'zip') or (FileExtension = 'rar') or (FileExtension = 'tar') or (FileExtension = 'gz') or (FileExtension = 'bz2')
    or (FileExtension = '7z') or (FileExtension = 'xz') then
    Result := Tfc_CompressFile
  else if (FileExtension = 'html') or (FileExtension = 'htm') or (FileExtension = 'xml') or (FileExtension = 'json') or
    (FileExtension = 'css') or (FileExtension = 'js') then
    Result := Tfc_Web
  else if (FileExtension = 'psd') or (FileExtension = 'ai') then
    Result := Tfc_GraphicDesign
  else
    Result := Tfc_Unknow;
end;

{ TAiMediaFiles }

procedure TAiMediaFile.Clear;
begin
  FContent.Clear;
  Ffilename := '';
  FUrlMedia := '';
  FFileType := '';
  FFullFileName := '';
  FTranscription := '';
  FProcesado := False;
  FDetail := '';
  FIdAudio := '';
  // FCloudUri := ''
end;

constructor TAiMediaFile.Create;
begin
  Inherited;
  FContent := TMemoryStream.Create;
  FMediaFiles := TAiMediaFiles.Create;
  FProcesado := False;
  FDetail := ''; // por defecto utiliza vac�o para no enviar nada y hacerlo compatible con otros modelos, detallado = "high" or "low"
end;

destructor TAiMediaFile.Destroy;
begin
  FContent.Free;
  FMediaFiles.Clear;
  FMediaFiles.Free;
  inherited;
end;

procedure TAiMediaFile.DownloadFileFromUrl(Url: String);
Var
  Client: THTTPClient;
  Headers: TNetHeaders;
  Response: TMemoryStream;
  Res: IHTTPResponse;
begin

  If Url <> '' then
  Begin

    Client := THTTPClient.Create;
    Response := TMemoryStream.Create;

    Try

      Res := Client.Get(Url, Response, Headers);

      if Res.StatusCode = 200 then
      Begin

        FContent.Clear; // Limpia el contenido actual antes de adicionar el nuevo
        FContent.Position := 0;

        Response.Position := 0;
        FContent.LoadFromStream(Response);
        FContent.Position := 0;
      End
      else
        Raise Exception.CreateFmt('Error Received: %d, %s', [Res.StatusCode, Res.ContentAsString]);

    Finally
      Client.Free;
      Response.Free;
    End;
  End;
end;

function TAiMediaFile.GetBase64: String;
begin
  FContent.Position := 0;
  Result := TNetEncoding.Base64.EncodeBytesToString(FContent.Memory, FContent.Size);
  Result := StringReplace(Result, sLineBreak, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]); // #10 es LF (\n)
end;

function TAiMediaFile.GetBytes: Integer;
begin
  Result := FContent.Size;
end;

function TAiMediaFile.GetContent: TMemoryStream;
begin
  Result := FContent;
  If FContent.Size > 5000 then // Si ya est� cargado el archivo solo lo retorna
    Exit;
  // Si tiene asignada una url la carga de la url y la deja en memoria

  If FUrlMedia <> '' then
  Begin
    DownloadFileFromUrl(FUrlMedia);
    Result := FContent;
  End;
end;

function TAiMediaFile.GetFileCategory: TAiFileCategory;
begin
  If Trim(Ffilename) = '' then
    Result := Tfc_Unknow
  Else
    Result := GetContentCategory(ExtractFileExt(LowerCase(Ffilename)));
end;

function TAiMediaFile.GetMimeType: String;
begin
  Result := GetMimeTypeFromFileName(LowerCase(ExtractFileExt(Ffilename)));
end;

procedure TAiMediaFile.LoadFromBase64(aFileName, aBase64: String);
Var
  St: TMemoryStream;
begin
  St := TBytesStream.Create(TNetEncoding.Base64.DecodeStringToBytes(aBase64));
  Try
    If Assigned(St) then
    Begin
      FContent.Clear;
      FContent.LoadFromStream(St);
      FFullFileName := aFileName;
      Ffilename := ExtractFileName(aFileName);
      FFileType := ExtractFileExt(filename);
    End;
  Finally
    St.Free;
  End;
end;

procedure TAiMediaFile.LoadFromfile(aFileName: String);
begin
  If TFile.Exists(aFileName) then
  Begin
    FContent.Clear;
    FContent.LoadFromfile(aFileName);
    FFullFileName := aFileName;
    Ffilename := ExtractFileName(aFileName);
    FFileType := LowerCase(ExtractFileExt(Ffilename));
  End;
end;

procedure TAiMediaFile.LoadFromStream(aFileName: String; Stream: TMemoryStream);
begin
  If Assigned(Stream) then
  Begin
    FContent.Clear;
    FContent.LoadFromStream(Stream);
    FFullFileName := aFileName;
    Ffilename := ExtractFileName(aFileName);
    FFileType := LowerCase(ExtractFileExt(Ffilename));
  End;
end;

procedure TAiMediaFile.LoadFromUrl(aUrl: String);
begin
  FUrlMedia := aUrl;
  FContent.Clear;
  GetContent;

  FFullFileName := aUrl;
  Ffilename := ExtractFileName(aUrl);
  FFileType := ExtractFileExt(filename);

end;

procedure TAiMediaFile.SaveToFile(aFileName: String);
begin
  FContent.SaveToFile(aFileName);
end;

procedure TAiMediaFile.SetBase64(const Value: String);
begin
  LoadFromBase64('', Value);
end;

procedure TAiMediaFile.SetCacheName(const Value: String);
begin
  FCacheName := Value;
end;

procedure TAiMediaFile.SetDetail(const Value: String);
begin
  FDetail := Value;
end;

procedure TAiMediaFile.Setfilename(const Value: String);
begin
  Ffilename := Value;
end;

procedure TAiMediaFile.SetFullFileName(const Value: String);
begin
  FFullFileName := Value;
end;

procedure TAiMediaFile.SetIdAudio(const Value: String);
begin
  FIdAudio := Value;
end;

procedure TAiMediaFile.SetIdFile(const Value: String);
begin
  FIdFile := Value;
end;

procedure TAiMediaFile.SetMediaFiles(const Value: TAiMediaFiles);
begin
  FMediaFiles := Value;
end;

procedure TAiMediaFile.SetProcesado(const Value: Boolean);
begin
  FProcesado := Value;
end;

procedure TAiMediaFile.SetTranscription(const Value: String);
begin
  FTranscription := Value;
end;

procedure TAiMediaFile.SetUrlMedia(const Value: String);
begin
  FUrlMedia := Value;
end;

{ TAiMediaFiles }

function TAiMediaFiles.GetMediaList(aFilters: TAiFileCategories; aProcesado: Boolean = False): TAiMediaFilesArray;
var
  i: Integer;
  Item: TAiMediaFile;
  Len: Integer;
begin
  SetLength(Result, 0); // Inicializamos el resultado para evitar basura
  for i := 0 to Self.Count - 1 do
  begin
    Item := Self.Items[i];
    if (Item.FileCategory in aFilters) and (Item.Procesado = aProcesado) then
    begin
      Len := Length(Result);
      SetLength(Result, Len + 1);
      Result[Len] := Item;
    end;
  end;
end;

{
  function TAiMediaFiles.GetMediaList(aFilter: TAiFileCategory; aProcesado: Boolean = False): TAiMediaFilesArray;
  Var
  i: Integer;
  Item: TAiMediaFile;
  Len: Integer;
  begin
  For i := 0 to Self.Count - 1 do
  Begin
  Item := Self.Items[i];
  If (Item.FileCategory = aFilter) and (Item.Procesado = aProcesado) then
  Begin
  Len := Length(Result);
  SetLength(Result, Len + 1);
  Result[Length(Result) - 1] := Item;
  End;
  End;
  end;
}

{ TAiToolFunction }

procedure TAiToolsFunction.Assign(aSource: TAiToolsFunction);
begin
  Self.id := aSource.id;
  Self.Tipo := aSource.Tipo;
  Self.name := aSource.name;
  Self.Description := aSource.Description;
  Self.Arguments := aSource.Arguments;
  Self.&Function := aSource.&Function;
  Self.Response := aSource.Response;
  Self.Body := aSource.Body;
  Metadata.JsonText := aSource.Metadata.JsonText;
end;

constructor TAiToolsFunction.Create;
begin
  inherited;
  Metadata := TAiMetadata.Create;
  Params := TStringList.Create;

end;

destructor TAiToolsFunction.Destroy;
begin
  Metadata.Free;
  Params.Free;
  inherited;
end;

procedure TAiToolsFunction.ParseFunction(JObj: TJSONObject);
Var
  JFunc: TJSONObject;
  FunName: String;
begin
  JFunc := JObj.GetValue<TJSONObject>('function');
  FunName := JFunc.GetValue<string>('name');

  Begin
    Name := JFunc.GetValue<String>('name');
    Self.Description := JFunc.GetValue<String>('description');
    &Function := JFunc.Format;
    Body := JObj; // La funcion original completa
  End;
end;

{ TAiMetadata }

function TAiMetadata.GetAsText: String;
Var
  Lista: TStringList;
  Clave: String;
begin

  Lista := TStringList.Create;
  Try
    For Clave in Self.Keys do
      Lista.Values[Clave] := Self.Items[Clave];

    Result := Lista.text;

  Finally
    Lista.Free;
  End;
end;

function TAiMetadata.GetJSonText: String;
Var
  JObj: TJSONObject;
  Clave: String;
begin
  JObj := TJSONObject.Create;

  Try
    For Clave in Self.Keys do
      JObj.AddPair(Clave, Self.Items[Clave]);

    Result := JObj.Format;
  Finally
    JObj.Free;
  End;
end;

procedure TAiMetadata.SetAsText(const Value: String);
Var
  Lista: TStringList;
  Clave, Valor: String;
  i: Integer;
begin

  Lista := TStringList.Create;

  Try
    Lista.text := Value;
    Self.Clear;
    For i := 0 to Lista.Count - 1 do
    Begin
      Clave := Lista.Names[i];
      Valor := Lista.Values[Clave];
      Self.Add(Clave, Valor);
    End;
  Finally
    Lista.Free;
  End;

end;

procedure TAiMetadata.SetJsonText(const Value: String);
Var
  JObj: TJSONObject;
  Pair: TJSONPair;
begin
  Self.Clear;
  JObj := TJSONObject(TJSONObject.ParseJSONValue(Value));
  try
    For Pair in JObj do
      Self.Add(Pair.JsonString.Value, Pair.JsonValue.Value)
  finally
    JObj.Free;
  end;
end;

function TAiMetadata.ToJSon: TJSONObject;
Var
  Clave: String;
begin
  Result := TJSONObject.Create;
  For Clave in Self.Keys do
    Result.AddPair(Clave, Self.Items[Clave]);
end;

{ TAitools_outputs }

procedure TAiToolsFunctions.AddFunction(aBody: TJSONObject);
Var
  Func, Func1: TAiToolsFunction;
begin
  Func := TAiToolsFunction.Create;
  Func.ParseFunction(aBody);

  If Self.TryGetValue(Func.name, Func1) = False then
    Self.Add(Func.name, Func)
  Else
  Begin
    Func1.Assign(Func);
    Func.Free;
  End;
end;

procedure TAiToolsFunctions.ValueNotify(const Value: TAiToolsFunction; Action: TCollectionNotification);
begin
  case Action of
    cnDeleting, cnRemoved:
      Value.Free;
  end;
  inherited;
end;

procedure TAiToolsFunctions.AddFunction(aBody: String);
Var
  Func: TJSONObject;
begin
  Func := TJSONObject(TJSONObject.ParseJSONValue(aBody));
  AddFunction(Func);
end;

function TAiToolsFunctions.ToFunctionsJSon: TJSonArray;
Var
  Clave: String;
  TObj: TJSONObject;
  Func: TAiToolsFunction;
begin
  Result := TJSonArray.Create;

  For Clave in Self.Keys do
  Begin
    Func := Self.Items[Clave];
    // Result.Add(TJSonObject(TJSonObject.ParseJSONValue(Self.Items[Clave].&Function)));
    TObj := TJSONObject(Func.Body.Clone);
    // TObj.AddPair('type', 'function');
    // TObj.AddPair('function', TJsonObject(Func.Body.Clone));
    Result.Add(TObj);
  End;
end;

function TAiToolsFunctions.ToOutputJSon: TJSonArray;
Var
  Clave: String;
  TObj: TJSONObject;
begin
  Result := TJSonArray.Create;

  For Clave in Self.Keys do // La clave es el nombre de la funci�n
  Begin
    TObj := TJSONObject.Create;
    TObj.AddPair('tool_call_id', Self.Items[Clave].id);
    TObj.AddPair('output', Self.Items[Clave].Response);
    Result.Add(TObj);
  End;
end;

{ TAiWebSearch }

constructor TAiWebSearch.Create;
begin
  &type := '';
  text := '';
  annotations := TAiWebSearchArray.Create;
end;

end.
