unit UMakerAi.ParamsRegistry;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  UMakerAi.Chat;

type
  TAiChatClass = class of TAiChat;

  TAiChatFactory = class
  private
  class var
    FInstance: TAiChatFactory;
    FRegisteredClasses: TDictionary<string, TAiChatClass>;
    // La clave ahora puede ser "DriverName" o "DriverName@ModelName"
    FUserParams: TDictionary<string, TStringList>;

    // Funci�n interna para crear la clave compuesta.
    class function GetCompositeKey(const DriverName, ModelName: string): string; static;

  public
    constructor Create;
    destructor Destroy; override;
    class function Instance: TAiChatFactory;

    // M�todos existentes (algunos con nueva firma)
    procedure RegisterDriver(AClass: TAiChatClass);
    // Ahora acepta un ModelName opcional para obtener los par�metros jer�rquicos.
    procedure GetDriverParams(const DriverName, ModelName: string; Params: TStrings; ExpandVariables: Boolean = True);
    function CreateDriver(const DriverName: string): TAiChat;
    function GetRegisteredDrivers: TArray<string>;
    function HasDriver(const DriverName: string): Boolean;

    // --- M�TODOS DE REGISTRO SIMPLIFICADOS ---
    // Versi�n principal para registrar un par�metro de un modelo espec�fico.
    procedure RegisterUserParam(const DriverName, ModelName, ParamName, ParamValue: string); Overload;
    // Sobrecarga para registrar un par�metro a nivel de Driver (compatibilidad y conveniencia).
    procedure RegisterUserParam(const DriverName, ParamName, ParamValue: string); Overload;

    // Limpia los par�metros (con sobrecarga para modelo).
    procedure ClearRegisterParams(const DriverName: String; ModelName: string = '');
  end;

implementation

{ TAiChatFactory }

// Funci�n interna para crear la clave
class function TAiChatFactory.GetCompositeKey(const DriverName, ModelName: string): string;
begin
  if ModelName.IsEmpty then
    Result := DriverName
  else
    Result := DriverName + '@' + ModelName;
end;

constructor TAiChatFactory.Create;
begin
  inherited;
  FRegisteredClasses := TDictionary<string, TAiChatClass>.Create;
  FUserParams := TDictionary<string, TStringList>.Create;
end;

destructor TAiChatFactory.Destroy;
begin
  for var SL in FUserParams.Values do
    SL.Free;
  FUserParams.Free;
  FRegisteredClasses.Free;
  inherited;
end;

class function TAiChatFactory.Instance: TAiChatFactory;
begin
  if not Assigned(FInstance) then
    FInstance := TAiChatFactory.Create;
  Result := FInstance;
end;

procedure TAiChatFactory.RegisterDriver(AClass: TAiChatClass);
begin
  FRegisteredClasses.AddOrSetValue(AClass.GetDriverName, AClass);
end;

procedure TAiChatFactory.GetDriverParams(const DriverName, ModelName: string; Params: TStrings; ExpandVariables : Boolean);
var
  DriverClass: TAiChatClass;
  UserParamList: TStringList;
  I: Integer;
  EnvVarName, EnvVarValue, Key: String;
begin
  Params.Clear;

  // Nivel 1: Cargar par�metros por defecto desde la clase del driver
  if FRegisteredClasses.TryGetValue(DriverName, DriverClass) then
    DriverClass.RegisterDefaultParams(Params);

  // Nivel 2: Fusionar con par�metros personalizados del DRIVER
  Key := GetCompositeKey(DriverName, '');
  if FUserParams.TryGetValue(Key, UserParamList) then
  begin
    For I := 0 to UserParamList.Count - 1 do
      Params.Values[UserParamList.Names[I]] := UserParamList.ValueFromIndex[I];
  end;

  // Nivel 3: Fusionar con par�metros personalizados del MODELO (si se especifica)
  if not ModelName.IsEmpty then
  begin
    Key := GetCompositeKey(DriverName, ModelName);
    if FUserParams.TryGetValue(Key, UserParamList) then
    begin
      For I := 0 to UserParamList.Count - 1 do
        Params.Values[UserParamList.Names[I]] := UserParamList.ValueFromIndex[I];
    end;
  end;

  If ExpandVariables = True then  //Debe expandir las variable con las de entorno
  Begin
    // Expansi�n de Variables de Entorno
    for I := 0 to Params.Count - 1 do
    begin
      if (Params.ValueFromIndex[I] <> '') and (Params.ValueFromIndex[I].StartsWith('@')) then
      begin
        EnvVarName := Params.ValueFromIndex[I].Substring(1);
        EnvVarValue := GetEnvironmentVariable(EnvVarName);
        Params.ValueFromIndex[I] := EnvVarValue;
      end;
    end;
  End;
end;

function TAiChatFactory.CreateDriver(const DriverName: string): TAiChat;
var
  DriverClass: TAiChatClass;
begin
  Result := nil;
  if FRegisteredClasses.TryGetValue(DriverName, DriverClass) then
    Result := DriverClass.CreateInstance(Nil);
end;

function TAiChatFactory.GetRegisteredDrivers: TArray<string>;
begin
  Result := FRegisteredClasses.Keys.ToArray;
end;

function TAiChatFactory.HasDriver(const DriverName: string): Boolean;
begin
  Result := FRegisteredClasses.ContainsKey(DriverName);
end;

procedure TAiChatFactory.ClearRegisterParams(const DriverName: String; ModelName: string = '');
var
  UserParamList: TStringList;
  Key: string;
begin
  Key := GetCompositeKey(DriverName, ModelName);
  if FUserParams.TryGetValue(Key, UserParamList) then
  begin
    UserParamList.Clear;
  end;
end;

// Versi�n principal para registrar un par�metro de un modelo espec�fico.
procedure TAiChatFactory.RegisterUserParam(const DriverName, ModelName, ParamName, ParamValue: string);
var
  UserParamList: TStringList;
  Key: string;
begin
  Key := GetCompositeKey(DriverName, ModelName);
  if not FUserParams.TryGetValue(Key, UserParamList) then
  begin
    UserParamList := TStringList.Create;
    FUserParams.Add(Key, UserParamList);
  end;
  UserParamList.Values[ParamName] := ParamValue;
end;

// Sobrecarga para registrar un par�metro a nivel de Driver.
procedure TAiChatFactory.RegisterUserParam(const DriverName, ParamName, ParamValue: string);
begin
  // Llama a la versi�n principal con un ModelName vac�o.
  RegisterUserParam(DriverName, '', ParamName, ParamValue);
end;

initialization

// La instancia se crea bajo demanda
finalization

if Assigned(TAiChatFactory.FInstance) then
begin
  TAiChatFactory.FInstance.Free;
  TAiChatFactory.FInstance := nil;
end;

end.
