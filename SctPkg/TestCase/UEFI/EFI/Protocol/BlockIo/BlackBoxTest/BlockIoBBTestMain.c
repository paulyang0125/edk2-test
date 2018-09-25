/** @file

  Copyright 2006 - 2017 Unified EFI, Inc.<BR>
  Copyright (c) 2010 - 2017, Intel Corporation. All rights reserved.<BR>

  This program and the accompanying materials
  are licensed and made available under the terms and conditions of the BSD License
  which accompanies this distribution.  The full text of the license may be found at 
  http://opensource.org/licenses/bsd-license.php
 
  THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
  WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.
 
**/
/*++

Module Name:

  BlockIoBBTestMain.c

Abstract:

  Test Driver of Block I/O Protocol

--*/

#include "SctLib.h"
#include "BlockIoBBTestMain.h"

EFI_EVENT TimerEvent = NULL;

//
// Build Data structure here
//

EFI_BB_TEST_PROTOCOL_FIELD gBBTestProtocolField = {
  BLOCK_IO_PROTOCOL_TEST_REVISION,
  EFI_BLOCK_IO_PROTOCOL_GUID,
  L"Block I/O Protocol Test",
  L"UEFI Block I/O Protocol Test"
};

EFI_GUID gSupportProtocolGuid1[2] = {
  EFI_STANDARD_TEST_LIBRARY_GUID,
  EFI_NULL_GUID
};

