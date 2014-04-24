/*=================================================================
 HSDIO Continuous Data Streaming To Disk (Used in Conjunction with MANTA)
 *=================================================================*/
// For Testing without external Starttrigger use: 
//   .\hsdio_stream_cont.exe R:\HSDIO 50000000 1000 1000 200000 D10 0 7 XX 96 16 0 1
// For Testing with external Starttrigger use:
//   .\hsdio_stream_cont.exe R:\HSDIO 50000000 1000 1000 200000 D10 0 7 PFI0 96 16 0 1
// 
// Connection Doctor: 
// If using Simulation Mode, nothing needs to be connected
// If using Non-Simulation Mode, the Trigger Channel needs to be chosen
//  This is the Start Trigger Channel in the arguments:
//  XX : Starts immediately
//  PFI0 : is the typical channel to trigger on
// In the latter case this is the port to connect the trigger from the controller
//
// General Notes: 
//  DIO 0-7 are acquired from (first bank of 8 only, in order to speed up processing)
//   DIO 0-6  for digital acquisition (672 Channels max)
//   DIO 7 should be used for the triggering channel from the controlling signal
//        (in any case it has to be last one out of the set of 0-7)
//  At this point we cannot use DIO 0-15 for acquisition, since the readout from the card is slightly too slow at the highest SR
//
//  DIO 8-15 are used for production
//   DIO 14 as a Clock Signal
//   DIO 15 as a Simulated Data Signal (was used for testing before, fed back to the system itself)         
//
// Note that LVDS and LVPECL can be used for triggering headstages, hence for 2 circuits, no additional circuitry is needed
//
// At this point, the information of the number of analog channels per headstage is not used.
// It would involve remapping the channels inside the streamer rather than in MANTA,
// and then removing part of the data after writing it to disk.


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
int ANALOGSAMPLESPERLOOP;
int VERBOSE;

// DECLARE INITIALLIZATION FUNCTIONS
ViStatus setupGenerationDevice(
        ViRsrc genDeviceID, 
        ViConstString genChannelList, 
        ViConstString sampleClockOutputTerminal,
        ViReal64 sampleClockRate, 
        ViConstString AcqTriggerTerminal, 
        ViConstString StartTriggerChan, 
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
        ViUInt8 *BData,
        ViUInt16 *AData,
        ViUInt32 DBufferPos,
        ViUInt32 *DBufferDecoded,
        ViUInt64 *DDecodedPosTotal,
        ViUInt32 *DSamplesShift,
        ViUInt32 *ASamplesRead, 
        ViUInt32 BitLength, 
        ViUInt32 PacketLength, 
        ViUInt32 LoopIteration,
        ViUInt32 NumberOfChannelsTotal,
        ViUInt32 *NumberOfChannelsByChan,
        ViUInt16 *AcqChannelsI,
        int NAcqChannels,
        ViUInt16 TrigChannelI,
        ViUInt32 *TriggerCount, 
        ViUInt64 *TriggerSamples,
        ViUInt64 *TriggerValues
        );
 
int acquireData(
        char* FileName, 
        ViUInt32 *NumberOfChannelsByChan,
        ViUInt32 NumberOfChannelsTotal,
        int DSamplingRate, 
        ViUInt32 MaxIterations, 
        int ASamplesPerIteration,
        char* DeviceName, 
        char* AcqChannels, 
        char* TrigChannel,
        char* StartTrigChannel,
        ViUInt32 BitLength);

int createData(
        char* FileName,
        ViUInt32 *NumberOfChannelsByChan,
        ViUInt32 NumberOfChannelsTotal,
        int DSamplingRate, 
        int MaxIterations, 
        int SamplesPerIteration);

int writeStatusFile(char *FileNameStatus, long ABufferPos, long ALoopCount, ViUInt64 ASamplesWrittenTotal);

int checkStopFile(char *FileNameStop);


