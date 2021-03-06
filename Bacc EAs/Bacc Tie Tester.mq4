//+----------------------------------------------------------------------+
//|                                                   Bacc Tie Tester.mq4|
//|                                                         David J. Lin |
//|                                                                      |
//|                                                                      |
//| Coded by David J. Lin                                                |
//| dave.j.lin@gmail.com                                                 |
//| Evanston, IL, October 19, 2010                                       |
//+----------------------------------------------------------------------+
#property copyright "Copyright � 2010, David J. Lin"
#property link      ""

bool ShoeDecisionsOutput=false; // output shoe & decision data
bool DebugOutput=false; // output debug data
bool ShoevsScoreOutput=false; // output shoe vs score

int Ndecks=8;        // number of desired decks
int Ncardsindeck=52; // number of cards in a deck
int Ncardvalues=13;  // number of individual values in a suite
int Nshoes=100000;    // number of desired shoes to generate in a batch
int Nbatch=1;        // number of batches of shoes to generate
 
int Ncards;           // number of cards in shoe
int Nshoe=0;          // number of generated shoes (running count)
int OutputFilehandle;  // handle for hands output file 
int OutputFilehandle2; // handle for decisions output file 
int OutputFilehandle3; // handle for decisions output file for Bacc Tester
int OutputFilehandle4; // handle for total stats of all batches of shoes
int OutputFilehandle5; // handle for debug file
// int OutputFilehandle6; // handle for tie data file
 int OutputFilehandle7; // handle for shoe vs score data file

int shoe[];          // array of cards;
int results[90,9];   // array of decision results;

int P=0,B=0,T=0;     // tally of P, B, T wins per shoe
int GP=0,GB=0,GT=0;  // tally of P, B, T wins for all shoes
int AP=0,AB=0,AT=0;  // tally of P, B, T wins for all batches of shoes 
int dec=0;           // tally of decision number

int loop;            // index for batch number to perform 
int NShoe_Global=0;  // current shoe number in entire run

int strikecount=60;  // strike count to start betting tie
int tiecount;        // Michael Brannon advanced tie count
int tiearray[];      // array keeping track of tie counts
int shoetiecount[90];  // array current tie count for all hands;

int     tiecountglobal[200]; // global tally of all tie counts for actual ties, each index corresponds to a tie count
int shoetiecountglobal[200]; // global tally of all tie counts for entire shoe, each index corresponds to a tie count

