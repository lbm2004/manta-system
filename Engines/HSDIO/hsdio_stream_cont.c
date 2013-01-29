/*=================================================================
 HSDIO Continuous Data Streaming To Disk (Used in Conjunction with MANTA)
 *=================================================================*/
#include <math.h>
#include <time.h>
#include <string.h>
//include "mex.h"
//include <conio.h>
//include <windows.h>

/* from ContinuousAcquisition */
#include <stdio.h>
#include "niHSDIO.h"

/* Defines */
#define DEBUG 1
#define ANALOGSAMPLESPERLOOP 19200000
//#define ANALOGSAMPLESPERLOOP 30000000

// DECLARE INITIALLIZATION FUNCTIONS
ViStatus setupGenerationDevice(
        ViRsrc genDeviceID, 
        ViConstString genChannelList, 
        ViConstString sampleClockOutputTerminal,
        ViReal64 sampleClockRate, 
        ViConstString AcqTriggerTerminal, 
        ViConstString GenTriggerTerminal, 
        ViInt32 StartTriggerEdge,
        ViUInt16 *waveformData,
        ViConstString waveformName, 
        ViUInt32 waveformLength,
        ViSession *genViPtr);

ViStatus setupAcquisitionDevice(ViRsrc acqDeviceID, 
        ViConstString acqChannelList, 
        ViConstString sampleClockSource,
        ViReal64 sampleClockRate,
        ViUInt32 SamplesPerIteration,
        ViConstString AcqTriggerTerminal,
        ViInt32 StartTriggerEdge, 
        ViSession *genViPtr);

void decodeData(
        ViUInt8 *DData,
        ViUInt16 *AData,
        ViUInt32 DTotalSamplesRead, 
        ViUInt32 DSamplesRead, 
        ViUInt32 *ATotalSamplesRead, 
        ViUInt32 *ASamplesRead, 
        ViUInt32 Bits, 
        ViUInt32 PacketLength,
        ViUInt32 LoopIteration,
        ViUInt32 *TriggerCount,
        ViUInt32 *TriggerSamples,
        ViUInt32 *TriggerValues
        );
 
int acquireData(
        char* FileName, 
        ViUInt32 NumberOfChannels, 
        int DSamplingRate, 
        ViUInt32 MaxIterations, 
        int ASamplesPerIteration,
        char* DeviceName, 
        int ChannelNumber, 
        char* TriggerChannel,
        ViUInt32 BitLength);

int createData(
        char* FileName,
        int NumberOfChannels,
        int DSamplingRate, 
        int MaxIterations, 
        int SamplesPerIteration);

int writeStatusFile(char *FileNameStatus, long APosThisLoop, long ALoopCount);

int checkStopFile(char *FileNameStop);


