unit Helper;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,DateUtils, DB, ADODB, FindPathUnit, ExtCtrls;

type EURUSDREC=record
   DateAndTime:TdateTime;
   OpenRate:Real;
   MaxRate:Real;
   MinRate:Real;
   CloseRate:Real;
   GraphNo:Integer;
end;



type
  TForm1 = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Edit1: TEdit;
    Button1: TButton;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    OpenDialog2: TOpenDialog;
    OpenDialog3: TOpenDialog;
    OpenDialog4: TOpenDialog;
    Button5: TButton;
    ADOConnection1: TADOConnection;
    ADOQuery1: TADOQuery;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FillEurUsd15;
    procedure FillEurUsd15Matrix;
    function  getDate(Data:String):TDateTime;
    function  getOpenRate(Data:String):Real;
    function  getMaxRate(Data:String):Real;
    function  getMinRate(Data:String):Real;
    function  getCloseRate(Data:String):Real;
    function  getGraphNo(MatrixNo:Integer; Value:Real):Integer;
    procedure FormCreate(Sender: TObject);
    procedure FindPath;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Timer1Timer(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  EURUSD15:Array of EURUSDREC;
  EURUSD30:Array[1..4200] of  EURUSDREC;
  EURUSD60:Array[1..4200] of  EURUSDREC;
  EURUSD240:Array[1..4200] of  EURUSDREC;
  EURUSD15M:array of array of byte;
  EURUSD30M:array of array of byte;
  EURUSD60M:array of array of byte;
  EURUSD240M:array of array of byte;
  EURUSD15COUNT:Integer;
  EURUSD30COUNT:Integer;
  EURUSD60COUNT:Integer;
  EURUSD240COUNT:Integer;
  LastGraphNo15:Integer;
  LastGraphNo30:Integer;
  LastGraphNo60:Integer;
  LastGraphNo240:Integer;
  Path:array[1..10000] of integer;
  PathElementsCount:Integer;
  PathsCount:Int64;
  MaxTime:longint;
  MinTime:longint;
  FromGraphNoGlobal:Integer;
  ToGraphNoGlobal:Integer;
  findPath1:TFindPath;
  findPath2:TFindPath;
  findPath3:TFindPath;
  findPath4:TFindPath;
  findPath5:TFindPath;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
 if OpenDialog1.Execute then
  begin
    Edit1.Text:=OpenDialog1.FileName;
  end;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
end;

//Кнопка старт
procedure TForm1.Button5Click(Sender: TObject);
var
 count:integer;
 CurrentRate:Real;
 TakeProfit:Real;
 StopLoss:Real;
 tmpGraphNo:Integer;
 CurrentRateGraphNo:Integer;
 TakeProfitGraphNo:Integer;
 StopLossGraphNo:Integer;
 der:Real;
 fileName:String;
 f:TextFile;
 tmplength:Integer;
begin
  Memo1.Clear;
  Button5.Enabled:=false;
  FillEurUsd15;
  FillEurUsd15Matrix;
  FindPath;
end;

//Заполнение EurUsd15
procedure TForm1.FillEurUsd15;
var
 fileName:String;
 f:TextFile;
 tmpStr:string;
 i:integer;
 k:integer;
 maxRate:Real;
 minRate:Real;
begin
  k:=1;
  fileName:=Edit1.Text;
  if fileName<>'' then
   begin
    SetLength(EURUSD15,1);
    AssignFile(f,fileName);
    Reset(f);
    i:=0;
    while NOT eof(f) do
     begin
      Readln(f,tmpStr);
      if k=1 then
       begin
        maxRate:=getMaxRate(tmpStr);
        minRate:=getMinRate(tmpStr);
       end;
      if k=30 then
       begin
        EURUSD15[i].DateAndTime:=getDate(tmpStr);
        EURUSD15[i].OpenRate:=getOpenRate(tmpStr);
        EURUSD15[i].MaxRate:=maxRate;
        EURUSD15[i].MinRate:=minRate;
        EURUSD15[i].CloseRate:=getCloseRate(tmpStr);
        i:=i+1;
        SetLength(EURUSD15,i+1);
        k:=1;
       end
      else
       begin
        if maxRate<getMaxRate(tmpStr) then
         maxRate:=getMaxRate(tmpStr);
        if minRate>getMinRate(tmpStr) then
         minRate:=getMinRate(tmpStr);
        k:=k+1;
       end;
     end;
   end;
   EURUSD15COUNT:=i-1;
   Memo1.Lines.Add('EURUSD15COUNT:='+IntToStr(EURUSD15COUNT));
end;

//Создание формы
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 if ADOConnection1.Connected then
  ADOConnection1.Connected:=false;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
 conStr:String;
begin
  //Соединение с базой
  conStr:='Provider=Microsoft.Jet.OLEDB.4.0;Data Source='+
           ExtractFilePath(Application.ExeName)+
           'db2.mdb;Persist Security Info=False';
  ADOConnection1.ConnectionString:=conStr;
  ADOConnection1.Connected:=true;

  //Удаляем все из RateTab
 { ADOQuery1.Close;
  ADOQuery1.SQL.Clear;
  ADOQuery1.SQL.Add('delete * from Ratetab');
  ADOQuery1.ExecSQL;
  //Удаляем все из PathTab
  ADOQuery1.Close;
  ADOQuery1.SQL.Clear;
  ADOQuery1.SQL.Add('delete * from PathTab');
  ADOQuery1.ExecSQL;             }

  OpenDialog1.InitialDir:=ExtractFilePath(Application.ExeName);
  OpenDialog2.InitialDir:=ExtractFilePath(Application.ExeName);
  OpenDialog3.InitialDir:=ExtractFilePath(Application.ExeName);
  OpenDialog4.InitialDir:=ExtractFilePath(Application.ExeName);
  EURUSD15COUNT:=0;
  EURUSD30COUNT:=0;
  EURUSD60COUNT:=0;
  EURUSD240COUNT:=0;
  LastGraphNo15:=0;
  LastGraphNo30:=0;
  LastGraphNo60:=0;
  LastGraphNo240:=0;
end;

//Заполенеие даты и времени
function  TForm1.getDate(Data:String):TDateTime;
var
 tmpStr:String;
 tempDateTime:TDateTime;
 i:integer;
 MySettings: TFormatSettings;
begin
  //tmpStr:='2011.12.27 20:30:00';
  tmpStr:='';
  GetLocaleFormatSettings(GetUserDefaultLCID, MySettings);
  MySettings.DateSeparator := '.';
  MySettings.TimeSeparator := ':';
  MySettings.ShortDateFormat := 'yyyy.mm.dd';
 // MySettings.ShortDateFormat := 'dd.mm.yyyy';
  MySettings.ShortTimeFormat := 'hh:nn:ss';
 // MySettings.ShortTimeFormat := 'hh:nn';
 for i := 1 to 16 do
//  for i := 1 to 18 do
  begin
   if Data[i]=',' then
    tmpStr:=tmpStr+' '
   else
    tmpStr:=tmpStr+Data[i];
  end;
  getDate:=StrToDateTime(tmpStr,MySettings);
end;

//Заполенеие котировки открытия
function  TForm1.getOpenRate(Data:String):Real;
var
 tmpStr:String;
 i:integer;
begin
  tmpStr:='';
  for i := 18 to 24 do
//  for i := 20 to 25 do
   if Data[i]<>',' then
    tmpStr:=tmpStr+Data[i]
   else
    tmpStr:=tmpStr+'.';
  getOpenRate:=StrToFloat(tmpStr);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
 c,r:Integer;
begin
 //c:=Trunc(length(EURUSD15M));
 r:=Trunc(length(EURUSD15M));
 if FromGraphNoGlobal+48<length(EURUSD15M) then
  c:=FromGraphNoGlobal+48
 else
  c:=length(EURUSD15M);

 if FromGraphNoGlobal<=r then
  begin
  //Для первого потока
   if ToGraphNoGlobal>c then
    begin
     FromGraphNoGlobal:=FromGraphNoGlobal+1;
     ToGraphNoGlobal:=(FromGraphNoGlobal+48)-48;
    end;

    //findPath1.Suspend;
    if Not (findPath1.getPathStat) and (FromGraphNoGlobal<=r) then
     begin
      Memo1.Lines.Add('Поток 1: От графа '+IntToStr(FromGraphNoGlobal)+' до графа'+ IntToStr(ToGraphNoGlobal));
      findPath1.SetPathPoint(FromGraphNoGlobal,ToGraphNoGlobal);
      findPath1.Resume;
      ToGraphNoGlobal:=ToGraphNoGlobal+1;
     end;


    //Для второго потока
   if ToGraphNoGlobal>c then
    begin
     FromGraphNoGlobal:=FromGraphNoGlobal+1;
     ToGraphNoGlobal:=(FromGraphNoGlobal+48)-48;
    end;

    if Not (findPath2.getPathStat) and (FromGraphNoGlobal<=r) then
     begin
      Memo1.Lines.Add('Поток 2: От графа '+IntToStr(FromGraphNoGlobal)+' до графа'+ IntToStr(ToGraphNoGlobal));
      findPath2.SetPathPoint(FromGraphNoGlobal,ToGraphNoGlobal);
      findPath2.Resume;
      ToGraphNoGlobal:=ToGraphNoGlobal+1;
     end;


       //Для третьего потока
   if ToGraphNoGlobal>c then
    begin
     FromGraphNoGlobal:=FromGraphNoGlobal+1;
     ToGraphNoGlobal:=(FromGraphNoGlobal+48)-48;
    end;

    if Not (findPath3.getPathStat) and (FromGraphNoGlobal<=r) then
     begin
      Memo1.Lines.Add('Поток 3: От графа '+IntToStr(FromGraphNoGlobal)+' до графа'+ IntToStr(ToGraphNoGlobal));
      findPath3.SetPathPoint(FromGraphNoGlobal,ToGraphNoGlobal);
      findPath3.Resume;
      ToGraphNoGlobal:=ToGraphNoGlobal+1;
     end;

       //Для четвертого потока
   if ToGraphNoGlobal>c then
    begin
     FromGraphNoGlobal:=FromGraphNoGlobal+1;
     ToGraphNoGlobal:=(FromGraphNoGlobal+48)-48;
    end;

    if Not (findPath4.getPathStat) and (FromGraphNoGlobal<=r) then
     begin
      Memo1.Lines.Add('Поток 4: От графа '+IntToStr(FromGraphNoGlobal)+' до графа'+ IntToStr(ToGraphNoGlobal));
      findPath4.SetPathPoint(FromGraphNoGlobal,ToGraphNoGlobal);
      findPath4.Resume;
      ToGraphNoGlobal:=ToGraphNoGlobal+1;
     end;


    //Для пятого потока
 {   if ToGraphNoGlobal>c then
     begin
      FromGraphNoGlobal:=FromGraphNoGlobal+1;
      ToGraphNoGlobal:=1;
     end;

     if Not (findPath5.getPathStat) and (FromGraphNoGlobal<=r) then
      begin
       Memo1.Lines.Add('Поток 5: От графа '+IntToStr(FromGraphNoGlobal)+' до графа'+ IntToStr(ToGraphNoGlobal));
       findPath5.SetPathPoint(FromGraphNoGlobal,ToGraphNoGlobal);
       findPath5.Resume;
       ToGraphNoGlobal:=ToGraphNoGlobal+1;
     end;}
  end
 else
  begin
   Memo1.Lines.Add('Завершено!');
   Button5.Enabled:=true;
   Timer1.Enabled:=false;
  end;
end;

//Заполенеие котировки максимальной
function  TForm1.getMaxRate(Data:String):Real;
var
 tmpStr:String;
  i:integer;
begin
  tmpStr:='';
  for i := 26 to 32 do
//  for i := 28 to 33 do
   if Data[i]<>',' then
    tmpStr:=tmpStr+Data[i]
   else
    tmpStr:=tmpStr+'.';
  getMaxRate:=StrToFloat(tmpStr);
end;

//Заполенеие котировки минимальной
function  TForm1.getMinRate(Data:String):Real;
var
 tmpStr:String;
 i:integer;
begin
 tmpStr:='';
  for i := 34 to 40 do
 // for i := 36 to 41 do
   if Data[i]<>',' then
    tmpStr:=tmpStr+Data[i]
   else
    tmpStr:=tmpStr+'.';
 getMinRate:=StrToFloat(tmpStr);
end;

//Заполенеие котировки закрытия
function  TForm1.getCloseRate(Data:String):Real;
var
 tmpStr:String;
 i:integer;
begin
 tmpStr:='';
  for i := 42 to 48 do
  //for i := 44 to 49 do
   if Data[i]<>',' then
    tmpStr:=tmpStr+Data[i]
   else
    tmpStr:=tmpStr+'.';
  getCloseRate:=StrToFloat(tmpStr);
end;

//Заполнение EurUsd15
procedure TForm1.FillEurUsd15Matrix;
var
 i:Integer;
 tmpGraphNo:Integer;
 der:Real;
 sqlString:String;
begin
 SetLength(EURUSD15M,1,1);
 for i:= 0 to EURUSD15COUNT do
  begin
   tmpGraphNo:=getGraphNo(0,EURUSD15[i].CloseRate); //Есть ли вершина графа
    if tmpGraphNo=0 then //Если нет то добавляем
     begin
      der:=-0.00001;
      while (tmpGraphNo=0) and (der<0.00001) do
       begin
        tmpGraphNo:=getGraphNo(0,EURUSD15[i].CloseRate+der); //Есть ли вершина графа
        der:=der+0.00001
       end;
       if tmpGraphNo=0 then //Если все таки не нашли
        begin
         LastGraphNo15:=LastGraphNo15+1;
         tmpGraphNo:=LastGraphNo15;
         SetLength(EURUSD15M,LastGraphNo15+1,LastGraphNo15+1);
     {    sqlString:= 'INSERT INTO RateTab ( DT, TM, OpenRate, MaxRate, MinRate,'+
                ' CloseRate, GraphNo, RateType ) '+
                ' SELECT '''+DateToStr(EURUSD15[i].DateAndTime)+''''+
                ' AS DT, '''+TimeToStr(EURUSD15[i].DateAndTime)+''''+
                ' AS TM, '+FloatToStrF(EURUSD15[i].OpenRate,ffFixed,8,5)+' AS OpenRate,'+
                FloatToStrF(EURUSD15[i].MaxRate,ffFixed,8,5)+' AS MaxRate, '+
                FloatToStrF(EURUSD15[i].MinRate,ffFixed,8,5)+' AS MinRate, '+
                FloatToStrF(EURUSD15[i].OpenRate,ffFixed,8,5)+' AS CloseRate,'+
                IntToStr(tmpGraphNo)+' AS GraphNo, 1 AS RateType';
         ADOQuery1.Close;
         ADOQuery1.SQL.Clear;
         ADOQuery1.SQL.Add(sqlString);
         ADOQuery1.ExecSQL;}
       end;
     end;
     EURUSD15[i].GraphNo:=tmpGraphNo;


     if i>1 then
      begin
        EURUSD15M[EURUSD15[i-1].GraphNo,tmpGraphNo]:=1;
      end;
   end;
end;

//Номер графа
function  TForm1.getGraphNo(MatrixNo:Integer; Value:Real):Integer;
var
 i:integer;
 GraphNo:integer;
begin
 GraphNo:=0;
  for i:= 1 to EURUSD15COUNT do
   if Value=EURUSD15[i].CloseRate then
    if GraphNo=0 then
      GraphNo:=EURUSD15[i].GraphNo;
 getGraphNo:=GraphNo;
end;

//Ищем все пути от одной вершины
procedure TForm1.FindPath;
var
 tmpStr:String;
 tmpStr1:String;
 j,i:Integer;
 c,r:Integer;
begin
  findPath1:=TFindPath.Create(true);
  findPath1.Priority:=tpHighest;
  findPath1.FreeOnTerminate:=false;
  findPath2:=TFindPath.Create(true);
  findPath2.Priority:=tpHighest;
  findPath2.FreeOnTerminate:=false;
  findPath3:=TFindPath.Create(true);
  findPath3.Priority:=tpHighest;
  findPath3.FreeOnTerminate:=false;
  findPath4:=TFindPath.Create(true);
  findPath4.Priority:=tpHighest;
  findPath4.FreeOnTerminate:=false;
  findPath5:=TFindPath.Create(true);
  findPath5.Priority:=tpHighest;
  findPath5.FreeOnTerminate:=false;


  if findPath1.Connect and findPath2.Connect and findPath3.Connect
     and findPath4.Connect and findPath5.Connect then
   begin
     Memo1.Lines.Add('Подключение к базе пяти потоков прошло успешно');
     //Переносим данные в поток
     findPath1.SetDataLength(length(EURUSD15));
     findPath2.SetDataLength(length(EURUSD15));
     findPath3.SetDataLength(length(EURUSD15));
     findPath4.SetDataLength(length(EURUSD15));
     findPath5.SetDataLength(length(EURUSD15));
     for i:=0 to length(EURUSD15) do
      begin
        findPath1.AddData(i,EURUSD15[i].DateAndTime,EURUSD15[i].OpenRate,EURUSD15[i].MaxRate,
                           EURUSD15[i].MinRate,EURUSD15[i].CloseRate,EURUSD15[i].GraphNo);
        findPath2.AddData(i,EURUSD15[i].DateAndTime,EURUSD15[i].OpenRate,EURUSD15[i].MaxRate,
                           EURUSD15[i].MinRate,EURUSD15[i].CloseRate,EURUSD15[i].GraphNo);
        findPath3.AddData(i,EURUSD15[i].DateAndTime,EURUSD15[i].OpenRate,EURUSD15[i].MaxRate,
                           EURUSD15[i].MinRate,EURUSD15[i].CloseRate,EURUSD15[i].GraphNo);
        findPath4.AddData(i,EURUSD15[i].DateAndTime,EURUSD15[i].OpenRate,EURUSD15[i].MaxRate,
                           EURUSD15[i].MinRate,EURUSD15[i].CloseRate,EURUSD15[i].GraphNo);
        findPath5.AddData(i,EURUSD15[i].DateAndTime,EURUSD15[i].OpenRate,EURUSD15[i].MaxRate,
                           EURUSD15[i].MinRate,EURUSD15[i].CloseRate,EURUSD15[i].GraphNo);
      end;

     //Переносим матрицу в поток
     c:=Trunc(length(EURUSD15M));
     r:=Trunc(length(EURUSD15M));
     findPath1.SetMatrixLength(c,r);
     findPath2.SetMatrixLength(c,r);
     findPath3.SetMatrixLength(c,r);
     findPath4.SetMatrixLength(c,r);
     findPath5.SetMatrixLength(c,r);
     for i:=0 to r-1 do
      for j := 0 to c-1 do
       begin
        findPath1.AddToMatrix(i,j,EURUSD15M[i,j]);
        findPath2.AddToMatrix(i,j,EURUSD15M[i,j]);
        findPath3.AddToMatrix(i,j,EURUSD15M[i,j]);
        findPath4.AddToMatrix(i,j,EURUSD15M[i,j]);
        findPath5.AddToMatrix(i,j,EURUSD15M[i,j]);
       end;
     c:=findPath1.getDataLength;
     c:=findPath1.getMatrixLength;
     Memo1.Lines.Add('Перенос данных прошел успешно');
      //Устанавливаем начальные пути
      FromGraphNoGlobal:=Trunc((length(EURUSD15M)/4)*3);
      ToGraphNoGlobal:=Trunc((length(EURUSD15M)/4)*3);
      //Запускаем потоки через секунду
      Timer1.Enabled:=True;
   end;
end;

end.
