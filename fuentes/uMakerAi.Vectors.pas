unit uMakerAi.Vectors;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections,
  System.Generics.Defaults, System.Classes, System.JSon, Rest.JSon,
  System.NetEncoding, uMakerAi.Chat, uMakerAi.Embeddings;

type

  ///---------------------------------------------------------------------------
  ///  TAiEmbeddingNode identifica un embedding, cincluyendo la longitud
  ///  el modelo y los datos, permite adicionalmente comparar dos embeddings
  ///  para conocer su similitud por coseno,  convierte de json a vector y de
  ///  vector a json
  ///  almacena tambi�n el dato de texto original del embedding
  ///  -------------------------------------------------------------------------
  TAiEmbeddingNode = class
  private
    FData: TAiEmbeddingData;
    FDim: Integer;
    FTagObject: TObject;
    FTag: Integer;
    FText: String;
    FjData: TJSonObject;
    FIdx: Double;
    FOrden: Integer;
    FModel: String;
    procedure SetData(const Value: TAiEmbeddingData);
    class function DotProduct(const A, B: TAiEmbeddingNode): Double;
    class function Magnitude(const A: TAiEmbeddingNode): Double;
    procedure SetjData(const Value: TJSonObject);
    procedure SetTag(const Value: Integer);
    procedure SetTagObject(const Value: TObject);
    procedure SetText(const Value: String);
    procedure SetIdx(const Value: Double);
    procedure SetOrden(const Value: Integer);
    procedure SetModel(const Value: String);
  public
    Constructor Create(aDim: Integer);
    Destructor Destroy; Override;
    class function CosineSimilarity(const A, B: TAiEmbeddingNode): Double;
    class Function ToJsonArray(Val: TAiEmbeddingNode): TJSonArray; Overload;
    Function ToJsonArray: TJSonArray; Overload;
    function ToJSON: TJSonObject;
    class function FromJSON(AJSONObject: TJSonObject): TAiEmbeddingNode;
    property Data: TAiEmbeddingData read FData write SetData;
    Property jData: TJSonObject read FjData write SetjData;
    Property Text: String read FText write SetText;
    Property TagObject: TObject read FTagObject write SetTagObject;
    Property Tag: Integer read FTag write SetTag;
    Property Dim: Integer read FDim;
    Property Idx: Double read FIdx write SetIdx;
    Property Orden: Integer read FOrden write SetOrden;
    Property Model: String read FModel write SetModel;
  end;

  TAiDataVec = Class;

  TOnDataVecAddItem = Procedure(Sender: TObject; aItem: TAiEmbeddingNode; Var Handled: Boolean) of object;
  TOnDataVecSearch = Procedure(Sender: TObject; Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double; Var aDataVec: TAiDataVec; Var Handled: Boolean) of object;

  ///---------------------------------------------------------------------------
  ///  TAIEmbeddingIndex representa la clase base para la b�squeda con embeddings en memoria
  ///  consiste en un vector de nodos y un indice de punteros a embeddings que permite la
  ///  b�squeda y seleccion de los candidatos que cumplen la condici�n
  ///  -------------------------------------------------------------------------
  TAIEmbeddingIndex = class
  private
    FDataVec: TAiDataVec;
    FActive: Boolean;
    procedure SetDataVec(const Value: TAiDataVec);
  public
    constructor Create; Virtual;
    destructor Destroy; override;
    procedure BuildIndex(Points: TAiDataVec); Virtual;
    Function Add(Point: TAiEmbeddingNode): Integer; Virtual;
    Function Search(Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double): TAiDataVec; Virtual;
    Function Connect(aHost, aPort, aLogin, aPassword: String): Boolean; Virtual;
    Property DataVec: TAiDataVec read FDataVec write SetDataVec;
    Property Active: Boolean read FActive;
  end;

  ///---------------------------------------------------------------------------
  ///  TAIBasicEmbeddingIndex implementaci�n sencilla de un Indice de embeddings
  ///  el cual se asigna por defecto al vector para realizar b�squedas en memoria
  ///  sin embargo hay maneras m�s eficientes de controlar esto en vectores de
  ///  embeddings.
  ///  -------------------------------------------------------------------------

  TAIBasicEmbeddingIndex = class(TAIEmbeddingIndex)
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure BuildIndex(Points: TAiDataVec); Override;
    Function Search(Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double): TAiDataVec; Override;
  end;



  ///---------------------------------------------------------------------------
  ///  TAiDataVec es la clase base que permite almacenar conjuntos de embeddings
  ///  se utiliza tanto para representar bases de datos de embeddings en memoria
  ///  como para la conexi�n con bases de datos de embeddings.
  ///  Por si solo no indexa ni b�sca, solo es el contenedor, para buscar
  ///  es necesario adicionar un TAIEmbeddingIndex, aunque por defecto tiene
  ///  un indice b�sico de b�squeda, pero hay modelos mejores.
 ///  -------------------------------------------------------------------------
  TAiDataVec = Class(TComponent)
  Private
    FActive: Boolean;
    FRagIndex: TAIEmbeddingIndex;
    FEmbeddings: TAiEmbeddings;
    FItems: TList<TAiEmbeddingNode>;
    FOnDataVecAddItem: TOnDataVecAddItem;
    FOnDataVecSearch: TOnDataVecSearch;
    FDim: Integer;
    FModel: String;
    FNameVec: String;
    FDescription: String;
    procedure SetActive(const Value: Boolean);
    procedure SetRagIndex(const Value: TAIEmbeddingIndex);
    procedure SetEmbeddings(const Value: TAiEmbeddings);
    function GetItems: TList<TAiEmbeddingNode>;
    procedure SetOnDataVecAddItem(const Value: TOnDataVecAddItem);
    procedure SetOnDataVecSearch(const Value: TOnDataVecSearch);
    procedure SetDescription(const Value: String);
    procedure SetNameVec(const Value: String);
  Protected

  Public
    Constructor Create(aOwner: TComponent); Override;
    Destructor Destroy; Override;
    Procedure SaveToStream(Stream: TMemoryStream);
    Procedure LoadFromStream(Stream: TMemoryStream);
    Procedure SaveToFile(FileName: String);
    Procedure LoadFromFile(FileName: String);
    Function Connect(aHost, aPort, aLogin, aPassword: String): Boolean;
    Function Search(Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double): TAiDataVec; Overload;
    Function Search(Prompt: String; aLimit: Integer; aPrecision: Double): TAiDataVec; Overload;
    procedure BuildIndex;

    Function AddItem(aItem: TAiEmbeddingNode): NativeInt; Overload; Virtual;
    Function AddItem(aText: String): TAiEmbeddingNode; Overload; Virtual;

    Function AddItemsFromJSonArray(aJSonArray: TJSonArray): Boolean; Virtual;
    Function AddItemsFromPlainText(aText: String; aLenChunk: Integer = 512; aLenOverlap: Integer = 80): Boolean; Virtual;
    Function CreateEmbeddingNode(aText: String; aEmbeddings: TAiEmbeddings = Nil): TAiEmbeddingNode;
    Function Count: Integer;
    Procedure Clear;

    Property RagIndex: TAIEmbeddingIndex read FRagIndex write SetRagIndex;
    Property Active: Boolean read FActive write SetActive;
    Property Items: TList<TAiEmbeddingNode> read GetItems;
  Published
    Property OnDataVecAddItem: TOnDataVecAddItem read FOnDataVecAddItem write SetOnDataVecAddItem;
    Property OnDataVecSearch: TOnDataVecSearch read FOnDataVecSearch write SetOnDataVecSearch;
    Property Embeddings: TAiEmbeddings read FEmbeddings write SetEmbeddings;
    Property Model: String read FModel;
    Property Dim: Integer read FDim;
    Property NameVec: String read FNameVec write SetNameVec;
    Property Description: String read FDescription write SetDescription;
  End;

  TAiRagChat = Class(TComponent)
  Private
    FDataVec: TAiDataVec;
    FChat: TAiOpenChat;
    procedure SetChat(const Value: TAiOpenChat);
    procedure SetDataVec(const Value: TAiDataVec);
  Protected
  Public
    Constructor Create(aOwner: TComponent); Override;
    Destructor Destroy; Override;
    Function AskToAi(aPrompt: String; aLimit: Integer = 10; aPresicion: Double = 0.5): String; Overload; Virtual;
    Function AskToAi(aPrompt: TAiEmbeddingNode; aLimit: Integer = 10; aPresicion: Double = 0.5): String; Overload; Virtual;
    Function AskToAi(aPrompt: String; DataVec: TAiDataVec): String; Overload; Virtual;
  Published
    Property Chat: TAiOpenChat read FChat write SetChat;
    Property DataVec: TAiDataVec read FDataVec write SetDataVec;
  End;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('MakerAI', [TAiRagChat, TAiDataVec]);