EFI_BB_TEST_ENTRY_FIELD gBBTestEntryField[] = {
  //
  // Conformance test section
  //
  {
    BLOCK_IO_PROTOCOL_READBLOCKS_CONFORMANCE_AUTO_GUID,
    L"ReadBlocks_Conf",
    L"Perform auto consistency checkes on the ReadBlocks interface",
    EFI_TEST_LEVEL_MINIMAL,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_AUTO,
    BBTestReadBlocksConformanceAutoTest
  },
  {
    BLOCK_IO_PROTOCOL_FLUSHBLOCKS_CONFORMANCE_AUTO_GUID,
    L"FlushBlocks_Conf",
    L"Perform auto consistency checkes on the FlushBlocks interface",
    EFI_TEST_LEVEL_MINIMAL,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_AUTO,
    BBTestFlushBlocksConformanceAutoTest
  },
  //
  // Function test section
  //
  {
    BLOCK_IO_PROTOCOL_RESET_FUNCTION_AUTO_GUID,
    L"Reset_Func",
    L"Invoke Reset and verify interface correctness within test case",
    EFI_TEST_LEVEL_DEFAULT,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_AUTO,
    BBTestResetFunctionAutoTest
  },
  {
    BLOCK_IO_PROTOCOL_READBLOCKS_FUNCTION_AUTO_GUID,
    L"ReadBlocks_Func",
    L"Invoke ReadBlocks and verify interface correctness within test case",
    EFI_TEST_LEVEL_DEFAULT,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_AUTO,
    BBTestReadBlocksFunctionAutoTest
  },
  {
    BLOCK_IO_PROTOCOL_FLUSHBLOCKS_FUNCTION_AUTO_GUID,
    L"FlushBlocks_Func",
    L"Invoke FlushBlocks and verify interface correctness within test case",
    EFI_TEST_LEVEL_DEFAULT,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_AUTO,
    BBTestFlushBlocksFunctionAutoTest
  },
  {
    BLOCK_IO_PROTOCOL_MEDIAINFO_INTEGRITY_AUTO_GUID,
    L"MediaInfo_Integrity",
    L"Check BlockIo Media Info Integrity within test case",
    EFI_TEST_LEVEL_DEFAULT,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_AUTO,
    BBTestMediaInfoCheckAutoTest
  },
  
  //
  // Stress test section
  //
#ifdef EFI_TEST_EXHAUSTIVE
  {
    BLOCK_IO_PROTOCOL_READBLOCKS_CONFORMANCE_MANUAL_GUID,
    L"ReadBlocks_Conf_Manual",
    L"Perform manually consistency checkes on the ReadBlocks interface",
    EFI_TEST_LEVEL_MINIMAL,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_MANUAL,
    BBTestReadBlocksConformanceManualTest
  },
  {
    BLOCK_IO_PROTOCOL_WRITEBLOCKS_CONFORMANCE_AUTO_GUID,
    L"WriteBlocks_Conf",
    L"Perform auto consistency checkes on the WriteBlocks interface",
    EFI_TEST_LEVEL_MINIMAL,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_AUTO | EFI_TEST_CASE_DESTRUCTIVE,
    BBTestWriteBlocksConformanceAutoTest
  },
  {
    BLOCK_IO_PROTOCOL_WRITEBLOCKS_CONFORMANCE_MANUAL_GUID,
    L"WriteBlocks_Conf_Manual",
    L"Perform manually consistency checkes on the WriteBlocks interface",
    EFI_TEST_LEVEL_MINIMAL,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_MANUAL | EFI_TEST_CASE_DESTRUCTIVE,
    BBTestWriteBlocksConformanceManualTest
  },
  {
    BLOCK_IO_PROTOCOL_FLUSHBLOCKS_CONFORMANCE_MANUAL_GUID,
    L"FlushBlocks_Conf_Manual",
    L"Perform manually consistency checkes on the FlushBlocks interface",
    EFI_TEST_LEVEL_MINIMAL,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_MANUAL,
    BBTestFlushBlocksConformanceManualTest
  },
  {
    BLOCK_IO_PROTOCOL_WRITEBLOCKS_FUNCTION_AUTO_GUID,
    L"WriteBlocks_Func",
    L"Invoke WriteBlocks and verify interface correctness within test case",
    EFI_TEST_LEVEL_DEFAULT,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_AUTO | EFI_TEST_CASE_DESTRUCTIVE,
    BBTestWriteBlocksFunctionAutoTest
  },
  {
    BLOCK_IO_PROTOCOL_MEDIA_INTEGRITY_MANUAL_GUID,
    L"Media_Integrity_Manual",
    L"Reinstall some different block devices and check the private data in Media data structure",
    EFI_TEST_LEVEL_DEFAULT,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_MANUAL,
    BBTestMediaIntegrityManualTest
  },
  {
    BLOCK_IO_PROTOCOL_RESET_STRESS_AUTO_GUID,
    L"Reset_Stress",
    L"Perform stress test on Reset",
    EFI_TEST_LEVEL_EXHAUSTIVE,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_AUTO,
    BBTestResetStressAutoTest
  },
  {
    BLOCK_IO_PROTOCOL_READBLOCKS_STRESS_AUTO_GUID,
    L"ReadBlocks_Stress",
    L"Perform stress test on ReadBlocks",
    EFI_TEST_LEVEL_EXHAUSTIVE,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_AUTO,
    BBTestReadBlocksStressAutoTest
  },
  {
    BLOCK_IO_PROTOCOL_WRITEBLOCKS_STRESS_AUTO_GUID,
    L"WriteBlocks_Stress",
    L"Perform stress test on WriteBlocks",
    EFI_TEST_LEVEL_EXHAUSTIVE,
    gSupportProtocolGuid1,
    EFI_TEST_CASE_AUTO | EFI_TEST_CASE_DESTRUCTIVE,
    BBTestWriteBlocksStressAutoTest
  },
#endif

  0
};

EFI_BB_TEST_PROTOCOL *gBBTestProtocolInterface;

EFI_STATUS
EFIAPI
BBTestBlockIoProtocolUnload (
  IN EFI_HANDLE       ImageHandle
  );

//
// Entry Point Declaration
//

