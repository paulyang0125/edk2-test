# 
#  Copyright 2006 - 2010 Unified EFI, Inc.<BR> 
#  Copyright (c) 2010, Intel Corporation. All rights reserved.<BR>
# 
#  This program and the accompanying materials
#  are licensed and made available under the terms and conditions of the BSD License
#  which accompanies this distribution.  The full text of the license may be found at 
#  http://opensource.org/licenses/bsd-license.php
# 
#  THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
#  WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.
# 
################################################################################
CaseLevel         FUNCTION
CaseAttribute     AUTO
CaseVerboseLevel  DEFAULT

#
# test case Name, category, description, GUID...
#
CaseGuid        AFABB617-14CF-4663-9286-A881F11C39FE
CaseName        Find.Func3.Case1
CaseCategory    ARP
CaseDescription {This case is to test the function of ARP.Find}
################################################################################

#
# Begin log ...
#
BeginLog

Include ARP/include/Arp.inc.tcl

set hostmac    [GetHostMac]
set targetmac  [GetTargetMac]

VifUp 0 172.16.210.162 255.255.255.0
BeginScope _ARP_FUNC_CONFORMANCE_

UINTN                            R_Status
UINTN                            R_Handle
EFI_IP_ADDRESS                   R_StationAddress
EFI_ARP_CONFIG_DATA              R_ArpConfigData
EFI_IP_ADDRESS                   R_TargetSwAddress
EFI_MAC_ADDRESS                  R_TargetHwAddress
EFI_IP_ADDRESS                   R_IpAddressBuffer
EFI_MAC_ADDRESS                  R_MacAddressBuffer
UINT32                           R_EntryLength
UINT32                           R_EntryCount
POINTER                          R_EntriesPtr

ArpServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "ArpSBP.CreateChild - Create Child 1"                          \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetIpv4Address R_StationAddress.v4     "172.16.210.102"
SetVar R_ArpConfigData.SwAddressType   0x800
SetVar R_ArpConfigData.SwAddressLength 4
SetVar R_ArpConfigData.StationAddress  &@R_StationAddress
SetVar R_ArpConfigData.EntryTimeOut    0
SetVar R_ArpConfigData.RetryCount      0
SetVar R_ArpConfigData.RetryTimeOut    0

Arp->Configure {&@R_ArpConfigData, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Arp.Configure - Config Child 1"                               \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetIpv4Address R_TargetSwAddress.v4 "172.16.210.161"
SetEthMacAddress R_TargetHwAddress "00:02:03:04:05:06"
SetVar R_IpAddressBuffer @R_TargetSwAddress
SetVar R_MacAddressBuffer @R_TargetHwAddress

Arp->Add {FALSE, &@R_TargetSwAddress, &@R_TargetHwAddress, 500000000, TRUE,    \
	        &@R_Status}
GetAck

set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Arp.Add - Add normal entry"                                   \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetIpv4Address R_TargetSwAddress.v4 "172.16.210.160"
SetEthMacAddress R_TargetHwAddress "00:02:03:04:05:06"
SetVar R_IpAddressBuffer @R_TargetSwAddress
SetVar R_MacAddressBuffer @R_TargetHwAddress

Arp->Add {FALSE, &@R_TargetSwAddress, &@R_TargetHwAddress, 500000000, TRUE,    \
	         &@R_Status}
GetAck

set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Arp.Add - Add normal entry"                                   \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
#
# stall for the entry timeout, this time these entries in the arp cache is still
# valid (20s < 50s)
#
Stall 20

#
# Check Point
#
Arp->Find {FALSE, &@R_MacAddressBuffer, &@R_EntryLength, &@R_EntryCount,       \
	        &@R_EntriesPtr, TRUE, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $ArpFindFuncAssertionGuid005                           \
                "Arp.Find - Find the entry with refresh"                       \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

GetVar R_EntryCount
set assert pass
if {$R_EntryCount != 0x2} {
  set assert fail
}
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Arp.Find - Check the entry"                                   \
                 EntryCount - $R_EntryCount, ExpectedCount - 0x2"

if {$R_EntryCount > 0x0} {
	BS->FreePool {@R_EntriesPtr, &@R_Status}
  GetAck
}

#
# stall for the entry timeout, this time these entries in the arp cache is still
# valid after refreshment (35s < 50s)
#
Stall 35

SetIpv4Address R_TargetSwAddress.v4 "172.16.210.161"
SetEthMacAddress R_TargetHwAddress "00:02:03:04:05:06"
SetVar R_IpAddressBuffer @R_TargetSwAddress
SetVar R_MacAddressBuffer @R_TargetHwAddress

#
# Check point
#
Arp->Find {FALSE, &@R_MacAddressBuffer, &@R_EntryLength, &@R_EntryCount,       \
	            &@R_EntriesPtr, FALSE, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $ArpFindFuncAssertionGuid006                           \
                "Arp.Find - Find the entry without refresh"                    \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

GetVar R_EntryCount
set assert pass
if {$R_EntryCount != 0x2} {
  set assert fail
}
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Arp.Find - Check the entry"                                   \
                 EntryCount - $R_EntryCount, ExpectedCount - 0x2"

if {$R_EntryCount > 0x0} {
	BS->FreePool {@R_EntriesPtr, &@R_Status}
  GetAck
}

#
# stall for the entry timeout, this time these entries in the arp cache is 
# invalid (20s > (50-35)s)
#
Stall 20

SetIpv4Address R_TargetSwAddress.v4 "172.16.210.161"
SetEthMacAddress R_TargetHwAddress "00:02:03:04:05:06"
SetVar R_IpAddressBuffer @R_TargetSwAddress
SetVar R_MacAddressBuffer @R_TargetHwAddress

#
# Check point
#
Arp->Find {FALSE, &@R_MacAddressBuffer, &@R_EntryLength, &@R_EntryCount,       \
	          &@R_EntriesPtr, FALSE, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_NOT_FOUND]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Arp.Find - Find the entry without refresh"                    \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_NOT_FOUND"

Arp->Delete {TRUE, NULL, &@R_Status}
GetAck

Arp->Delete {FALSE, NULL, &@R_Status}
GetAck

ArpServiceBinding->DestroyChild {@R_Handle, &@R_Status}
GetAck

EndScope _ARP_FUNC_CONFORMANCE_
VifDown 0

#
# End Log
#
EndLog