end;

procedure TAiEmbeddingNode.SetData(const Value: TAiEmbeddingData);
begin
  FData := Value;
end;

procedure TAiEmbeddingNode.SetIdx(const Value: Double);
begin
  FIdx := Value;
end;

procedure TAiEmbeddingNode.SetjData(const Value: TJSonObject);
begin
  FjData := Value;
end;

procedure TAiEmbeddingNode.SetModel(const Value: String);
begin
  FModel := Value;
end;

procedure TAiEmbeddingNode.SetOrden(const Value: Integer);
begin
  FOrden := Value;
end;

procedure TAiEmbeddingNode.SetTag(const Value: Integer);
begin
  FTag := Value;
end;

procedure TAiEmbeddingNode.SetTagObject(const Value: TObject);
begin
  FTagObject := Value;
end;

procedure TAiEmbeddingNode.SetText(const Value: String);
begin
  FText := Value;
end;

function TAiEmbeddingNode.ToJSON: TJSonObject;
var
  JSONArray: TJSonArray;
  Value: Double;
begin
  Result := TJSonObject.Create;
  JSONArray := TJSonArray.Create;

  for Value in FData do
    JSONArray.Add(Value);

  Result.AddPair('data', JSONArray);
  Result.AddPair('text', FText);
  Result.AddPair('json', FjData);
  Result.AddPair('orden', FOrden);