/**
 *  Block I/O Protocol Test Driver Entry point.
 *  @param ImageHandle the driver image handle.
 *  @param SystemTable the system table.
 *  @return EFI_SUCCESS the driver is loaded successfully.
 */
EFI_STATUS
EFIAPI
InitializeBBTestBlockIo (
  IN EFI_HANDLE           ImageHandle,
  IN EFI_SYSTEM_TABLE     *SystemTable
  )
{
  EfiInitializeTestLib (ImageHandle, SystemTable);
  SctInitializeLib (ImageHandle, SystemTable);

  gtBS->CreateEvent (EVT_TIMER, 0, (EFI_EVENT_NOTIFY) NULL, NULL, &TimerEvent);

  return EfiInitAndInstallBBTestInterface (
           &ImageHandle,
           &gBBTestProtocolField,
           gBBTestEntryField,
           BBTestBlockIoProtocolUnload,
           &gBBTestProtocolInterface
           );
}

/**
 *  The driver's Unload function.
 *  @param ImageHandle the test driver image handle.
 *  @return EFI_SUCCESS unload successfully.
 */
EFI_STATUS
EFIAPI
BBTestBlockIoProtocolUnload (
  IN EFI_HANDLE       ImageHandle
  )
{
  EFI_STATUS          Status;

  gtBS->CloseEvent (TimerEvent);

  Status = EfiUninstallAndFreeBBTestInterface (
             ImageHandle,
             gBBTestProtocolInterface
             );

  return Status;
}

/**
 *  assistant function to verify two buffer
 *  @param  Buffer1 first buffer
 *  @param  Buffer2 second buffer
 *  @param  BufferSize size of the buffer
 *  @return Count of the different byte of two buffers
*/
UINTN
VerifyBuffer (
  IN UINT8            *Buffer1,
  IN UINT8            *Buffer2,
  IN UINTN            BufferSize
  )
{
  UINTN               Loop;
  UINTN               Count;

  Count = 0;
  for (Loop = 0; Loop < BufferSize; Loop++) {
    if (Buffer1[Loop] != Buffer2[Loop]) {
      Count++;
    }
  }

  return Count;
}