///////////////////////////////////////////////////////////////////////////////////////////
int createData(char* FileName,int NumberOfChannels,int DSamplingRate, int MaxIterations, int ASamplesPerIteration) {

  FILE *DataFile, *StopFile, *StatusFile, *TriggersFile;
  short *AData;
  int *StopBit;
  long APosThisLoopBytes[2];
  long ASamplesTotal = 0, ASamplesWritten= 0, ATotalSamplesWritten =0 , AHeadSamples =0 , ASamplesRead = 0, ATailSamples = 0;
  long ATailWritten = 0, AHeadWritten = 0, AOffset = 0,  APosThisLoop = 0, CurrentPosition = 0,  Done = 0, kk, iTotal=0, i,j,k, ALoopCount =0;
  long TrigCount = 0, TrigSpacing = 50000;
  double TimePerIteration, Elapsed = 0, ASamplingRate;
  clock_t Clock1, Clock2;
  double Time1, Time2;
  long cStep = 0;
  char FileNameStatus[255], FileNameBuffer[255], FileNameTriggers[255], FileNameStop[255];
  
  ASamplingRate = DSamplingRate/1600; // Assuming 16 bits here
  if (DEBUG) printf("Analog Sampling Rate : %f\n",ASamplingRate);
  TimePerIteration = (double) (ASamplesPerIteration/ASamplingRate);
// OPEN FILE FOR WRITING
  strcpy(FileNameBuffer,FileName);
  strcat(FileNameBuffer,".bin");
  if (DEBUG) printf("Buffer File Name: %s\n",FileNameBuffer);
  DataFile = fopen(FileNameBuffer, "wb");
  if (DataFile == NULL) { printf("Targetfile for Data could not be opened!\n"); return -1;}
  
  // PREPARE STATUS FILE
  strcpy(FileNameStatus,FileName);
  strcat(FileNameStatus,".status");
  if (DEBUG) printf("Status File Name: %s\n",FileNameStatus);
  
  // PREPARE TRIGGER FILE
  strcpy(FileNameTriggers,FileName);
  strcat(FileNameTriggers,".triggers");
  printf("Triggers File Name: %s\n",FileNameTriggers);
  // OPEN TRIGGERS FILE
  TriggersFile = fopen(FileNameTriggers, "w");
  if (TriggersFile == NULL) { printf("TriggersFile could not be opened!\n"); return -1;}
  
  // PREPARE STOP FILE
  strcpy(FileNameStop,FileName);
  strcat(FileNameStop, ".stop");
  printf("Stop File Name: %s\n",FileNameStop);
  
// SETUP DATA MATRIX
  ASamplesRead = ASamplesPerIteration;
  ASamplesTotal = (int) (ASamplesRead*NumberOfChannels);
  if (DEBUG) printf("Analog Samples per Iteration : %d\n", ASamplesTotal);
  AData = (short*)calloc(ASamplesTotal,sizeof(short));
  for (i=0;i<ASamplesTotal;i++) AData[i] = 0; // Initialize to  0
  StopBit = (int*) malloc(sizeof(int));

  for (k=0;k<MaxIterations;k++) {
    // KILL SOME TIME IN ORDER TO PRODUCE DATA IN NEAR REALTIME
    if (DEBUG) printf("%d %2.2f ",k,TimePerIteration);
    Elapsed = 0;
    Clock1 = clock();
    if (DEBUG) printf("Clock: %d ",Clock1);
    Time1 = (double)Clock1/ (double)CLOCKS_PER_SEC;
    if (DEBUG) printf("Time1 : %2.2f ",Time1);
    while (Elapsed<TimePerIteration) {
      Clock2= clock();
      Time2= (double)Clock2/(double)CLOCKS_PER_SEC ;
      Elapsed = Time2 - Time1;
    }
    printf("Time2 : %2.2f ",Time2);
    printf("%f s - \n ",Elapsed);
    fflush(stdout);
    
    // GENERATE DATA
    for (i=0;i<ASamplesRead;i++) {
      cStep = iTotal + i;
      for (j=0;j<NumberOfChannels;j++) {
        // Simulate Continuous 60Hz Noise
        AData[i*NumberOfChannels+j] = (short) (10000*sin(2*3.14159*5.123*(i+iTotal+100*j)/ASamplingRate));
        // Simulate temporally stable grid   
        //AData[i*NumberOfChannels+j] = 0;
        //if (cStep % 1000 == 0) {AData[i*NumberOfChannels+j] = 10000;}
      }
    }
    iTotal = iTotal + ASamplesRead;
  
    // WRITE ANALOG DATA TO DISK (FOR ONLINE READING)
    // DATA IS WRITTEN TO LARGE CIRCULAR BUFFER
    if (APosThisLoop+ASamplesTotal > ANALOGSAMPLESPERLOOP) {
      ATailSamples=(ANALOGSAMPLESPERLOOP-APosThisLoop)/NumberOfChannels;
      AHeadSamples=ASamplesRead-ATailSamples;
    } else {
      ATailSamples=ASamplesRead;
      AHeadSamples=0;
    }

    if (DEBUG) printf("\tAcquired:\t\t%d Tail + %d Head = %d Read\n", ATailSamples, AHeadSamples, ASamplesRead);
    
    // WRITE TAIL
    if (ATailSamples>0) {
      ATailWritten = fwrite(AData, sizeof(short), (size_t) (ATailSamples*NumberOfChannels), DataFile);
      //if (DEBUG) printf("\tTailSamples  %d %d %d %d %d\n", ATailSamples,ATailWritten,NumberOfChannels,sizeof(short),sizeof(AData));
      if (ATailWritten != ATailSamples*NumberOfChannels) { printf("Tail samples could not be written!\n"); return -1;}
    }
    
    // WRITE HEAD
    if (AHeadSamples>0) {
      AOffset=ATailSamples*NumberOfChannels;
      fseek(DataFile  , 0 , SEEK_SET );
      AHeadWritten = fwrite(&(AData[AOffset]), sizeof(short), (size_t) (AHeadSamples*NumberOfChannels), DataFile);
      //if (DEBUG) printf("\tHeadSamples  %d %d %d %d %d\n", AHeadSamples,AHeadWritten,NumberOfChannels,sizeof(short),sizeof(AData));
      if (AHeadWritten != AHeadSamples*NumberOfChannels) { printf("Head samples could not be written!\n"); return -1;}
      ALoopCount++;
      if (DEBUG) printf("\tStarting output loop %d\n", ALoopCount);
      APosThisLoop=AHeadWritten;
    } else {
      AHeadWritten=0;
      APosThisLoop+=ATailWritten;
    }
    
    ASamplesWritten = ATailWritten + AHeadWritten;
    ATotalSamplesWritten = ATotalSamplesWritten + ASamplesWritten;
    fflush(DataFile);
    CurrentPosition=ftell(DataFile);
    
    if (DEBUG) printf("\tWritten:\t\t%d Tail+%d Head = %d Read\n", ATailWritten, AHeadWritten, ASamplesWritten);
    if (DEBUG) printf("\tWritten (Total):\t%d This Loop | %d All Loops \n", APosThisLoop, ATotalSamplesWritten);
    if (DEBUG) printf("\tFile pos :\t\t%d\n", CurrentPosition);
  
      // WRITE TRIGGERS (SAMPLE,)
    if (iTotal > TrigCount*TrigSpacing) {
      if (TrigCount) fprintf(TriggersFile,"%i %i %i\n",2*TrigCount,TrigCount*TrigSpacing-2000,0);
      fprintf(TriggersFile,"%i %i %i\n",2*TrigCount+1,TrigCount*TrigSpacing+1000,1);
      TrigCount++;
    }

    // WRITE STATUS FILE
    writeStatusFile(FileNameStatus, APosThisLoop,ALoopCount);
    
    // CHECK WHETHER TO STOP RECORDING
     if ( checkStopFile(FileNameStop) ) break;
  }
  fclose(DataFile);
  fclose(TriggersFile);
  return 1;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
int acquireData(char* FileName, ViUInt32 NumberOfChannels, int DSamplingRate, ViUInt32 MaxIterations, int ASamplesPerIteration,
            char* DeviceName, int ChannelNumber, char* TriggerChannel, ViUInt32 BitLength) {
  
  // TRANSFER ARGUMENTS TO NI VARIABLES 
  ViRsrc deviceID = (ViRsrc) DeviceName;
  ViReal64 SampleClockRate = (ViReal64) DSamplingRate;
  
  // DATA MATRICES
  ViUInt16 *AData;
  ViUInt8 *DData;
  
  // TRIGGER MATRICES
  ViUInt32 *TriggerSamples, *TriggerValues;
  
  // ACQUISITION PARAMETERS
  ViConstString acqChannelList = "0,2"; // Acquisition and Trigger Channel
  ViSession vi = VI_NULL;
  ViUInt32 readTimeout, dataWidth = 1, i, j,Aoffset, Doffset, BufferIterations = 10;
  ViUInt32 BackLogSamples, DSamplesRead = 0, ASamplesRead = 0, DTotalSamplesRead = 0, ATotalSamplesRead = 0;
  ViUInt32 ASamplesWritten = 0, DSamplesWritten = 0, ATotalSamplesWritten = 0, DTotalSamplesWritten = 0;
  ViUInt32 PacketLength, DSamplesPerIteration, ASamplesPerChannel, ASamplesTotal, DSamplesTotal;
  ViUInt16 ConstLevel = 2;
  
  // GENERATION PARAMETERS
  ViConstString genChannelList = "1";
  ViSession genVi = VI_NULL;
  ViConstString GenTriggerTerminal = (ViConstString) TriggerChannel; // Generation triggered by external trigger, sends trigger to Acquisition trigger
  ViConstString AcqTriggerTerminal = NIHSDIO_VAL_PFI0_STR; // Acquisition trigger received by Generation device, otherwise timing not reliable.
  ViInt32 msTimeout, StartTriggerEdge =  NIHSDIO_VAL_RISING_EDGE; // Mysteriously, one needs to connect the trigger inverted between GND and +. Probably better in a closed circuit/with a switch
  ViConstString sampleClockOutputTerminal = NIHSDIO_VAL_DDC_CLK_OUT_STR; // MAYBE THIS IS THE PLACE WHERE THE ACQUIRED SAMPLES ARE SHOWN?? See setupGenerationDevice
  ViUInt16 *waveformData; /* data type of waveformData needs to change if data width is not 2 bytes. */
  ViConstString waveformName = "myWfm";

// circular output buffer in memory
  ViUInt32 ASamplesLoopSize=50000, TriggerCount=0, TriggersWritten = 0;
  ViUInt32 ASamplesWrittenThisLoop=0, ALoopCount=0, ABytesWrittenThisLoop[2];
  ViUInt32 ATailSamples=0, ATailWritten=0, AHeadSamples=0, AHeadWritten=0;
  
  // circular buffer variables
  ViUInt32 ASamplesPerChannelBuffer, ASamplesBuffer, DSamplesBuffer, DSamplesBufferValid;
  ViUInt32 DBufferSamplesRead=0, ABufferSamplesRead=0, ASamplesBufferValid;
  long CurrentPosition=0, TrigSample = 0, TrigValue =0, APosThisLoop =0;
  
  clock_t time1, time2;
  float ExpectedTimeToPass, TimePassed;
  int WriteDigital=1, WriteAnalog=1, MaxTriggers = 1000000;
  char FileNameBuffer[255], FileNameD[255], FileNameStop[255], FileNameStatus[255], FileNameTriggers[255], TriggersStatus[255];
  int *StopBit;
  
  FILE *DataFile, *DataFileD, *StopFile, *StatusFile, *TriggersFile;
  
  /* ERROR VARIABLES */
  ViChar errDesc[1024];
  ViStatus error = VI_SUCCESS;
  
  // PARSE OPTIONS FOR DIFFERENT BITS
  if (BitLength==12) PacketLength = 1200;
  if (BitLength==16) PacketLength = 1600;
  
  // OVERALL SAMPLES/TIME
  // SVD 2012-07-03: circular buffer plus max iterations to avoid running out of memory
  // leave 10 iterations of space at the end of the circular buffer
  DSamplesPerIteration = (ViUInt32) (ASamplesPerIteration*PacketLength);
  ASamplesPerChannelBuffer = (BufferIterations+10)*ASamplesPerIteration;
  ASamplesBuffer = (ViUInt32) (ASamplesPerChannelBuffer*NumberOfChannels);
  ASamplesBufferValid = ASamplesBuffer-(ASamplesPerIteration*NumberOfChannels*10);
  DSamplesBuffer = (ViUInt32) (ASamplesPerChannelBuffer*PacketLength);
  DSamplesBufferValid = DSamplesBuffer-DSamplesPerIteration*10;
  ASamplesPerChannel = MaxIterations*ASamplesPerIteration;
  ASamplesTotal = (ViUInt32) (ASamplesPerChannel*NumberOfChannels);
  DSamplesTotal = (ViUInt32) (ASamplesPerChannel*PacketLength);
  readTimeout = (ViInt32) (DSamplesTotal/SampleClockRate*1000+1000); /* milliseconds */
  msTimeout = (ViInt32) (DSamplesPerIteration/SampleClockRate*1000+10000);
  
  // GET DATA MATRIX
  // Note: it would be much better to have a circular engine, since
  // the size of the array can be arbitrary, e.g. in free running mode, there is no limit.
  // Implementation would be pretty straight forward, with a current position pointer and wrapping at the end.
  DData = (char*)malloc(DSamplesBuffer*sizeof(char));
  AData = (ViUInt16*)malloc(ASamplesBuffer*sizeof(ViUInt16));
  TriggerSamples = (ViUInt32*)malloc(MaxTriggers*sizeof(ViUInt32));
  TriggerValues = (ViUInt32*)malloc(MaxTriggers*sizeof(ViUInt32));
  StopBit = (int*) calloc(1,sizeof(int));

  // GENERATION CODE
  /* create data for output */
  waveformData = (ViUInt16*) malloc(DSamplesPerIteration*sizeof(ViUInt16));
  for (i = 0; i < DSamplesPerIteration; i++)  waveformData[i] = ConstLevel*(i % 2);
  if (DEBUG) printf("Sizeof Waveform : %d\n",sizeof(waveformData));
  
  time1 = clock();
  ExpectedTimeToPass=(float)DSamplesTotal / (float)SampleClockRate;
  if (DEBUG) printf("Expected time (s): %.3f\n",ExpectedTimeToPass);
  
  /* Initialize, configure, and write waveforms to generation device */
  checkErr(setupGenerationDevice (deviceID, genChannelList, sampleClockOutputTerminal,
          SampleClockRate, AcqTriggerTerminal, GenTriggerTerminal, StartTriggerEdge,  waveformData, waveformName, DSamplesPerIteration, &genVi));  
  time2 = clock(); printf("Time Difference : %f seconds\n",difftime (time2,time1)/CLOCKS_PER_SEC);
  /* Commit settings to start sample clock, run before initiate the acquisition */
  checkErr(niHSDIO_CommitDynamic(genVi));
  
  // ACQUISITION CODE
  checkErr(setupAcquisitionDevice(deviceID, acqChannelList, NIHSDIO_VAL_ON_BOARD_CLOCK_STR,
          SampleClockRate,  DSamplesPerIteration, AcqTriggerTerminal , StartTriggerEdge, &vi));
  /* Query Data Width */
  checkErr(niHSDIO_GetAttributeViInt32(vi, VI_NULL, NIHSDIO_ATTR_DATA_WIDTH, &dataWidth));
  /* Configure Fetch */
  checkErr(niHSDIO_SetAttributeViInt32 (vi, "",NIHSDIO_ATTR_FETCH_RELATIVE_TO, NIHSDIO_VAL_FIRST_SAMPLE));
      
  checkErr(niHSDIO_Initiate(genVi));
  
  checkErr(niHSDIO_SetAttributeViInt32 (vi, "",NIHSDIO_ATTR_FETCH_RELATIVE_TO,NIHSDIO_VAL_CURRENT_READ_POSITION));

   // PREPARE STATUS FILE
  strcpy(FileNameStatus,FileName);
  strcat(FileNameStatus,".status");
  if (DEBUG) printf("Status File Name: %s\n",FileNameStatus);
  
  // PREPARE TRIGGER FILE
  strcpy(FileNameTriggers,FileName);
  strcat(FileNameTriggers,".triggers");
  printf("Triggers File Name: %s\n",FileNameTriggers);
  // OPEN TRIGGERS FILE
  TriggersFile = fopen(FileNameTriggers, "w");
  if (TriggersFile == NULL) { printf("TriggersFile could not be opened!\n"); return -1;}
  
  // PREPARE STOP FILE
  strcpy(FileNameStop,FileName);
  strcat(FileNameStop, ".stop");
  printf("Stop File Name: %s\n",FileNameStop);

  // PREPARE DIGITAL DATA FILE
  if (WriteDigital) {
    strcpy(FileNameD,FileName);
    strcat(FileNameD,".digital");
    DataFileD = fopen(FileNameD, "wb");
    if (DataFileD == NULL) { printf("Targetfile for digital data could not be opened!\n"); return -1; }
  }  
  
   // PREPARE ANALOG DATA FILE
  // do this last to insure proper handshaking with MANTA
  if (WriteAnalog) {
    strcpy(FileNameBuffer,FileName);
    strcat(FileNameBuffer,".bin");
    DataFile = fopen(FileNameBuffer, "wb+");
    if (DataFile == NULL) { printf("Targetfile for analog data could not be opened!\n"); return -1; }
  }
  
  // START ACQUISITION
  time1 = clock();
  for (i=0; i<MaxIterations; i++)  {
    printf(">> Starting loop %d / %d\n",i+1,MaxIterations);
    /* Configure Fetch */
    checkErr(niHSDIO_SetAttributeViInt32 (vi, "",NIHSDIO_ATTR_FETCH_OFFSET, 0));
    
    // ACQUIRE DATA FROM DEVICE
    checkErr(niHSDIO_FetchWaveformU8(vi, DSamplesPerIteration, readTimeout,&DSamplesRead, &(DData[DBufferSamplesRead])));
    DBufferSamplesRead = DBufferSamplesRead + DSamplesRead;
    DTotalSamplesRead = DTotalSamplesRead + DSamplesRead;
    if (DEBUG) printf("\tNumber of Samples read : %d\n",DTotalSamplesRead);
     
    /* Check Remaining Samples */
    checkErr(niHSDIO_GetAttributeViInt32 (vi, "",NIHSDIO_ATTR_FETCH_BACKLOG, &BackLogSamples));
    if (DEBUG) printf("\tSamples left in buffer %d\n",BackLogSamples);
    
    // WRITE DIGITAL DATA
    if (WriteDigital) {
        Doffset=(DBufferSamplesRead-DSamplesRead);
        DSamplesWritten = fwrite(&(DData[Doffset]), sizeof(char), (size_t) (DSamplesRead), DataFileD);
        if (DSamplesWritten != DSamplesRead) { printf("Samples could not be written!\n"); return -1;}
        if (DEBUG) printf("\tDigital Samples written : %d from offset %d\n",DSamplesWritten,Doffset);
        DTotalSamplesWritten = DTotalSamplesWritten + DSamplesWritten;
    } 
    
    if (WriteAnalog) {
      // DECODE CHANNELS
      decodeData(DData, AData, DBufferSamplesRead, DSamplesRead, &ABufferSamplesRead, &ASamplesRead, BitLength, PacketLength,i,
              &TriggerCount,TriggerSamples,TriggerValues);
      ATotalSamplesRead=ATotalSamplesRead+ASamplesRead;
      if (DEBUG) printf("\tASamples this loop %d/%d (%d)\n", ASamplesRead, ABufferSamplesRead, ATotalSamplesRead);      
      
      // WRITE ANALOG DATA TO DISK (FOR ONLINE READING)
      // TO DO: modify to loop to begining for file if 
      // ATotalSamplesWrittenThisLoop goes over limit specified by 
      // hard-coded ANALOGSAMPLESPERLOOP
      
      if (ASamplesWrittenThisLoop+ASamplesRead*NumberOfChannels > ANALOGSAMPLESPERLOOP) {
         ATailSamples=(ANALOGSAMPLESPERLOOP-ASamplesWrittenThisLoop)/NumberOfChannels;
         AHeadSamples=ASamplesRead-ATailSamples;
      } else {
         ATailSamples=ASamplesRead;
         AHeadSamples=0;
      }
      
      Aoffset=(ABufferSamplesRead-ASamplesRead)*NumberOfChannels;
      ATailWritten = fwrite(&(AData[Aoffset]), sizeof(ViUInt16), (size_t) (ATailSamples*NumberOfChannels), DataFile);
      if (ATailWritten != ATailSamples*NumberOfChannels) { printf("Tail samples could not be written!\n"); return -1;}
      
      if (AHeadSamples>0) {
         Aoffset=(ABufferSamplesRead-AHeadSamples)*NumberOfChannels;
         fseek (DataFile  , 0 , SEEK_SET );
         AHeadWritten = fwrite(&(AData[Aoffset]), sizeof(ViUInt16), (size_t) (AHeadSamples*NumberOfChannels), DataFile);
         if (AHeadWritten != AHeadSamples*NumberOfChannels) { printf("Head samples could not be written!\n"); return -1;}
         ALoopCount++;
         if (DEBUG) printf("\tStarting output loop %d\n", ALoopCount);
         ASamplesWrittenThisLoop=AHeadWritten;
      } else {
         AHeadWritten=0;
         ASamplesWrittenThisLoop+=ATailWritten;
      }
      
      ASamplesWritten = ATailWritten + AHeadWritten;
      ATotalSamplesWritten = ATotalSamplesWritten + ASamplesWritten;
      fflush(DataFile);
      CurrentPosition=ftell(DataFile);
  
      if (DEBUG) printf("\tT+H=ASamples acqu'd:  %d + %d = %d\n", ATailSamples, AHeadSamples, ASamplesRead);
      if (DEBUG) printf("\tT+H=ASamples written: %d + %d = %d\n", ATailWritten, AHeadWritten, ASamplesWritten);
      if (DEBUG) printf("\tT+H=Total:            %d (loop) %d (all)\n", ASamplesWrittenThisLoop, ATotalSamplesWritten);
      if (DEBUG) printf("\tFile pos :            %d\n", CurrentPosition);
      
       // WRITE TRIGGERS
      while (TriggersWritten < TriggerCount) {
        TriggersWritten++;
        fprintf(TriggersFile,"%i %i %i\n",TriggersWritten,TriggerSamples[TriggersWritten],TriggerValues[TriggersWritten]);
      }
      
      // WRITE STATUS FILE
      writeStatusFile(FileNameStatus, APosThisLoop,ALoopCount);    
    }

    time2=clock();
    TimePassed=difftime(time2,time1)/CLOCKS_PER_SEC;
    if (TimePassed > ExpectedTimeToPass+1) {
      if (DEBUG) {printf("Timeout on HSDIO read. Quitting.\n"); }
      i=MaxIterations;
    }
    
    // bookkeeping : move any extra data from the end of the circular buffers to the beginning and take modulo of counters
    
    // DIGITAL BUFFER (CIRCULAR)
    if (DBufferSamplesRead>DSamplesBufferValid) {
      //printf("Circling. DBufferSamplesRead: %d  Per Iteration: %d  Valid: %d\n",DBufferSamplesRead,DSamplesPerIteration,DSamplesBufferValid);
      //printf("j goes: %d to %d\n",0,DBufferSamplesRead % (DSamplesBufferValid-DSamplesPerIteration));
      //printf("offset: %d to %d\n",0+DSamplesBufferValid-DSamplesPerIteration,DBufferSamplesRead % (DSamplesBufferValid-DSamplesPerIteration)+DSamplesBufferValid-DSamplesPerIteration);
      for (j=0;j<DBufferSamplesRead % (DSamplesBufferValid-DSamplesPerIteration);j++){
        DData[j]=DData[j+DSamplesBufferValid-DSamplesPerIteration];
      }
      DBufferSamplesRead=DBufferSamplesRead % (DSamplesBufferValid-DSamplesPerIteration);
      if (DEBUG) printf("DBufferSamplesRead: %d  Valid: %d\n",DBufferSamplesRead,DSamplesBufferValid);
      
      if (WriteAnalog) {
        // ANALOG BUFFER (CIRCULAR)
        //printf("Circling. ABufferSamplesRead: %d  Per Iteration: %d  Valid: %d\n",ABufferSamplesRead*NumberOfChannels,ASamplesPerIteration*NumberOfChannels,ASamplesBufferValid);
        //printf("j goes: %d to %d\n",0,(ABufferSamplesRead*NumberOfChannels) % (ASamplesBufferValid-ASamplesPerIteration*NumberOfChannels));
        //printf("offset: %d to %d\n",0+ASamplesBufferValid-ASamplesPerIteration*NumberOfChannels,(ABufferSamplesRead*NumberOfChannels) % (ASamplesBufferValid-ASamplesPerIteration*NumberOfChannels)+ASamplesBufferValid-ASamplesPerIteration*NumberOfChannels);
        for (j=0;j<(ABufferSamplesRead*NumberOfChannels) % (ASamplesBufferValid-ASamplesPerIteration*NumberOfChannels);j++){
           AData[j]=AData[j+ASamplesBufferValid-ASamplesPerIteration*NumberOfChannels];
        }
        ABufferSamplesRead=ABufferSamplesRead % (ASamplesBufferValid/NumberOfChannels-ASamplesPerIteration);
        if (DEBUG)printf("ABufferSamplesRead: %d  Valid: %d\n", ABufferSamplesRead*NumberOfChannels, ASamplesBufferValid);
      }
    }
    
    // CHECK WHETHER TO STOP
    if ( checkStopFile(FileNameStop) ) break;
    
  } // END OF MAIN LOOP
  niHSDIO_reset(vi);
  
  if (WriteAnalog) fclose(DataFile);
  if (WriteDigital) fclose(DataFileD);
  
  Error:
    if (error == VI_SUCCESS) { /* print result */
      printf("Done without error.\n");
      printf("Number of digital samples read = %d.\n", DTotalSamplesRead);
      printf("Number of analog samples written = %d.\n", ATotalSamplesWritten);
    } else { /* Get error description and print */
      niHSDIO_GetError(vi, &error, sizeof(errDesc)/sizeof(ViChar), errDesc);
      printf("\nError encountered\n===================\n%s\n", errDesc);}
    
    niHSDIO_close(vi); /* close the session */
    return error;
};
  

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void decodeData(ViUInt8 *DData,
        ViUInt16 *AData,
        ViUInt32 DTotalSamplesRead,
        ViUInt32 DSamplesRead, 
        ViUInt32 *ATotalSamplesRead, 
        ViUInt32 *ASamplesRead, 
        ViUInt32 BitLength, 
        ViUInt32 PacketLength, 
        ViUInt32 LoopIteration,
        ViUInt32 *TriggerCount, 
        ViUInt32 *TriggerSamples,
        ViUInt32 *TriggerValues
        ) {
  
  ViUInt32 NumberOfChannels = 96;
  ViInt32 Bundles = 32;
  ViUInt32 ChannelsPerBundle = 32;
  ViUInt32 BitsPerBundle = 3*BitLength;
  ViUInt8 Header[] = {0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,1};
  ViInt32 HeaderLength = sizeof(Header)/sizeof(ViUInt8);
  ViInt32 FlagLength = 8;
  ViInt32 DataOffset = 0;
  ViInt32 cStart, DataStart, PacketStart, IterationStart = DTotalSamplesRead - DSamplesRead; // Jumps back to the first entry in the current Iteration
  ViInt32 i1, i2, i3, EqCount, AOffset, Offset;
  ViInt32 PacketsThisIteration = (ViInt32) (floor(DSamplesRead/PacketLength));
  ViInt32 HeaderFound = 0;
  ViInt32 HeaderStart = 0;
  ViUInt32 cATotalSamplesRead;
  ViUInt32 TBDLength = 0;
  long DeadEnd = 0, NDeadD = 100;
  int ProcessData = 0;
  
  // ADDITIONAL HEADER FOR THE 
  if (BitLength==16) TBDLength = 16;
  
  // SCAN FOR TRIGGER (NOTE DOWN TRIGGERS AND REDUCE REPRESENTATION TO HEADSSTAGE CODE)
  if (DEBUG) printf("\tChecking for Triggers\n");
  for (i1=IterationStart; i1<(DSamplesRead+IterationStart-1); i1++) {
    if (i1>DeadEnd) { // CHECK IF WITHIN DEADTIME AFTER LAST TRIGGER
      if (DData[i1]>1 & DData[i1+1]<=1) { // FIND DOWN TRIGGER
        TriggerCount[0]++;
        TriggerSamples[TriggerCount[0]] = floor((i1 + IterationStart)/PacketLength);
        TriggerValues[TriggerCount[0]] = 0;
        DeadEnd = i1+NDeadD;
        if (DEBUG) printf("\t\t T%d : DOWN Trigger (Sample: %d)\n",TriggerCount[0],TriggerSamples[TriggerCount[0]]);
      }
      if (DData[i1]<=1 & DData[i1+1]>1) { // FIND UP TRIGGER
        TriggerCount[0]++;
        TriggerSamples[TriggerCount[0]] = floor((i1 + IterationStart)/PacketLength);
        TriggerValues[TriggerCount[0]] = 1;
        DeadEnd = i1+NDeadD;
        if (DEBUG) printf("\t\t T%d : UP Trigger (Sample: %d)\n",TriggerCount[0],TriggerSamples[TriggerCount[0]]);
      }
    }
    if (DData[i1]>1) DData[i1] = DData[i1]-4; // SUBTRACT TRIGGER DIFFERENCE
  }
  
  
  if (ProcessData) {
    // DISTANCE FROM THE PACKETSTART TO THE DATA START
    DataOffset = HeaderLength + FlagLength + TBDLength;
    
    if (DEBUG) printf("\tEntering decoder (DSample : %d, ASample : %d)...\n",IterationStart,ATotalSamplesRead[0]);
    // FIND NEXT/LAST HEADER
    Offset=0;
    if (LoopIteration != 0) { // SEARCH BACKWARD
      for (i1=0; i1<PacketLength; i1++) {
        EqCount = 0;
        for (i2=0; i2<HeaderLength; i2++) {
          // DUAL HEADER DETECTION
          if (DData[IterationStart-PacketLength+1+i1+i2] == Header[i2] & DData[IterationStart+1+i1+i2] == Header[i2])
            EqCount++;
        }
        // found a match
        if (EqCount == HeaderLength) {
          Offset = -PacketLength+1+i1; HeaderFound = 1;break;
        }
      }
    } else { // SEARCH FORWARD
      for (i1=0; i1<PacketLength; i1++) {
        EqCount = 0;
        for (i2=0; i2<HeaderLength; i2++) {
          // DUAL HEADER DETECTION
          if (DData[IterationStart+i1+i2] == Header[i2] & DData[IterationStart+PacketLength+i1+i2] == Header[i2])
            EqCount++;
        }
        if (EqCount == HeaderLength) {Offset = i1; HeaderFound = 1; PacketsThisIteration--; break;}
      }
    }
    // END OF HEADER DETECTION
    
    // DECODE PACKAGES
    //if (DEBUG) printf("\t Decoding Packet\n");
    PacketStart = IterationStart + Offset;
    for (i1 = 0; i1<PacketsThisIteration; i1++) { // Loop over the number of expected analog packets (samples in time)
      // CHECK WHETHER PACKET STARTS AT EXPECTED LOCATION
      HeaderStart=PacketStart;
      EqCount = 0;
      for (i2=0; i2<HeaderLength; i2++) {
        if (DData[HeaderStart+i2] == Header[i2]) EqCount++;
      }
      // IF HEADER NOT FOUND, LOOK FOR HEADER (should happen only rarely)
      if (EqCount < HeaderLength) {
        if (DEBUG) {
          printf("ASamp: %d DSamp: %d Iteration: %d:  Header not found at offset : %d\n Searching for header ...\n",i1+ATotalSamplesRead[0],HeaderStart,i1,Offset);
        }
        for (i3=0; i3<PacketLength; i3++) { // SEARCH FOR HEADER WITHIN ONE PACKETLENGTH
          EqCount = 0;
          for (i2=0; i2<HeaderLength; i2++) {
            if (DData[HeaderStart-(PacketLength/2)+i3+i2] == Header[i2]) EqCount++;
          }
          // found a match
          if (EqCount == HeaderLength) {
            if (DEBUG) {
              printf("Found a new match, adjusting offset from %d to %d\n",Offset,Offset-(PacketLength/2)+i3);
            }
            Offset = Offset-(PacketLength/2)+i3;
            PacketStart=PacketStart-(PacketLength/2)+i3;
            HeaderFound = 2;
            break;
          }
        }
        if (~HeaderFound) {printf("No Header Found within one packetlength");}
      }
      
      DataStart = PacketStart + DataOffset;
      switch (BitLength) {
        case 12:
          for (i2 = 0; i2<Bundles ; i2++ ) { // Loop over the Bundles in the data section in a packet
            cStart = DataStart + i2*BitsPerBundle;
            cATotalSamplesRead = i1+ATotalSamplesRead[0];
            AOffset = cATotalSamplesRead*NumberOfChannels + i2*3;
            AData[AOffset]     = -2048*DData[cStart]     + 1024*DData[cStart+3] + 512*DData[cStart+6] + 256*DData[cStart+9]   + 128*DData[cStart+12] + 64*DData[cStart+15] + 32*DData[cStart+18] + 16*DData[cStart+21] + 8*DData[cStart+24] + 4*DData[cStart+27] + 2*DData[cStart+30] + 1*DData[cStart+33];
            AData[AOffset+1] = -2048*DData[cStart+1] + 1024*DData[cStart+4] + 512*DData[cStart+7] + 256*DData[cStart+10] + 128*DData[cStart+13] + 64*DData[cStart+16] + 32*DData[cStart+19] + 16*DData[cStart+22] + 8*DData[cStart+25] + 4*DData[cStart+28] + 2*DData[cStart+31] + 1*DData[cStart+34];
            AData[AOffset+2] = -2048*DData[cStart+2] + 1024*DData[cStart+5] + 512*DData[cStart+8] + 256*DData[cStart+11] + 128*DData[cStart+14] + 64*DData[cStart+17] + 32*DData[cStart+20] + 16*DData[cStart+23] + 8*DData[cStart+26] + 4*DData[cStart+29] + 2*DData[cStart+32] + 1*DData[cStart+35];
          };
          break;
        case 16:
          for (i2 = 0; i2<Bundles ; i2++ ) { // Loop over the Bundles in the data section in a packet
            cStart = DataStart + i2*BitsPerBundle;
            cATotalSamplesRead = i1+ATotalSamplesRead[0];
            AOffset = cATotalSamplesRead*NumberOfChannels + i2*3;
            AData[AOffset]      = 32768*DData[cStart]     + 16384*DData[cStart+3] + 8192*DData[cStart+6] + 4096*DData[cStart+9]   + 2048*DData[cStart+12] + 1024*DData[cStart+15] + 512*DData[cStart+18] + 256*DData[cStart+21] + 128*DData[cStart+24] + 64*DData[cStart+27] + 32*DData[cStart+30] + 16*DData[cStart+33] + 8*DData[cStart+36] + 4*DData[cStart+39] + 2*DData[cStart+42] + 1*DData[cStart+45];
            AData[AOffset+1] = 32768*DData[cStart+1] + 16384*DData[cStart+4] + 8192*DData[cStart+7] + 4096*DData[cStart+10] + 2048*DData[cStart+13] + 1024*DData[cStart+16] + 512*DData[cStart+19] + 256*DData[cStart+22] + 128*DData[cStart+25] + 64*DData[cStart+28] + 32*DData[cStart+31] + 16*DData[cStart+34] + 8*DData[cStart+37] + 4*DData[cStart+40] + 2*DData[cStart+43] + 1*DData[cStart+46];
            AData[AOffset+2] = 32768*DData[cStart+2] + 16384*DData[cStart+5] + 8192*DData[cStart+8] + 4096*DData[cStart+11] + 2048*DData[cStart+14] + 1024*DData[cStart+17] + 512*DData[cStart+20] + 256*DData[cStart+23] + 128*DData[cStart+26] + 64*DData[cStart+29] + 32*DData[cStart+32] + 16*DData[cStart+35] + 8*DData[cStart+38] + 4*DData[cStart+41] + 2*DData[cStart+44] + 1*DData[cStart+47];
          };
          break;
        default:
          printf("Unknown Bitlength specified!"); return;
      }
      PacketStart = PacketStart + PacketLength;
    } // END OF DECODING LOOP
  } // END PROCESS IF
  
  ASamplesRead[0]=PacketsThisIteration;
  ATotalSamplesRead[0] = ATotalSamplesRead[0] + ASamplesRead[0];
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
ViStatus setupGenerationDevice(ViRsrc genDeviceID, ViConstString genChannelList, ViConstString sampleClockOutputTerminal,
        ViReal64 SampleClockRate,
        ViConstString AcqTriggerTerminal, ViConstString StartTriggerSource, ViInt32 StartTriggerEdge,
        ViUInt16 *waveformData, ViConstString waveformName, ViUInt32 waveformLength, ViSession *genViPtr)  {
  
  ViStatus error = VI_SUCCESS;
  ViSession vi = VI_NULL;
  char notrigger[2]="XX";
  
  /* Initialize generation session */
  checkErr(niHSDIO_InitGenerationSession(genDeviceID, VI_FALSE, VI_TRUE, VI_NULL, &vi));
  /* Assign channels for dynamic generation */
  checkErr(niHSDIO_AssignDynamicChannels (vi, genChannelList));  
  /* Configure Sample Clock */
  checkErr(niHSDIO_ConfigureSampleClock (vi, NIHSDIO_VAL_ON_BOARD_CLOCK_STR, SampleClockRate));
  /* Configure generation mode to play a waveform */
  checkErr(niHSDIO_ConfigureGenerationMode (vi, NIHSDIO_VAL_WAVEFORM));
  /* Configure generation mode to repeat the waveform indefinitely */
  checkErr(niHSDIO_ConfigureGenerationRepeat (vi, NIHSDIO_VAL_CONTINUOUS, 0));
  /* Export Sample Clock */
  checkErr(niHSDIO_ExportSignal (vi, NIHSDIO_VAL_SAMPLE_CLOCK, VI_NULL, sampleClockOutputTerminal));
  /* Export data active event */
  checkErr(niHSDIO_ExportSignal(vi, NIHSDIO_VAL_DATA_ACTIVE_EVENT, VI_NULL, AcqTriggerTerminal));
  
  if (strcmp((char *)StartTriggerSource, notrigger)) {
    /* Configure start trigger */
    if (DEBUG) printf("Trigger is %s.\n",StartTriggerSource);
    checkErr(niHSDIO_SetAttributeViInt32(vi, "", NIHSDIO_ATTR_DIGITAL_EDGE_START_TRIGGER_TERMINAL_CONFIGURATION, NIHSDIO_VAL_SINGLE_ENDED));
    checkErr(niHSDIO_ConfigureDigitalEdgeStartTrigger(vi,StartTriggerSource, StartTriggerEdge));
  } else {
    /* no trigger */
    if (DEBUG) printf("No trigger, starting immediately.\n");
  }
  /* Write waveform to device |  use different Write function if default data width is not 4 bytes. */
  checkErr(niHSDIO_WriteNamedWaveformU16(vi, waveformName, waveformLength, waveformData));

  Error:  
    *genViPtr = vi;
    return error;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
ViStatus setupAcquisitionDevice (ViRsrc acqDeviceID, ViConstString acqChannelList, ViConstString sampleClockSource,
        ViReal64 SampleClockRate,  ViUInt32 SamplesPerIteration, ViConstString AcqTriggerTerminal, ViInt32 StartTriggerEdge,
        ViSession *acqViPtr)  {
  
  ViStatus error = VI_SUCCESS;
  ViSession vi = VI_NULL;
  ViUInt32 TotalAcqMem;
  ViUInt32 DataWidth = 1;
  
  /* Initialize acquisition session */
  checkErr(niHSDIO_InitAcquisitionSession(acqDeviceID, VI_FALSE, VI_FALSE, VI_NULL, &vi));
  /* Assign channels for dynamic acquisition */
  checkErr(niHSDIO_AssignDynamicChannels (vi, acqChannelList));
  /* Configure Sample clock parameters */
  checkErr(niHSDIO_ConfigureSampleClock(vi, sampleClockSource, SampleClockRate));
  /* Configure the acquistion to be continuous (not finite). */
  checkErr(niHSDIO_SetAttributeViBoolean (vi, "",NIHSDIO_ATTR_SAMPLES_PER_RECORD_IS_FINITE, VI_FALSE));
  /* Configure the number of samples to acquire to device */
  //checkErr(niHSDIO_ConfigureAcquisitionSize(vi, SamplesPerIteration, 1));
  /* Configure start trigger */
  checkErr(niHSDIO_ConfigureDigitalEdgeStartTrigger(vi,AcqTriggerTerminal, StartTriggerEdge));
  //checkErr(niHSDIO_ConfigureDigitalEdgeStartTrigger(vi, NIHSDIO_VAL_PFI1_STR, StartTriggerEdge));
  /* Set the Data Width Attribute */
  checkErr(niHSDIO_SetAttributeViInt32(vi, VI_NULL, NIHSDIO_ATTR_DATA_WIDTH, DataWidth));
  /* Set the Data Width Attribute */
  checkErr(niHSDIO_GetAttributeViInt32(vi, VI_NULL, NIHSDIO_ATTR_TOTAL_ACQUISITION_MEMORY_SIZE, &TotalAcqMem));
  
  printf("Total Memory/Channel : %i Mb\n",TotalAcqMem*2/DataWidth/(1024^2));
   
  /* Initiate Acquisition */
  checkErr(niHSDIO_Initiate (vi));
  
  Error:
    *acqViPtr = vi;
    return error;   
}

//////////////// WRITE STATUS TO FILE /////////////////////////////////////////////////
int writeStatusFile(char *FileNameStatus, long APosThisLoop, long ALoopCount) {
  FILE *StatusFile = fopen(FileNameStatus, "w");
  if (StatusFile == NULL) { printf("StatusFile could not be opened!\n"); return -1;}
  if (DEBUG) printf("\tBytes this loop : %d\n",APosThisLoop*2);
  fprintf(StatusFile,"%i %i",APosThisLoop*2,ALoopCount);
  fclose(StatusFile);
  return 1;
}

///////////////// CHECK WHETHER TO STOP RECORDING /////////////////////////////
int checkStopFile(char *FileNameStop) {
  FILE *StopFile;
  int *StopBit;
  int ReturnValue;
  StopBit = (int*) malloc(sizeof(int));
  if (StopFile = fopen(FileNameStop,"r")) {
    fread(StopBit,sizeof(int),1,StopFile);
    ReturnValue = StopBit[0];
    fclose(StopFile);
  } else {
    ReturnValue = 0;
    if (DEBUG) printf("No StopFile Found: %s\n",FileNameStop);
  }
  return ReturnValue;
}
        

/////////////////////////////////////////////////////////////////////////////////
// MAIN FUNCTION //////////////////////////////////////////////////////////////
int main(int argc, char *argv[]) {
  // Arguments: 
  // FileName : Filename where the temporary file is saved
  // DSamplingRate : Sampling rate of the digital acquisition
  // SamplesPerIteration : Number of Samples Per Iteration
  // MaxIterations : Maximal Iterations to Acquire
  // DeviceName : Name of the digital NI-DAQ device
  // ChannelNumber : Digital channel to acquire
  // TriggerChannel : Digital channel to receive the trigger from
  // NumberOfChannels : Number of analog channels to decode
  // BitLength : Bit Length of the headstage
  // SimulationMode : Whether to acquire the data or generate it for testing
  
  char FileName[100], DeviceName[2], TriggerChannel[5]; 
  int DSamplingRate = 0, ASamplesPerIteration = 0, MaxIterations = 0;
  int ChannelNumber = 0 , NumberOfChannels = 0, BitLength = 0, SimulationMode = 0;
  
  // CHECK NUMBER OF ARGUMENTS
  if (DEBUG) printf("Starting hsdio_stream_dual.\n");
  if (argc != 11) { printf("Ten input arguments required (%d provided).\n",argc-1); return 0; };
  
  // ASSIGN INPUT ARGUMENTS TO LOCAL VARIABLES
  strcpy(FileName, argv[1]); if (DEBUG) printf("Root Filename : %s \n",FileName);
  sscanf(argv[2], "%d", &DSamplingRate);  if (DEBUG) printf("Digital Sampling Rate : %d \n", DSamplingRate);
  sscanf(argv[3],"%d",&ASamplesPerIteration); if (DEBUG) printf("Analog Samples Per Iteration : %d \n",ASamplesPerIteration);
  sscanf(argv[4],"%d",&MaxIterations);  if (DEBUG) printf("Maximal Number of Iterations : %d \n",MaxIterations);
  strcpy(DeviceName, argv[5]); if (DEBUG) printf("DeviceName : %s \n",DeviceName);
  sscanf(argv[6],"%d",&ChannelNumber); if (DEBUG) printf("Digital Channel Number : %d \n",ChannelNumber);
  strcpy(TriggerChannel,argv[7]); if (DEBUG) printf("Triggerchannel : %s \n",TriggerChannel);
  sscanf(argv[8],"%d",&NumberOfChannels); if (DEBUG) printf("Number of Analog Channels : %d \n",NumberOfChannels);
  sscanf(argv[9],"%d",&BitLength); if (DEBUG) printf("Resolution of Headstage in Bits : %d \n",BitLength);
  sscanf(argv[10],"%d",&SimulationMode); if (DEBUG) printf("Simulation Mode : %d \n",SimulationMode);
  
  // CALL DATA COLLECTION /GENERATION FUNCTIONS
  if (SimulationMode==0) {// ACQUIRE READ DATA
    acquireData(FileName,(ViUInt32)  NumberOfChannels, DSamplingRate, (ViUInt32) MaxIterations, ASamplesPerIteration, 
            DeviceName, ChannelNumber, TriggerChannel, (ViUInt32) BitLength);
  }
  else {// GENERATE SURROGATE DATA
    if (DEBUG) printf("Entering Data Creation Function...\n");
    createData( FileName, NumberOfChannels, DSamplingRate, MaxIterations,ASamplesPerIteration);
  }
  return 1;
}