end;

function TAiEmbeddingNode.ToJsonArray: TJSonArray;
Var
  i: Integer;
begin
  Result := TJSonArray.Create;

  For i := 0 to Length(FData) - 1 do
    Result.Add(FData[i]);
end;

class function TAiEmbeddingNode.ToJsonArray(Val: TAiEmbeddingNode): TJSonArray;
Var
  i: Integer;
begin
  Result := TJSonArray.Create;

  For i := 0 to Length(Val.FData) - 1 do
    Result.Add(Val.FData[i]);
end;

class function TAiEmbeddingNode.CosineSimilarity(const A, B: TAiEmbeddingNode): Double;
var
  MagA, MagB, DotProd: Double;
begin
  if Length(A.Data) <> Length(B.Data) then
    raise Exception.Create('Los vectores deben ser de la misma longitud');

  MagA := Magnitude(A);
  MagB := Magnitude(B);

  if (MagA = 0) or (MagB = 0) then
    Exit(0)
  else
  begin
    DotProd := DotProduct(A, B);
    Result := DotProd / (MagA * MagB);
  end;
end;

constructor TAiEmbeddingNode.Create(aDim: Integer);
begin
  FDim := aDim;
  SetLength(FData, FDim);
end;

destructor TAiEmbeddingNode.Destroy;
begin

  inherited;
end;

class function TAiEmbeddingNode.DotProduct(const A, B: TAiEmbeddingNode): Double;
var
  i: Integer;