int shoescore=0; // score of shoe
int shoescoresSpacing=25; // number of shoes in a group for final printout
int shoescorescount=0; // keeps track of current count of shoes in the group
int totalwon=0; // number of bets won
int totallost=0; // number of bets lost
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
 for(loop=1;loop<=Nbatch;loop++)
 {
  OpenFiles();
  Initialize();
  Process();
  CloseFiles();
 }
 OutputTotal();
 return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
{
 return(0);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
 return(0);
}
//=========================================================================
void Initialize()
{
 GP=0;
 GB=0;
 GT=0;
 Nshoe=0;
 return;
}
//=========================================================================
void Process()
{
 Ncards=Ndecks*Ncardsindeck;
 ArrayResize(shoe,Ncards); 
 ArrayResize(shoetiecount,Ncards); 
 
 for(int n=0;n<Nshoes;n++)
 {
  //MathSrand(TimeLocal()+(((loop-1)*Nshoes)+n));
  MathSrand(((loop-1)*Nshoes)+n); 
  //MathSrand(0+n); // seed 0 for 100000 shoes
  Shuffle();
  Deal();
  RecordTies();
  if(ShoevsScoreOutput) OutputScore();
  //if(ShoeDecisionsOutput) Output();
  //if(DebugOutput) OutputDebug();  
 }
 return;
}
//=========================================================================
void Shuffle()
{
 int r,temp,value;
 P=0;B=0;T=0;
 dec=0;
 
 tiecount=0; 
 
 NShoe_Global++;
 
 for (int i=0; i<Ncards; i++) // fill the array in order
 {
  value=(i%Ncardvalues)+1;
  if(value<10) shoe[i] = value;
  else         shoe[i] = 0; // monkey!  
 }
 
 for(i=0; i<(Ncards-1); i++) 
 {
  r = i + (MathRand() % (Ncards-i)); // Random remaining position.
  temp = shoe[i]; 
  shoe[i] = shoe[r]; 
  shoe[r] = temp;
 }
 return;
}
//=========================================================================
void Deal()
{
 int HandsP[3],HandsB[3];
 int valueP,valueB;
 bool drawB3;

 for(int i=0;i<Ncards;i++)
 {
  if(i>Ncards-6) break;
  
  HandsP[0]=shoe[i];
  HandsB[0]=shoe[i+1];
  HandsP[1]=shoe[i+2];
  HandsB[1]=shoe[i+3];  
  
  for(int j=0;j<2;j++)
  {
   KeepCount(i,HandsP[j]);
   KeepCount(i,HandsB[j]);   
  }
  
  valueP=(HandsP[0]+HandsP[1])%10;
  valueB=(HandsB[0]+HandsB[1])%10;

  if(valueP>7||valueB>7) // natural, no 3rd hand 
  {
   if(valueP==valueB)      Tally(-1,valueP,valueB,HandsP[0],HandsP[1],-1,HandsB[0],HandsB[1],-1);
   else if(valueP>valueB)  Tally(1,valueP,valueB,HandsP[0],HandsP[1],-1,HandsB[0],HandsB[1],-1);
   else if(valueP<valueB)  Tally(0,valueP,valueB,HandsP[0],HandsP[1],-1,HandsB[0],HandsB[1],-1);
   i=i+3;
  }
  else if(valueP>5&&valueB>5) // no draw, no 3rd hand 
  {
   if(valueP==valueB)      Tally(-1,valueP,valueB,HandsP[0],HandsP[1],-1,HandsB[0],HandsB[1],-1);
   else if(valueP>valueB)  Tally(1,valueP,valueB,HandsP[0],HandsP[1],-1,HandsB[0],HandsB[1],-1);
   else if(valueP<valueB)  Tally(0,valueP,valueB,HandsP[0],HandsP[1],-1,HandsB[0],HandsB[1],-1);
   i=i+3;
  }
  else if(valueP>5&&valueB<=5) // only Banker draws
  {
   HandsB[2]=shoe[i+4];
   KeepCount(i,HandsB[2]);
   
   valueB=(valueB+HandsB[2])%10;
   if(valueP==valueB)      Tally(-1,valueP,valueB,HandsP[0],HandsP[1],-1,HandsB[0],HandsB[1],HandsB[2]);
   else if(valueP>valueB)  Tally(1,valueP,valueB,HandsP[0],HandsP[1],-1,HandsB[0],HandsB[1],HandsB[2]);
   else if(valueP<valueB)  Tally(0,valueP,valueB,HandsP[0],HandsP[1],-1,HandsB[0],HandsB[1],HandsB[2]);   
   i=i+4;
  }
  else if(valueP<=5&&valueB>5) // only Player draws
  {
   HandsP[2]=shoe[i+4];
   KeepCount(i,HandsP[2]);   
   valueP=(valueP+HandsP[2])%10;
   if(valueP==valueB)      Tally(-1,valueP,valueB,HandsP[0],HandsP[1],HandsP[2],HandsB[0],HandsB[1],-1);
   else if(valueP>valueB)  Tally(1,valueP,valueB,HandsP[0],HandsP[1],HandsP[2],HandsB[0],HandsB[1],-1);
   else if(valueP<valueB)  Tally(0,valueP,valueB,HandsP[0],HandsP[1],HandsP[2],HandsB[0],HandsB[1],-1);   
   i=i+4;
  }
  else // both may draw 
  {
   HandsP[2]=shoe[i+4]; // player first
   KeepCount(i,HandsP[2]);   
   valueP=(valueP+HandsP[2])%10;
   drawB3=CheckBankerDraw(HandsP[2],valueB);
   if(drawB3) // banker draws 3rd card
   {
    HandsB[2]=shoe[i+5];
    KeepCount(i,HandsB[2]);    
    valueB=(valueB+HandsB[2])%10;    
    if(valueP==valueB) Tally(-1,valueP,valueB,HandsP[0],HandsP[1],HandsP[2],HandsB[0],HandsB[1],HandsB[2]);
    if(valueP>valueB)  Tally(1,valueP,valueB,HandsP[0],HandsP[1],HandsP[2],HandsB[0],HandsB[1],HandsB[2]);
    if(valueP<valueB)  Tally(0,valueP,valueB,HandsP[0],HandsP[1],HandsP[2],HandsB[0],HandsB[1],HandsB[2]);   
    i=i+5;   
   }
   else // banker stands
   {
    if(valueP==valueB) Tally(-1,valueP,valueB,HandsP[0],HandsP[1],HandsP[2],HandsB[0],HandsB[1],-1);
    if(valueP>valueB)  Tally(1,valueP,valueB,HandsP[0],HandsP[1],HandsP[2],HandsB[0],HandsB[1],-1);
    if(valueP<valueB)  Tally(0,valueP,valueB,HandsP[0],HandsP[1],HandsP[2],HandsB[0],HandsB[1],-1);   
    i=i+4;
   }
  }
 }
 
 return;
}
//=========================================================================
bool CheckBankerDraw(int p3,int b2)
{
 if((p3==9||p3<=1)&&b2<=3) return(true);
 else if(p3==8&&b2<=2) return(true);
 else if(p3==7&&b2<=6) return(true); 
 else if(p3==6&&b2<=6) return(true);
 else if(p3==5&&b2<=5) return(true); 
 else if(p3==4&&b2<=5) return(true);
 else if(p3==3&&b2<=4) return(true); 
 else if(p3==2&&b2<=4) return(true);
 else                  return(false);
 
 return(false);
}
//=========================================================================
void Tally(int result,int totalP,int totalB,int P1,int P2,int P3,int B1,int B2,int B3)
{
 results[dec,0]=result;
 results[dec,1]=totalP; 
 results[dec,2]=totalB; 
 results[dec,3]=P1;
 results[dec,4]=P2; 
 results[dec,5]=P3;
 results[dec,6]=B1;
 results[dec,7]=B2;
 results[dec,8]=B3;    
 
 if(result>0) 
 {
  P++;GP++;AP++;
  TallyScore(false);
 }
 else if(result<0) // tie
 {
  T++;GT++;AT++;
  ArrayResize(tiearray,T);
  tiearray[T-1]=tiecount;
  TallyScore(true);
 }
 else 
 {
  B++;GB++;AB++;
  TallyScore(false);
 }

 shoetiecount[dec]=tiecount;
 dec++;
 
 return;
}
//=========================================================================
void Output()
{
 Nshoe++;
 string outputstring;

// Shoe Hands Output:
 
 outputstring=DoubleToStr(shoe[0],0);
 for(int i=1;i<Ncards;i++)
 {
  outputstring=StringConcatenate(outputstring,",",DoubleToStr(shoe[i],0)); 
 }
 outputstring=StringConcatenate(outputstring,",");
 FileWrite(OutputFilehandle,outputstring);  

// Decisions Output:
 
 int shoenumber=((loop-1)*Nshoes)+Nshoe;
 
 outputstring=StringConcatenate("Shoe Number ",DoubleToStr(shoenumber,0));
 FileWrite(OutputFilehandle2,outputstring);
 FileWrite(OutputFilehandle2," ");

 for(i=0;i<dec;i++)
 { 
  outputstring=Convert(true,results[i,0]);  
  for(int j=1;j<9;j++)
  {
   if(j==5||j==8)
   {
    outputstring=StringConcatenate(outputstring,",",Convert(false,results[i,j]));
   }
   else
   {
    outputstring=StringConcatenate(outputstring,",",DoubleToStr(results[i,j],0));
   }
  }
  FileWrite(OutputFilehandle2,outputstring);
 }
 FileWrite(OutputFilehandle2," "); 
 
 outputstring=StringConcatenate("Player Wins = ",DoubleToStr(P,0));
 FileWrite(OutputFilehandle2,outputstring); 

 outputstring=StringConcatenate("Banker Wins = ",DoubleToStr(B,0));
 FileWrite(OutputFilehandle2,outputstring);

 outputstring=StringConcatenate("Tie Wins = ",DoubleToStr(T,0));
 FileWrite(OutputFilehandle2,outputstring);  

 FileWrite(OutputFilehandle2," "); 

 if(Nshoe==Nshoes) // last shoe 
 {
  FileWrite(OutputFilehandle2,"Totals All Shoes");
  
  double total=GP+GB+GT;
  double percent=GP/total;
  
  outputstring=StringConcatenate("Player Wins = ",DoubleToStr(GP,0),"  ",DoubleToStr(percent,6));
  FileWrite(OutputFilehandle2,outputstring); 

  percent=GB/total;
  outputstring=StringConcatenate("Banker Wins = ",DoubleToStr(GB,0),"  ",DoubleToStr(percent,6));
  FileWrite(OutputFilehandle2,outputstring);

  percent=GT/total;  
  outputstring=StringConcatenate("Tie Wins = ",DoubleToStr(GT,0),"  ",DoubleToStr(percent,6));
  FileWrite(OutputFilehandle2,outputstring);  
 }

// Decisions Output for Bacc Tester:

 outputstring=StringConcatenate(DoubleToStr(Nshoe,0),",",Convert(true,results[0,0]),",");

 for(i=1;i<dec;i++)
 { 
  outputstring=StringConcatenate(outputstring,DoubleToStr(Nshoe,0),",",Convert(true,results[i,0]),",");
 }

 if(Nshoe==Nshoes) // last shoe 
 {
  outputstring=StringConcatenate(outputstring,DoubleToStr(Nshoe+1,0),",E,",DoubleToStr(Nshoe+1,0),",END");
 }

 FileWrite(OutputFilehandle3,outputstring);
 
 return;
}
//=========================================================================
void OutputTotal()
{
 int j,tiecountvalue,tiecountfrequency,lasttiecountvalue;
 double freq;
 
 string outputstring,filename="Final Stats.csv";
 OutputFilehandle4=FileOpen(filename,FILE_CSV|FILE_WRITE|FILE_READ);
 
 int shoenumber=Nbatch*Nshoes;

 outputstring=StringConcatenate("Total Number of Shoes: ",DoubleToStr(shoenumber,0));
 FileWrite(OutputFilehandle4,outputstring);
  
 double total=AP+AB+AT;
 double percent=AP/total;
  
 outputstring=StringConcatenate("\nPlayer Wins = ",DoubleToStr(AP,0),"  ",DoubleToStr(percent,6));
 FileWrite(OutputFilehandle4,outputstring); 

 percent=AB/total;
 outputstring=StringConcatenate("Banker Wins = ",DoubleToStr(AB,0),"  ",DoubleToStr(percent,6));
 FileWrite(OutputFilehandle4,outputstring);

 percent=AT/total;  
 outputstring=StringConcatenate("Tie Wins = ",DoubleToStr(AT,0),"  ",DoubleToStr(percent,6));
 FileWrite(OutputFilehandle4,outputstring);  

 FileWrite(OutputFilehandle4,"\nWin Loss Stats:\n");
 
 outputstring=StringConcatenate("Total Won: ",DoubleToStr(totalwon,0));
 FileWrite(OutputFilehandle4,outputstring);   

 outputstring=StringConcatenate("Total Lost: ",DoubleToStr(totallost,0));
 FileWrite(OutputFilehandle4,outputstring);
 
 total=totalwon+totallost;

 outputstring=StringConcatenate("Total Won and Lost: ",DoubleToStr(total,0));
 FileWrite(OutputFilehandle4,outputstring); 
 
 percent=Divide(totalwon,total);
 outputstring=StringConcatenate("Percent Won: ",DoubleToStr(percent,6));
 FileWrite(OutputFilehandle4,outputstring); 
 
 FileWrite(OutputFilehandle4,"\nTie Counts for Ties");  

 for(j=0;j<200;j++)
 {
  outputstring=StringConcatenate(DoubleToStr(j-100,0),"  ",DoubleToStr(tiecountglobal[j],0));
  FileWrite(OutputFilehandle4,outputstring);  
 }

 FileWrite(OutputFilehandle4,"\nTie Counts for All Hands"); 
 for(j=0;j<200;j++)
 {
  outputstring=StringConcatenate(DoubleToStr(j-100,0),"  ",DoubleToStr(shoetiecountglobal[j],0));
  FileWrite(OutputFilehandle4,outputstring);  
 }  

 FileWrite(OutputFilehandle4,"\nPercentage"); 
 for(j=0;j<200;j++)
 {
  percent=Divide(tiecountglobal[j],shoetiecountglobal[j]);
  outputstring=StringConcatenate(DoubleToStr(j-100,0),"  ",DoubleToStr(percent,6));
  FileWrite(OutputFilehandle4,outputstring);  
 }

 FileClose(OutputFilehandle4);
 return;
}
//=========================================================================
void RecordTies()
{
// Tie data processing
 
 ArraySort(tiearray);
 TallyCounts(true,tiearray,T); // counts for ties

 ArraySort(shoetiecount,dec);
 TallyCounts(false,shoetiecount,dec); // counts for all hands

// outputstring="\nTie Percentages\n";
// FileWrite(OutputFilehandle6,outputstring); 

// for(j=-100;j<=100;j+=10)
// {
//  freq=TieCountFrequency(j,GT);
//  percent=freq/GT;
 
//  outputstring=StringConcatenate(DoubleToStr(j,0),",",DoubleToStr(freq,0),",",DoubleToStr(percent,6));
//  FileWrite(OutputFilehandle6,outputstring);
// }

 return;
}
//=========================================================================
void OutputScore() // Score vs. Shoes:
{
 shoescorescount++; 
 
 if(shoescorescount==shoescoresSpacing) // for truncated score vs shoe output 
 {
  string outputstring; 
  outputstring=StringConcatenate(DoubleToStr(NShoe_Global,0),",",DoubleToStr(shoescore,0));
  FileWrite(OutputFilehandle7,outputstring);
  
  shoescorescount=0;
 }

 return;
}
//=========================================================================
void OutputDebug()
{
 string outputstring;

// Shoe Hands Output:
 
 outputstring=DoubleToStr(shoetiecount[0],0);
 for(int i=1;i<Ncards;i++)
 {
  outputstring=StringConcatenate(outputstring,",",DoubleToStr(shoetiecount[i],0)); 
 }
 outputstring=StringConcatenate(outputstring,",");
 FileWrite(OutputFilehandle5,outputstring);  
 return;
}
//=========================================================================
void OpenFiles()
{
 string filename;

// filename=StringConcatenate(DoubleToStr(loop,0)," Ties.csv");
// OutputFilehandle6=FileOpen(filename,FILE_CSV|FILE_WRITE|FILE_READ);
 
 if(DebugOutput)
 {
  filename=StringConcatenate(DoubleToStr(loop,0),"0000 Debug.csv");
  OutputFilehandle5=FileOpen(filename,FILE_CSV|FILE_WRITE|FILE_READ);
 }

 if(ShoevsScoreOutput)
 {
  filename=StringConcatenate(DoubleToStr(loop,0),"0000 Shoe Score.csv");
  OutputFilehandle7=FileOpen(filename,FILE_CSV|FILE_WRITE|FILE_READ);  
 }

 if(!ShoeDecisionsOutput) return;
 
 filename=StringConcatenate(DoubleToStr(loop,0),"0000 Shoe.csv");
 OutputFilehandle=FileOpen(filename,FILE_CSV|FILE_WRITE|FILE_READ);

 filename=StringConcatenate(DoubleToStr(loop,0),"0000 Decisions.csv");
 OutputFilehandle2=FileOpen(filename,FILE_CSV|FILE_WRITE|FILE_READ); 

 filename=StringConcatenate(DoubleToStr(loop+4,0)," data.csv");
 OutputFilehandle3=FileOpen(filename,FILE_CSV|FILE_WRITE|FILE_READ); 
 
 return;
}
//=========================================================================
void CloseFiles()
{
// FileClose(OutputFilehandle6);

 if(DebugOutput) FileClose(OutputFilehandle5); 

 if(ShoevsScoreOutput) FileClose(OutputFilehandle7);

 if(!ShoeDecisionsOutput) return;
 
 FileClose(OutputFilehandle);
 FileClose(OutputFilehandle2); 
 FileClose(OutputFilehandle3);  
 return;
}
//=========================================================================
string Convert(bool flag, int v)
{
 if(flag) // P/B/T decision
 {
  if(v<0) return("T");
  else if (v>0) return("P");
  else return("B");
 }
 else // 3rd draw decision
 {
  if(v<0) return("x");
  else    return(DoubleToStr(v,0));
 }
 return("X");
}
//=========================================================================
string KeepCount(int i,int d)
{
 if(d==1||d==3||d==5||d==7||d==9) tiecount+=2;
 else if(d==2||d==8) tiecount+=1;
 else tiecount-=2;
 return;
}
//=========================================================================
int TieCountFrequency(int limit, int max) // count number of tie events greater than or equal to limit
{
 int i;
 
 for(i=0;i<max;i++)
 {
  if(tiearray[i]>=limit) 
  {
   return(max-i); // return answer when find the first index i of element which exceeds desired limit
  }
 } 
 return(0);
}
//=========================================================================
void TallyCounts(bool flag, int values[], int max) // tally the frequency of counts
{
 if(max==0) return; // this is possible if tracking per shoe
 
 int j,count,frequency,lastcount;
 string outputstring;
 
 frequency=1; // start frequency at 1
 lastcount=values[0]; // initialize with first element
 
 if(max>1) // more than 1 tie
 {
  for(j=1;j<max;j++)
  {
   count=values[j];
   if(count!=lastcount)
   {
   
    if(flag) tiecountglobal[lastcount+100]+= frequency;     // for actual ties
    else     shoetiecountglobal[lastcount+100]+= frequency; // for all hands
    
    lastcount=count;   
    frequency=1;
   }
   else frequency++;
  
   if(j==max-1) // last data point, final printout 
   {
    if(flag) tiecountglobal[lastcount+100]+= frequency;     // for actual ties
    else     shoetiecountglobal[lastcount+100]+= frequency; // for all hands
   }
  }
 }
 else //only 1 tie
 {
  if(flag) tiecountglobal[lastcount+100]+= frequency;     // for actual ties
  else     shoetiecountglobal[lastcount+100]+= frequency; // for all hands
 }
 return;
}
//=========================================================================
void TallyScore(bool flag) // update score
{
 if(tiecount<strikecount) return;
 
 if(flag) 
 {
  shoescore+=8; // win flat bet
  totalwon++;
 }
 else     
 {
  shoescore-=1; // lose flat bet
  totallost++;
 }

 return;
}
//=========================================================================
double Divide(double a, double b) // avoide divide by zero
{
 if(b==0) return(0);
 else     return(a/b);
}
//=========================================================================

