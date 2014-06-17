unit FindPathUnit;

interface
uses
 Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
 Dialogs, StdCtrls,DateUtils, DB, ADODB;

type EURUSDREC=record
   DateAndTime:TdateTime;
   OpenRate:Real;
   MaxRate:Real;
   MinRate:Real;
   CloseRate:Real;
   GraphNo:Integer;
end;

type
  TFindPath = class(TThread)
  private
   PathStat:boolean;
   PathsCount:Int64;
   FromGraphNoGlobal:Integer;
   ToGraphNoGlobal:Integer;
   Path:array[1..10000] of integer;
   PathElementsCount:Integer;
   procedure FindPath(FromGraphNo:Integer;ToGraphNo:Integer);
   function  inPath(GraphNo:Integer):Boolean;
   function  getPathTime:longint;
   function  getSlump:longint;
  public
   procedure Find;
   function  Connect:boolean;
   function  Disconnect:boolean;
   procedure SetDataLength(C:Integer);
   procedure AddData(C:Integer; DateAndTime:TdateTime; OpenRate,MaxRate,MinRate,CloseRate:Real;GraphNo:Integer);
   procedure SetMatrixLength(C,R:Integer);
   procedure AddToMatrix(C,R,E:Integer);
   procedure SetPathPoint(FromGraphNo:Integer;ToGraphNo:Integer);
   function getPathStat:boolean;
   function getDataLength:Integer;
   function getMatrixLength:Integer;
  protected
   procedure execute; override;
  end;

var
 EURUSD15M:array of array of byte;
 EURUSD15:Array of EURUSDREC;
 ADOConnection1:TADOConnection;
 ADOQuery1:TADOQuery;



implementation

function TFindPath.getDataLength:Integer;
 begin
   getDataLength:=length(EURUSD15);
 end;

function TFindPath.getMatrixLength:Integer;
begin
   getMatrixLength:=length(EURUSD15M);
end;

function  TFindPath.Connect:boolean;
 var
  conStr:String;
  tmpStat:boolean;
 begin
   tmpStat:=true;
   conStr:='Provider=Microsoft.Jet.OLEDB.4.0;Data Source='+
           ExtractFilePath(Application.ExeName)+
           'db2.mdb;Persist Security Info=False';
   try
    ADOConnection1:=TADOConnection.Create(nil);
    ADOQuery1:=TADOQuery.Create(nil);
    ADOConnection1.ConnectionString:=conStr;
    ADOConnection1.LoginPrompt:=false;
    ADOConnection1.KeepConnection:=true;
    ADOConnection1.Mode:=cmShareDenyNone;
    ADOConnection1.Connected:=true;
    ADOQuery1.Connection:=ADOConnection1;
   except
     tmpStat:=false;
   end;
  PathStat:=false;
  Connect:=tmpStat;
 end;

function  TFindPath.Disconnect:boolean;
 var
  tmpStat:boolean;
 begin
  try
    if ADOConnection1.Connected then
     ADOConnection1.Connected:=false;
   ADOConnection1.Destroy;
   ADOQuery1.Destroy;
   except
     tmpStat:=false;
   end;
   Disconnect:=tmpStat;
 end;

procedure TFindPath.Find;
 begin
  if PathStat then
   begin
    FindPath(FromGraphNoGlobal,ToGraphNoGlobal);
    PathStat:=false;
   end;
 end;

procedure TFindPath.FindPath(FromGraphNo:Integer;ToGraphNo:Integer);
  var
 tmpStr:String;
 tmpStr1:String;
 j,i:Integer;
 fileName:String;
 fileDir:String;
 f:TextFile;
 sqlString:String;
 tmpString:String;
 beginCycle,endCycle:integer;