begin
  if Length(A.Data) <> Length(B.Data) then
    raise Exception.Create('Los vectores deben ser de la misma longitud');

  Result := 0;

  for i := Low(A.FData) to High(A.FData) do
    Result := Result + A.FData[i] * B.FData[i];
end;

class function TAiEmbeddingNode.FromJSON(AJSONObject: TJSonObject): TAiEmbeddingNode;
var
  JSONArray: TJSonArray;
  i: Integer;
begin
  JSONArray := AJSONObject.GetValue<TJSonArray>('data');
  Result := TAiEmbeddingNode.Create(JSONArray.Count);
  // SetLength(Result.FData, JSONArray.Count);

  for i := 0 to JSONArray.Count - 1 do
    Result.FData[i] := JSONArray.Items[i].AsType<Double>;

  AJSONObject.TryGetValue<String>('text', Result.FText);
  AJSONObject.TryGetValue<TJSonObject>('json', Result.FjData);
  AJSONObject.TryGetValue<Integer>('json', Result.FOrden);
end;

class function TAiEmbeddingNode.Magnitude(const A: TAiEmbeddingNode): Double;
var
  Sum: Double;
  i: Integer;
begin
  Sum := 0.0;
  for i := Low(A.FData) to High(A.FData) do
    Sum := Sum + A.FData[i] * A.FData[i];

  Result := Sqrt(Sum);
end;

function CompareEmbeddings(const Left, Right: TAiEmbeddingNode; Axis: Integer): Integer;
const
  TOLERANCE = 1.0E-12;
begin
  if Abs(Left.Data[Axis] - Right.Data[Axis]) < TOLERANCE then
    Result := 0
  else if Left.Data[Axis] < Right.Data[Axis] then
    Result := -1
  else
    Result := 1;
end;

{ TOAiDataVec }

Function TAiDataVec.AddItem(aItem: TAiEmbeddingNode): NativeInt;
Var
  Handled: Boolean;
begin
  Handled := False;

  If Assigned(FOnDataVecAddItem) then
    FOnDataVecAddItem(Self, aItem, Handled);

  If Handled = True then
  Begin
    aItem.Free; // Si se almacena en la base de datos no se necesita en memoria
  End
  Else
  Begin // Se almacena en memoria y se asigna al indice en memoria si lo hay
    Result := Self.FItems.Add(aItem);
    If Assigned(FRagIndex) then
      FRagIndex.Add(aItem);
  End;

  // En cualquiera de los casos si logr� almacenarlo, guarda el modelo y la longitud
  FModel := aItem.Model;
  FDim := aItem.Dim;
end;

function TAiDataVec.AddItem(aText: String): TAiEmbeddingNode;
Var
  Ar: TAiEmbeddingData;
begin
  If not Assigned(FEmbeddings) then
    Raise Exception.Create('No se ha asignado un modelo de embeddings');

  Try
    Ar := FEmbeddings.CreateEmbedding(aText, 'user');

    Result := TAiEmbeddingNode.Create(1);
    Result.Text := aText;
    Result.Data := Ar;
    Result.Model := FEmbeddings.Model;

    Self.AddItem(Result); // LLama al additem(TAiEmbeddingNode);
  Finally
  End;
end;

function TAiDataVec.AddItemsFromJSonArray(aJSonArray: TJSonArray): Boolean;
Var
  JVal: TJsonValue;
  Emb: TAiEmbeddingNode;
  i: Integer;
begin
  i := 0;
  For JVal in aJSonArray do
  Begin
    Emb := AddItem(JVal.Format);
    Emb.Orden := i;
    Inc(i);
  End;
  Result := True;
end;

function TAiDataVec.AddItemsFromPlainText(aText: String; aLenChunk, aLenOverlap: Integer): Boolean;
Var
  i: Integer;
  S, Text: String;
  Emb: TAiEmbeddingNode;
begin

  i := 0;
  Text := aText.trim;
  Repeat
    S := Copy(Text, 1, aLenChunk).trim;

    Emb := AddItem(S);
    Emb.Orden := i;
    Text := Copy(Text, aLenChunk - aLenOverlap, Length(Text));
    Inc(i);
  Until Length(Text) <= 0;
