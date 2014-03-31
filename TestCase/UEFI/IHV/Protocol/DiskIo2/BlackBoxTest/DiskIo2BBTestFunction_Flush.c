/*++
  The material contained herein is not a license, either        
  expressly or impliedly, to any intellectual property owned    
  or controlled by any of the authors or developers of this     
  material or to any contribution thereto. The material         
  contained herein is provided on an "AS IS" basis and, to the  
  maximum extent permitted by applicable law, this information  
  is provided AS IS AND WITH ALL FAULTS, and the authors and    
  developers of this material hereby disclaim all other         
  warranties and conditions, either express, implied or         
  statutory, including, but not limited to, any (if any)        
  implied warranties, duties or conditions of merchantability,  
  of fitness for a particular purpose, of accuracy or           
  completeness of responses, of results, of workmanlike         
  effort, of lack of viruses and of lack of negligence, all     
  with regard to this material and any contribution thereto.    
  Designers must not rely on the absence or characteristics of  
  any features or instructions marked "reserved" or             
  "undefined." The Unified EFI Forum, Inc. reserves any         
  features or instructions so marked for future definition and  
  shall have no responsibility whatsoever for conflicts or      
  incompatibilities arising from future changes to them. ALSO,  
  THERE IS NO WARRANTY OR CONDITION OF TITLE, QUIET ENJOYMENT,  
  QUIET POSSESSION, CORRESPONDENCE TO DESCRIPTION OR            
  NON-INFRINGEMENT WITH REGARD TO THE TEST SUITE AND ANY        
  CONTRIBUTION THERETO.                                         
                                                                
  IN NO EVENT WILL ANY AUTHOR OR DEVELOPER OF THIS MATERIAL OR  
  ANY CONTRIBUTION THERETO BE LIABLE TO ANY OTHER PARTY FOR     
  THE COST OF PROCURING SUBSTITUTE GOODS OR SERVICES, LOST      
  PROFITS, LOSS OF USE, LOSS OF DATA, OR ANY INCIDENTAL,        
  CONSEQUENTIAL, DIRECT, INDIRECT, OR SPECIAL DAMAGES WHETHER   
  UNDER CONTRACT, TORT, WARRANTY, OR OTHERWISE, ARISING IN ANY  
  WAY OUT OF THIS OR ANY OTHER AGREEMENT RELATING TO THIS       
  DOCUMENT, WHETHER OR NOT SUCH PARTY HAD ADVANCE NOTICE OF     
  THE POSSIBILITY OF SUCH DAMAGES.                              
                                                                
  Copyright 2006 - 2013 Unified EFI, Inc. All  
  Rights Reserved, subject to all existing rights in all        
  matters included within this Test Suite, to which United      
  EFI, Inc. makes no claim of right.                            
                                                                
  Copyright (c) 2013, Intel Corporation. All rights reserved.<BR>   
   
--*/
/*++

Module Name:

  DiskIo2BBFunctionTest.c

Abstract:

  Interface Function Test Cases of Disk I/O2 Protocol

--*/


#include "DiskIo2BBTestMain.h"



EFI_STATUS
BBTestFlushDiskExFunctionAutoTestCheckpoint1(
  EFI_STANDARD_TEST_LIBRARY_PROTOCOL    *StandardLib,
  EFI_DISK_IO_PROTOCOL                  *DiskIo,
  EFI_DISK_IO2_PROTOCOL                 *DiskIo2,
  EFI_BLOCK_IO2_PROTOCOL                *BlockIo2
  );


EFI_STATUS
BBTestFlushDiskExFunctionAutoTestCheckpoint2(
  EFI_STANDARD_TEST_LIBRARY_PROTOCOL    *StandardLib,
  EFI_DISK_IO_PROTOCOL                  *DiskIo,
  EFI_DISK_IO2_PROTOCOL                 *DiskIo2,
  EFI_BLOCK_IO2_PROTOCOL                *BlockIo2
  );

EFI_STATUS
BBTestFlushDiskExFunctionAutoTestCheckpoint3(
  EFI_STANDARD_TEST_LIBRARY_PROTOCOL    *StandardLib,
  EFI_DISK_IO_PROTOCOL                  *DiskIo,
  EFI_DISK_IO2_PROTOCOL                 *DiskIo2,
  EFI_BLOCK_IO2_PROTOCOL                *BlockIo2
  );




#define EFI_INITIALIZE_LOCK_VARIABLE(Tpl) {Tpl,0,0}



//
// Async Flush Queue
//
EFI_LIST_ENTRY  AsyncFlushFinishListHead  = INITIALIZE_LIST_HEAD_VARIABLE(AsyncFlushFinishListHead);
EFI_LIST_ENTRY  AsyncFlushExecuteListHead = INITIALIZE_LIST_HEAD_VARIABLE(AsyncFlushExecuteListHead);
EFI_LIST_ENTRY  AsyncFlushFailListHead    = INITIALIZE_LIST_HEAD_VARIABLE(AsyncFlushFailListHead);

//
// Async Flush lock
//
FLOCK gAsyncFlushQueueLock = EFI_INITIALIZE_LOCK_VARIABLE (EFI_TPL_CALLBACK);


//
// Async signal
//

UINTN       AsyncBatchFlushFinished = 0;



VOID
EFIAPI DiskIo2FlushNotifyFunc (
  IN  EFI_EVENT                Event,
  IN  VOID                     *Context
  )
{
  DiskIO2_Task *DiskIo2Entity;
  
  DiskIo2Entity = (DiskIO2_Task *)Context;

  //
  // Remove entity from AsyncFlushExecuteListHead &  add entity to AsyncFlushFinishListHead
  // All DiskIo2 Notify function run at Call Back level only once, So no locks required
  //
  AcquireLock(&gAsyncFlushQueueLock);
  RemoveEntryList(&DiskIo2Entity->ListEntry);
  InsertTailList(&AsyncFlushFinishListHead, &DiskIo2Entity->ListEntry);
  ReleaseLock(&gAsyncFlushQueueLock);
}


