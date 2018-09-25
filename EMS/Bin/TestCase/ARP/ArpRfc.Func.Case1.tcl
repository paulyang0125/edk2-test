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
CaseVerboseLevel  default

#
# test case Name, category, description, GUID...
#
CaseGuid        67C85B8D-8F49-4c86-95C1-E3BFAE4EAE44
CaseName        ArpRfc.Func.Case1
CaseCategory    ARP
CaseDescription {This case is to test the RFC function of ARP.}
################################################################################

proc CleanUpEutEnvironment {} {
  Arp->Delete {TRUE, NULL, &@R_Status}
  GetAck

  Arp->Delete {FALSE, NULL, &@R_Status}
  GetAck
 
  ArpServiceBinding->DestroyChild {@R_Handle, &@R_Status}
  GetAck
 
  EndCapture
  EndScope _ARP_FUNC_CONFORMANCE_
  VifDown 0
  EndLog
}

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
SetVar R_ArpConfigData.RetryCount      30
SetVar R_ArpConfigData.RetryTimeOut    5000000

#
# Check point
#
Arp->Configure {&@R_ArpConfigData, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Arp.Configure - Config Child 1"                               \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

set L_Filter "ether proto \\arp and src host 172.16.210.102"
StartCapture CCB $L_Filter

#
# Send ARP request
#
LocalEther  00:02:03:04:05:07
RemoteEther ff:ff:ff:ff:ff:ff
LocalIp     172.16.210.161
RemoteIp    172.16.210.102

CreatePayload ReqPktPayload const 18 0x0
CreatePacket ArpReqPkt -t arp -arp_op 1 -arp_tha 00:00:00:00:00:00 -arp_payload\
              ReqPktPayload

SendPacket ArpReqPkt

ReceiveCcbPacket CCB ReqReplyPkt 10
if { ${CCB.received} == 0} {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Arp.Reply - Send Reply"                                     \
                  "Packet not captured"
  
  CleanUpEutEnvironment
  return
}

set assert pass
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Arp.Reply - Send Reply"                                       \
                "Send Reply packet"

DumpPacket ReqReplyPkt
ValidatePacket ReqReplyPkt -t arp "(arp_hrd=1)AND(arp_pro=0x0800)AND(arp_hln=6)\
                          AND(arp_pln=4)AND(arp_op=2)AND(arp_sha=$targetmac)AND\
                          (arp_spa=172.16.210.102)AND(arp_tha=00:02:03:04:05:07)\
                           AND(arp_tpa=172.16.210.161)"
if {[string compare -nocase $EMS_RESULT "TRUE"] == 0} {
  set assert pass
} else {
  set assert fail
}
RecordAssertion $assert $ArpRfcFuncAssertionGuid001                            \
                 "Arp - check packet field"

CleanUpEutEnvironment