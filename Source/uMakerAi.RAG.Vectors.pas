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


unit uMakerAi.RAG.Vectors;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections,
  System.Generics.Defaults, System.Classes, System.JSon, Rest.JSon,
  System.NetEncoding, uMakerAi.Chat, uMakerAi.Embeddings, uMakerAi.Chat.AiConnection;

type

  /// ---------------------------------------------------------------------------
  /// TAiEmbeddingNode identifica un embedding, cincluyendo la longitud
  /// el modelo y los datos, permite adicionalmente comparar dos embeddings
  /// para conocer su similitud por coseno,  convierte de json a vector y de
  /// vector a json
  /// almacena tambi�n el dato de texto original del embedding
  /// -------------------------------------------------------------------------

  TAiRagIndexType = (TAIBasicIndex, TAIHNSWIndex);

  TAiEmbeddingMetaData = Class
  private
    FTagObject: TObject;
    FData: TStrings;
    FTagString: String;
    procedure SetData(const Value: TStrings);
    procedure SetTagObject(const Value: TObject);
    procedure SetFTagString(const Value: String);
  Public
    Constructor Create;
    Destructor Destroy;
    Property Data: TStrings read FData write SetData;
    Property TagObject: TObject read FTagObject write SetTagObject;
    Property TagString: String read FTagString write SetFTagString;
  End;

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

  TAiRAGVector = Class;

  TOnDataVecAddItem = Procedure(Sender: TObject; aItem: TAiEmbeddingNode; MetaData: TAiEmbeddingMetaData; Var Handled: Boolean) of object;
  TOnDataVecSearch = Procedure(Sender: TObject; Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double; Var aDataVec: TAiRAGVector;
    Var Handled: Boolean) of object;

  /// ---------------------------------------------------------------------------
  /// TAIEmbeddingIndex representa la clase base para la b�squeda con embeddings en memoria
  /// consiste en un vector de nodos y un indice de punteros a embeddings que permite la
  /// b�squeda y seleccion de los candidatos que cumplen la condici�n
  /// -------------------------------------------------------------------------
  TAIEmbeddingIndex = class
  private
    FDataVec: TAiRAGVector;
    FActive: Boolean;
    procedure SetDataVec(const Value: TAiRAGVector);
  public
    constructor Create; Virtual;
    destructor Destroy; override;
    procedure BuildIndex(Points: TAiRAGVector); Virtual;
    Function Add(Point: TAiEmbeddingNode): Integer; Virtual;
    Function Search(Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double): TAiRAGVector; Virtual;
    Function Connect(aHost, aPort, aLogin, aPassword: String): Boolean; Virtual;
    Property DataVec: TAiRAGVector read FDataVec write SetDataVec;
    Property Active: Boolean read FActive;
  end;

  /// ---------------------------------------------------------------------------
  /// TAIBasicEmbeddingIndex implementaci�n sencilla de un Indice de embeddings
  /// el cual se asigna por defecto al vector para realizar b�squedas en memoria
  /// sin embargo hay maneras m�s eficientes de controlar esto en vectores de
  /// embeddings.
  /// -------------------------------------------------------------------------

  TAIBasicEmbeddingIndex = class(TAIEmbeddingIndex)
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure BuildIndex(Points: TAiRAGVector); Override;
    Function Search(Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double): TAiRAGVector; Override;
  end;

  /// ---------------------------------------------------------------------------
  /// THNSWIndex implementa un Approximate Nearest Neighbors (ANN) usando el algoritmo
  /// HNSW (Hierarchical Navigable Small World) que es mucho m�s eficiente en la busqueda
  /// en vectores embeddings
  /// -------------------------------------------------------------------------

  TConnListArray = array of TList<Integer>;

  THNSWNode = class
  private
    FID: Integer;
    FVector: TAiEmbeddingNode;
    FConnections: TConnListArray;
  public
    constructor Create(aID: Integer; aVector: TAiEmbeddingNode; aNumLevels: Integer);
    destructor Destroy; override;
    property ID: Integer read FID;
    property Vector: TAiEmbeddingNode read FVector;
    property Connections: TConnListArray read FConnections;
  end;

  THNSWIndex = class(TAIEmbeddingIndex)
  private
    FNodes: TDictionary<Integer, THNSWNode>;
    FEntryPoint: Integer;
    FMaxLevel: Integer;
    FLevelMult: Double;
    FEfConstruction: Integer;
    FMaxConnections: Integer;

    function GetRandomLevel: Integer;
    procedure InsertConnection(Node: THNSWNode; Level: Integer; TargetID: Integer);
    function SearchLayer(Query: TAiEmbeddingNode; EntryPoint: Integer; Level: Integer; Ef: Integer): TList<Integer>;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure BuildIndex(Points: TAiRAGVector); override;
    function Add(Point: TAiEmbeddingNode): Integer; override;
    function Search(Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double): TAiRAGVector; override;
  end;

  /// ---------------------------------------------------------------------------
  /// TAiDataVec es la clase base que permite almacenar conjuntos de embeddings
  /// se utiliza tanto para representar bases de datos de embeddings en memoria
  /// como para la conexi�n con bases de datos de embeddings.
  /// Por si solo no indexa ni b�sca, solo es el contenedor, para buscar
  /// es necesario adicionar un TAIEmbeddingIndex, aunque por defecto tiene
  /// un indice b�sico de b�squeda, pero hay modelos mejores.
  /// -------------------------------------------------------------------------
  TAiRAGVector = Class(TComponent)
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
    FInMemoryIndexType: TAiRagIndexType;
    procedure SetActive(const Value: Boolean);
    procedure SetRagIndex(const Value: TAIEmbeddingIndex);
    procedure SetEmbeddings(const Value: TAiEmbeddings);
    function GetItems: TList<TAiEmbeddingNode>;
    procedure SetOnDataVecAddItem(const Value: TOnDataVecAddItem);
    procedure SetOnDataVecSearch(const Value: TOnDataVecSearch);
    procedure SetDescription(const Value: String);
    procedure SetNameVec(const Value: String);
    procedure SetInMemoryIndexType(const Value: TAiRagIndexType);
  Protected

  Public
    Constructor Create(aOwner: TComponent); Override;
    Destructor Destroy; Override;
    Procedure SaveToStream(Stream: TMemoryStream);
    Procedure LoadFromStream(Stream: TMemoryStream);
    Procedure SaveToFile(FileName: String);
    Procedure LoadFromFile(FileName: String);
    Function Connect(aHost, aPort, aLogin, aPassword: String): Boolean;
    Function Search(Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double): TAiRAGVector; Overload;
    Function Search(Prompt: String; aLimit: Integer; aPrecision: Double): TAiRAGVector; Overload;
    procedure BuildIndex;

    Function AddItem(aItem: TAiEmbeddingNode; MetaData: TAiEmbeddingMetaData): NativeInt; Overload; Virtual;
    Function AddItem(aText: String; MetaData: TAiEmbeddingMetaData = Nil): TAiEmbeddingNode; Overload; Virtual;

    Function AddItemsFromJSonArray(aJSonArray: TJSonArray): Boolean; Virtual;
    procedure AddItemsFromPlainText(aText: String; aLenChunk: Integer = 512; aLenOverlap: Integer = 80); Virtual;
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
    Property InMemoryIndexType: TAiRagIndexType read FInMemoryIndexType write SetInMemoryIndexType;
  End;

  TAiRagChat = Class(TComponent)
  Private
    FDataVec: TAiRAGVector;
    FChat: TAiChatConnection;
    procedure SetChat(const Value: TAiChatConnection);
    procedure SetDataVec(const Value: TAiRAGVector);
  Protected
  Public
    Constructor Create(aOwner: TComponent); Override;
    Destructor Destroy; Override;
    Function AskToAi(aPrompt: String; aLimit: Integer = 10; aPresicion: Double = 0.5): String; Overload; Virtual;
    Function AskToAi(aPrompt: TAiEmbeddingNode; aLimit: Integer = 10; aPresicion: Double = 0.5): String; Overload; Virtual;
    Function AskToAi(aPrompt: String; DataVec: TAiRAGVector): String; Overload; Virtual;
  Published
    Property Chat: TAiChatConnection read FChat write SetChat;
    Property DataVec: TAiRAGVector read FDataVec write SetDataVec;
  End;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('MakerAI', [TAiRagChat, TAiRAGVector]);

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