/**
 *   Provide EFI_DISK_IO2_PROTOCOL.FlushDiskEx() function abstraction interface
 *  @param DiskIo 2 a pointer to Disk IO2 to be tested.
 *  @param MediaId Read media ID.
 *  @param Offset the starting byte offset to read from.
 *  @return EFI_SUCCESS Finish the test successfully.
 */

STATIC
EFI_STATUS
DiskIo2AsyncFlushData (
  IN EFI_DISK_IO2_PROTOCOL            *DiskIo2,
  IN UINT32                            MediaId,
  IN UINT64                            Offset
  )
{
  
  EFI_STATUS                         Status;
  DiskIO2_Task                       *DiskIo2Entity = NULL;

  ASSERT(DiskIo2 != NULL);
  
  //
  // Allocate memory for one DiskIo2Entity
  //
  Status = gtBS->AllocatePool(
                   EfiBootServicesData, 
                   sizeof(DiskIO2_Task), 
                   &DiskIo2Entity);
  if (EFI_ERROR(Status) ) {
    return Status;
  }
  //
  // DiskIo2Token initialization
  //
  Status = gtBS->CreateEvent (
                   EFI_EVENT_NOTIFY_SIGNAL,
                   EFI_TPL_CALLBACK,
                   DiskIo2FlushNotifyFunc,
                   DiskIo2Entity,
                   &DiskIo2Entity->DiskIo2Token.Event
                   );
  if (EFI_ERROR(Status)) {
    gtBS->FreePool(DiskIo2Entity);
    return Status;
  }
  
  DiskIo2Entity->DiskIo2Token.TransactionStatus = EFI_NOT_READY;

  //
  // Acquire lock to add entity to Execution ListHead
  //
  AcquireLock(&gAsyncFlushQueueLock);
  InsertTailList(&AsyncFlushExecuteListHead, &DiskIo2Entity->ListEntry);
  ReleaseLock(&gAsyncFlushQueueLock);
  

  //
  // Async ReadDiskEx Call
  //
  Status = DiskIo2->FlushDiskEx (
                      DiskIo2,
                      MediaId,
                      Offset,
                      &DiskIo2Entity->DiskIo2Token
                      );
  
  if (EFI_ERROR (Status)) {
    gtBS->CloseEvent(DiskIo2Entity->DiskIo2Token.Event);
    //
    // Failed Status Event should never be signaled, so remove this entity from the list
    //
    AcquireLock(&gAsyncFlushQueueLock);
    RemoveEntryList(&DiskIo2Entity->ListEntry);
    // 
    // Put failure execution into fail List
    //
    InsertTailList(&AsyncFlushFailListHead, &DiskIo2Entity->ListEntry);
    ReleaseLock(&gAsyncFlushQueueLock);

    DiskIo2Entity->Buffer = NULL;
  }

  //
  // Record execution Info to Disk IO 2 entity 
  //
  DiskIo2Entity->Signature = DISKIO2ENTITY_SIGNATURE;
  DiskIo2Entity->MediaId = MediaId;
  DiskIo2Entity->Offset = Offset;
  DiskIo2Entity->StatusAsync = Status;
  //
  // memory uncompared with DiskIO interface
  //
  DiskIo2Entity->MemCompared = FALSE;               
  
  return Status;
}



VOID
EFIAPI DiskIo2FlushBatchNotifyFunc (
  IN  EFI_EVENT                Event,
  IN  VOID                     *Context
  )
{
  
  DiskIO2_Batch_Task_Context          *TaskContext;
  DiskIO2_Task                        *DiskIo2Entity = NULL;
  EFI_LIST_ENTRY                      *CurrentTaskEntry = NULL;
  EFI_DISK_IO2_PROTOCOL               *DiskIo2 = NULL;
  EFI_STATUS                          Status;

  
  TaskContext      = (DiskIO2_Batch_Task_Context *) Context;
  CurrentTaskEntry = TaskContext->CurrentTaskEntry;
  DiskIo2          = TaskContext->DiskIo2;

  if (!IsNodeAtEnd(TaskContext->TaskHeader, CurrentTaskEntry) ){
    DiskIo2Entity = CR(CurrentTaskEntry->ForwardLink, DiskIO2_Task, ListEntry, DISKIO2ENTITY_SIGNATURE);

    DiskIo2Entity->DiskIo2Token.Event = NULL;
    Status = gtBS->CreateEvent (
                     EFI_EVENT_NOTIFY_SIGNAL,
                     EFI_TPL_CALLBACK,
                     DiskIo2FlushBatchNotifyFunc,
                     TaskContext,
                     &DiskIo2Entity->DiskIo2Token.Event
                     );
    if (Status != EFI_SUCCESS) {
      goto END;
    }
    //
    // Current Task Entry move forward
    //
    TaskContext->CurrentTaskEntry = CurrentTaskEntry->ForwardLink;

    Status = DiskIo2->FlushDiskEx (
                        DiskIo2,
                        DiskIo2Entity->MediaId,
                        DiskIo2Entity->Offset,
                        &DiskIo2Entity->DiskIo2Token
                        );
    if (Status != EFI_SUCCESS) {
      goto END;
    }
  } else {
      //
      // All Task has been handled, kick off notify event & clean Task context
      //
      gtBS->SignalEvent (TaskContext->Token->Event);
      //
      // Close current Event
      //
      DiskIo2Entity = CR(CurrentTaskEntry, DiskIO2_Task, ListEntry, DISKIO2ENTITY_SIGNATURE);
      if (DiskIo2Entity->DiskIo2Token.Event != NULL) {
        gtBS->CloseEvent (DiskIo2Entity->DiskIo2Token.Event);
      }
      
      gtBS->FreePool (TaskContext);

      return;
  }

END:
  //
  // Close current Event
  //
  DiskIo2Entity = CR(CurrentTaskEntry, DiskIO2_Task, ListEntry, DISKIO2ENTITY_SIGNATURE);
  if (DiskIo2Entity->DiskIo2Token.Event != NULL) {
    gtBS->CloseEvent (DiskIo2Entity->DiskIo2Token.Event);
  }
  
  return;
}






