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
#define DEBUG2 0
#define DEBUG3 0
#define ANALOGSAMPLESPERLOOP 19200000

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
        ViUInt32 *DSamplesPerChannelHW,
        ViConstString AcqTriggerTerminal,
        ViInt32 StartTriggerEdge, 
        ViSession *genViPtr);

void decodeData(
      ViUInt8 *DData,
        ViUInt16 *AData,
        ViUInt32 DBufferPos,
        ViUInt32 *DBufferDecoded,
        ViUInt64 *DDecodedPosTotal,
        ViUInt32 *DSamplesShift,
        ViUInt32 *ASamplesRead, 
        ViUInt32 BitLength, 
        ViUInt32 PacketLength, 
        ViUInt32 LoopIteration,
        ViUInt32 *TriggerCount, 
        ViUInt64 *TriggerSamples,
        ViUInt64 *TriggerValues
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

int writeStatusFile(char *FileNameStatus, long ABufferPos, long ALoopCount, ViUInt64 ASamplesWrittenTotal);

int checkStopFile(char *FileNameStop);


///////////////////////////////////////////////////////////////////////////////////////////
int createData(
        char* FileName,
        int NumberOfChannels,
        int DSamplingRate, 
        int MaxIterations, 
        int ASamplesPerIteration) {

  FILE *DataFile, *StopFile, *StatusFile, *TriggersFile;
  short *AData;
  int *StopBit;
  long ABufferPosBytes[2];
  long ASamplesTotal = 0, ASamplesWritten= 0, ASamplesWrittenTotal =0 , AHeadSamples =0 , ASamplesRead = 0, ATailSamples = 0;
  long ATailWritten = 0, AHeadWritten = 0, AOffset = 0,  ABufferPos = 0, CurrentPosition = 0,  Done = 0, kk, iTotal=0, i,j,LoopIteration, ALoopCount =0;
  long TrigCount = 0, LowTrigCount = 1, HighTrigCount = 0, TrigSpacing = 50000;
  double TimePerIteration, Elapsed = 0, ASamplingRate;
  clock_t Clock1, Clock2;
  double Time1, Time2;
  long cStep = 0;
  char FileNameStatus[1000], FileNameBuffer[1000], FileNameTriggers[1000], FileNameStop[1000];
  
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

  for (LoopIteration=0;LoopIteration<MaxIterations;LoopIteration++) {
    // KILL SOME TIME IN ORDER TO PRODUCE DATA IN NEAR REALTIME
    if (DEBUG) printf("%d %2.2f ",LoopIteration,TimePerIteration);
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
        AData[i*NumberOfChannels+j] = (short) (10000*sin(2*3.14159*5.123*(i+iTotal)/ASamplingRate));
        // Simulate temporally stable grid 
        //AData[i*NumberOfChannels+j] = 0;
        //if (cStep % 1000 == 0) {AData[i*NumberOfChannels+j] = 10000;}
      }
    }
    iTotal = iTotal + ASamplesRead;
  
    // WRITE ANALOG DATA TO DISK (FOR ONLINE READING, BIG CIRCULAR BUFFER)
    if (ABufferPos+ASamplesTotal > ANALOGSAMPLESPERLOOP) {
      ATailSamples=(ANALOGSAMPLESPERLOOP-ABufferPos)/NumberOfChannels;
      AHeadSamples=ASamplesRead-ATailSamples;
    } else {
      ATailSamples=ASamplesRead; AHeadSamples=0;
    }
      
    if (DEBUG) printf("\tAcquired:\t\t%d Tail + %d Head = %d Read\n", ATailSamples, AHeadSamples, ASamplesRead);
    
    // WRITE TAIL
    if (ATailSamples>0) {
      ATailWritten = fwrite(AData, sizeof(short), (size_t) (ATailSamples*NumberOfChannels), DataFile);
      //if (DEBUG) printf("\tTailSamples  %d %d %d %d %d\n", ATailSamples,ATailWritten,NumberOfChannels,sizeof(short),sizeof(AData));
      if (ATailWritten != ATailSamples*NumberOfChannels) { printf("Tail samples could not be written!\n"); return -1;}
    } else {
      ATailWritten = 0;
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
      ABufferPos=AHeadWritten;
    } else {
      AHeadWritten=0;
      ABufferPos+=ATailWritten;
    }
    
    ASamplesWritten = ATailWritten + AHeadWritten;
    ASamplesWrittenTotal = ASamplesWrittenTotal + ASamplesWritten;
    fflush(DataFile);
    CurrentPosition=ftell(DataFile);
    
    if (DEBUG) printf("\tWritten:\t\t%d Tail+%d Head = %d Read\n", ATailWritten, AHeadWritten, ASamplesWritten);
    if (DEBUG) printf("\tWritten (Total):\t%d This Loop | %d All Loops \n", ABufferPos, ASamplesWrittenTotal);
    if (DEBUG) printf("\tFile pos :\t\t%d LoopCount: %d\n", CurrentPosition,ALoopCount);
  
    // OPEN TRIGGERS FILE & WRITE TRIGGERS
    if (LoopIteration==0) TriggersFile = fopen(FileNameTriggers, "w");
    else  TriggersFile = fopen(FileNameTriggers, "a");
    if (TriggersFile == NULL) { printf("TriggersFile could not be opened!\n"); return -1;}
    
    // WRITE DOWN TRIGGERS
    if (iTotal >= LowTrigCount*TrigSpacing-2000) {
      TrigCount++;
      fprintf(TriggersFile,"%d %d %d\n",TrigCount,(int) LowTrigCount*TrigSpacing-2000,0);
      LowTrigCount ++; 
    }

    // WRITE UP TRIGGERS
    if (iTotal >= HighTrigCount*TrigSpacing+1000) {
      TrigCount++;
      fprintf(TriggersFile,"%d %d %d\n",TrigCount,(int) HighTrigCount*TrigSpacing+1000,1);
      HighTrigCount ++;
    }
 
    fclose(TriggersFile);

    // WRITE STATUS FILE
    writeStatusFile(FileNameStatus, ABufferPos,ALoopCount,(ViUInt64) ASamplesWrittenTotal);
    
    // CHECK WHETHER TO STOP RECORDING
     if ( checkStopFile(FileNameStop) ) break;
  }
  fclose(DataFile);
  fclose(TriggersFile);
  return 1;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