end;

procedure TAiDataVec.BuildIndex;
begin
  If not Assigned(FRagIndex) then
    Raise Exception.Create('No existe un indice asignado');

  FRagIndex.BuildIndex(Self);
  FActive := True;
end;

procedure TAiDataVec.Clear;
begin
  FItems.Clear;
end;

function TAiDataVec.Connect(aHost, aPort, aLogin, aPassword: String): Boolean;
begin
  If not Assigned(FRagIndex) then
    Raise Exception.Create('No existe un indice asignado');

  Result := FRagIndex.Connect(aHost, aPort, aLogin, aPassword);
  FActive := True;
end;

function TAiDataVec.Count: Integer;
begin
  Result := FItems.Count;
end;

constructor TAiDataVec.Create(aOwner: TComponent);
begin
  inherited;
  FItems := TList<TAiEmbeddingNode>.Create;

  // Por defecto crea un indice en memoria sencillo
  // Si se personaliza con eventos no se utiliza
  // Se pueden crear indices m�s complejos en memoria tambi�n
  FRagIndex := TAIBasicEmbeddingIndex.Create;
  BuildIndex; // Inicializa el Indice
end;

function TAiDataVec.CreateEmbeddingNode(aText: String; aEmbeddings: TAiEmbeddings): TAiEmbeddingNode;
Var
  Ar: TAiEmbeddingData;
begin
  If aEmbeddings = Nil then
    aEmbeddings := FEmbeddings;

  If aEmbeddings = Nil then
    Raise Exception.Create('Debe especificar un modelo de embeddings primero');

  Try
    Ar := aEmbeddings.CreateEmbedding(aText, 'user');
    Result := TAiEmbeddingNode.Create(1);
    Result.Text := aText;
    Result.Data := Ar;
    Result.Model := aEmbeddings.Model;
  Finally
  End;
end;

destructor TAiDataVec.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TAiDataVec.GetItems: TList<TAiEmbeddingNode>;
begin
  Result := FItems;
end;

procedure TAiDataVec.LoadFromFile(FileName: String);
Var
  ST: TStringStream;
begin
  ST := TStringStream.Create;
  Try
    ST.LoadFromFile(FileName);
    LoadFromStream(ST);
  Finally
    ST.Free;
  End;
end;

procedure TAiDataVec.LoadFromStream(Stream: TMemoryStream);
Var
  ST: TStringStream;
  JItem, JObj: TJSonObject;
  JArr: TJSonArray;
  JVal: TJsonValue;
  Emb: TAiEmbeddingNode;
begin
  ST := TStringStream.Create;

  Try
    Stream.Position := 0;
    ST.LoadFromStream(Stream);

    JObj := TJSonObject(TJSonObject.ParseJSONValue(ST.DataString));
    Try
      JObj.TryGetValue<String>('name', FNameVec);
      JObj.TryGetValue<String>('description', FDescription);
      JObj.TryGetValue<String>('model', FModel);
      JObj.TryGetValue<Integer>('dim', FDim);
      JObj.TryGetValue<TJSonArray>('data', JArr);

      If Assigned(JArr) then
      Begin
        For JVal in JArr do
        Begin
          JItem := TJSonObject(JVal);
          Emb := TAiEmbeddingNode.FromJSON(JItem);
          Self.Items.Add(Emb);
        End;
      End;
    Finally
      JObj.Free;
    End;
  Finally
    ST.Free;
  End;
end;

procedure TAiDataVec.SaveToFile(FileName: String);
Var
  ST: TMemoryStream;
begin
  ST := TMemoryStream.Create;
  Try
    SaveToStream(ST);
    ST.SaveToFile(FileName);
  Finally
    ST.Free;
  End;
end;

procedure TAiDataVec.SaveToStream(Stream: TMemoryStream);
Var
  Emb: TAiEmbeddingNode;
  i: Integer;
  ST: TStringStream;
  JArr: TJSonArray;
  JItem, JObj: TJSonObject;