/**
 *   Provide Batch task for EFI_DISK_IO2_PROTOCOL.FlushDiskEx() function 
 *  @param DiskIo 2 a pointer to Disk IO2 to be tested.
 *  @param TaskList point to batch task list.
 *  @param Token task list token.
 *  @return EFI_SUCCESS Finish the test successfully.
 */


STATIC
EFI_STATUS
DiskIo2AsyncBatchFlush (
  IN EFI_DISK_IO2_PROTOCOL           *DiskIo2,
  IN EFI_LIST_ENTRY                  *ListHeader,
  IN OUT EFI_DISK_IO2_TOKEN	         *Token
  )
{
  DiskIO2_Batch_Task_Context         *TaskContext = NULL;
  DiskIO2_Task                       *DiskIo2Entity = NULL;
  EFI_STATUS                         Status = EFI_SUCCESS;
  
  ASSERT(Token != NULL && Token->Event != NULL);
  
  if (!IsListEmpty(ListHeader)) {  
    //
    // Task Context will be freed in DiskIo2ReadBatchNotifyFunc when all task finished
    //
    Status = gtBS->AllocatePool (
                     EfiBootServicesData, 
                     sizeof(DiskIO2_Batch_Task_Context), 
                     &TaskContext
                     );
    if (TaskContext == NULL) {
      return EFI_OUT_OF_RESOURCES;
    }

    // 
    // Init BatchTask structure
    // 
    TaskContext->TaskHeader       = ListHeader;
    TaskContext->CurrentTaskEntry = ListHeader->ForwardLink;
    TaskContext->Token            = Token;
    TaskContext->DiskIo2          = DiskIo2;

    DiskIo2Entity = CR(ListHeader->ForwardLink, DiskIO2_Task, ListEntry, DISKIO2ENTITY_SIGNATURE);
 
    Status = gtBS->CreateEvent (
                     EFI_EVENT_NOTIFY_SIGNAL,
                     EFI_TPL_CALLBACK,
                     DiskIo2FlushBatchNotifyFunc,
                     TaskContext,
                     &DiskIo2Entity->DiskIo2Token.Event
                     );
    if (EFI_ERROR(Status)) {
      return Status;
    }
    
    Status = DiskIo2->FlushDiskEx (
                        DiskIo2,
                        DiskIo2Entity->MediaId,
                        DiskIo2Entity->Offset,
                        &DiskIo2Entity->DiskIo2Token
                        );
  }

  return Status;
}







/**
 *  Entrypoint for EFI_DISK_IO2_PROTOCOL.ReadDiskEx() Function Test.
 *  @param This a pointer of EFI_BB_TEST_PROTOCOL.
 *  @param ClientInterface a pointer to the interface to be tested.
 *  @param TestLevel test "thoroughness" control.
 *  @param SupportHandle a handle containing protocols required.
 *  @return EFI_SUCCESS Finish the test successfully.
 */
 
//
// TDS 5.2
//


EFI_STATUS
BBTestFlushDiskExFunctionAutoTest (
  IN EFI_BB_TEST_PROTOCOL       *This,
  IN VOID                       *ClientInterface,
  IN EFI_TEST_LEVEL             TestLevel,
  IN EFI_HANDLE                 SupportHandle
  )
 
{
  EFI_STATUS                            Status;
  EFI_STANDARD_TEST_LIBRARY_PROTOCOL    *StandardLib = NULL;
  EFI_BLOCK_IO2_PROTOCOL                *BlockIo2 = NULL;
  EFI_DISK_IO2_PROTOCOL                 *DiskIo2 = NULL;
  EFI_DISK_IO2_PROTOCOL                 *DiskIo2Temp = NULL;
  EFI_DISK_IO_PROTOCOL                  *DiskIo = NULL;
  EFI_DEVICE_PATH_PROTOCOL              *DevicePath = NULL;
  CHAR16                                *DevicePathStr = NULL;
  UINTN                                 Index;
  UINTN                                 NoHandles;
  EFI_HANDLE                            *HandleBuffer = NULL;
     
  
  //
  // Get the Standard Library Interface
  //
  Status = gtBS->HandleProtocol (
                   SupportHandle,
                   &gEfiStandardTestLibraryGuid,
                   &StandardLib
                   );
  
  if (EFI_ERROR(Status)) {
    StandardLib->RecordAssertion (
                   StandardLib,
                   EFI_TEST_ASSERTION_FAILED,
                   gTestGenericFailureGuid,
                   L"BS.HandleProtocol - Handle standard test library",
                   L"%a:%d:Status - %r",
                   __FILE__,
                   (UINTN)__LINE__,
                   Status
                   );
    return Status;
  }
  DiskIo2 = (EFI_DISK_IO2_PROTOCOL *)ClientInterface;
     
  Status = LocateBlockIo2FromDiskIo2 (DiskIo2, &BlockIo2, StandardLib);
  if (EFI_ERROR(Status)) {
    return EFI_DEVICE_ERROR;
  }
  
  //
  // Locate Device path of the current DiskIo2 device
  // and save it into log for investigating
  //
  LocateDevicePathFromDiskIo2 (DiskIo2, &DevicePath, StandardLib);
  
  DevicePathStr = DevicePathToStr (DevicePath);
  if (DevicePathStr != NULL) {
    StandardLib->RecordMessage (
                  StandardLib,
                  EFI_VERBOSE_LEVEL_DEFAULT,
                  L"\r\nCurrent Device: %s",
                  DevicePathStr
                  );
    gtBS->FreePool (DevicePathStr);
    DevicePathStr = NULL;
  }
  
  
  //
  // Locate DISK IO protocol on same handler for test
  //
  Status = gtBS->LocateHandleBuffer (
                   ByProtocol,
                   &gEfiDiskIo2ProtocolGuid,
                   NULL,
                   &NoHandles,
                   &HandleBuffer
                   );
  for (Index = 0; Index < NoHandles; Index++) {
     Status = gtBS->HandleProtocol (
                      HandleBuffer[Index],
                      &gEfiDiskIo2ProtocolGuid,
                      &DiskIo2Temp
                      );
    if (Status == EFI_SUCCESS && DiskIo2Temp == DiskIo2) {
       break;
    }
  }
  
  if (HandleBuffer != NULL) {
     gtBS->FreePool (HandleBuffer);
  }
  
  
  //
  // Async call 1 to test Disk IO 2 FlushDiskEx
  // Using Link list to manage token pool
  //
  BBTestFlushDiskExFunctionAutoTestCheckpoint1 (StandardLib,DiskIo,DiskIo2,BlockIo2);
  
  //
  // Sync call to test Disk IO 2 FlushDiskEx
  //
  BBTestFlushDiskExFunctionAutoTestCheckpoint2 (StandardLib, DiskIo, DiskIo2,BlockIo2);
  //
  // Async call 2 to test Disk IO 2 FlushDiskEx
  // Using Cascade Event Chain to manage token pool
  //
  BBTestFlushDiskExFunctionAutoTestCheckpoint3 (StandardLib, DiskIo,DiskIo2,BlockIo2);
  return Status;

  }
  
  
  /**
   *   EFI_DISK_IO2_PROTOCOL.FlushDiskEx() Function Test 1. Async mode test
   *  @param StandardLib a point to standard test lib
   *  @param DiskIo a pointer to Disk IO the interface.
   *  @param DiskIo 2 a pointer to Disk IO2 to be tested.
   *  @return EFI_SUCCESS Finish the test successfully.
   */
  