int acquireData(
        char* FileName, 
        ViUInt32 NumberOfChannels, 
        int DSamplingRate, 
        ViUInt32 MaxIterations, 
        int ASamplesPerIteration,
        char* DeviceName, 
        int ChannelNumber, 
        char* TriggerChannel, 
        ViUInt32 BitLength) {
  
  // TRANSFER ARGUMENTS TO NI VARIABLES 
  ViRsrc deviceID = (ViRsrc) DeviceName;
  ViReal64 SampleClockRate = (ViReal64) DSamplingRate;
  
  // DATA MATRICES
  ViUInt16 *AData;
  ViUInt8 *DData;
    
  // ACQUISITION PARAMETERS
  ViConstString acqChannelList = "0,2"; // Acquisition and Trigger Channel
  ViSession vi = VI_NULL;
  ViUInt32 ReadTimeout = 1500; // Milliseconds : this corresponds to 2x the maximal bufferduration at 50MHz

  // GENERATION PARAMETERS
  ViConstString genChannelList = "1,3";
  ViSession genVi = VI_NULL;
  ViConstString GenTriggerTerminal = (ViConstString) TriggerChannel; // Generation triggered by external trigger, sends trigger to Acquisition trigger
  ViConstString AcqTriggerTerminal = NIHSDIO_VAL_PFI0_STR; // Acquisition trigger received by Generation device, otherwise timing not reliable.
  ViInt32 StartTriggerEdge =  NIHSDIO_VAL_RISING_EDGE; // Mysteriously, one needs to connect the trigger inverted between GND and +. Probably better in a closed circuit/with a switch
  ViConstString sampleClockOutputTerminal = NIHSDIO_VAL_DDC_CLK_OUT_STR; // MAYBE THIS IS THE PLACE WHERE THE ACQUIRED SAMPLES ARE SHOWN?? See setupGenerationDevice
  ViUInt16 *waveformData; /* data type of waveformData needs to change if data width is not 2 bytes. */
  ViConstString waveformName = "ClockSignal";

  // DATA MANAGEMENT PARAMETERS (DIGITAL  & ANALOG)
  ViUInt32 DataWidth = 1, i,j, AOffset, DOffset, PacketLength, HeaderLength, DataStart, NPackets, OutputLength, DSamplesPerIteration, DSamplesPerChannelHW = 0, LoopIteration = 0; 
  ViUInt32 ASamplesRead = 0, ASamplesWritten = 0 , ABufferPos =0, ASamplesBuffer=0;
  ViUInt32 DSamplesRead = 0, DSamplesWritten = 0, BackLogSamples =0, DSamplesShift = 0, DBufferPos = 0, DBufferDecoded = 0, DSamplesBuffer=0;
  ViUInt64 DSamplesReadTotal = 0, DDecodedPosTotal = 0, DSamplesWrittenTotal = 0, ASamplesReadTotal = 0, ASamplesWrittenTotal = 0;
  ViUInt16 ConstLevel = 2;

  // CIRCULAR ANALOG BUFFER
  ViUInt32 ASamplesWrittenThisLoop=0, ALoopCount=0;
  ViUInt32 ATailSamples=0, ATailWritten=0, AHeadSamples=0, AHeadWritten=0;
  
  // TRIGGER MATRICES & VARIABLES
  ViUInt64 *TriggerSamples, *TriggerValues;
  ViUInt32 TriggerCount=0, TriggersWritten = 0;
  long TrigSample = 0, TrigValue =0, MaxTriggers = 1000000;  
  
  int WriteDigital=0, WriteAnalog=1;
  int *StopBit;
  ViUInt16 Header[] = {0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,1};
  ViInt32 BitsPerBundle = 3*BitLength, FlagLength = 8, TBDLength = 0;
  
  // FILENAMES
  char FileNameBuffer[1000], FileNameD[1000], FileNameStop[1000], FileNameStatus[1000], FileNameTriggers[1000], TriggersStatus[1000];
  FILE *DataFile, *DataFileD, *StopFile, *StatusFile, *TriggersFile;
  
  /* ERROR VARIABLES */
  ViChar errDesc[1024];
  ViStatus error = VI_SUCCESS;
  
  //----------------------------------------------------------------------------------------------------//
  
  // PARSE OPTIONS FOR DIFFERENT BITS
  if (BitLength==12) PacketLength = 1200;
  if (BitLength==16) PacketLength = 1600;
  
     // OVERALL SAMPLES/TIME
  DSamplesPerIteration = (ViUInt32) (ASamplesPerIteration*PacketLength);
  
  // GENERATION CODE
  // CREATES SOME (10 PACKETS) FOR TESTING ACQUISITION (LONGTERM TEST)
  NPackets = 32;
  OutputLength = NPackets*PacketLength;
  waveformData = (ViUInt16*) malloc(OutputLength*sizeof(ViUInt16));
  HeaderLength = 16;
  for (i = 0; i < OutputLength; i++)  waveformData[i] = ConstLevel*(i % 2);
  for (i=0;i<PacketLength;i++) printf("%d",waveformData[i]);
  printf("\n");
  for (j = 0; j < NPackets; j++) { // Loop over packets
    for (i = 0; i < HeaderLength; i++) {
      if (Header[i]==1) waveformData[i+j*PacketLength] = waveformData[i+j*PacketLength] + (ViUInt16) 8;
    }
    DataStart = j*PacketLength + HeaderLength + FlagLength + TBDLength;
    for (i = 0; i < 3 ; i++) { // Change only 3 Channels
      waveformData[DataStart + i + j*3] = waveformData[DataStart  + i + j*3] + 8;
    }
  }  
  for (i=0;i<PacketLength;i++) printf("%d ",waveformData[i]);
  
  if (DEBUG) printf("Sizeof Waveform : %d\n",sizeof(waveformData));
  /* Initialize, configure, and write waveforms to generation device */
  checkErr(setupGenerationDevice (deviceID, genChannelList, sampleClockOutputTerminal,
          SampleClockRate, AcqTriggerTerminal, GenTriggerTerminal, StartTriggerEdge, 
          waveformData, waveformName,OutputLength, &genVi));  
  /* Commit settings to start sample clock, run before initiate the acquisition */
  checkErr(niHSDIO_CommitDynamic(genVi));
  
  // ACQUISITION CODE
  checkErr(setupAcquisitionDevice(deviceID, acqChannelList, NIHSDIO_VAL_ON_BOARD_CLOCK_STR,
          SampleClockRate,  DSamplesPerIteration, &DSamplesPerChannelHW,  AcqTriggerTerminal , StartTriggerEdge, &vi));
  /* Query Data Width */
  checkErr(niHSDIO_GetAttributeViInt32(vi, VI_NULL, NIHSDIO_ATTR_DATA_WIDTH, &DataWidth));
  /* Configure Fetch */
  checkErr(niHSDIO_SetAttributeViInt32 (vi, "",NIHSDIO_ATTR_FETCH_RELATIVE_TO, NIHSDIO_VAL_FIRST_SAMPLE));
  checkErr(niHSDIO_Initiate(genVi));
  checkErr(niHSDIO_SetAttributeViInt32 (vi, "",NIHSDIO_ATTR_FETCH_RELATIVE_TO,NIHSDIO_VAL_CURRENT_READ_POSITION));
  
    // GET DIGITAL DATA MATRIX
  DSamplesBuffer = (ViUInt32) (2*DSamplesPerChannelHW);
  if (DEBUG) printf("Allocating Digital Buffer: %d bits \n",DSamplesBuffer);
  DData = (char*)malloc(DSamplesBuffer*sizeof(char));
  // GET ANALOG DATA MATRIX
  ASamplesBuffer = ceil(DSamplesBuffer/PacketLength*NumberOfChannels);
  if (DEBUG) printf("Allocating Analog Buffer: %d samples \n",ASamplesBuffer);
  AData = (ViUInt16*)malloc(ASamplesBuffer*sizeof(ViUInt16));
  TriggerSamples = (ViUInt64*)malloc(MaxTriggers*sizeof(ViUInt64));
  TriggerValues = (ViUInt64*)malloc(MaxTriggers*sizeof(ViUInt64));
  StopBit = (int*) calloc(1,sizeof(int));
  
   // PREPARE STATUS FILE
  strcpy(FileNameStatus,FileName);
  strcat(FileNameStatus,".status");
  if (DEBUG) printf("Status File Name: %s\n",FileNameStatus);
  
  // PREPARE TRIGGER FILE
  strcpy(FileNameTriggers,FileName);
  strcat(FileNameTriggers,".triggers");
  printf("Triggers File Name: %s\n",FileNameTriggers);
  
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
  
   // PREPARE ANALOG DATA FILE (do this last to insure proper handshaking with MANTA)
  if (WriteAnalog) {
    strcpy(FileNameBuffer,FileName);
    strcat(FileNameBuffer,".bin");
    DataFile = fopen(FileNameBuffer, "wb+");
    if (DataFile == NULL) { printf("Targetfile for analog data could not be opened!\n"); return -1; }
  }
  
  // START ACQUISITION //////////////////////////////////////////////////////////////////////////////////////
  for (LoopIteration=0; LoopIteration<MaxIterations; LoopIteration++)  {
    printf(">> Starting loop %d / %d\n",LoopIteration+1,MaxIterations);
    // CONFIGURE FETCH
    checkErr(niHSDIO_SetAttributeViInt32 (vi, "",NIHSDIO_ATTR_FETCH_OFFSET, 0));

    // CHECK REMAINING SAMPLES
    BackLogSamples = 0;
    while (BackLogSamples<DSamplesPerIteration) {
      //sleep(10); // wait for 10 ms between retries
      checkErr(niHSDIO_GetAttributeViInt32 (vi, "",NIHSDIO_ATTR_FETCH_BACKLOG, &BackLogSamples));
    }
    if (DEBUG) printf("\tDSamples available on Card \t\t%d\n",BackLogSamples);      
 
    // ACQUIRE DIGITAL DATA FROM DEVICE
    checkErr(niHSDIO_FetchWaveformU8(vi, BackLogSamples, ReadTimeout, &DSamplesRead, &(DData[DBufferPos])));
    DBufferPos = DBufferPos + DSamplesRead;
    DSamplesReadTotal = DSamplesReadTotal + (ViUInt64) DSamplesRead;
    if (DEBUG) printf("\tDSamples read : \t %d (now) %llu (tot)\n",DSamplesRead,DSamplesReadTotal);
      
    // WRITE DIGITAL DATA
    if (WriteDigital) {
        DOffset=(DBufferPos-DSamplesRead);
        DSamplesWritten = fwrite(&(DData[DOffset]), sizeof(char), (size_t) (DSamplesRead), DataFileD);
        DSamplesWrittenTotal = DSamplesWrittenTotal +  (ViUInt64) DSamplesWritten;
        if (DSamplesWritten != DSamplesRead) { printf("Samples could not be written!\n"); return -1;}
        if (DEBUG) printf("\tDigital Samples written : \t %d (now) %llu (tot)\n",DSamplesWritten,DSamplesWrittenTotal);
    }
    
    if (WriteAnalog) {
      // DECODE ANALOG DATA FROM DIGITAL DATA 
      decodeData(DData, AData, 
              DBufferPos,
              &DBufferDecoded, 
              &DDecodedPosTotal, 
              &DSamplesShift, 
              &ASamplesRead, 
              BitLength, 
              PacketLength, 
              LoopIteration,
              &TriggerCount,
              TriggerSamples,
              TriggerValues);
      ASamplesReadTotal = ASamplesReadTotal + (ViUInt64) ASamplesRead;
      if (DEBUG) printf("\tASamples converted : \t %d (now)  %llu (tot)\n", ASamplesRead, ASamplesReadTotal);      
     
      // WRITE ANALOG DATA TO DISK (FOR ONLINE READING, BIG CIRCULAR BUFFER)
      if (ABufferPos+ASamplesRead <= ANALOGSAMPLESPERLOOP) {
        ATailSamples=ASamplesRead; AHeadSamples=0;
      } else {
        ATailSamples = (ANALOGSAMPLESPERLOOP-ABufferPos);
        AHeadSamples = ASamplesRead-ATailSamples;
      }
      
      if (DEBUG) printf("\tASamples to write : \t %d (now)  %llu (tot)  %d (tail)  %d (head)  %d (pos)\n",
              ASamplesRead,ASamplesReadTotal,ATailSamples,AHeadSamples,ABufferPos);
      
      // WRITE TAIL
      if (ATailSamples>0) {
        ATailWritten = fwrite(AData, sizeof(short), (size_t) (ATailSamples), DataFile);
        if (ATailWritten != ATailSamples) { printf("Tail samples could not be written!\n"); return -1;}
        //if (DEBUG) printf("\tTailSamples  %d %d %d %d %d\n", ATailSamples,ATailWritten,NumberOfChannels,sizeof(short),sizeof(AData));
      } else {
        ATailWritten = 0;
      }
      
      // WRITE HEAD
      if (AHeadSamples>0) { ALoopCount++;
        if (DEBUG) printf("\tStarting output loop %d\n", ALoopCount);
        AOffset=ATailSamples;
        fseek(DataFile,0,SEEK_SET);
        AHeadWritten = fwrite(&(AData[AOffset]), sizeof(short), (size_t) (AHeadSamples), DataFile);
        if (AHeadWritten != AHeadSamples) { printf("Head samples could not be written!\n"); return -1;}
        //if (DEBUG) printf("\tHeadSamples  %d %d %d %d %d\n", AHeadSamples,AHeadWritten,NumberOfChannels,sizeof(short),sizeof(AData));
        ABufferPos=AHeadWritten;
      } else {
        AHeadWritten=0; ABufferPos+=ATailWritten;
      }
      fflush(DataFile);
      
      ASamplesWritten = ATailWritten + AHeadWritten;
      ASamplesWrittenTotal = ASamplesWrittenTotal + (ViUInt64) ASamplesWritten;
      
      if (DEBUG) printf("\tASamples written : \t %d (now)  %llu (tot)  %d (tail)  %d (head)\n", 
              ASamplesWritten,ASamplesWrittenTotal,ATailWritten,AHeadWritten);
      
       // OPEN TRIGGERS FILE
      if (LoopIteration==0) TriggersFile = fopen(FileNameTriggers, "w");
      else  TriggersFile = fopen(FileNameTriggers, "a");
      if (TriggersFile == NULL) { printf("TriggersFile could not be opened!\n"); return -1;}
      
      // WRITE TRIGGERS
      while (TriggersWritten < TriggerCount) { TriggersWritten++;
        fprintf(TriggersFile,"%i %llu %llu\n",TriggersWritten,TriggerSamples[TriggersWritten],TriggerValues[TriggersWritten]);
      }
      fclose(TriggersFile);
      
      // WRITE STATUS FILE
      writeStatusFile(FileNameStatus, ABufferPos ,ALoopCount,ASamplesWrittenTotal);    
    } // END WRITE ANALOG
        
    // MOVE SAMPLES OF UNFINISHED PACKET FROM THE END OF THE BUFFER BACK TO THE BEGINNING
    // (HENCE DData almost always starts with a header)
    for (i=0;i<DBufferPos-DBufferDecoded;i++) DData[i]=DData[DBufferDecoded + i];
    DBufferPos = DBufferPos-DBufferDecoded;
    
    // CHECK WHETHER TO STOP
    if ( checkStopFile(FileNameStop) ) break;
    
  } // END OF MAIN LOOP /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  niHSDIO_reset(vi);
  
  if (WriteAnalog) fclose(DataFile);
  if (WriteDigital) fclose(DataFileD);
  
  Error:
    if (error == VI_SUCCESS) { /* print result */
      printf("Done without error.\n");
      printf("Number of digital samples read = %llu.\n", DSamplesReadTotal);
      printf("Number of analog samples written = %llu.\n", ASamplesWrittenTotal);
    } else { /* Get error description and print */
      niHSDIO_GetError(vi, &error, sizeof(errDesc)/sizeof(ViChar), errDesc);
      printf("\nError encountered\n===================\n%s\n", errDesc);}
    
    niHSDIO_close(vi); /* close the session */
    return error;
};
  

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void decodeData(
        ViUInt8 *DData,
        ViUInt16 *AData,
        ViUInt32 DBufferPos,
        ViUInt32 *DBufferDecoded,
        ViUInt64 *DDecodedPosTotal,
        ViUInt32 *DSamplesShift,
        ViUInt32 *ASamplesRead, 
        ViUInt32 BitLength, 
        ViUInt32 PacketLength, 
        ViUInt32 LoopIteration,
        ViUInt32 *TriggerCount, 
        ViUInt64 *TriggerSamples,
        ViUInt64 *TriggerValues
        ) {
  
  ViInt32 HeaderFound = 0, HeaderStart = 0, ProcessData = 1;
  ViInt32 NumberOfChannels = 96, Bundles = 32;
  ViInt32 BitsPerBundle = 3*BitLength, FlagLength = 8, TBDLength = 0;
  ViUInt8 Header[] = {0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,1};
  ViInt32 HeaderLength = sizeof(Header)/sizeof(ViUInt8);
  ViInt32 cStart= 0, DataStart = 0, PacketStart =0, DataOffset = 0, AOffset =0, Offset = 0;
  ViInt32 cASamplesRead = 0, i1, i2, i3, EqCount;
  ViInt32 PacketsThisIteration = (ViInt32) (floor(DBufferPos/PacketLength));
  ViInt64 TriggerSample = 0;
          
  // ADDITIONAL HEADER FOR CONTROL INFORMATION?
  if (BitLength==16) TBDLength = 16;
 
  if (DEBUG) printf("\tShift : %d\n",DSamplesShift[0]);
  
  // SCAN FOR TRIGGER (NOTE DOWN TRIGGERS AND REDUCE REPRESENTATION TO HEADSSTAGE CODE)
  if (DEBUG2) printf("\tChecking for Triggers : \n");
  for (i1=0; i1<DBufferPos; i1+=PacketLength) {
    if (TriggerValues[TriggerCount[0]]==0 && DData[i1]>1) {    
      TriggerSample = floor((DDecodedPosTotal[0] + i1 + DSamplesShift[0])/PacketLength);
      if (TriggerSample == 0) { // DO NOT CONSIDER ONE AT BEGINNING A TRIGGER
        TriggerValues[0] = 1;
      } else {
        TriggerCount[0]++;
        TriggerSamples[TriggerCount[0]] = floor((DDecodedPosTotal[0] + i1 + DSamplesShift[0])/PacketLength);
        TriggerValues[TriggerCount[0]] = 1;
        printf("\t\t T%d : UP Trigger (DLocal : %d) (D: %llu, T: %d)\n",TriggerCount[0],i1,DDecodedPosTotal[0] + i1 + DSamplesShift[0],TriggerSamples[TriggerCount[0]]);
        //for (i2=-20;i2<20;i2++) printf("%d ",DData[i1+i2]); printf("\n");
      }
    } else if (TriggerValues[TriggerCount[0]]==1 && DData[i1]<2) {   
      TriggerCount[0]++;
      TriggerSamples[TriggerCount[0]] = floor((DDecodedPosTotal[0] + i1 + DSamplesShift[0])/PacketLength);
      TriggerValues[TriggerCount[0]] = 0;
      printf("\t\t T%d : DN Trigger (DLocal : %d) (D: %llu, T: %d)\n",TriggerCount[0],i1,DDecodedPosTotal[0] + i1 + DSamplesShift[0],TriggerSamples[TriggerCount[0]]);
      //for (i2=-20;i2<20;i2++) printf("%d ",DData[i1+i2]); printf("\n");
    }
  }
  
  // MOVE THE DATA BACK TO BINARY
  for (i1 = 0;  i1<2*PacketLength; i1++) DData[i1] = DData[i1] % 2;

  if (DEBUG2) printf("\tChecking for Header...\n",DDecodedPosTotal[0]);
  
  // DISTANCE FROM THE PACKETSTART TO THE DATA START
  DataOffset = HeaderLength + FlagLength + TBDLength;
  // DETECT FIRST HEADER ( SEARCH FORWARD )
  for (Offset=0; Offset<PacketLength; Offset++) {   
    EqCount = 0;
    for (i2=0; i2<HeaderLength; i2++) { // DUAL HEADER DETECTION
      if ((DData[Offset+i2] == Header[i2]) && (DData[PacketLength+Offset+i2] == Header[i2]))
        EqCount++;
    }
    // MATCH FOUND
    if (EqCount == HeaderLength) {
      PacketStart = Offset; HeaderFound = 1; PacketsThisIteration--; break;
      if (DEBUG) printf("\tInitial Header found at : %d\n",PacketStart);
    }
  }

  if (!HeaderFound) {
    printf("\tInitial Header not found within one PacketLength!!!\n"); 
    for (i1=0;i1<PacketLength;i1++) printf("%d ",DData[i1]);
    printf("\n");
    for (i1=PacketLength;i1<2*PacketLength;i1++) printf("%d ",DData[i1]); 
    printf("\n");
  }
  if (DEBUG2) printf("\tEntering decoder (DSample : %d)...\n",DDecodedPosTotal[0]);
  
  // DECODE PACKAGES
  for (i1 = 0; i1<PacketsThisIteration; i1++) { // LOOP OVER ANALOG PACKETS
    HeaderStart=PacketStart;
    
    // MOVE THE DATA BACK TO BINARY
    for (i2 = PacketStart;  i2<PacketStart+PacketLength; i2++) DData[i2] = DData[i2] % 2;
    
    // CHECK WHETHER PACKET HEADER LOCATED AT EXPECTED LOCATION
    EqCount = 0;
    for (i2=0; i2<HeaderLength; i2++)   EqCount += DData[HeaderStart+i2] == Header[i2];
    
    // IF HEADER NOT FOUND, LOOK FOR HEADER (should happen only rarely)
    if (EqCount != HeaderLength) {
      if (DEBUG2) printf("ASamp: %d DSamp: %d Iteration: %d:  Header not found at offset : %d\n Searching for header ...\n",
              i1,HeaderStart,i1,Offset);
      for (i3=0; i3<PacketLength; i3++) { // SEARCH FOR HEADER WITHIN ONE PACKETLENGTH
        EqCount = 0;
        for (i2=0; i2<HeaderLength; i2++) {
          EqCount += DData[HeaderStart-(PacketLength/2)+i3+i2] == Header[i2];
        }
        // MATCH FOUND
        if (EqCount == HeaderLength) {
          if (DEBUG2) printf("Found a new match, adjusting offset from %d to %d\n",Offset,Offset-(PacketLength/2)+i3);
          Offset = Offset-(PacketLength/2)+i3;
          PacketStart=PacketStart-(PacketLength/2)+i3;
          HeaderFound = 2;
          break;
          DSamplesShift[0] = DSamplesShift[0] - PacketLength+i3;
        }
      }
      if (~HeaderFound && DEBUG3) printf("No Header Found within one packetlength\n");
    }
    
    if (DEBUG3) printf("\tDecoding Packet %d APos %d DPos %d\n",i1,AOffset,cStart);
 
    DataStart = PacketStart + DataOffset;
    switch (BitLength) {
      case 12:
        for (i2 = 0; i2<Bundles ; i2++ ) { // Loop over the Bundles in the data section in a packet
          cStart = DataStart + i2*BitsPerBundle;
          cASamplesRead = i1;
          AOffset = cASamplesRead*NumberOfChannels + i2*3;
          AData[AOffset]     = -2048*DData[cStart]     + 1024*DData[cStart+3] + 512*DData[cStart+6] + 256*DData[cStart+9]   + 128*DData[cStart+12] + 64*DData[cStart+15] + 32*DData[cStart+18] + 16*DData[cStart+21] + 8*DData[cStart+24] + 4*DData[cStart+27] + 2*DData[cStart+30] + 1*DData[cStart+33];
          AData[AOffset+1] = -2048*DData[cStart+1] + 1024*DData[cStart+4] + 512*DData[cStart+7] + 256*DData[cStart+10] + 128*DData[cStart+13] + 64*DData[cStart+16] + 32*DData[cStart+19] + 16*DData[cStart+22] + 8*DData[cStart+25] + 4*DData[cStart+28] + 2*DData[cStart+31] + 1*DData[cStart+34];
          AData[AOffset+2] = -2048*DData[cStart+2] + 1024*DData[cStart+5] + 512*DData[cStart+8] + 256*DData[cStart+11] + 128*DData[cStart+14] + 64*DData[cStart+17] + 32*DData[cStart+20] + 16*DData[cStart+23] + 8*DData[cStart+26] + 4*DData[cStart+29] + 2*DData[cStart+32] + 1*DData[cStart+35];
        };
        break;
      case 16:
        for (i2 = 0; i2<Bundles ; i2++ ) { // Loop over the Bundles in the data section in a packet
          cStart = DataStart + i2*BitsPerBundle;
          cASamplesRead = i1;
          AOffset = cASamplesRead*NumberOfChannels + i2*3;
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
  
  DBufferDecoded[0] = PacketStart;
  
  if (DEBUG) printf("\tLeaving decoder (DSample : %d)...\n",DBufferDecoded[0]);
  
  // CHECK WHETHER FIRST TRIGGER WAS OUTSIDE OF CURRENT SET OF SAMPLES
  if (TriggerSamples[TriggerCount[0]] > DBufferDecoded[0]) TriggerCount--;
  
  DDecodedPosTotal[0] = DDecodedPosTotal[0] +  (ViUInt64) (DBufferDecoded[0]) ;
  ASamplesRead[0]=PacketsThisIteration*NumberOfChannels;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
ViStatus setupGenerationDevice(
        ViRsrc genDeviceID, 
        ViConstString genChannelList, 
        ViConstString sampleClockOutputTerminal,
        ViReal64 SampleClockRate,
        ViConstString AcqTriggerTerminal, 
        ViConstString StartTriggerSource, 
        ViInt32 StartTriggerEdge,
        ViUInt16 *waveformData, 
        ViConstString waveformName, 
        ViUInt32 waveformLength, 
        ViSession *genViPtr)  {
  
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
  
//   if (strcmp((char *)StartTriggerSource, notrigger)) {
//     /* Configure start trigger */
//     if (DEBUG) printf("Trigger is %s.\n",StartTriggerSource);
//     checkErr(niHSDIO_SetAttributeViInt32(vi, "", NIHSDIO_ATTR_DIGITAL_EDGE_START_TRIGGER_TERMINAL_CONFIGURATION, NIHSDIO_VAL_SINGLE_ENDED));
//     checkErr(niHSDIO_ConfigureDigitalEdgeStartTrigger(vi,StartTriggerSource, StartTriggerEdge));
//   } else {
    /* no trigger */
    if (DEBUG) printf("No trigger, starting immediately.\n");
//   }
  /* Write waveform to device |  use different Write function if default data width is not 4 bytes. */
  checkErr(niHSDIO_WriteNamedWaveformU16(vi, waveformName, waveformLength, waveformData));

  Error:  
    *genViPtr = vi;
    return error;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
ViStatus setupAcquisitionDevice (
        ViRsrc acqDeviceID, 
        ViConstString acqChannelList, 
        ViConstString sampleClockSource,
        ViReal64 SampleClockRate,  
        ViUInt32 SamplesPerIteration, 
        ViUInt32 *DSamplesPerChannelHW, 
        ViConstString AcqTriggerTerminal, 
        ViInt32 StartTriggerEdge,
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
  
  DSamplesPerChannelHW[0] = TotalAcqMem*2/DataWidth;
  printf("Total Memory/Channel : %i Mb\n",DSamplesPerChannelHW[0]/(1024^2));
   
  /* Initiate Acquisition */
  checkErr(niHSDIO_Initiate (vi));
  
  Error:
    *acqViPtr = vi;
    return error;   
}

//////////////// WRITE STATUS TO FILE /////////////////////////////////////////////////
int writeStatusFile(char *FileNameStatus, long ABufferPos, long ALoopCount, ViUInt64 ASamplesWrittenTotal) {
  FILE *StatusFile = fopen(FileNameStatus, "w");
  if (StatusFile == NULL) { printf("StatusFile could not be opened!\n"); return -1;}
  if (DEBUG2) printf("\tBytes this loop : %d\n",ABufferPos*2);
  fprintf(StatusFile,"%i %i %llu",ABufferPos*2,ALoopCount,ASamplesWrittenTotal);
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
    if (DEBUG2) printf("No StopFile Found: %s\n",FileNameStop);
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