/**
 *  assistant function to locate DevicePath Protocol from BlockIo Protocol
 *  @param  BlockIo protocol interface
 *  @param  DevicePath protocol interface
 *  @param  StandardLib protocol interface for record assertion point
 *  @return Status
*/
EFI_STATUS
LocateDevicePathFromBlockIo (
  IN EFI_BLOCK_IO_PROTOCOL                *BlockIo,
  IN EFI_DEVICE_PATH_PROTOCOL             **DevicePath,
  IN EFI_STANDARD_TEST_LIBRARY_PROTOCOL   *StandardLib
  )
{
  EFI_STATUS                Status;
  UINTN                     Index;
  UINTN                     NoHandles;
  EFI_HANDLE                *HandleBuffer;
  EFI_BLOCK_IO_PROTOCOL     *OtherBlockIo;

  //
  // Locate the Handle that the BlockIo interface is bound to
  //
  Status = gtBS->LocateHandleBuffer (
                   ByProtocol,
                   &gBlackBoxEfiBlockIoProtocolGuid,
                   NULL,
                   &NoHandles,
                   &HandleBuffer
                   );
  if (EFI_ERROR(Status) || (NoHandles == 0)) {
    StandardLib->RecordAssertion (
                   StandardLib,
                   EFI_TEST_ASSERTION_FAILED,
                   gTestGenericFailureGuid,
                   L"BS.LocateHandle - Locate Block IO protocol",
                   L"%a:%d:Status - %r, NoHandles - %d",
                   __FILE__,
                   (UINTN)__LINE__,
                   Status,
                   NoHandles
                   );
    return EFI_NOT_FOUND;
  }

  //
  // Find the exact handle that DiskIo bound to
  //
  for (Index = 0; Index < NoHandles; Index++) {
    Status = gtBS->HandleProtocol (
                     HandleBuffer[Index],
                     &gBlackBoxEfiBlockIoProtocolGuid,
                     (VOID **) &OtherBlockIo
                     );
    if (EFI_ERROR (Status)) {
      StandardLib->RecordAssertion (
                     StandardLib,
                     EFI_TEST_ASSERTION_FAILED,
                     gTestGenericFailureGuid,
                     L"BS.HandleProtocol - Locate Block IO protocol from handle",
                     L"%a:%d:Status - %r",
                     __FILE__,
                     (UINTN)__LINE__,
                     Status
                     );
      return Status;
    }

    if (OtherBlockIo == BlockIo) {
      break;
    }
  }

  if (Index >= NoHandles) {
    //
    // No Handle Found!!
    //
    return EFI_DEVICE_ERROR;
  }

  //
  // Locate the DevicePath Protocol bound to BlockIo Protocol
  //
  Status = gtBS->HandleProtocol (
                   HandleBuffer[Index],
                   &gEfiDevicePathProtocolGuid,
                   (VOID **) DevicePath
                   );
  if (EFI_ERROR(Status)) {
    StandardLib->RecordAssertion (
                   StandardLib,
                   EFI_TEST_ASSERTION_FAILED,
                   gTestGenericFailureGuid,
                   L"BS.HandleProtocol - Locate Device Path protocol from handle",
                   L"%a:%d:Status - %r",
                   __FILE__,
                   (UINTN)__LINE__,
                   Status
                   );
    return Status;
  }

  //
  // Free resource
  //
  Status = gtBS->FreePool (HandleBuffer);
  if (EFI_ERROR(Status)) {
    StandardLib->RecordAssertion (
                   StandardLib,
                   EFI_TEST_ASSERTION_FAILED,
                   gTestGenericFailureGuid,
                   L"BS.FreePool - Free handle buffer",
                   L"%a:%d:Status - %r",
                   __FILE__,
                   (UINTN)__LINE__,
                   Status
                   );
    return Status;
  }

  return EFI_SUCCESS;
}