EFI_STATUS
BBTestFlushDiskExFunctionAutoTestCheckpoint1(
  EFI_STANDARD_TEST_LIBRARY_PROTOCOL  *StandardLib,
  EFI_DISK_IO_PROTOCOL                *DiskIo,
  EFI_DISK_IO2_PROTOCOL               *DiskIo2,
  EFI_BLOCK_IO2_PROTOCOL              *BlockIo2
  )
{
  EFI_STATUS            Status = EFI_SUCCESS;
  EFI_STATUS            StatusAsync = EFI_SUCCESS;
  
  UINT32                MediaId;
  BOOLEAN               RemovableMedia;
  BOOLEAN               MediaPresent;
  BOOLEAN               LogicalPartition;
  BOOLEAN               ReadOnly;
  BOOLEAN               WriteCaching;
  UINT32                BlockSize;
  UINT32                IoAlign;
  EFI_LBA               LastBlock;
  UINT64                LastOffset;
  
  UINTN                 Index;
  
  UINT64                Offset;
  UINTN                 Remainder;
  
  
  DiskIO2_Task          *DiskIo2Entity = NULL;
  UINTN                 WaitIndex;
  EFI_LIST_ENTRY        *ListEntry = NULL;
  
  //
  // Initialize variable
  //
  MediaId          = BlockIo2->Media->MediaId;
  RemovableMedia   = BlockIo2->Media->RemovableMedia;
  MediaPresent     = BlockIo2->Media->MediaPresent;
  LogicalPartition = BlockIo2->Media->LogicalPartition;
  ReadOnly         = BlockIo2->Media->ReadOnly;
  WriteCaching     = BlockIo2->Media->WriteCaching;
  BlockSize        = BlockIo2->Media->BlockSize;
  IoAlign          = BlockIo2->Media->IoAlign;
  LastBlock        = BlockIo2->Media->LastBlock;
  
  
  LastOffset       = MultU64x32 (LastBlock+1, BlockSize);
  
  //
  // Assertion Point 5.2.2.1
  // FlushDiskEx must succeed to read proper data from device with valid parameter
  //
  if ((MediaPresent == TRUE) && (ReadOnly == FALSE) && (WriteCaching == TRUE)) {
   
    Print (L" ================ Start to do Async FlushDiskEx call ================ \n\n");
  
    for (Index = 0; Index < 30; Index++) {
      //
      // Prepare test data of Offset
      // Following Offset value covers:
      //    Offset at the front part of the disk
      //    Offset at the end   part of the disk
      //    Offset at the middle part of the disk
      //    Offset right at the boundary of the block of the disk
      //    Offset not at the boundary of the block of the disk
      //
      switch (Index) {
        case 0:
          Offset = 0;
          break;
        case 1:
          Offset = BlockSize;
          break;
        case 2:
          Offset = 2 * BlockSize;
          break;
        case 3:
          Offset = MultU64x32 (LastBlock , BlockSize);
          break;
        case 4:
          Offset = MultU64x32 (LastBlock-1 , BlockSize);
          break;
        case 5:
          Offset = MultU64x32 (DivU64x32 (LastBlock, 2, &Remainder) , BlockSize);
          break;
        case 6:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) - 1) , BlockSize);
          break;
        case 7:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) + 1) , BlockSize);
          break;
  
        case 10:
          Offset = BlockSize + 1;
          break;
        case 11:
          Offset = 2 * BlockSize + 1;
          break;
        case 12:
          Offset = MultU64x32 (LastBlock , BlockSize) + 1;
          break;
        case 13:
          Offset = MultU64x32 (LastBlock-1 , BlockSize) + 1;
          break;
        case 14:
          Offset = MultU64x32 (DivU64x32 (LastBlock, 2, &Remainder) , BlockSize) + 1;
          break;
        case 15:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) - 1) , BlockSize) + 1;
          break;
        case 16:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) + 1) , BlockSize) + 1;
          break;
  
        case 20:
          Offset = BlockSize - 1;
          break;
        case 21:
          Offset = 2 * BlockSize - 1;
          break;
        case 22:
          Offset = MultU64x32 (LastBlock , BlockSize) - 1;
          break;
        case 23:
          Offset = MultU64x32 (LastBlock-1 , BlockSize) - 1;
          break;
        case 24:
          Offset = MultU64x32 (DivU64x32 (LastBlock, 2, &Remainder) , BlockSize) - 1;
          break;
        case 25:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) - 1) , BlockSize) - 1;
          break;
        case 26:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) + 1) , BlockSize) - 1;
          break;
  
        default:
          Offset = LastOffset + 1;
      }
  
  
  
  
      // 
      // Check that the Offset value is still valid.
      // 
      // When LastBlock==2 (or 3) in case 25 above the final arithmetic becomes
      // Offset = 0 - 1; 
      // which results in Offset underflowing to become 0xFFFFFFFFFFFFFFFF.
      // This is not covered by any other checks. For example,
      // adding (Offset + NewbufferSize) is (0xFFFFFFFFFFFFFFFF + NewBufferSize),
      // which overflows to the equivalent value (NewBufferSize - 1);
      //
      if ( Offset > LastOffset ) {
         continue;
      }
      
      //
      // Async Call FlushDiskEx with the specified Offset 
      //
      StatusAsync = DiskIo2AsyncFlushData (
                      DiskIo2,
                      MediaId,
                      Offset
                      );
                    
                    
      }//end of loop of Offset - Index
  
      Print (L" ================== Async FlushDiskEx call finshed ================== \n\n");
  
  
  
      //
      // Busy waiting 60s on all the execute entity being moved to finished queue
      //  
      Print (L"Wait maximumly 60s for all Async Flush events signaled\n\n");
      Status = gtBS->SetTimer (TimerEvent, TimerPeriodic, 10000000);
      Index = 0;
      
      AcquireLock(&gAsyncFlushQueueLock);
      while (!IsListEmpty(&AsyncFlushExecuteListHead) && Index < 60) {
        ReleaseLock(&gAsyncFlushQueueLock);
        
        gtBS->WaitForEvent (   
                1,
                &TimerEvent,
                &WaitIndex
                );
        Index++;
        Print (L".");
        AcquireLock(&gAsyncFlushQueueLock);
      }
      ReleaseLock(&gAsyncFlushQueueLock);
  
      Status = gtBS->SetTimer (TimerEvent, TimerCancel, 0);
      Print(L"\n");
    }
  
  
  
    //
    // clear all Disk IO2 events from gFlushFinishQueue 
    // gFlushFinshQueue is handled first since we use Disk IO flush to do flush buffer validation 
    // Here no logs should be wrote to this disk device to keep data intact
    //
    AcquireLock(&gAsyncFlushQueueLock);
    if (!IsListEmpty(&AsyncFlushFinishListHead)) {
      for(ListEntry = GetFirstNode(&AsyncFlushFinishListHead); ; ListEntry = GetNextNode(&AsyncFlushFinishListHead, ListEntry)) {
        DiskIo2Entity = CR(ListEntry, DiskIO2_Task, ListEntry, DISKIO2ENTITY_SIGNATURE);
        ReleaseLock(&gAsyncFlushQueueLock);
           
        //
        // Check & record every Disk IO2 execution entity status 
        //
        //
        if (DiskIo2Entity->DiskIo2Token.TransactionStatus == EFI_SUCCESS) {	
          DiskIo2Entity->AssertionType = EFI_TEST_ASSERTION_PASSED;
        } else {
            DiskIo2Entity->AssertionType = EFI_TEST_ASSERTION_FAILED;
        }
    
        AcquireLock(&gAsyncFlushQueueLock);
        //
        // Last list node handled
        //
        if (IsNodeAtEnd(&AsyncFlushFinishListHead, ListEntry)) {
           break;
        }
      }
    }
  
    //
    // Record All Finished Flush case results
    //
    while (!IsListEmpty(&AsyncFlushFinishListHead)) {
      DiskIo2Entity = CR(AsyncFlushFinishListHead.ForwardLink, DiskIO2_Task, ListEntry, DISKIO2ENTITY_SIGNATURE);
   
      RemoveEntryList(&DiskIo2Entity->ListEntry);
      ReleaseLock(&gAsyncFlushQueueLock);
   
      StandardLib->RecordAssertion (
                     StandardLib,
                     DiskIo2Entity->AssertionType,
                     gDiskIo2FunctionTestAssertionGuid017,
                     L"EFI_DISK_IO2_PROTOCOL.FlushDiskEx - Async Flush Disk with proper parameter from valid media",
                     L"%a:%d: MediaId=%d Offset=0x%lx ",
                     __FILE__,
                     (UINTN)__LINE__,
                     DiskIo2Entity->MediaId,
                     DiskIo2Entity->Offset
                     );
    
      gtBS->CloseEvent(DiskIo2Entity->DiskIo2Token.Event);
      gtBS->FreePool(DiskIo2Entity);
      AcquireLock(&gAsyncFlushQueueLock);
    }
    ReleaseLock(&gAsyncFlushQueueLock);
  
    //
    // If AsyncFlushFailListHead is not empty, which means some Async Calls are wrong 
    // 
    while(!IsListEmpty(&AsyncFlushFailListHead)) {
      DiskIo2Entity = CR(AsyncFlushFailListHead.ForwardLink, DiskIO2_Task, ListEntry, DISKIO2ENTITY_SIGNATURE);
      RemoveEntryList(&DiskIo2Entity->ListEntry);
    
      StandardLib->RecordAssertion (
                     StandardLib,
                     EFI_TEST_ASSERTION_FAILED,
                     gDiskIo2FunctionTestAssertionGuid018,
                     L"EFI_DISK_IO2_PROTOCOL.FlushDiskEx - Async Flush Disk with proper parameter from valid media "	  \
                     L"Read Failed ",
                     L"%a:%d: Offset=0x%lx, StatusAsync=%r",
                     __FILE__,
                     (UINTN)__LINE__,
                     DiskIo2Entity->Offset,
                     DiskIo2Entity->StatusAsync
                     );
    
      gtBS->FreePool(DiskIo2Entity);
    }
  
  
    //
    // If FlushExecuteList is not empty, which means some token events havn't been signaled yet
    //
    //
    // Be careful, All the entities in Execution List should NOT be freed here!
    //
    AcquireLock(&gAsyncFlushQueueLock);
    if (!IsListEmpty(&AsyncFlushExecuteListHead)) {
      for(ListEntry = GetFirstNode(&AsyncFlushExecuteListHead); ; ListEntry = GetNextNode(&AsyncFlushExecuteListHead, ListEntry)) {
        DiskIo2Entity = CR(ListEntry, DiskIO2_Task, ListEntry, DISKIO2ENTITY_SIGNATURE);
        ReleaseLock(&gAsyncFlushQueueLock);
           
        StandardLib->RecordAssertion (
                       StandardLib,
                       EFI_TEST_ASSERTION_FAILED,
                       gDiskIo2FunctionTestAssertionGuid019,
                       L"EFI_DISK_IO2_PROTOCOL.FlushDiskEx - Async Flush Disk with proper parameter from valid media "   \
                       L"Read event has not been signaled",
                       L"%a:%d: MediaId=%d Offset=0x%lx  ",
                       __FILE__,
                       (UINTN)__LINE__,
                       DiskIo2Entity->MediaId,
                       DiskIo2Entity->Offset
                       );
                    
        AcquireLock(&gAsyncFlushQueueLock);
        //
        // Last list node handled
        //
        if (IsNodeAtEnd(&AsyncFlushExecuteListHead, ListEntry)) {
           break;
        }
      }
    }
    
    ReleaseLock(&gAsyncFlushQueueLock);
    
    return EFI_SUCCESS;
}

   
  /**
   *   EFI_DISK_IO2_PROTOCOL.FlushDiskEx() Function Test 2. Sync mode test
   *  @param StandardLib a point to standard test lib
   *  @param DiskIo a pointer to Disk IO the interface.
   *  @param DiskIo 2 a pointer to Disk IO2 to be tested.
   *  @return EFI_SUCCESS Finish the test successfully.
   */
  