begin
  If Not Assigned(Stream) then
    Stream := TMemoryStream.Create;

  JArr := TJSonArray.Create;

  JObj := TJSonObject.Create;
  JObj.AddPair('name', FNameVec);
  JObj.AddPair('description', FDescription);
  JObj.AddPair('model', FModel);
  JObj.AddPair('dim', FDim);
  JObj.AddPair('data', JArr);

  For i := 0 to FItems.Count - 1 do
  Begin
    Emb := FItems[i];
    JItem := Emb.ToJSON;
    JArr.Add(JItem)
  End;

  ST := TStringStream.Create(JObj.Format, TEncoding.Ansi);
  Try
    Stream.LoadFromStream(ST);
  Finally
    ST.Free;
    JArr.Free;
  End;
end;

function TAiDataVec.Search(Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double): TAiDataVec;
Var
  Handled: Boolean;
begin
  Handled := False;

  If Assigned(FOnDataVecSearch) then
    FOnDataVecSearch(Self, Target, aLimit, aPrecision, Result, Handled);

  If Handled = False then
  Begin
    If not Assigned(FRagIndex) then
      Raise Exception.Create('No existe un indice asignado');

    If (FModel <> '') and (FModel <> Target.Model) then
      Raise Exception.Create('Los modelos de embedding no coinciden BD="' + FModel + '" B�squeda="' + Target.Model + '"');

    Result := FRagIndex.Search(Target, aLimit, aPrecision);
  End;
end;

function TAiDataVec.Search(Prompt: String; aLimit: Integer; aPrecision: Double): TAiDataVec;
Var
  Target: TAiEmbeddingNode;
begin
  If Not Assigned(FEmbeddings) then
    Raise Exception.Create('Debe asignar primero un modelo de Embeddigns');

  Target := CreateEmbeddingNode(Prompt);
  Try
    Result := Search(Target, aLimit, aPrecision); // Llama al search(TAiEmbeddingNode, Integer, Double);
  Finally
    Target.Free;
  End;
end;

procedure TAiDataVec.SetActive(const Value: Boolean);
begin
  FActive := Value;
end;

procedure TAiDataVec.SetDescription(const Value: String);
begin
  FDescription := Value;
end;

procedure TAiDataVec.SetEmbeddings(const Value: TAiEmbeddings);
begin
  FEmbeddings := Value;
end;

procedure TAiDataVec.SetNameVec(const Value: String);
begin
  FNameVec := Value;
end;

procedure TAiDataVec.SetOnDataVecAddItem(const Value: TOnDataVecAddItem);
begin
  FOnDataVecAddItem := Value;
end;

procedure TAiDataVec.SetOnDataVecSearch(const Value: TOnDataVecSearch);
begin
  FOnDataVecSearch := Value;
end;

procedure TAiDataVec.SetRagIndex(const Value: TAIEmbeddingIndex);
begin
  FRagIndex := Value;
end;

function TAIEmbeddingIndex.Add(Point: TAiEmbeddingNode): Integer;
begin
  // Esta funci�n se debe implementar en cada modelo solo cuando sea necesario
end;

{ TOAIIndex }

procedure TAIEmbeddingIndex.BuildIndex(Points: TAiDataVec);
begin
  FDataVec := Points;
end;

function TAIEmbeddingIndex.Connect(aHost, aPort, aLogin, aPassword: String): Boolean;
begin

end;

constructor TAIEmbeddingIndex.Create;
begin

end;

destructor TAIEmbeddingIndex.Destroy;
begin

  inherited;
end;

function TAIEmbeddingIndex.Search(Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double): TAiDataVec;
begin

end;

procedure TAIEmbeddingIndex.SetDataVec(const Value: TAiDataVec);
begin
  FDataVec := Value;
end;

{ TAOIBasicIndex }

procedure TAIBasicEmbeddingIndex.BuildIndex(Points: TAiDataVec);
begin
  Inherited;