Function TAiRAGVector.AddItem(aItem: TAiEmbeddingNode; MetaData: TAiEmbeddingMetaData): NativeInt;
Var
  Handled: Boolean;
begin
  Handled := False;

  If Assigned(FOnDataVecAddItem) then
    FOnDataVecAddItem(Self, aItem, MetaData, Handled);

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

function TAiRAGVector.AddItem(aText: String; MetaData: TAiEmbeddingMetaData): TAiEmbeddingNode;
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

    Self.AddItem(Result, MetaData); // LLama al additem(TAiEmbeddingNode);
  Finally
  End;
end;

function TAiRAGVector.AddItemsFromJSonArray(aJSonArray: TJSonArray): Boolean;
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

procedure TAiRAGVector.AddItemsFromPlainText(aText: String; aLenChunk, aLenOverlap: Integer);
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

procedure TAiRAGVector.BuildIndex;
begin
  If not Assigned(FRagIndex) then
    Raise Exception.Create('No existe un indice asignado');

  FRagIndex.BuildIndex(Self);
  FActive := True;
end;

procedure TAiRAGVector.Clear;
begin
  FItems.Clear;
end;

function TAiRAGVector.Connect(aHost, aPort, aLogin, aPassword: String): Boolean;
begin
  If not Assigned(FRagIndex) then
    Raise Exception.Create('No existe un indice asignado');

  Result := FRagIndex.Connect(aHost, aPort, aLogin, aPassword);
  FActive := True;