EFI_STATUS
BBTestFlushDiskExFunctionAutoTestCheckpoint2(
  EFI_STANDARD_TEST_LIBRARY_PROTOCOL  *StandardLib,
  EFI_DISK_IO_PROTOCOL                *DiskIo,
  EFI_DISK_IO2_PROTOCOL               *DiskIo2,
  EFI_BLOCK_IO2_PROTOCOL              *BlockIo2
  )
{

  EFI_STATUS                StatusSync = EFI_SUCCESS;
  EFI_TEST_ASSERTION        AssertionType;
  
  UINT32                    MediaId;
  BOOLEAN                   RemovableMedia;
  BOOLEAN                   MediaPresent;
  BOOLEAN                   LogicalPartition;
  BOOLEAN                   ReadOnly;
  BOOLEAN                   WriteCaching;
  UINT32                    BlockSize;
  UINT32                    IoAlign;
  EFI_LBA                   LastBlock;
  UINT64                    LastOffset;
  
  UINTN                     Index;
  UINTN                     Remainder;
  UINT64                    Offset;
     
    
  EFI_DISK_IO2_TOKEN        DiskIo2TokenSync;
  
  //
  // Initialize variable
  //
  MediaId          = BlockIo2->Media->MediaId;
  RemovableMedia   = BlockIo2->Media->RemovableMedia;
  MediaPresent     = BlockIo2->Media->MediaPresent;
  LogicalPartition = BlockIo2->Media->LogicalPartition;
  ReadOnly         = BlockIo2->Media->ReadOnly;
  WriteCaching     = BlockIo2->Media->WriteCaching;
  BlockSize        = BlockIo2->Media->BlockSize;
  IoAlign          = BlockIo2->Media->IoAlign;
  LastBlock        = BlockIo2->Media->LastBlock;
     
  LastOffset       = MultU64x32 (LastBlock+1, BlockSize);
     
     
     
     
  //
  // Sync Token Init
  //
  DiskIo2TokenSync.Event             = NULL;
  DiskIo2TokenSync.TransactionStatus = EFI_NOT_READY;
  
  
  
  //
  // Assertion Point 5.2.2.1
  // FlushDiskEx must succeed to read proper data from device with valid parameter
  //
  if ((MediaPresent == TRUE) && (ReadOnly == FALSE) && (WriteCaching == TRUE)) {
    
    for (Index = 0; Index < 30; Index++) {
      //
      // Prepare test data of Offset
      // Following Offset value covers:
      //    Offset at the front part of the disk
      //    Offset at the end   part of the disk
      //    Offset at the middle part of the disk
      //    Offset right at the boundary of the block of the disk
      //    Offset not at the boundary of the block of the disk
      //
      switch (Index) {
        case 0:
          Offset = 0;
          break;
        case 1:
          Offset = BlockSize;
          break;
        case 2:
          Offset = 2 * BlockSize;
          break;
        case 3:
          Offset = MultU64x32 (LastBlock , BlockSize);
          break;
        case 4:
          Offset = MultU64x32 (LastBlock-1 , BlockSize);
          break;
        case 5:
          Offset = MultU64x32 (DivU64x32 (LastBlock, 2, &Remainder) , BlockSize);
          break;
        case 6:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) - 1) , BlockSize);
          break;
        case 7:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) + 1) , BlockSize);
          break;
     
        case 10:
          Offset = BlockSize + 1;
          break;
        case 11:
          Offset = 2 * BlockSize + 1;
          break;
        case 12:
          Offset = MultU64x32 (LastBlock , BlockSize) + 1;
          break;
        case 13:
          Offset = MultU64x32 (LastBlock-1 , BlockSize) + 1;
          break;
        case 14:
          Offset = MultU64x32 (DivU64x32 (LastBlock, 2, &Remainder) , BlockSize) + 1;
          break;
        case 15:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) - 1) , BlockSize) + 1;
          break;
        case 16:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) + 1) , BlockSize) + 1;
          break;
     
        case 20:
          Offset = BlockSize - 1;
          break;
        case 21:
          Offset = 2 * BlockSize - 1;
          break;
        case 22:
          Offset = MultU64x32 (LastBlock , BlockSize) - 1;
          break;
        case 23:
          Offset = MultU64x32 (LastBlock-1 , BlockSize) - 1;
          break;
        case 24:
          Offset = MultU64x32 (DivU64x32 (LastBlock, 2, &Remainder) , BlockSize) - 1;
          break;
        case 25:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) - 1) , BlockSize) - 1;
          break;
        case 26:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) + 1) , BlockSize) - 1;
          break;
     
        default:
          Offset = LastOffset + 1;
      }
     
      
      // Check that the Offset value is still valid.
      // 
      // When LastBlock==2 (or 3) in case 25 above the final arithmetic becomes
      // Offset = 0 - 1; 
      // which results in Offset underflowing to become 0xFFFFFFFFFFFFFFFF.
      // This is not covered by any other checks. For example,
      // adding (Offset + NewbufferSize) is (0xFFFFFFFFFFFFFFFF + NewBufferSize),
      // which overflows to the equivalent value (NewBufferSize - 1);
      //
      if ( Offset > LastOffset ) {
        continue;
      }
      //
      // Sync Call Disk IOFlushDiskEx with specified Offset and BufferSize
      //
     
        
      StatusSync = DiskIo2->FlushDiskEx (
                              DiskIo2,
                              MediaId,
                              Offset,
                              &DiskIo2TokenSync
                              );
       
      if (StatusSync == EFI_SUCCESS) {
        AssertionType = EFI_TEST_ASSERTION_PASSED;
      } else {
          AssertionType = EFI_TEST_ASSERTION_FAILED;
      }
     
  
      StandardLib->RecordAssertion (
                     StandardLib,
                     AssertionType,
                     gDiskIo2FunctionTestAssertionGuid020,
                     L"EFI_DISK_IO2_PROTOCOL.FlushDiskEx - Sync Flush Disk with proper parameter from valid media",
                     L"%a:%d: Offset=0x%lx, StatusSync=%r",
                     __FILE__,
                     (UINTN)__LINE__,
                     Offset,
                     StatusSync
                     );
        
    }//end of loop of Offset - IndexJ
  }//end of loop of BufferSize - IndexI
  return EFI_SUCCESS;
}
  
  
  