/**
 *  assistant function to locate BlockIo Protocol from DevicePath Protocol
 *  @param  BlockIo protocol interface
 *  @param  DevicePath protocol interface
 *  @param  StandardLib protocol interface for record assertion point
 *  @return Status
*/
EFI_STATUS
LocateBlockIoFromDevicePath (
  IN EFI_BLOCK_IO_PROTOCOL                **BlockIo,
  IN EFI_DEVICE_PATH_PROTOCOL             *DevicePath,
  IN EFI_STANDARD_TEST_LIBRARY_PROTOCOL   *StandardLib
  )
{
  EFI_STATUS                Status;
  UINTN                     Index;
  UINTN                     NoHandles;
  EFI_HANDLE                *HandleBuffer;
  EFI_DEVICE_PATH_PROTOCOL  *OtherDevicePath;

  //
  // Locate the Handle that the DevicePath interface is bound to
  //
  Status = gtBS->LocateHandleBuffer (
                   ByProtocol,
                   &gEfiDevicePathProtocolGuid,
                   NULL,
                   &NoHandles,
                   &HandleBuffer
                   );
  if (EFI_ERROR(Status) || (NoHandles == 0)) {
    StandardLib->RecordAssertion (
                   StandardLib,
                   EFI_TEST_ASSERTION_FAILED,
                   gTestGenericFailureGuid,
                   L"BS.LocateHandle - Locate Device Path protocol",
                   L"%a:%d:Status - %r, NoHandles - %d",
                   __FILE__,
                   (UINTN)__LINE__,
                   Status,
                   NoHandles
                   );
    return EFI_NOT_FOUND;
  }

  //
  // Find the exact handle that DiskIo bound to
  //
  for (Index = 0; Index < NoHandles; Index++) {
    Status = gtBS->HandleProtocol (
                     HandleBuffer[Index],
                     &gEfiDevicePathProtocolGuid,
                     (VOID **) &OtherDevicePath
                     );
    if (EFI_ERROR (Status)) {
      StandardLib->RecordAssertion (
                     StandardLib,
                     EFI_TEST_ASSERTION_FAILED,
                     gTestGenericFailureGuid,
                     L"BS.HandleProtocol - Locate Device Path protocol from handle",
                     L"%a:%d:Status - %r",
                     __FILE__,
                     (UINTN)__LINE__,
                     Status
                     );
      return Status;
    }

    if (OtherDevicePath == DevicePath) {
      break;
    }
  }

  if (Index >= NoHandles) {
    //
    // No Handle Found!!
    //
    return EFI_DEVICE_ERROR;
  }

  //
  // Locate the BlockIo Protocol bound to DevicePath Protocol
  //
  Status = gtBS->HandleProtocol (
                   HandleBuffer[Index],
                   &gBlackBoxEfiBlockIoProtocolGuid,
                   (VOID **) BlockIo
                   );
  if (EFI_ERROR(Status)) {
    StandardLib->RecordAssertion (
                   StandardLib,
                   EFI_TEST_ASSERTION_FAILED,
                   gTestGenericFailureGuid,
                   L"BS.HandleProtocol - Locate Block IO protocol from handle",
                   L"%a:%d:Status - %r",
                   __FILE__,
                   (UINTN)__LINE__,
                   Status
                   );
    return Status;
  }

  //
  // Free resource
  //
  Status = gtBS->FreePool (HandleBuffer);
  if (EFI_ERROR(Status)) {
    StandardLib->RecordAssertion (
                   StandardLib,
                   EFI_TEST_ASSERTION_FAILED,
                   gTestGenericFailureGuid,
                   L"BS.FreePool - Free handle buffer",
                   L"%a:%d:Status - %r",
                   __FILE__,
                   (UINTN)__LINE__,
                   Status
                   );
    return Status;
  }

  return EFI_SUCCESS;
}

/**
 *  assistant function to auto judge the user's choice, correct or uncorrect?
 *  @param  Seconds time inteval
 *  @return TRUE/FALSE standing for correct/uncorrect choice respectively
*/
BOOLEAN
AutoJudge (
  IN  UINTN         Seconds,
  IN  BOOLEAN       Default,
  IN  CHAR16        *Message
  )
{
  EFI_STATUS              Status;
  EFI_EVENT               WaitList[2];
  UINTN                   WaitIndex;
  EFI_INPUT_KEY           Key;
  BOOLEAN                 PressYes;
  BOOLEAN                 IsWait;

  //
  // Set 1 second periodic timer
  //
  Status = gtBS->SetTimer (TimerEvent, TimerPeriodic, 10000000);

  //
  // Set up a wait list for a key and the timer
  //
  WaitList[0] = TimerEvent;
  WaitList[1] = gtST->ConIn->WaitForKey;

  PressYes = Default;
  IsWait   = TRUE;

  //
  // Wait for either
  //
  SctPrint (Message);

  while (IsWait) {
    if (Default) {
      SctPrint (L"\rYes/No?(Auto judge as Yes in %d seconds)", Seconds);
    } else {
      SctPrint (L"\rYes/No?(Auto judge as No in %d seconds)", Seconds);
    }

    Status = gtBS->WaitForEvent (2, WaitList, &WaitIndex);

    switch (WaitIndex) {
    case 0:
      Seconds--;
      if (Seconds <= 0) {
        //
        // To stop loop
        //
        IsWait = FALSE;
      }
      break;

    case 1:
      //
      // Read the key
      //
      Status = gtST->ConIn->ReadKeyStroke (gtST->ConIn, &Key);
      SctAPrint ((char*)(&Key.UnicodeChar));
      switch (Key.UnicodeChar) {
        case 'Y':
        case 'y':
          IsWait = FALSE;
          PressYes = TRUE;
          break;
        case 'N':
        case 'n':
          IsWait = FALSE;
          PressYes = FALSE;
          break;
        default :
          SctPrint (L"\n");
          break;
      }
      break;

    default:
      break;
    }
  }

  SctPrint (L"\r\n");

  //
  // Cancle periodic timer
  //
  Status = gtBS->SetTimer (TimerEvent, TimerCancel, 0);

  return PressYes;
}