end;

function TAiRAGVector.Count: Integer;
begin
  Result := FItems.Count;
end;

constructor TAiRAGVector.Create(aOwner: TComponent);
begin
  inherited;
  FItems := TList<TAiEmbeddingNode>.Create;

  FInMemoryIndexType := TAIHNSWIndex;

  If FInMemoryIndexType = TAIBasicIndex then
    FRagIndex := TAIBasicEmbeddingIndex.Create
  Else If FInMemoryIndexType = TAIHNSWIndex then
    FRagIndex := THNSWIndex.Create;

  BuildIndex; // Inicializa el Indice

end;

function TAiRAGVector.CreateEmbeddingNode(aText: String; aEmbeddings: TAiEmbeddings): TAiEmbeddingNode;
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

destructor TAiRAGVector.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TAiRAGVector.GetItems: TList<TAiEmbeddingNode>;
begin
  Result := FItems;
end;

procedure TAiRAGVector.LoadFromFile(FileName: String);
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

procedure TAiRAGVector.LoadFromStream(Stream: TMemoryStream);
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

procedure TAiRAGVector.SaveToFile(FileName: String);
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

procedure TAiRAGVector.SaveToStream(Stream: TMemoryStream);
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

function TAiRAGVector.Search(Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double): TAiRAGVector;
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

function TAiRAGVector.Search(Prompt: String; aLimit: Integer; aPrecision: Double): TAiRAGVector;
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

procedure TAiRAGVector.SetActive(const Value: Boolean);
begin
  FActive := Value;
end;

procedure TAiRAGVector.SetDescription(const Value: String);
begin
  FDescription := Value;
end;

procedure TAiRAGVector.SetEmbeddings(const Value: TAiEmbeddings);
begin
  FEmbeddings := Value;
end;

procedure TAiRAGVector.SetInMemoryIndexType(const Value: TAiRagIndexType);
begin

  If FInMemoryIndexType <> Value then
  Begin
    FRagIndex.Free;

    FInMemoryIndexType := Value;

    If FInMemoryIndexType = TAIBasicIndex then
      FRagIndex := TAIBasicEmbeddingIndex.Create
    Else If FInMemoryIndexType = TAIHNSWIndex then
      FRagIndex := THNSWIndex.Create;

    BuildIndex; // Inicializa el Indice
  End;

end;

procedure TAiRAGVector.SetNameVec(const Value: String);
begin
  FNameVec := Value;