/**
 *   EFI_DISK_IO2_PROTOCOL.FlushDiskEx() Function Test 3. Async mode test
 *  @param StandardLib a point to standard test lib
 *  @param DiskIo 2 a pointer to Disk IO2 to be tested.
 *  @return EFI_SUCCESS Finish the test successfully.
 */

EFI_STATUS
BBTestFlushDiskExFunctionAutoTestCheckpoint3(
  EFI_STANDARD_TEST_LIBRARY_PROTOCOL	  *StandardLib,
  EFI_DISK_IO_PROTOCOL				  *DiskIo,
  EFI_DISK_IO2_PROTOCOL				  *DiskIo2,
  EFI_BLOCK_IO2_PROTOCOL                *BlockIo2
  )
{
  EFI_STATUS                Status = EFI_SUCCESS;
  UINT32                    MediaId;
  BOOLEAN                   RemovableMedia;
  BOOLEAN                   MediaPresent;
  BOOLEAN                   LogicalPartition;
  BOOLEAN                   ReadOnly;
  BOOLEAN                   WriteCaching;
  UINT32                    BlockSize;
  UINT32                    IoAlign;
  EFI_LBA                   LastBlock;
     
  UINT64                    LastOffset;
                            
  UINTN                     Index;
                            
  UINT64                    Offset;
  UINTN                     Remainder;
                            
     
     
  EFI_LIST_ENTRY            ListHeader;
  EFI_LIST_ENTRY            *ListEntry = NULL;
  UINTN                     WaitIndex;
  DiskIO2_Task              *DiskIo2Entity = NULL;
  EFI_DISK_IO2_TOKEN        BatchFlushToken;
  BOOLEAN                   MemoryAllocFail = FALSE;
  
  //
  // Initialize variable
  //
  MediaId          = BlockIo2->Media->MediaId;
  RemovableMedia   = BlockIo2->Media->RemovableMedia;
  MediaPresent     = BlockIo2->Media->MediaPresent;
  LogicalPartition = BlockIo2->Media->LogicalPartition;
  ReadOnly         = BlockIo2->Media->ReadOnly;
  WriteCaching     = BlockIo2->Media->WriteCaching;
  BlockSize        = BlockIo2->Media->BlockSize;
  IoAlign          = BlockIo2->Media->IoAlign;
  LastBlock        = BlockIo2->Media->LastBlock;
     
  LastOffset       = MultU64x32 (LastBlock+1, BlockSize);
     
     
  //
  // Initialize batch task list header
  //
  ListHeader.ForwardLink = &(ListHeader);
  ListHeader.BackLink = &(ListHeader);
     
  //
  // Sync Token Init
  //
  AsyncBatchFlushFinished = 0;
  BatchFlushToken.Event = NULL;
  
  Status = gtBS->CreateEvent (
                   EFI_EVENT_NOTIFY_SIGNAL,
                   EFI_TPL_CALLBACK,
                   DiskIo2FinishNotifyFunc,
                   &AsyncBatchFlushFinished,
                   &BatchFlushToken.Event
                   );

  if (EFI_ERROR(Status)) {
    StandardLib->RecordAssertion (
                   StandardLib,
                   EFI_TEST_ASSERTION_FAILED,
                   gTestGenericFailureGuid,
                   L"Create Event Fail",
                   L"%a:%d:",
                   __FILE__,
                   (UINTN)__LINE__
                   );
    goto END;
  }
  
  BatchFlushToken.TransactionStatus = EFI_NOT_READY;
     
  
  Print (L"Create Batch Flush Task List.\n\n");
  //
  // Create one Batch Flush task list
  //
  if ((MediaPresent == TRUE) && (ReadOnly == FALSE) && (WriteCaching == TRUE)) {
     
    for (Index = 0; Index < 30; Index++) {
      //
      // Prepare test data of Offset
      // Following Offset value covers:
      //    Offset at the front part of the disk
      //    Offset at the end   part of the disk
      //    Offset at the middle part of the disk
      //    Offset right at the boundary of the block of the disk
      //    Offset not at the boundary of the block of the disk
      //
      switch (Index) {
        case 0:
          Offset = 0;
          break;
        case 1:
          Offset = BlockSize;
          break;
        case 2:
          Offset = 2 * BlockSize;
          break;
        case 3:
          Offset = MultU64x32 (LastBlock , BlockSize);
          break;
        case 4:
          Offset = MultU64x32 (LastBlock-1 , BlockSize);
          break;
        case 5:
          Offset = MultU64x32 (DivU64x32 (LastBlock, 2, &Remainder) , BlockSize);
          break;
        case 6:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) - 1) , BlockSize);
          break;
        case 7:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) + 1) , BlockSize);
          break;
      
        case 10:
          Offset = BlockSize + 1;
          break;
        case 11:
          Offset = 2 * BlockSize + 1;
          break;
        case 12:
          Offset = MultU64x32 (LastBlock , BlockSize) + 1;
          break;
        case 13:
          Offset = MultU64x32 (LastBlock-1 , BlockSize) + 1;
          break;
        case 14:
          Offset = MultU64x32 (DivU64x32 (LastBlock, 2, &Remainder) , BlockSize) + 1;
          break;
        case 15:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) - 1) , BlockSize) + 1;
          break;
        case 16:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) + 1) , BlockSize) + 1;
          break;
      
        case 20:
          Offset = BlockSize - 1;
          break;
        case 21:
          Offset = 2 * BlockSize - 1;
          break;
        case 22:
          Offset = MultU64x32 (LastBlock , BlockSize) - 1;
          break;
        case 23:
          Offset = MultU64x32 (LastBlock-1 , BlockSize) - 1;
          break;
        case 24:
          Offset = MultU64x32 (DivU64x32 (LastBlock, 2, &Remainder) , BlockSize) - 1;
          break;
        case 25:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) - 1) , BlockSize) - 1;
          break;
        case 26:
          Offset = MultU64x32 ((DivU64x32 (LastBlock, 2, &Remainder) + 1) , BlockSize) - 1;
          break;
      
        default:
          Offset = LastOffset + 1;
      }
      
      // 
      // Check that the Offset value is still valid.
      // 
      // When LastBlock==2 (or 3) in case 25 above the final arithmetic becomes
      // Offset = 0 - 1; 
      // which results in Offset underflowing to become 0xFFFFFFFFFFFFFFFF.
      // This is not covered by any other checks. For example,
      // adding (Offset + NewbufferSize) is (0xFFFFFFFFFFFFFFFF + NewBufferSize),
      // which overflows to the equivalent value (NewBufferSize - 1);
      //
      if ( Offset > LastOffset ) {
        continue;
      }
  
      //
      // Allocate memory for one DiskIo2Entity
      //
      Status = gtBS->AllocatePool(
                      EfiBootServicesData, 
                      sizeof(DiskIO2_Task), 
                      &DiskIo2Entity
                      );
      if (Status != EFI_SUCCESS) {
        MemoryAllocFail = TRUE;
        goto END;
      } 
    }//end of loop of Offset - Index
  
    Status = DiskIo2AsyncBatchFlush (
               DiskIo2,
               &ListHeader,
               &BatchFlushToken
               );
    if (EFI_ERROR(Status)) {
      goto END;
    }
    
    //
    // Busy Waiting for BatchFlushToken signal
    // Busy waiting 60s on all the execute entity being moved to finished queue
    //  
    Print (L"Wait maximumly 60s for Async Batch Read events signaled\n\n");
    Status = gtBS->SetTimer (TimerEvent, TimerPeriodic, 10000000);
    Index = 0;
    
    while (Index < 60 && AsyncBatchFlushFinished == 0) {
      Status =gtBS->WaitForEvent (   
                      1,
                      &TimerEvent,
                      &WaitIndex
                      );
      Index++;
      Print(L".");
    }
    
    Status = gtBS->SetTimer (TimerEvent, TimerCancel, 0);
    Print(L"\n");
  }