/**
  Allocates a buffer of a certain pool type at a specified alignment.

  Allocates the number bytes specified by AllocationSize of a certain pool type with an alignment
  specified by Alignment.  The allocated buffer is returned.  If AllocationSize is 0, then a valid
  buffer of 0 size is returned.  If there is not enough memory at the specified alignment remaining
  to satisfy the request, then NULL is returned.
  If Alignment is not a power of two and Alignment is not zero, then ASSERT().

  @param  PoolType              The type of pool to allocate.
  @param  AllocationSize        The number of bytes to allocate.
  @param  Alignment             The requested alignment of the allocation.  Must be a power of two.                            If Alignment is zero, then byte alignment is used.
                                If Alignment is zero, then byte alignment is used.

  @return A pointer to the allocated buffer or NULL if allocation fails.

**/
VOID *
AllocateAlignedPool (
  IN EFI_MEMORY_TYPE  PoolType,
  IN UINTN            AllocationSize,
  IN UINTN            Alignment
  )
{
  EFI_STATUS  Status;
  VOID        *RawAddress;
  UINTN       AlignedAddress;
  UINTN       AlignmentMask;
  UINTN       OverAllocationSize;
  UINTN       RealAllocationSize;
  VOID        **FreePointer;

  //
  // Alignment must be a power of two or zero.
  //
  ASSERT ((Alignment & (Alignment - 1)) == 0);
  
  if (Alignment == 0) {
    AlignmentMask = Alignment;
  } else {
    AlignmentMask = Alignment - 1;
  }
  //
  // Calculate the extra memory size, over-allocate memory pool and get the aligned memory address. 
  //
  OverAllocationSize  = sizeof (RawAddress) + AlignmentMask;
  RealAllocationSize  = AllocationSize + OverAllocationSize;
  //
  // Make sure that AllocationSize plus OverAllocationSize does not overflow. 
  //
  ASSERT (RealAllocationSize > AllocationSize); 

  Status = (gtBS->AllocatePool) (PoolType, RealAllocationSize, &RawAddress);
  if (EFI_ERROR (Status)) {
    return NULL;
  }

  AlignedAddress      = ((UINTN) RawAddress + OverAllocationSize) & ~AlignmentMask;
  //
  // Save the original memory address just before the aligned address.
  //
  FreePointer         = (VOID **)(AlignedAddress - sizeof (RawAddress));
  *FreePointer        = RawAddress;

  return (VOID *) AlignedAddress;
}


/**
  Frees a buffer that was previously allocated with one of the aligned pool allocation functions 
  in the Memory Allocation Library.

  Frees the buffer specified by Buffer.  Buffer must have been allocated on a previous call to the
  aligned pool allocation services of the Memory Allocation Library.
  If Buffer was not allocated with an aligned pool allocation function in the Memory Allocation
  Library, then ASSERT().

  @param  Buffer                Pointer to the buffer to free.

  @return free aligned pool function status

**/
EFI_STATUS
FreeAlignedPool (
  IN VOID   *Buffer
  )
{
  VOID        *RawAddress;
  VOID        **FreePointer;
  EFI_STATUS  Status;

  //
  // Get the pre-saved original address in the over-allocate pool.
  //
  FreePointer = (VOID **)((UINTN) Buffer - sizeof (RawAddress));
  RawAddress  = *FreePointer;

  Status = (gtBS->FreePool) (RawAddress);

  return Status;
}