end;

procedure TAiRAGVector.SetOnDataVecAddItem(const Value: TOnDataVecAddItem);
begin
  FOnDataVecAddItem := Value;
end;

procedure TAiRAGVector.SetOnDataVecSearch(const Value: TOnDataVecSearch);
begin
  FOnDataVecSearch := Value;
end;

procedure TAiRAGVector.SetRagIndex(const Value: TAIEmbeddingIndex);
begin
  FRagIndex := Value;
end;

function TAIEmbeddingIndex.Add(Point: TAiEmbeddingNode): Integer;
begin
  Result := -1;
  // Esta funci�n se debe implementar en cada modelo solo cuando sea necesario
end;

{ TOAIIndex }

procedure TAIEmbeddingIndex.BuildIndex(Points: TAiRAGVector);
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

function TAIEmbeddingIndex.Search(Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double): TAiRAGVector;
begin
  Result := nil;
end;

procedure TAIEmbeddingIndex.SetDataVec(const Value: TAiRAGVector);
begin
  FDataVec := Value;
end;

{ TAOIBasicIndex }

procedure TAIBasicEmbeddingIndex.BuildIndex(Points: TAiRAGVector);
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

function TAIBasicEmbeddingIndex.Search(Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double): TAiRAGVector;
Var
  i: Integer;
  Emb: TAiEmbeddingNode;
  Idx: Double;
  Text: String;
begin
  Result := TAiRAGVector.Create(Nil);

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




// -----------------------------------------------------------------------------------------------

{ THNSWNode }
constructor THNSWNode.Create(aID: Integer; aVector: TAiEmbeddingNode; aNumLevels: Integer);
var
  i: Integer;
begin
  FID := aID;
  FVector := aVector;
  SetLength(FConnections, aNumLevels);
  for i := 0 to aNumLevels - 1 do
    FConnections[i] := TList<Integer>.Create;
end;

destructor THNSWNode.Destroy;
var
  i: Integer;
begin
  for i := 0 to Length(FConnections) - 1 do
    FConnections[i].Free;
  inherited;
end;

constructor THNSWIndex.Create;
begin
  inherited;
  FNodes := TDictionary<Integer, THNSWNode>.Create;
  FMaxLevel := 16;
  FLevelMult := 1 / ln(2);
  FEfConstruction := 40;
  FMaxConnections := 16;
  FEntryPoint := -1;
end;

destructor THNSWIndex.Destroy;
var
  Node: THNSWNode;
begin
  for Node in FNodes.Values do
    Node.Free;
  FNodes.Free;
  inherited;
end;

function THNSWIndex.GetRandomLevel: Integer;
begin
  Result := Floor(-ln(Random) * FLevelMult);
  if Result >= FMaxLevel then
    Result := FMaxLevel - 1;
end;

{ THNSWIndex }

procedure THNSWIndex.InsertConnection(Node: THNSWNode; Level: Integer; TargetID: Integer);
begin
  if Node.Connections[Level].Count >= FMaxConnections then
  begin
    // Implementar pol�tica de selecci�n para mantener mejores conexiones
    // Por ejemplo, mantener las conexiones m�s cercanas
    Exit;
  end;

  if not Node.Connections[Level].Contains(TargetID) then
    Node.Connections[Level].Add(TargetID);
end;

function THNSWIndex.SearchLayer(Query: TAiEmbeddingNode; EntryPoint: Integer; Level: Integer; Ef: Integer): TList<Integer>;
var
  Visited: TDictionary<Integer, Boolean>;
  Candidates: TList<TPair<Double, Integer>>;
  BestCandidates: TList<TPair<Double, Integer>>;
  CurrentNode: THNSWNode;
  Distance: Double;
  i: Integer;