END:
  if (BatchFlushToken.Event != NULL) {
    gtBS->CloseEvent (BatchFlushToken.Event);
  } 
  
  //
  // Verify all Async Flush Task Result 
  //
  if (!IsListEmpty(&ListHeader) && MemoryAllocFail == FALSE) {
    for(ListEntry = GetFirstNode(&ListHeader); ; ListEntry = GetNextNode(&ListHeader, ListEntry)) {
      DiskIo2Entity = CR(ListEntry, DiskIO2_Task, ListEntry, DISKIO2ENTITY_SIGNATURE);
  
      //
      // Check & record every Disk IO2 execution entity status 
      //
      DiskIo2Entity->AssertionType = EFI_TEST_ASSERTION_PASSED;
      //
      //
      //
      if ( DiskIo2Entity->DiskIo2Token.TransactionStatus == EFI_SUCCESS) {
        DiskIo2Entity->AssertionType = EFI_TEST_ASSERTION_PASSED;
      } else {
        DiskIo2Entity->AssertionType = EFI_TEST_ASSERTION_FAILED;
      }
      
      //
      // Last list node handled
      //
      if (IsNodeAtEnd(&ListHeader, ListEntry)) {
         break;
      }
    }
  }
  
  
  //
  // Do logging & clean up 
  //
  while(!IsListEmpty(&ListHeader)) {
    DiskIo2Entity = CR(ListHeader.ForwardLink, DiskIO2_Task, ListEntry, DISKIO2ENTITY_SIGNATURE);
    RemoveEntryList(&DiskIo2Entity->ListEntry);
  
    if ( MemoryAllocFail == FALSE) { 
      StandardLib->RecordAssertion (
                     StandardLib,
                     DiskIo2Entity->AssertionType,
                     gDiskIo2FunctionTestAssertionGuid021,
                     L"EFI_DISK_IO2_PROTOCOL.FlushDiskEx - Batch Async Flush Disk with proper parameter from valid media",
                     L"%a:%d:MediaId=%d, Offset=0x%lx, TransactionStatus=%r",
                     __FILE__,
                     (UINTN)__LINE__,
                     DiskIo2Entity->MediaId,
                     DiskIo2Entity->Offset,
                     DiskIo2Entity->DiskIo2Token.TransactionStatus
                     );
                    
    }
  
    gtBS->FreePool(DiskIo2Entity);
  }
  
  return Status;
}