///////////////////////////////////////////////////////////////////////////////////////////
int createData(
        char* FileName,
        ViUInt32 *NumberOfChannelsByChan,
        ViUInt32 NumberOfChannelsTotal,
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
  double TimePerIteration, ASamplingRate;
  clock_t Clock1, Clock2;
  double Elapsed = 0,Time1, Time2;
  long cStep = 0;
  char FileNameStatus[1000], FileNameBuffer[1000], FileNameTriggers[1000], FileNameStop[1000];
  
  
  ASamplingRate = DSamplingRate/1600; // Assuming 16 bits here
  if (VERBOSE>0) printf("Analog Sampling Rate : %f\n",ASamplingRate);
  TimePerIteration = (double) (ASamplesPerIteration/ASamplingRate);
// OPEN FILE FOR WRITING
  strcpy(FileNameBuffer,FileName);
  strcat(FileNameBuffer,".bin");
  if (VERBOSE>0) printf("Buffer File Name: %s\n",FileNameBuffer);
  DataFile = fopen(FileNameBuffer, "wb");
  if (DataFile == NULL) { printf("Targetfile for Data could not be opened!\n"); return -1;}
  
  // PREPARE STATUS FILE
  strcpy(FileNameStatus,FileName);
  strcat(FileNameStatus,".status");
  if (VERBOSE>0) printf("Status File Name: %s\n",FileNameStatus);
  
  // PREPARE TRIGGER FILE
  strcpy(FileNameTriggers,FileName);
  strcat(FileNameTriggers,".triggers");
  if (VERBOSE>0) printf("Triggers File Name: %s\n",FileNameTriggers);
  
  // PREPARE STOP FILE
  strcpy(FileNameStop,FileName);
  strcat(FileNameStop, ".stop");
  if (VERBOSE>0) printf("Stop File Name: %s\n",FileNameStop);
  
// SETUP DATA MATRIX
  ASamplesRead = ASamplesPerIteration;
  ASamplesTotal = (int) (ASamplesRead*NumberOfChannelsTotal);
  if (VERBOSE>0) printf("Analog Samples per Iteration : %d\n", ASamplesTotal);
  AData = (short*)calloc(ASamplesTotal,sizeof(short));
  for (i=0;i<ASamplesTotal;i++) AData[i] = 0; // Initialize to  0
  StopBit = (int*) malloc(sizeof(int));

  for (LoopIteration=0;LoopIteration<MaxIterations;LoopIteration++) {
    // KILL SOME TIME IN ORDER TO PRODUCE DATA IN NEAR REALTIME
    if (VERBOSE>0) printf("%d %2.2f ",LoopIteration,TimePerIteration);
    Elapsed = 0;
    Clock1 = clock();
    if (VERBOSE>0) printf("Clock: %d ",Clock1);
    Time1 = (double)Clock1/ (double)CLOCKS_PER_SEC;
    if (VERBOSE>0) printf("Time1 : %2.2f ",Time1);
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
      for (j=0;j<NumberOfChannelsTotal;j++) {
        // Simulate Continuous 60Hz Noise
        AData[i*NumberOfChannelsTotal+j] = (short) (10000*sin(2*3.14159*5.123*(i+iTotal)/ASamplingRate));
        // Simulate temporally stable grid 
        //AData[i*NumberOfChannels+j] = 0;
        //if (cStep % 1000 == 0) {AData[i*NumberOfChannels+j] = 10000;}
      }
    }
    iTotal = iTotal + ASamplesRead;
  
    // WRITE ANALOG DATA TO DISK (FOR ONLINE READING, BIG CIRCULAR BUFFER)
    
    
    if (ABufferPos+ASamplesTotal > ANALOGSAMPLESPERLOOP) {
      ATailSamples=(ANALOGSAMPLESPERLOOP-ABufferPos)/NumberOfChannelsTotal;
      AHeadSamples=ASamplesRead-ATailSamples;
    } else {
      ATailSamples=ASamplesRead; AHeadSamples=0;
    }
      
    if (VERBOSE>0) printf("\tAcquired:\t\t%d Tail + %d Head = %d Read\n", ATailSamples, AHeadSamples, ASamplesRead);
    
    // WRITE TAIL
    if (ATailSamples>0) {
      ATailWritten = fwrite(AData, sizeof(short), (size_t) (ATailSamples*NumberOfChannelsTotal), DataFile);
      //if (VERBOSE>0) printf("\tTailSamples  %d %d %d %d %d\n", ATailSamples,ATailWritten,NumberOfChannelsTotal,sizeof(short),sizeof(AData));
      if (ATailWritten != ATailSamples*NumberOfChannelsTotal) { printf("Tail samples could not be written!\n"); return -1;}
    } else {
      ATailWritten = 0;
    }
    
    // WRITE HEAD
    if (AHeadSamples>0) {
      AOffset=ATailSamples*NumberOfChannelsTotal;
      fseek(DataFile  , 0 , SEEK_SET );
      AHeadWritten = fwrite(&(AData[AOffset]), sizeof(short), (size_t) (AHeadSamples*NumberOfChannelsTotal), DataFile);
      //if (VERBOSE>0) printf("\tHeadSamples  %d %d %d %d %d\n", AHeadSamples,AHeadWritten,NumberOfChannelsTotal,sizeof(short),sizeof(AData));
      if (AHeadWritten != AHeadSamples*NumberOfChannelsTotal) { printf("Head samples could not be written!\n"); return -1;}
      ALoopCount++;
      if (VERBOSE>0) printf("\tStarting output loop %d\n", ALoopCount);
      ABufferPos=AHeadWritten;
    } else {
      AHeadWritten=0;
      ABufferPos+=ATailWritten;
    }
    
    ASamplesWritten = ATailWritten + AHeadWritten;
    ASamplesWrittenTotal = ASamplesWrittenTotal + ASamplesWritten;
    fflush(DataFile);
    CurrentPosition=ftell(DataFile);
    
    if (VERBOSE>0) printf("\tWritten:\t\t%d Tail+%d Head = %d Read\n", ATailWritten, AHeadWritten, ASamplesWritten);
    if (VERBOSE>0) printf("\tWritten (Total):\t%d This Loop | %d All Loops \n", ABufferPos, ASamplesWrittenTotal);
    if (VERBOSE>0) printf("\tFile pos :\t\t%d LoopCount: %d\n", CurrentPosition,ALoopCount);
  
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
        ViUInt32 *NumberOfChannelsByChan, 
        ViUInt32 NumberOfChannelsTotal, 
        int DSamplingRate, 
        ViUInt32 MaxIterations, 
        int ASamplesPerIteration,
        char* DeviceName, 
        char* AcqChannels, 
        char* TrigChannel, 
        char* StartTrigChannel, 
        ViUInt32 BitLength) {
  
  // TRANSFER ARGUMENTS TO NI VARIABLES 
  ViRsrc deviceID = (ViRsrc) DeviceName;
  ViReal64 SampleClockRate = (ViReal64) DSamplingRate;
  
  // DATA MATRICES
  ViUInt8  *DData; // HOLDS THE DIGITAL DATA
  ViUInt8  *BData; // HOLDS THE INTERMEDIATE BINARY DATA
  ViUInt16 *AData; // HOLDS THE ANALOG (DECODED) DATA
 
  // ACQUISITION PARAMETERS
  ViConstString acqChannelList; // Acquisition & Trigger Channels
  ViUInt16 TrigChannelI= atoi(TrigChannel); 
  ViSession vi = VI_NULL;
  ViUInt32 ReadTimeout = -1; // Milliseconds : this corresponds to 2x the maximal bufferduration at 50MHz
  ViUInt16 AcqChannelsI[16];
  
  // GENERATION PARAMETERS
  ViConstString genChannelList = "14,15"; // GENERATION CHANNELS : First is clock, second is test signal
  ViSession genVi = VI_NULL;
  ViConstString GenTriggerTerminal = (ViConstString) StartTrigChannel; // Generation triggered by external trigger, sends trigger to Acquisition trigger
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
  
  char* Rest;
  char acqChannelChars[100];
  int NAcqChannels = 0;
  
  
  clock_t Clock1, Clock2;
  double Elapsed = 0, WaitTime = 0,Time1, Time2;
  
  //----------------------------------------------------------------------------------------------------//
 
  sprintf(acqChannelChars,"%s,%s",AcqChannels,TrigChannel);
  acqChannelList = (ViConstString) acqChannelChars;
  
  if (VERBOSE>0) printf("Acquisition Channel List : %s\n",(char *) acqChannelList);
  
  // PARSE CHANNELNUMBERS
  Rest = strtok(AcqChannels,",");
  while (Rest != NULL) {
    AcqChannelsI[NAcqChannels] = atoi(Rest);
    Rest = strtok(NULL,",");
    NAcqChannels ++;
  }
  if (VERBOSE>0) printf("\tNumber of Digital Acquisition Channels : \t%d\n",NAcqChannels) ;
    
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
  for (i = 0; i < OutputLength; i++)  waveformData[i] = ConstLevel*(i % 2); // CLOCK
  if (VERBOSE>2) printf("Generation Data Packet :\n");
  if (VERBOSE>2) for (i=0;i<PacketLength;i++) printf("%d",waveformData[i]);
  if (VERBOSE>2) printf("\n");
  for (j = 0; j < NPackets; j++) { // Loop over packets
    for (i = 0; i < HeaderLength; i++) {
      if (Header[i]==1) waveformData[i+j*PacketLength] = waveformData[i+j*PacketLength] + (ViUInt16) 8;
    }
    DataStart = j*PacketLength + HeaderLength + FlagLength + TBDLength;
    for (i = 0; i < 3 ; i++) { // Change only 3 Channels
      waveformData[DataStart + i + j*3] = waveformData[DataStart  + i + j*3] + 8;
    }
  }  
  if (VERBOSE>2) {
    for (i=0;i<PacketLength;i++) printf("%d ",waveformData[i]);
  }
  
  if (VERBOSE>0) printf("\tSize of generated Waveform : \t\t\t%d\n",sizeof(waveformData));
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
  if (VERBOSE>0) printf("\tAllocating Digital Buffer: \t\t\t%d bits \n",DSamplesBuffer);
  DData = (ViUInt8*) malloc(DSamplesBuffer*sizeof(ViUInt8));
  // GET BINARY DATA MATRIX
  BData = (ViUInt8*) malloc(DSamplesBuffer*sizeof(ViUInt8));
  // GET ANALOG DATA MATRIX
  ASamplesBuffer = ceil(DSamplesBuffer/PacketLength*NumberOfChannelsTotal);
  if (VERBOSE>0) printf("\tAllocating Analog Buffer: \t\t\t%d samples \n",ASamplesBuffer);
  AData = (ViUInt16*)malloc(ASamplesBuffer*sizeof(ViUInt16));
  TriggerSamples = (ViUInt64*)malloc(MaxTriggers*sizeof(ViUInt64));
  TriggerValues = (ViUInt64*)malloc(MaxTriggers*sizeof(ViUInt64));
  StopBit = (int*) calloc(1,sizeof(int));
  
  
  if (VERBOSE>0) printf("\tDigital Samples/Iteration : \t\t\t%d\n",DSamplesPerIteration);
  
   // PREPARE STATUS FILE
  if (VERBOSE>0) printf("\nPreparing Files : \n\n");
  
  strcpy(FileNameStatus,FileName);
  strcat(FileNameStatus,".status");
  if (VERBOSE>0) printf("\tStatus File Name: %s\n",FileNameStatus);
  
  // PREPARE TRIGGER FILE
  strcpy(FileNameTriggers,FileName);
  strcat(FileNameTriggers,".triggers");
  if (VERBOSE>0) printf("\tTriggers File Name: %s\n",FileNameTriggers);
  
  // PREPARE STOP FILE
  strcpy(FileNameStop,FileName);
  strcat(FileNameStop, ".stop");
  if (VERBOSE>0) printf("\tStop File Name: %s\n",FileNameStop);

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
    // GET STARTING TIME OF ITERATION
    Elapsed = 0; Clock1 = clock(); Time1 = (double)Clock1/ (double)CLOCKS_PER_SEC;
    
    printf("\n>> Starting loop %d / %d\n",LoopIteration+1,MaxIterations);
    // CONFIGURE FETCH
    checkErr(niHSDIO_SetAttributeViInt32 (vi, "",NIHSDIO_ATTR_FETCH_OFFSET, 0));

    if (VERBOSE>1) {
      Clock2= clock(); Time2 = (double)Clock2/(double)CLOCKS_PER_SEC; Elapsed = Time2 - Time1;
      printf("\n\tTime after Set Attribute: %f s\n",Elapsed);
    }
    
    // CHECK REMAINING SAMPLES
    if (LoopIteration==0) printf("\tWaiting for Samples or Trigger ...\n");
    BackLogSamples = 0;
    while (BackLogSamples<DSamplesPerIteration) {
      //sleep(10); // wait for 10 ms between retries
      checkErr(niHSDIO_GetAttributeViInt32 (vi, "",NIHSDIO_ATTR_FETCH_BACKLOG, &BackLogSamples));
    }
    Clock2= clock(); Time2= (double)Clock2/(double)CLOCKS_PER_SEC; WaitTime = Time2 - Time1;
    if (VERBOSE>0) printf("\tWaited for Samples : \t\t\t%f s\n",WaitTime);
    if (VERBOSE>0) printf("\tDSamples available on Card: \t\t%d\n",BackLogSamples);      
 
      
    // ACQUIRE DIGITAL DATA FROM DEVICE
    checkErr(niHSDIO_FetchWaveformU8(vi, BackLogSamples, ReadTimeout, &DSamplesRead, &(DData[DBufferPos])));
    DBufferPos = DBufferPos + DSamplesRead;
    DSamplesReadTotal = DSamplesReadTotal + (ViUInt64) DSamplesRead;
    if (VERBOSE>0) printf("\tDSamples read : \t %d (now) %llu (tot)\n",DSamplesRead,DSamplesReadTotal);
    
    if (VERBOSE>1) {
      Clock2= clock(); Time2 = (double)Clock2/(double)CLOCKS_PER_SEC; Elapsed = Time2 - Time1;
      printf("\n\tTime after Fetch: %f s\n",Elapsed);
    }
    
    // WRITE DIGITAL DATA
    if (WriteDigital) {
        DOffset=(DBufferPos-DSamplesRead);
        DSamplesWritten = fwrite(&(DData[DOffset]), sizeof(ViUInt8), (size_t) (DSamplesRead), DataFileD);
        DSamplesWrittenTotal = DSamplesWrittenTotal +  (ViUInt64) DSamplesWritten;
        if (DSamplesWritten != DSamplesRead) { printf("Samples could not be written!\n"); return -1;}
        if (VERBOSE>0) printf("\tDigital Samples written : \t %d (now) %llu (tot)\n",DSamplesWritten,DSamplesWrittenTotal);
    }
    
    if (VERBOSE>1) {
      Clock2= clock(); Time2= (double)Clock2/(double)CLOCKS_PER_SEC; Elapsed = Time2 - Time1;
      printf("\n\tTime after Digital Write: %f s\n",Elapsed);
    }
    
    if (WriteAnalog) {
      // DECODE ANALOG DATA FROM DIGITAL DATA
      decodeData(DData, 
              BData, 
              AData, 
              DBufferPos,
              &DBufferDecoded, 
              &DDecodedPosTotal, 
              &DSamplesShift, 
              &ASamplesRead, 
              BitLength, 
              PacketLength, 
              LoopIteration,
              NumberOfChannelsTotal,
              NumberOfChannelsByChan,
              AcqChannelsI,
              NAcqChannels,
              TrigChannelI,
              &TriggerCount,
              TriggerSamples,
              TriggerValues);
      
      if (VERBOSE>1) {
        Clock2= clock(); Time2= (double)Clock2/(double)CLOCKS_PER_SEC; Elapsed = Time2 - Time1;
        printf("\n\tTime after Decoding: %f s\n",Elapsed);
      }
      
      ASamplesReadTotal = ASamplesReadTotal + (ViUInt64) ASamplesRead;
      if (VERBOSE>0) printf("\tASamples converted : \t %d (now)  %llu (tot)\n", ASamplesRead, ASamplesReadTotal);      
     
      // WRITE ANALOG DATA TO DISK (FOR ONLINE READING, BIG CIRCULAR BUFFER)
      if (ABufferPos+ASamplesRead <= ANALOGSAMPLESPERLOOP) {
        ATailSamples=ASamplesRead; AHeadSamples=0;
      } else {
        ATailSamples = (ANALOGSAMPLESPERLOOP-ABufferPos);
        AHeadSamples = ASamplesRead-ATailSamples;
      }
      
      if (VERBOSE>0) printf("\tASamples to write : \t %d (now)  %llu (tot)  %d (tail)  %d (head)  %d (pos)\n",
              ASamplesRead,ASamplesReadTotal,ATailSamples,AHeadSamples,ABufferPos);
      
      // WRITE TAIL
      if (ATailSamples>0) {
        ATailWritten = fwrite(AData, sizeof(short), (size_t) (ATailSamples), DataFile);
        if (ATailWritten != ATailSamples) { printf("Tail samples could not be written!\n"); return -1;}
        //if (VERBOSE>0) printf("\tTailSamples  %d %d %d %d %d\n", ATailSamples,ATailWritten,NumberOfChannelsTotal,sizeof(short),sizeof(AData));
      } else {
        ATailWritten = 0;
      }
      
      // WRITE HEAD
      if (AHeadSamples>0) { ALoopCount++;
        if (VERBOSE>0) printf("\tStarting output loop %d\n", ALoopCount);
        AOffset=ATailSamples;
        fseek(DataFile,0,SEEK_SET);
        AHeadWritten = fwrite(&(AData[AOffset]), sizeof(short), (size_t) (AHeadSamples), DataFile);
        if (AHeadWritten != AHeadSamples) { printf("Head samples could not be written!\n"); return -1;}
        //if (VERBOSE>0) printf("\tHeadSamples  %d %d %d %d %d\n", AHeadSamples,AHeadWritten,NumberOfChannelsTotal,sizeof(short),sizeof(AData));
        ABufferPos=AHeadWritten;
      } else {
        AHeadWritten=0; ABufferPos+=ATailWritten;
      }
      fflush(DataFile);

      Clock2= clock(); Time2= (double)Clock2/(double)CLOCKS_PER_SEC; Elapsed = Time2 - Time1;
      if (VERBOSE>1) printf("\n\tTime after Analog Write: %f s\n",Elapsed);
      
      ASamplesWritten = ATailWritten + AHeadWritten;
      ASamplesWrittenTotal = ASamplesWrittenTotal + (ViUInt64) ASamplesWritten;
      
      if (VERBOSE>0) printf("\tASamples written : \t %d (now)  %llu (tot)  %d (tail)  %d (head)\n", 
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
      writeStatusFile(FileNameStatus,ABufferPos,ALoopCount,ASamplesWrittenTotal);    
    } // END WRITE ANALOG  
    
     // MOVE SAMPLES OF UNFINISHED PACKET FROM THE END OF THE BUFFER BACK TO THE BEGINNING
    // (HENCE DData almost always starts with a header)
    for (i=0; i < DBufferPos-DBufferDecoded; i++) DData[i] = DData[DBufferDecoded + i];
    DBufferPos = DBufferPos - DBufferDecoded;
    
    // CHECK WHETHER TO STOP
    if ( checkStopFile(FileNameStop) ) {printf("STOP-file indicates to stop."); break;}

    Clock2= clock(); Time2= (double)Clock2/(double)CLOCKS_PER_SEC; Elapsed = Time2 - Time1;
    if (VERBOSE>1) printf("\n\tTime after Loop: %f s\n",Elapsed);
    printf("\tCycle Load: %3.1f %%\n",100*(Elapsed-WaitTime)/(((double) DSamplesRead)/((double) DSamplingRate)));
    printf("\tMemory Load: %3.1f %%\n",100*((double) DSamplesRead)/((double) DSamplesPerChannelHW));
    
    
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
        ViUInt8 *BData,
        ViUInt16 *AData,
        ViUInt32 DBufferPos,
        ViUInt32 *DBufferDecoded,
        ViUInt64 *DDecodedPosTotal,
        ViUInt32 *DSamplesShift,
        ViUInt32 *ASamplesRead, 
        ViUInt32 BitLength, 
        ViUInt32 PacketLength, 
        ViUInt32 LoopIteration,
        ViUInt32 NumberOfChannelsTotal,
        ViUInt32 *NumberOfChannelsByChan,
        ViUInt16 *AcqChannelsI,
        int NAcqChannels,
        ViUInt16 TrigChannelI,
        ViUInt32 *TriggerCount, 
        ViUInt64 *TriggerSamples,
        ViUInt64 *TriggerValues
        ) {
  
  ViInt32 HeaderFound = 0, HeaderStart = 0, ProcessData = 1, Bundles = 32;
  ViInt32 BitsPerBundle = 3*BitLength, FlagLength = 8, TBDLength = 0;
  ViUInt16 Header[] = {0,0,0,0,0,1,0,1,0,0,0,0,0,1,0,1};
  ViInt32 HeaderLength = sizeof(Header)/sizeof(ViUInt16);
  ViInt32 cStart= 0, DataStart = 0, PacketStart = 0, DataOffset = 0, AOffset = 0, Offset = 0;
  ViInt32 cASamplesRead = 0, i1, i2, i3, EqCount, iAC;
  ViInt32 PacketsThisIteration = (ViInt32) (floor(DBufferPos/PacketLength));
  ViInt64 TriggerSample = 0;
  ViInt32 TriggerLimit = 2^TrigChannelI;
  ViUInt32 NumberOfChannelsDone = 0;
  ViUInt16 cBit = 0;
  unsigned int Mask = 0;        
  
  
  // ADDITIONAL HEADER FOR CONTROL INFORMATION?
  if (BitLength==16) TBDLength = 16;
 
  if (VERBOSE>0) printf("\tShift : %d\n",DSamplesShift[0]);
    
  // SCAN FOR TRIGGER (NOTE DOWN TRIGGERS AND REDUCE REPRESENTATION TO HEADSTAGE CODE)
  // TRIGGERLIMIT IS DETERMINED FROM THE TRIGGER CHANNEL
  if (VERBOSE>2) printf("\tChecking for Triggers : \n");
  for (i1=0; i1<DBufferPos; i1+=PacketLength) {
    if (TriggerValues[TriggerCount[0]]==0 && DData[i1]>=TriggerLimit) { // TRIGGER HIGH
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
    } else if (TriggerValues[TriggerCount[0]]==1 && DData[i1]<TriggerLimit) { // TRIGGER LOW
      TriggerCount[0]++;
      TriggerSamples[TriggerCount[0]] = floor((DDecodedPosTotal[0] + i1 + DSamplesShift[0])/PacketLength);
      TriggerValues[TriggerCount[0]] = 0;
      printf("\t\t T%d : DN Trigger (DLocal : %d) (D: %llu, T: %d)\n",TriggerCount[0],i1,DDecodedPosTotal[0] + i1 + DSamplesShift[0],TriggerSamples[TriggerCount[0]]);
      //for (i2=-20;i2<20;i2++) printf("%d ",DData[i1+i2]); printf("\n");
    }
  }

  if (VERBOSE>0) printf("\tNumber of Acquisition Channels : %d\n",NAcqChannels);
  // LOOP OVER THE DIFFERENT ACQUISITION CHANNELS
  for (iAC = 0; iAC < NAcqChannels; iAC++) {
    if (VERBOSE>0) printf("\tDecoding Acquisition Channel %d\n",AcqChannelsI[iAC]);
    cBit = AcqChannelsI[iAC];
    Mask = 1<<cBit;
    if (VERBOSE>2) printf("cBit = %d, Mask = %d\n",cBit,Mask);
  
    // WITHIN THIS LOOP, A HEADER IS FOUND, WHICH DEFINES THE PACKET START
    // THE COUNT ON THE ANALOG MATRIX INCLUDES THE CHANNELS FROM ALL HEADSTAGES TOGETHER
    
    // EXTRACT THE CURRENT BIT
    for (i1 = 0;  i1<2*PacketLength; i1++) BData[i1] = (DData[i1] & Mask)>>cBit;
    
    if (VERBOSE>2) printf("\tChecking for Header...\n",DDecodedPosTotal[0]);
    
    // DISTANCE FROM THE PACKETSTART TO THE DATA START
    DataOffset = HeaderLength + FlagLength + TBDLength;
    // DETECT FIRST HEADER ( SEARCH FORWARD )
    for (Offset=0; Offset<PacketLength; Offset++) {
      EqCount = 0;
      for (i2=0; i2<HeaderLength; i2++) { // DUAL HEADER DETECTION
        if ((BData[Offset+i2] == Header[i2]) && (BData[PacketLength+Offset+i2] == Header[i2]))
          EqCount++;
      }
      // MATCH FOUND
      if (EqCount == HeaderLength) {
        if (VERBOSE>0) printf("\tInitial Header found at : %d\n",Offset);
        PacketStart = Offset; HeaderFound = 1; PacketsThisIteration--; break; 
      }
      
    }
    
    if (!HeaderFound) {
      printf("\tInitial Header not found within one PacketLength!!!\n Bits 1-1600:\n");
      for (i1=0;i1<PacketLength;i1++) printf("%d ",BData[i1]);
      printf("\n");
    }
    if (VERBOSE>2) printf("\tEntering decoder (DSample : %d)...\n",DDecodedPosTotal[0]);
    
    // DECODE PACKAGES
    for (i1 = 0; i1<PacketsThisIteration; i1++) { // LOOP OVER ANALOG PACKETS
      HeaderStart=PacketStart;
      
      // EXTRACT THE CURRENT BIT
      for (i2 = PacketStart;  i2<PacketStart+PacketLength; i2++) BData[i2] = (DData[i2] & Mask)>>cBit;
      
      // CHECK WHETHER PACKET HEADER LOCATED AT EXPECTED LOCATION
      EqCount = 0;
      for (i2=0; i2<HeaderLength; i2++)   EqCount += BData[HeaderStart+i2] == Header[i2];
      
      // IF HEADER NOT FOUND, LOOK FOR HEADER (should happen only rarely)
      if (EqCount != HeaderLength) {
        if (VERBOSE>2) printf("ASamp: %d DSamp: %d Iteration: %d:  Header not found at offset : %d\n Searching for header ...\n",
                i1,HeaderStart,i1,Offset);
        for (i3=0; i3<PacketLength; i3++) { // SEARCH FOR HEADER WITHIN ONE PACKETLENGTH
          EqCount = 0;
          for (i2=0; i2<HeaderLength; i2++) {
            EqCount += BData[HeaderStart-(PacketLength/2)+i3+i2] == Header[i2];
          }
          // MATCH FOUND
          if (EqCount == HeaderLength) {
            if (VERBOSE>2) printf("Found a new match, adjusting offset from %d to %d\n",Offset,Offset-(PacketLength/2)+i3);
            Offset = Offset-(PacketLength/2)+i3;
            PacketStart=PacketStart-(PacketLength/2)+i3;
            HeaderFound = 2;
            break;
            DSamplesShift[0] = DSamplesShift[0] - PacketLength+i3;
          }
        }
        if (~HeaderFound && VERBOSE>3) printf("No Header Found within one packetlength\n");
      }
      
      if (VERBOSE>3) printf("\tDecoding Packet %d APos %d DPos %d\n",i1,AOffset,cStart);
      
      DataStart = PacketStart + DataOffset;
      switch (BitLength) {
        case 12:
          for (i2 = 0; i2<Bundles ; i2++ ) { // Loop over the Bundles in the data section in a packet
            cStart = DataStart + i2*BitsPerBundle;
            cASamplesRead = i1;
            AOffset = cASamplesRead*NumberOfChannelsTotal + NumberOfChannelsDone + i2*3; // This has to be expanded for multiple headstages
            AData[AOffset]   = -2048*BData[cStart]   + 1024*BData[cStart+3] + 512*BData[cStart+6] + 256*BData[cStart+9]  + 128*BData[cStart+12] + 64*BData[cStart+15] + 32*BData[cStart+18] + 16*BData[cStart+21] + 8*BData[cStart+24] + 4*BData[cStart+27] + 2*BData[cStart+30] + 1*BData[cStart+33];
            AData[AOffset+1] = -2048*BData[cStart+1] + 1024*BData[cStart+4] + 512*BData[cStart+7] + 256*BData[cStart+10] + 128*BData[cStart+13] + 64*BData[cStart+16] + 32*BData[cStart+19] + 16*BData[cStart+22] + 8*BData[cStart+25] + 4*BData[cStart+28] + 2*BData[cStart+31] + 1*BData[cStart+34];
            AData[AOffset+2] = -2048*BData[cStart+2] + 1024*BData[cStart+5] + 512*BData[cStart+8] + 256*BData[cStart+11] + 128*BData[cStart+14] + 64*BData[cStart+17] + 32*BData[cStart+20] + 16*BData[cStart+23] + 8*BData[cStart+26] + 4*BData[cStart+29] + 2*BData[cStart+32] + 1*BData[cStart+35];
          };
          break;
        case 16:
          for (i2 = 0; i2<Bundles ; i2++ ) { // Loop over the Bundles in the data section in a packet
            cStart = DataStart + i2*BitsPerBundle;
            cASamplesRead = i1;
            AOffset = cASamplesRead*NumberOfChannelsTotal + NumberOfChannelsDone + i2*3;
            AData[AOffset]   = 32768*BData[cStart]   + 16384*BData[cStart+3] + 8192*BData[cStart+6] + 4096*BData[cStart+9]  + 2048*BData[cStart+12] + 1024*BData[cStart+15] + 512*BData[cStart+18] + 256*BData[cStart+21] + 128*BData[cStart+24] + 64*BData[cStart+27] + 32*BData[cStart+30] + 16*BData[cStart+33] + 8*BData[cStart+36] + 4*BData[cStart+39] + 2*BData[cStart+42] + 1*BData[cStart+45];
            AData[AOffset+1] = 32768*BData[cStart+1] + 16384*BData[cStart+4] + 8192*BData[cStart+7] + 4096*BData[cStart+10] + 2048*BData[cStart+13] + 1024*BData[cStart+16] + 512*BData[cStart+19] + 256*BData[cStart+22] + 128*BData[cStart+25] + 64*BData[cStart+28] + 32*BData[cStart+31] + 16*BData[cStart+34] + 8*BData[cStart+37] + 4*BData[cStart+40] + 2*BData[cStart+43] + 1*BData[cStart+46];
            AData[AOffset+2] = 32768*BData[cStart+2] + 16384*BData[cStart+5] + 8192*BData[cStart+8] + 4096*BData[cStart+11] + 2048*BData[cStart+14] + 1024*BData[cStart+17] + 512*BData[cStart+20] + 256*BData[cStart+23] + 128*BData[cStart+26] + 64*BData[cStart+29] + 32*BData[cStart+32] + 16*BData[cStart+35] + 8*BData[cStart+38] + 4*BData[cStart+41] + 2*BData[cStart+44] + 1*BData[cStart+47];
          };
          break;
        default:
          printf("Unknown Bitlength specified!"); return;
      }
      PacketStart = PacketStart + PacketLength;
    } // END OF DECODING LOOP
    
    NumberOfChannelsDone = NumberOfChannelsDone + NumberOfChannelsByChan[iAC];
    if (iAC==0) DBufferDecoded[0] = PacketStart; 
  }
  
  if (VERBOSE>0) printf("\tLeaving decoder (DSample : %d)...\n",DBufferDecoded[0]);
  
  // CHECK WHETHER FIRST TRIGGER WAS OUTSIDE OF CURRENT SET OF SAMPLES
  if (TriggerSamples[TriggerCount[0]] > DBufferDecoded[0]) TriggerCount--;
  
  DDecodedPosTotal[0] = DDecodedPosTotal[0] +  (ViUInt64) (DBufferDecoded[0]) ;
  ASamplesRead[0]=PacketsThisIteration*NumberOfChannelsTotal;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
ViStatus setupGenerationDevice(
        ViRsrc genDeviceID, 
        ViConstString genChannelList, 
        ViConstString sampleClockOutputTerminal,
        ViReal64 SampleClockRate,
        ViConstString AcqTriggerTerminal, 
        ViConstString StartTriggerChan, 
        ViInt32 StartTriggerEdge,
        ViUInt16 *waveformData, 
        ViConstString waveformName, 
        ViUInt32 waveformLength, 
        ViSession *genViPtr)  {
  
  ViStatus error = VI_SUCCESS;
  ViSession vi = VI_NULL;
  char NoTriggerChan[] = "XX";
  
  
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
  
  
  // NOTE: 0 means strings are equal
  if (strcmp(StartTriggerChan, NoTriggerChan)) {
    /* Configure start trigger */
    if (VERBOSE>0) printf("\tTrigger is %s.\n",StartTriggerChan);
    checkErr(niHSDIO_SetAttributeViInt32(vi, "", NIHSDIO_ATTR_DIGITAL_EDGE_START_TRIGGER_TERMINAL_CONFIGURATION, NIHSDIO_VAL_SINGLE_ENDED));
    checkErr(niHSDIO_ConfigureDigitalEdgeStartTrigger(vi,StartTriggerChan, StartTriggerEdge));
  } else { // no trigger
    if (VERBOSE>0) printf("\tNo trigger, starting immediately.\n");
  }
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
  
  
  TotalAcqMem = TotalAcqMem * 2; // since it returns for the default data width of 2
  DSamplesPerChannelHW[0] = TotalAcqMem/DataWidth;
  if (VERBOSE>0) printf("\tDataWidth : \t\t\t\t\t%d Bytes\n",DataWidth);
  if (VERBOSE>0) printf("\tTotal Memory/Channel : \t\t\t\t%d Mb\n",TotalAcqMem/1048576);
  if (VERBOSE>0) printf("\tEffective Memory/Channel : \t\t\t%d Mb\n",DSamplesPerChannelHW[0]/1048576);
   
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
  if (VERBOSE>2) printf("\tBytes this loop : %d\n",ABufferPos*2);
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
    if (VERBOSE>2) printf("No StopFile Found: %s\n",FileNameStop);
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
  // SamplesPerLoopPerChannel : Number Of Samples per Channel in the running AnalogBuffer
  // DeviceName : Name of the digital NI-DAQ device
  // AcqChannels : Digital channels to acquire, has to be comma-separated list
  // TrigChannel : Digital channel where the trigger is sent (should be 15, has to be larger than the last AcqChannel)
  // StartTrigChannel : Digital channel to receive the trigger from (This is the trigger for starting the engine, e.g. PFI0)
  // NumberOfChannelsByChan : Number of analog channels to decode per Headstage, has to be comma-separated list
  // BitLength : Bit Length of the headstage
  // SimulationMode : Whether to acquire the data or generate it for testing
  // Verbosity : How much output to provide
  
  char FileName[100], DeviceName[3], AcqChannels[34], TrigChannel[2], StartTrigChannel[5], NumberOfChannels[60], NumberOfChannelsByChan[60];
  char* Rest; 
  int DSamplingRate = 0, ASamplesPerIteration = 0, MaxIterations = 0, SamplesPerLoopPerChannel;
  int BitLength = 0, SimulationMode = 0, NumberOfChannelsTotal = 0, NAcqChannels = 0;
  ViUInt32 NumberOfChannelsByChanI[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}; // ONE ENTRY FOR EVERY POSSIBLE CHANNEL/HEADSTAGE
  
  // CHECK NUMBER OF ARGUMENTS
  if (VERBOSE>0) printf("\nAssigned Arguments:\n\n");
  if (argc != 14) { printf("13 input arguments required (%d provided).\n",argc-1); return 0; };
  
  // ASSIGN INPUT ARGUMENTS TO LOCAL VARIABLES
  sscanf(argv[13],"%d",&VERBOSE);
  strcpy(FileName, argv[1]); if (VERBOSE) printf("\tRoot Filename : \t\t\t\t%s \n",FileName);
  sscanf(argv[2], "%d", &DSamplingRate);  if (VERBOSE) printf("\tDigital Sampling Rate : \t\t\t%d \n", DSamplingRate);
  sscanf(argv[3],"%d",&ASamplesPerIteration); if (VERBOSE) printf("\tAnalog Samples Per Iteration : \t\t\t%d \n",ASamplesPerIteration);
  sscanf(argv[4],"%d",&MaxIterations);  if (VERBOSE) printf("\tMaximal Number of Iterations : \t\t\t%d \n",MaxIterations);
  sscanf(argv[5],"%d",&SamplesPerLoopPerChannel);  if (VERBOSE) printf("\tNumber of Samples in Buffer/Channel : \t%d \n",SamplesPerLoopPerChannel);  
  strcpy(DeviceName, argv[6]); if (VERBOSE) printf("\tDeviceName : \t\t\t\t\t%s \n",DeviceName);
  strcpy(AcqChannels,argv[7]); if (VERBOSE) printf("\tDigital Channels for Acquisition [0]: \t\t%s \n",AcqChannels);
  strcpy(TrigChannel,argv[8]); if (VERBOSE) printf("\tDigital Channel for Trigger [7] : \t\t%s \n",TrigChannel);
  strcpy(StartTrigChannel,argv[9]); if (VERBOSE) printf("\tChannel of Start Trigger [PFI0] : \t\t%s \n",StartTrigChannel);
  strcpy(NumberOfChannelsByChan,argv[10]); if (VERBOSE) printf("\tNumber of Analog Channels per Digital Channel: \t%s \n",NumberOfChannelsByChan);
  sscanf(argv[11],"%d",&BitLength); if (VERBOSE) printf("\tResolution of Headstage in Bits : \t\t%d \n",BitLength);
  sscanf(argv[12],"%d",&SimulationMode); if (VERBOSE) printf("\tSimulation Mode : \t\t\t\t%d \n",SimulationMode);
  if (VERBOSE) printf("\tVerbosity : \t\t\t\t\t%d \n",VERBOSE);
  
  if (VERBOSE) printf("\n");
    // PARSE CHANNELNUMBERS
  Rest = strtok(NumberOfChannelsByChan,",");
  while (Rest != NULL) {
    NumberOfChannelsByChanI[NAcqChannels] = atoi(Rest);
    Rest = strtok(NULL,",");
    NumberOfChannelsTotal += (int) NumberOfChannelsByChanI[NAcqChannels];
    NAcqChannels ++;
  }
  
  ANALOGSAMPLESPERLOOP = NumberOfChannelsTotal * SamplesPerLoopPerChannel;
  if (VERBOSE) printf("\tTotal Number of Analog Samples in Buffer: \t%d\n\n",ANALOGSAMPLESPERLOOP);
  
  // CALL DATA COLLECTION /GENERATION FUNCTIONS
  if (SimulationMode==0) {// ACQUIRE READ DATA
    if (VERBOSE) printf("Entering Data Acquisition:\n\n");
    acquireData(FileName,NumberOfChannelsByChanI, NumberOfChannelsTotal,DSamplingRate, (ViUInt32) MaxIterations, ASamplesPerIteration, 
            DeviceName, AcqChannels, TrigChannel, StartTrigChannel, (ViUInt32) BitLength);
  }
  else {// GENERATE SURROGATE DATA
    if (VERBOSE) printf("Entering Data Creation Function:\n\n");
    createData( FileName, NumberOfChannelsByChanI, NumberOfChannelsTotal, DSamplingRate, MaxIterations,ASamplesPerIteration);
  }
  return 1;
}