begin
  tmpStr1:='';
  if (FromGraphNo<>ToGraphNo) then
   begin
     Path[PathElementsCount]:=FromGraphNo;
     PathElementsCount:=PathElementsCount+1;
     //Старт
     if FromGraphNo-48>0 then
      beginCycle:=FromGraphNo-48
     else
      beginCycle:=0;
     //Конец
     if FromGraphNo+48<ToGraphNo then
      endCycle:=FromGraphNo+48
     else
      endCycle:=ToGraphNo;

   //  if (getPathTime<1440) then
    //  begin
      for j := beginCycle to endCycle do
        begin
         if (EURUSD15M[FromGraphNo,j]=1) then
          if not inPath(j) then
            FindPath(j,ToGraphNo);
        end;
      //end;
    Path[PathElementsCount]:=0;
    PathElementsCount:=PathElementsCount-1;
   end
   else
    begin
     Path[PathElementsCount]:=FromGraphNo;
      if (getPathTime<1440) then
       begin
        PathsCount:=PathsCount+1;
        tmpString:='';
        if PathElementsCount>1 then
         begin
          for i := 0 to PathElementsCount do
           tmpString:=tmpString+':'+IntToStr(Path[i]);

          sqlstring:='Select key from PathTab where  FromGraphNo='+IntToStr(FromGraphNoGlobal)+
                     ' and  ToGraphNo='+IntToStr(ToGraphNo)+' and Path='''+tmpString+'''';
          ADOQuery1.Close;
          ADOQuery1.SQL.Clear;
          ADOQuery1.SQL.Add(sqlString);
          ADOQuery1.Open;
          if ADOQuery1.RecordCount=0 then
           begin
            sqlString:= 'INSERT INTO PathTab ( FromGraphNo, ToGraphNo, Path, [Time], Slump )'+
                        'SELECT '+IntToStr(FromGraphNoGlobal)+' AS FromGraphNo, '
                        +IntToStr(ToGraphNo)+' AS ToGraphNo,'''+
                         tmpString +''' AS Path, '+IntToStr(getPathTime)+' AS [Time],'+
                        IntToStr(getSlump)+' AS Slump';
            try
            ADOQuery1.Close;
            ADOQuery1.SQL.Clear;
            ADOQuery1.SQL.Add(sqlString);
            ADOQuery1.ExecSQL;
           except
            on E : Exception do
             ShowMessage(E.ClassName+' поднята ошибка, с сообщением : '+E.Message);
           end;
          end;
         end;
       end;
    end;
  end;

  procedure TFindPath.SetMatrixLength(C,R:Integer);
  var
   i:integer;
  begin
    SetLength(EURUSD15M,C,R);
  end;

  procedure TFindPath.AddToMatrix(C,R,E:Integer);
  var
   i:integer;
  begin
    EURUSD15M[C,R]:=E;
  end;

  procedure TFindPath.SetPathPoint(FromGraphNo:Integer;ToGraphNo:Integer);
  begin
    FromGraphNoGlobal:=FromGraphNo;
    ToGraphNoGlobal:=ToGraphNo;
    PathStat:=true;
  end;

  //Выполнение
  procedure TFindPath.execute;
  begin
  while true do
   begin
    Synchronize(Find);
    sleep(1000);
   end;
  end;

  //Статус
 function TFindPath.getPathStat:boolean;
  begin
   getPathStat:=PathStat;
  end;

//Число в пути
function  TFindPath.inPath(GraphNo:Integer):Boolean;
 var
  i:integer;
  tmpStr:String;
  flag:boolean;
 begin
  flag:=false;
  for i := 1 to PathElementsCount do
   if Path[i]=GraphNo then
    flag:=true;
  inPath:=flag;
 end;

//Время прохождения пути
function  TFindPath.getPathTime:longint;
var
 i:integer;
 Minutes:int64;
 tmpStr:String;
 sqlString:String;
 FromGraphDateTime:TDateTime;
 ToGraphDateTime:TDateTime;
begin
 Minutes:=0;
 tmpStr:='';
 for i := 2 to PathElementsCount do
   begin
     if Path[i]<>0 then
     begin
      ADOQuery1.Close;
      sqlString:='Select DT,TM From RateTab where GraphNo='+IntToStr(Path[i-1]);
      ADOQuery1.SQL.Clear;
      ADOQuery1.SQL.Add(sqlString);
      ADOQuery1.Open;
      if ADOQuery1.RecordCount>0 then
       begin
        tmpStr:=DateToStr(ADOQuery1.FieldByName('DT').AsDateTime)+' '+TimeToStr(ADOQuery1.FieldByName('TM').AsDateTime);
        FromGraphDateTime:=StrToDateTime(tmpStr);
       end;

      ADOQuery1.Close;
      sqlString:='Select DT,TM From RateTab where GraphNo='+IntToStr(Path[i]);
      ADOQuery1.SQL.Clear;
      ADOQuery1.SQL.Add(sqlString);
      ADOQuery1.Open;
      if ADOQuery1.RecordCount>0 then
       begin
        tmpStr:=DateToStr(ADOQuery1.FieldByName('DT').AsDateTime)+' '+TimeToStr(ADOQuery1.FieldByName('TM').AsDateTime);
        ToGraphDateTime:=StrToDateTime(tmpStr);
       end;
      // Minutes:=Minutes+MinutesBetween(EURUSD15[Path[i-1]].DateAndTime, EURUSD15[Path[i]].DateAndTime);
      Minutes:=Minutes+MinutesBetween(FromGraphDateTime, IncMilliSecond(ToGraphDateTime));
     end;
   end;
 getPathTime:=Minutes;
end;

function  TFindPath.getSlump:longint;
var
 i:integer;
 maxPoints:int64;
 Points:int64;
 sqlString:String;
 FirstCloseRate,CurrentMaxRate:Real;
begin
  maxPoints:=0;
  Points:=0;
  for i := 2 to PathElementsCount do
   begin
     if Path[i]<>0 then
      begin
       ADOQuery1.Close;
       sqlString:='Select CloseRate From RateTab where GraphNo='+IntToStr(Path[1]);
       ADOQuery1.SQL.Clear;
       ADOQuery1.SQL.Add(sqlString);
       ADOQuery1.Open;
       if ADOQuery1.RecordCount>0 then
        FirstCloseRate:=ADOQuery1.Fields[0].AsFloat;

       ADOQuery1.Close;
       sqlString:='Select MaxRate From RateTab where GraphNo='+IntToStr(Path[1]);
       ADOQuery1.SQL.Clear;
       ADOQuery1.SQL.Add(sqlString);
       ADOQuery1.Open;
       if ADOQuery1.RecordCount>0 then
        CurrentMaxRate:=ADOQuery1.Fields[0].AsFloat;

       Points:=Trunc(Abs(FirstCloseRate-CurrentMaxRate)*100000);
       if Points>maxPoints then
        maxPoints:=Points;
      end;
   end;
  getSlump:=maxPoints;
end;

procedure TFindPath.SetDataLength(C:Integer);
 begin
  SetLength(EURUSD15,C);
 end;

procedure TFindPath.AddData(C:Integer; DateAndTime:TdateTime; OpenRate,MaxRate,MinRate,CloseRate:Real;GraphNo:Integer);
 begin
   EURUSD15[C].DateAndTime:=DateAndTime;
   EURUSD15[C].OpenRate:=OpenRate;
   EURUSD15[C].MaxRate:=MaxRate;
   EURUSD15[C].MinRate:=MinRate;
   EURUSD15[C].CloseRate:=CloseRate;
   EURUSD15[C].CloseRate:=GraphNo;
 end;

end.