end;

constructor TAIBasicEmbeddingIndex.Create;
begin
  Inherited;
end;

destructor TAIBasicEmbeddingIndex.Destroy;
begin

  inherited;
end;

function TAIBasicEmbeddingIndex.Search(Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double): TAiDataVec;
Var
  i: Integer;
  Emb: TAiEmbeddingNode;
  Idx: Double;
  Text: String;
begin
  Result := TAiDataVec.Create(Nil);

  // Calcula la similitud de coseno para todos los elementos
  For i := 0 to DataVec.Count - 1 do
  Begin
    Emb := DataVec.Items[i];
    Idx := TAiEmbeddingNode.CosineSimilarity(Emb, Target);
    Emb.Idx := Idx;
  End;

  // Ordena toda la lista por los m�s cercanos a 1 donde 1 es lo m�ximo de similitud
  DataVec.FItems.Sort(TComparer<TAiEmbeddingNode>.Construct(
    function(const Left, Right: TAiEmbeddingNode): Integer
    const
      TOLERANCE = 1.0E-12;
    begin
      if Abs(Left.Idx - Right.Idx) < TOLERANCE then
        Result := 0
      else if Left.Idx > Right.Idx then
        Result := -1
      else
        Result := 1;
    end));

  // Recorre la lista filtrando por aLimit y aPrecision
  Text := '';
  For i := 0 to DataVec.Count - 1 do
  Begin
    Emb := DataVec.FItems[i];
    If (i > aLimit) then // or (Emb.Idx < aPresicion) then
      Break;

    Result.FItems.Add(Emb);
  End;
end;

{ TAiRagChat }

function TAiRagChat.AskToAi(aPrompt: String; aLimit: Integer = 10; aPresicion: Double = 0.5): String;
Var
  TmpVec: TAiDataVec;
Begin
  TmpVec := FDataVec.Search(aPrompt, aLimit, aPresicion);

  Try
    Result := AskToAi(aPrompt, TmpVec)
  Finally
    TmpVec.Free;
  End;
end;

function TAiRagChat.AskToAi(aPrompt: TAiEmbeddingNode; aLimit: Integer; aPresicion: Double): String;
Var
  TmpVec: TAiDataVec;
Begin
  TmpVec := FDataVec.Search(aPrompt, aLimit, aPresicion);

  Try
    Result := AskToAi(aPrompt.Text, TmpVec)
  Finally
    TmpVec.Free;
  End;
end;

function TAiRagChat.AskToAi(aPrompt: String; DataVec: TAiDataVec): String;
Var
  Prompt, Text: String;
  i: Integer;
  Emb: TAiEmbeddingNode;
Begin

  Text := '';
  For i := 0 to DataVec.Count - 1 do
  Begin
    Emb := DataVec.FItems[i];
    Text := Text + Emb.Text.trim + #$D#$A;
  End;

  If Text.trim = '' then
    Prompt := 'Al siguiente prompt: "' + aPrompt + '" Responde que no hemos encontrado informaci�n sobre el tema solicitado'
  Else
  Begin
    Prompt := 'Teniendo en cuenta la siguiente informaci�n, responde la solicitud' + #$D#$A + 'Informaci�n:' + Text + #$D#$A + 'Solicitud: ' + aPrompt;
  End;

  If FChat.Asynchronous then
  Begin
    Result := '';
    FChat.AddMessageAndRun(Prompt, 'user', []);
  End
  Else
    Result := FChat.AddMessageAndRun(Prompt, 'user', []);
end;

constructor TAiRagChat.Create(aOwner: TComponent);
begin
  Inherited;
end;

destructor TAiRagChat.Destroy;
begin

  inherited;
end;

procedure TAiRagChat.SetChat(const Value: TAiOpenChat);
begin
  FChat := Value;
end;

procedure TAiRagChat.SetDataVec(const Value: TAiDataVec);
begin
  FDataVec := Value;
end;

end.
