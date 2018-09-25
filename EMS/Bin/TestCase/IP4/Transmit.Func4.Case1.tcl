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
set reportfile    report.csv

#
# test case Name, category, description, GUID...
#
CaseGuid        8AC2AA72-A456-4355-B2C2-B077F7CE82AC
CaseName        Transmit.Func4.Case1
CaseCategory    IP4
CaseDescription {Test the Transmit Function of IP4 - Invoke Transmit() to      \
                 transmit a packet when TxData.FragmentCount set as 4 and      \
                 IpConfigData.DoNotFragment set as TRUE.}
################################################################################

Include IP4/include/Ip4.inc.tcl

proc CleanUpEutEnvironment {} {
  Ip4ServiceBinding->DestroyChild {@R_Handle, &@R_Status}
  GetAck

  BS->CloseEvent "@R_Token.Event, &@R_Status"
  GetAck

  DestroyPacket
  EndCapture
  
  VifDown 0
  
  EndScope _IP4_TRANSMIT_FUNCTION4_CASE1_
  
  EndLog
}

#
# Begin log ...
#
BeginLog

#
# BeginScope
#
BeginScope _IP4_TRANSMIT_FUNCTION4_CASE1_

set hostmac    [GetHostMac]
set targetmac  [GetTargetMac]

VifUp 0 172.16.210.162 255.255.255.0

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                            R_Status
UINTN                            R_Handle
EFI_IP4_CONFIG_DATA              R_IpConfigData
UINTN                            R_Context
EFI_IP4_COMPLETION_TOKEN         R_Token
EFI_IP4_TRANSMIT_DATA_P4         R_TxData
EFI_IP4_FRAGMENT_DATA            R_FragmentTable
CHAR8                            R_FragmentBuffer(1600)

Ip4ServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Ip4SBP.Transmit - Func - Create Child"                        \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetVar R_IpConfigData.DefaultProtocol            0
SetVar R_IpConfigData.AcceptAnyProtocol          TRUE
SetVar R_IpConfigData.AcceptIcmpErrors           TRUE
SetVar R_IpConfigData.AcceptBroadcast            TRUE
SetVar R_IpConfigData.AcceptPromiscuous          TRUE
SetVar R_IpConfigData.UseDefaultAddress          FALSE
SetIpv4Address R_IpConfigData.StationAddress     "172.16.210.102"
SetIpv4Address R_IpConfigData.SubnetMask         "255.255.255.0"
SetVar R_IpConfigData.TypeOfService              0
SetVar R_IpConfigData.TimeToLive                 16
SetVar R_IpConfigData.DoNotFragment              TRUE
SetVar R_IpConfigData.RawData                    FALSE
SetVar R_IpConfigData.ReceiveTimeout             0
SetVar R_IpConfigData.TransmitTimeout            0

#
# check point
#
Ip4->Configure {&@R_IpConfigData, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Ip4.Transmit - Func - Config Child"                           \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                 &@R_Token.Event, &@R_Status"
GetAck

SetIpv4Address R_TxData.DestinationAddress   "172.16.210.162"
SetVar R_TxData.TotalDataLength              80
SetVar R_TxData.FragmentCount                4

SetVar R_FragmentBuffer                      "IpConfigureTest"
SetVar R_FragmentTable.FragmentLength        20
SetVar R_FragmentTable.FragmentBuffer        &@R_FragmentBuffer
SetVar R_TxData.FragmentTable(0)             @R_FragmentTable
SetVar R_TxData.FragmentTable(1)             @R_FragmentTable
SetVar R_TxData.FragmentTable(2)             @R_FragmentTable
SetVar R_TxData.FragmentTable(3)             @R_FragmentTable

SetVar R_Token.Packet                        &@R_TxData

#
# create an arp repquest packet to add an arp record in the EFI arp cache
#
CreatePacket arprepquest -t arp -arp_hrd 0x01 -arp_pro 0x0800 -arp_hln 6       \
	          -arp_pln 4 -arp_op 0x0001 -arp_sha $hostmac -arp_spa 172.16.210.162\
	           -arp_tha 0:0:0:0:0:0 -arp_tpa 172.16.210.102

SendPacket   arprepquest

set L_Filter "ip and host 172.16.210.102"
StartCapture CCB $L_Filter

Ip4->Transmit {&@R_Token, &@R_Status}

ReceiveCcbPacket CCB aaa 10
if { ${CCB.received} == 0} {
  GetAck
  GetVar R_Status
  GetVar R_Token.Status
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Ip4.Transmit - Func - Transmit a packet"                    \
                  "Packet not captured, R_Status - $R_Status, R_Token.Status - \
                  ${R_Token.Status}"

  CleanUpEutEnvironment

  return
}

GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Ip4.Transmit - Func - Transmit a packet"                      \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

GetVar R_Token.Status
if {${R_Token.Status} == $EFI_SUCCESS} {
  set assert pass
} else {
  set assert fail
}
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Ip4.Transmit - Func - check R_Token"                          \
                "ReturnStatus - ${R_Token.Status}, ExpectedStatus - $EFI_SUCCESS"

GetVar R_Context
if {$R_Context == 1} {
  set assert pass
} else {
  set assert fail
}
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Ip4.Transmit - Func - check Event"                            \
                "Return R_Context - $R_Context, Expected R_Context - 1"

DumpPacket    aaa
ParsePacket aaa -t eth -eth_src ETH_SRC
puts $ETH_SRC
ValidatePacket aaa -t ip "(ipv4_ver=4)AND(ipv4_ihl=5)AND(ipv4_tos=0)AND        \
                          (ipv4_frag=0x4000)AND(ipv4_ttl=16)AND(ipv4_prot=0)AND\
                          (ipv4_src=172.16.210.102)AND(ipv4_dst=172.16.210.162)"
if {[string compare -nocase $EMS_RESULT "TRUE"] == 0} {
  set assert pass
} else {
  set assert fail
}
RecordAssertion $assert $Ip4TransmitFunc4AssertionGuid001                      \
                        "Ip4.Transmit - Func - check packet field"

CleanUpEutEnvironment
