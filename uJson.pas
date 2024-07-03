unit uJson;

interface

uses
  superobject, Windows, SysUtils, Rtti, TypInfo;

type
  JsonSerializer<T> = class
  public
    class procedure FromJson(js: ISuperObject; var item: T); overload;
    class procedure FromJson(jstr: string; var item: T); overload;
    class function ToJson(item: T): ISuperObject;
  end;

implementation


{ JsonSerializer<T> }

class procedure JsonSerializer<T>.FromJson(js: ISuperObject; var item: T);
var
  v: TValue;
  ctx: TSuperRttiContext;
begin
  if js = nil then
    raise Exception.Create('Invalid object');
  ctx := TSuperRttiContext.Create;
  try
    TValue.Make(nil, TypeInfo(T), v);
    ctx.FromJson(v.TypeInfo, js, v);
    if v.TypeInfo.Kind = tkRecord then
      v.Cast(v.TypeInfo).ExtractRawData(@item);
  finally
    ctx.Free;
  end;
end;

class procedure JsonSerializer<T>.FromJson(jstr: string; var item: T);
begin
  FromJson(SO(jstr), item);
end;

class function JsonSerializer<T>.ToJson(item: T): ISuperObject;
var
  v: TValue;
  ctx: TSuperRttiContext;
begin
  ctx := TSuperRttiContext.Create;
  try
    TValue.Make(@item, TypeInfo(T), v);
    Result := ctx.ToJson(v, SO);
  finally
    ctx.Free;
  end;
end;

end.