begin
  Result := TList<Integer>.Create;
  Visited := TDictionary<Integer, Boolean>.Create;
  Candidates := TList < TPair < Double, Integer >>.Create;
  BestCandidates := TList < TPair < Double, Integer >>.Create;

  try
    // Inicializar con punto de entrada
    CurrentNode := FNodes[EntryPoint];
    Distance := TAiEmbeddingNode.CosineSimilarity(Query, CurrentNode.Vector);
    Candidates.Add(TPair<Double, Integer>.Create(Distance, EntryPoint));
    BestCandidates.Add(TPair<Double, Integer>.Create(Distance, EntryPoint));
    Visited.Add(EntryPoint, True);

    while Candidates.Count > 0 do
    begin
      // Obtener el candidato m�s cercano
      Candidates.Sort(TComparer < TPair < Double, Integer >>.Construct(
        function(const Left, Right: TPair<Double, Integer>): Integer
        begin
          if Left.Key > Right.Key then
            Result := -1
          else if Left.Key < Right.Key then
            Result := 1
          else
            Result := 0;
        end));

      CurrentNode := FNodes[Candidates[0].Value];
      Candidates.Delete(0);

      // Explorar conexiones
      for i in CurrentNode.Connections[Level] do
      begin
        if not Visited.ContainsKey(i) then
        begin
          Visited.Add(i, True);
          Distance := TAiEmbeddingNode.CosineSimilarity(Query, FNodes[i].Vector);

          if (BestCandidates.Count < Ef) or (Distance > BestCandidates.Last.Key) then
          begin
            Candidates.Add(TPair<Double, Integer>.Create(Distance, i));
            BestCandidates.Add(TPair<Double, Integer>.Create(Distance, i));

            if BestCandidates.Count > Ef then
            begin
              BestCandidates.Sort(TComparer < TPair < Double, Integer >>.Construct(
                function(const Left, Right: TPair<Double, Integer>): Integer
                begin
                  if Left.Key > Right.Key then
                    Result := -1
                  else if Left.Key < Right.Key then
                    Result := 1
                  else
                    Result := 0;
                end));
              BestCandidates.Delete(BestCandidates.Count - 1);
            end;
          end;
        end;
      end;
    end;

    // Convertir mejores candidatos a lista de resultados
    for i := 0 to BestCandidates.Count - 1 do
      Result.Add(BestCandidates[i].Value);

  finally
    Visited.Free;
    Candidates.Free;
    BestCandidates.Free;
  end;
end;

function THNSWIndex.Add(Point: TAiEmbeddingNode): Integer;
var
  NodeID: Integer;
  Level: Integer;
  CurrentLevel: Integer;
  EntryPointCopy: Integer;
  W: TList<Integer>;
  Node: THNSWNode;
  i: Integer;
begin
  NodeID := FNodes.Count;
  Level := GetRandomLevel;

  // Crear nuevo nodo
  Node := THNSWNode.Create(NodeID, Point, FMaxLevel);
  FNodes.Add(NodeID, Node);

  if FEntryPoint = -1 then
  begin
    FEntryPoint := NodeID;
    Result := NodeID;
    Exit;
  end;

  // Insertar en la estructura
  EntryPointCopy := FEntryPoint;
  CurrentLevel := FMaxLevel - 1;

  while CurrentLevel > Level do
  begin
    W := SearchLayer(Point, EntryPointCopy, CurrentLevel, 1);
    if W.Count > 0 then
      EntryPointCopy := W[0];
    Dec(CurrentLevel);
    W.Free;
  end;

  while CurrentLevel >= 0 do
  begin
    W := SearchLayer(Point, EntryPointCopy, CurrentLevel, FEfConstruction);
    try
      for i in W do
      begin
        InsertConnection(Node, CurrentLevel, i);
        InsertConnection(FNodes[i], CurrentLevel, NodeID);
      end;

      if W.Count > 0 then
        EntryPointCopy := W[0];
    finally
      W.Free;
    end;
    Dec(CurrentLevel);
  end;

  if Level > -1 then
    FEntryPoint := NodeID;

  Result := NodeID;
end;

procedure THNSWIndex.BuildIndex(Points: TAiRAGVector);
var
  i: Integer;
  Point: TAiEmbeddingNode;
begin
  inherited;

  // Construir el �ndice a�adiendo todos los puntos
  for i := 0 to Points.Count - 1 do
  begin
    Point := Points.Items[i];
    Add(Point);
  end;
end;

