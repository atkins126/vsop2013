unit Om.AstronomicalAlgorithms;   // implementation of
// Astronomical Algorithms from like named Jean Meeus book
// mostly programmed by oMAR

interface

uses
  System.SysUtils;

procedure AngleTo0_360(var A:Double); // put angle in 0..360� range
function getAngleTo0_360(const A:Double):Double;  //same as above, but different..
// date utils
Function JD(Y,M,D,UT:Double):Double;  // encode Julian date
Function JDtoDatetime(const JD:Double):TDatetime;
Function DatetimeToJD(const D:TDatetime):Double;
Function TJ2000(K,M,I,UT:Double):Double; {Time in centuries since  J2000.0}

// T in centuries since j2000
Procedure NutationCorrection(const T,aRAi,aDecli:Double; {out:} var DAlfaNu,DDeltaNu:Double);

// Nutation correction ( aka: the Nutella correction :)
Procedure CorrNut(const T:Double; var Eps,DPhy,DEps:Double);

// zenital
Procedure geoPositionToCelestial(aDay,aMonth,aYear:word; const aGMTTime,aLat,aLon:double;{out:}var aRA,aDecl:double);

// returns celestial coordinates (RA,Decl) of Greenwitch apparent position
Procedure GreenwitchToCelestial(const aUT:TDatetime; {out:} var aRA,aDecl:double);

// degree trigs
Function Sing(const G:Double):Double;  { Sin() using degrees}
Function ASing(const S:Double):Double; {arc sin em Graus}
Function Cosg(const G:Double):Double;  { Cos() using degrees}
Function Tang(G:Double):Double;        { Tan() using degrees }