function THNSWIndex.Search(Target: TAiEmbeddingNode; aLimit: Integer; aPrecision: Double): TAiRAGVector;
var
  CurrentLevel: Integer;
  EntryPointCopy: Integer;
  W: TList<Integer>;
  ResultList: TList<TPair<Double, Integer>>;
  i: Integer;
  Distance: Double;
  Node: THNSWNode;
begin
  Result := TAiRAGVector.Create(nil);

  if FEntryPoint = -1 then
    Exit;

  ResultList := TList < TPair < Double, Integer >>.Create;
  try
    EntryPointCopy := FEntryPoint;
    CurrentLevel := FMaxLevel - 1;

    // Descender por niveles hasta encontrar el m�s cercano
    while CurrentLevel >= 0 do
    begin
      W := SearchLayer(Target, EntryPointCopy, CurrentLevel, 1);
      try
        if W.Count > 0 then
          EntryPointCopy := W[0];
      finally
        W.Free;
      end;
      Dec(CurrentLevel);
    end;

    // B�squeda final en el nivel base
    W := SearchLayer(Target, EntryPointCopy, 0, aLimit * 2);
    try
      // Calcular similitudes y ordenar resultados
      for i in W do
      begin
        Node := FNodes[i];
        Distance := TAiEmbeddingNode.CosineSimilarity(Target, Node.Vector);
        if Distance >= aPrecision then
          ResultList.Add(TPair<Double, Integer>.Create(Distance, i));
      end;

      ResultList.Sort(TComparer < TPair < Double, Integer >>.Construct(
        function(const Left, Right: TPair<Double, Integer>): Integer
        begin
          if Left.Key > Right.Key then
            Result := -1
          else if Left.Key < Right.Key then
            Result := 1
          else
            Result := 0;
        end));

      // Tomar los mejores resultados
      for i := 0 to Min(aLimit - 1, ResultList.Count - 1) do
      begin
        Node := FNodes[ResultList[i].Value];
        Node.Vector.Idx := ResultList[i].Key;
        // Result.AddItem(Node.Vector, Nil);
        Result.Items.Add(Node.Vector);
      end;

    finally
      W.Free;
    end;

  finally
    ResultList.Free;
  end;
end;

{ TAiRagChat }

function TAiRagChat.AskToAi(aPrompt: String; aLimit: Integer = 10; aPresicion: Double = 0.5): String;
Var
  TmpVec: TAiRAGVector;
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
  TmpVec: TAiRAGVector;
Begin
  TmpVec := FDataVec.Search(aPrompt, aLimit, aPresicion);

  Try
    Result := AskToAi(aPrompt.Text, TmpVec)
  Finally
    TmpVec.Free;
  End;
end;

function TAiRagChat.AskToAi(aPrompt: String; DataVec: TAiRAGVector): String;
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
    Prompt := 'Teniendo en cuenta la siguiente informaci�n, responde la solicitud' + #$D#$A + 'Informaci�n:' + Text + #$D#$A + 'Solicitud: '
      + aPrompt;
  End;

  { If FChat.Asynchronous then
    Begin
    Result := '';
    FChat.AddMessageAndRun(Prompt, 'user', []);
    End
    Else
  }
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

procedure TAiRagChat.SetChat(const Value: TAiChatConnection);
begin
  FChat := Value;
end;

procedure TAiRagChat.SetDataVec(const Value: TAiRAGVector);
begin
  FDataVec := Value;
end;

{ TAiEmbeddingMetaData }

constructor TAiEmbeddingMetaData.Create;
begin
  Inherited;
  FData := TStringList.Create;
  FTagObject := Nil;
  FTagString := '';
end;

destructor TAiEmbeddingMetaData.Destroy;
begin
  FData.Free;
  Inherited;
end;

procedure TAiEmbeddingMetaData.SetData(const Value: TStrings);
begin
  FData := Value;
end;

procedure TAiEmbeddingMetaData.SetFTagString(const Value: String);
begin
  FTagString := Value;
end;

procedure TAiEmbeddingMetaData.SetTagObject(const Value: TObject);
begin
  FTagObject := Value;
end;

end.