// float --> str
function floatToLatitudeStr(const a:Double):String;   // degrees -->  '23.26�N'
function floatToLongitudeStr(const a:Double):String;
Function floatToHHMMSS(R:Double):String; {Double --> 'HHHh MM' SS"} //nova fev06
Function floatToGMSD(R:Double):String;   //degrees Double --> 'GGG�MM'SS.DD"} mai08:Om:

implementation //--------------------------------------

uses
  System.Math;

Function Sing(const G:Double):Double;  { Sin() using degrees}
begin Sing := Sin(G*Pi/180); end;

Function ASing(const S:Double):Double; {arc sin em Graus}
begin ASing := ArcSin(S)*180/Pi; end;

Function Cosg(const G:Double):Double;  { Cos() using degrees}
begin Cosg := Cos(G*Pi/180); end;

Function Tang(G:Double):Double;        { Tan() using degrees }
var CG:Double;
begin
  CG:=Cosg(G);
  {if CG=0.0 then CG:=1E-20;}     {= Numero bem pequeno}
  Tang:=Sing(G)/CG;
end;

// Nutation correction ( aka: the Nutella correction :)
Procedure CorrNut(const T:Double; var Eps,DPhy,DEps:Double);
var
  Omega:Double;
  L,Ll:Double;
  T2,T3:Double; Eps0:Double;
begin            {Nutacao e obliquidade da ecliptica Ast.Alg. pag. 132}
  T2 := T*T; T3 := T*T2;
  Omega := 125.04452-1934.136261*T;
  L     := 280.4665 + 36000.7698*T;
  Ll    := 218.3165 +481267.8813*T;
  {nas formulas da pag 132, DPhy e DEps em " de grau, Eps0 em graus}
  DPhy := -17.2*Sing(Omega)-1.32*sing(2*L)-0.23*Sing(2*Ll)+0.21*Sing(2*Omega);
  DEps :=   9.2*cosg(Omega)+0.57*cosg(2*L)+0.10*Cosg(2*Ll)-0.09*Cosg(2*Omega);
  Eps0 :=  23.4392911+(-46.8150*T-0.00059*T2+0.001813*T3)/3600;    {21.2}
  Eps  :=  Eps0+DEps/3600;
end;

Procedure PrecessionCorrction(const T,aRAi,aDecli:Double; var DAlfaPre,DDeltaPre:Double);
var  {T=Tempo em seculos desde j2000.0 - calcule com TJ2000() }
  m,n:Double;
  DAlfaP,DDeltaP:Double; {Correcao anual por precessao}
  NAnos:Double;
begin  {Efeito da precessao - Extraido de Astronomical Algorithms-J. Meeus p. 124}
  NAnos := T*100.0;             {Numero de anos desde J2000.0}

  m := (3.07496+0.00186*T)*15;  {*15 converte de seg p/ " }
  n := 20.0431-0.0085*T;

  DAlfaP  := m+n*Sing(aRAi)*Tang(aDecli);  {Deltas em " de arco -  formula 20.1}
  DDeltaP := n*Cosg(aRAi);                 {Esses valores sao anuais}

{  WriteLn('DA P:',DAlfaP:8:4);
   WriteLn ('DD P:',DDeltaP:8:4);}

  DAlfaPre  := DAlfaP*NAnos; {Converte em valores absolutos, multiplicando por NAnos}
  DDeltaPre := DDEltaP*NAnos;

{  WriteLn('DA Pre:',DAlfaPre:8:4);
   WriteLn ('DD Pre:',DDeltaPre:8:4);}
end;

// T in centuries since j2000
Procedure NutationCorrection(const T,aRAi,aDecli:Double; {out:} var DAlfaNu,DDeltaNu:Double);
var DPhy,DEps:Double;
    Eps:Double;
    TDi,SEps,CEps,SA,CA:Double;
begin
  CorrNut(T,Eps,DPhy,DEps);
  SEps := Sing(Eps);
  CEps := Cosg(Eps);
  SA := Sing(aRAi);   CA := Cosg(aRAi);   TDi := Tang(aDecli);  //memoise trigs
  DAlfaNu  := (CEps+SEps*SA*TDi)*DPhy-(CA*TDi)*DEps;            {formula 22.1 pag.139 Ast.Alg}
  DDeltaNu := (SEps*CA)*DPhy+SA*DEps;
end;

Procedure CalculaSunTrueLongitude(const T:Double; var Teta:Double);
var L0,C,T2,T3,M:Double;
begin {Calculo da Long Verd. do Sol}
  T2 := T*T; T3 := T*T2;
  L0 := 280.46645+36000.76983*T+0.0003032*T2;            {FORMULA 24.2}
  M  := 357.5291+35999.0503*T-0.0001559*T2-0.00000048*T3; {24.4}
  C  := +(1.9146-0.004817*T-0.000014*T2)*Sing(M)+(0.019993-0.000101*T)*Sing(2.0*M)+0.000290*Sing(3.0*M);
  Teta := L0+C;
end;

Procedure AberrationCorrection(const T,aRAi,aDecli:Double; var DAlfaAbe,DDeltaAbe:Double);
var Teta,e,Pi_,T2,T3:Double; {Teta=Sun True Longitude}
    CA,SA,Eps0,CEp,SEp,STt,CTt,SDl,CDl,SPi,CPi,K1,K2:Double; {Vars auxiliares}
    Omega:Double;
const  Kapa=20.49552; {Constante de aberracao}

begin {Efeito da aberracao}
  T2    := T*T;  T3 := T*T2;
  Omega := 125.04452-1934.136261*T;
  Eps0  := 23.4392911+(-46.8150*T-0.00059*T2+0.001813*T3)/3600;
  CalculaSunTrueLongitude(T,Teta);
  e     := 0.016708617-0.00004237*T-0.0000001236*T2;
  Pi_   := 102.93735+0.71953*T+0.00046*T2;
  { memoise trigs }
  CA :=Cosg(aRAi);   SA :=Sing(aRAi);
  CTt:=Cosg(Teta);   STt:=Sing(Teta);
  CEp:=Cosg(Eps0);   SEp:=Sing(Eps0);
  CDl:=Cosg(aDecli); SDl:=Sing(aDecli);
  CPi:=Cosg(Pi_);    SPi:=Sing(Pi_);

  DAlfaAbe := -Kapa*((CA*CTt*CEp+SA*STt)/CDl) + e*Kapa*((CA*CPi*CEp+SA*SPi)/CDl);
  k1       := CEp*(Tang(Eps0)*CDl-SA*SDl); K2:=CA*SDl;
  DDeltaAbe:= -Kapa*(CTt*K1+K2*STt)+e*Kapa*CPi*K1+K2*SPi;
end;

{JD - Julian Day - Astro Algorithms J.Meeus, pg 61 formula 7.1 }
{Implementada em Jul/04 para ter maior validade que a do Alm For Comp }
{alguns usuarios reclamaram que a formula acima n�o funciona para 1800 ! }
Function JD(Y,M,D,UT:Double):Double;
var A,B:double;
begin
  if (M<=2) then
    begin
      Y:=Y-1;
      M:=M+12;
    end;
  A:=Int(Y/100);
  B:=2-A+Int(A/4); //Gregoriano
  //B:=0;          //Juliano
  Result := Int(365.25*(Y+4716))+Int(30.6001*(M+1))+D+B-1524.5+UT/24;
end;

Function TJ2000(K,M,I,UT:Double):Double; {Time in centuries since  J2000.0}
begin
  TJ2000 := (JD(K,M,I,UT)-2451545.0)/36525.0;
end;

Function HourTo0_24(const H:Double):Double; //put H in 0- 24h range
begin
  Result := H;
  if (Result<0)        then Result := Result+24
  else if (Result>=24) then Result := Result-24;
end;

procedure AngleTo0_360(var A:Double); // put angle in 0..360� range
begin
  while (A<0)      do A:=A+360.0;
  while (A>=360.0) do A:=A-360.0;
end;

function getAngleTo0_360(const A:Double):Double;  //same as abovce, but different..
var aA:Double;
begin
  aA := A;
  AngleTo0_360( aA );
  Result := aA;
end;

// H in hours UT
// GMST - Greenwitch Mean Sideral Time
// GAST - Greenwich Apparent Sidereal Time ( = GMST affected by nutation )
// returned times in hours
Procedure SiderealTime(D,M,A,H:Double;{out:} var GMST,GAST:Double); {AA pag.83}
var T,E,Eps,DPhy,DEps:Double;
begin
  T    := TJ2000(A,M,D,0);
  GMST := 24110.54841+8640184.812866*T+0.093104*T*T-0.0000062*T*T*T; {em seg, 0 UT}
  GMST := GMST/3600.0+1.00273790935*H;   {em horas}
  CorrNut(T, Eps, DPhy, DEps);           {calc Corr por nutacao}
  E    := DPhy*Cosg(Eps)/3600.0/15.0;
  GAST := GMST+E;
  GAST := HourTo0_24(GAST);
  GMST := HourTo0_24(GMST);
end;

// returns celestial coordinates (RA,Decl) of the zenith at position aLat,aLon
Procedure geoPositionToCelestial(aDay,aMonth,aYear:word; const aGMTTime,aLat,aLon:double; var aRA,aDecl:double);
var aGHA,aGMST,aGAST:Double;
begin
  SiderealTime(aDay,aMonth,aYear,aGMTTime,{out:} aGMST,aGAST);  //calc GAST (in hours)
  aDecl:= aLat;
  aGHA := aLon;
  aRA  := aGAST*15-aGHA;   //15 converte de horas para graus.
  AngleTo0_360(aRA);       // Ajusta o angulo colocando entre 0 e 360�
end;

// returns celestial coordinates (RA,Decl) of Greenwitch apparent position
Procedure GreenwitchToCelestial(const aUT:TDatetime; {out:} var aRA,aDecl:double);  // RA and dec returns in degrees
var aGHA,aGMST,aGAST,aHour:Double; YY,MM,DD:word; D:TDatetime;
begin
  D     := Trunc( aUT );
  DecodeDate( D, {out:} YY,MM,DD);
  aHour := Frac(aUT)*24;        // in hours

  SiderealTime(DD,MM,YY,aHour,{out:} aGMST,aGAST);  //calc GAST (in hours)
  aDecl:= 0;  //
  aGHA := 0;  // greenwitch GHA=0
  // use GW apparent time  ( applies nutation to GMST )
  aRA  := aGAST*15-aGHA;   // 15 converte de horas para graus. ()
  AngleTo0_360(aRA);       // Ajusta o angulo colocando entre 0 e 360�
end;

// Some date utils
Function DatetimeToJD(const D:TDatetime):Double; // D in UT
var YY,MM,DD:Word; H:Double;
begin
  DecodeDate( Trunc(D), {out:}YY,MM,DD);
  H := Frac(D)*24;
  Result := JD(YY,MM,DD,{UT:}H  );
end;

// Julian number to Gregorian Date. Astronomical Algorithms - J. Meeus
Function JDtoDatetime(const JD:Double):TDatetime;  // convert JD to UT ( TDatetime )
var A,B,F,H:Double; alpha,C,E:integer; D,Z:longint; dd,mm,yy:word;
begin
  H := Frac(JD+0.5);    // JD zeroes at noon  ( go figure... )

  Z := trunc(JD + 0.5);
  F := (JD + 0.5) - Z;
  if (Z<2299161.0) then A:=Z
    else begin
      alpha := trunc( (Z-1867216.25)/36524.25 );
      A := Z+1+alpha-(alpha div 4);
    end;
  B := A + 1524;
  C := trunc( (B - 122.1) / 365.25);
  D := trunc( 365.25 * C);
  E := trunc((B - D) / 30.6001);
  dd := Trunc(B - D - int(30.6001 * E) + F);
  if (E<14) then mm:=E-1
    else mm :=E-13;
  if mm > 2 then yy := C - 4716
    else yy := C - 4715;

  Result := EncodeDate(yy,mm,dd)+ H;   // time
end;

function floatToLatitudeStr(const a:Double):String;
var ang:Double; Sulfix:String;
begin
  if      (a>0) then Sulfix:='N'
  else if (a<0) then Sulfix:='S'
  else Sulfix:='';   // 0 --> '00.00'
  ang := Abs(a);
  Result := Trim( Format('%5.1f�',[ang]) )+Sulfix;
end;

function floatToLongitudeStr(const a:Double):String;
var ang:Double; Sulfix:String;
begin
  if      (a>0) then Sulfix:='E'
  else if (a<0) then Sulfix:='W'
  else Sulfix:='';   // 0 --> '00.00'
  ang := Abs(a);
  Result := Trim( Format('%6.1f�',[ang]) )+Sulfix;
end;

function R2HMS(R:Double;var HMS:Double):String;    {Double --> 'HHHh MM' SS"}
var h,m,s:Double; sh,sm,ss:String; Sx:Char; Sn:Integer;
begin
  if R<0 then begin Sx:='O'; Sn:=-1; r:=-r;  end //nov/05 Sx= '0' quando negativo ?
    else begin Sx:=' '; Sn:=1; end;
  {R=HH.DDDD}
  h := Trunc(R);  {HH}
  R := 60*(R-h);  {MM.DD}
  m := Trunc(R);  {MM}
  R := 60*(R-m);  {SSDD}
  s := Round(R);
  if (S>=60) then begin S:=s-60; m:=m+1; end;
  if (m>=60) then begin m:=m-60; h:=h+1; end;
  Str(h:2:0, sh);
  Str(m:2:0, sm);
  Str(s:2:0, ss);
  if sm[1]=' ' then sm[1]:='0';
  if ss[1]=' ' then ss[1]:='0';
  R2HMS:=sh+':'+sm+':'+ss+' '+Sx;
  HMS:=Sn*(h+m/100+s/10000);      {H retorna HH.MMSS}
end;

// R (0..1) --> HH:MM:SS (0..24)
Function floatToHHMMSS(R:Double):String; {Double --> 'HHHh MM' SS"} //nova fev06
var Dummy:Double; L:integer;
begin
  Result := R2HMS(R,Dummy);
  L := Length(Result);
  if (Result[L]='O') then //O no final de R2HMS() significa negativo
    begin
      Delete(Result,L,1);
      Result:='(-)'+Result;
    end;
end;

Function floatToGMSD(R:Double):String;   //degrees Double --> 'GGG�MM'SS.DD"} mai08:Om:
var g,m,s:Double; sg,sm,ss:String; Sx:Char; Sn:Integer;
begin
  if (R<0) then begin Sx:='-'; r:=-r;  end
    else begin  Sx:=' '; end;
  {R=GG.DDDD}
  g := Trunc(R);  {GG}
  R := 60*(R-g);  {MM.DD}
  m := Trunc(R);  {MM}
  R := 60*(R-m);  {SSDD}
  s := R;
  if (s>=60) then begin s:=s-60; m:=m+1; end;
  if (m>=60) then begin m:=m-60; g:=g+1; end;
  Str(g:2:0,sg);
  Str(m:2:0,sm);
  if (sm[1]=' ') then sm[1]:='0';
  ss := Format('%5.2f',[s]);
  if (ss[1]=' ') then ss[1]:='0';
  Result := Trim( Sx+sg+'�'+sm+''''+ss+'"');
end;

end.
