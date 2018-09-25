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
CaseLevel         CONFORMANCE
CaseAttribute     AUTO
CaseVerboseLevel  DEFAULT 
set reportfile    report.csv

#
# test case Name, category, description, GUID...
#
CaseGuid        8393927C-3F6E-4174-89B9-64501865122F
CaseName        Transmit.Conf4.Case1
CaseCategory    Udp4
CaseDescription {Test the Transmit Conformance of UDP4 - Invoke Transmit() when\
                 there is no route to the destination network or address. The  \
                 return status should be EFI_NOT_FOUND.}
################################################################################

Include UDP4/include/Udp4.inc.tcl

#
# Begin log ...
#
BeginLog

#
# BeginScope
#
BeginScope _UDP4_TRANSMIT_CONFORMANCE4_CASE1_

set hostmac              [GetHostMac]
set targetmac            [GetTargetMac]
set targetip             192.168.88.1
set hostip               192.168.88.2
set subnetmask           255.255.255.0
set targetport           4000
set hostport             4000
set arg_destaddrss       172.16.220.3

VifUp 0 $hostip

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                            R_Status
UINTN                            R_Handle
EFI_UDP4_CONFIG_DATA             R_Udp4ConfigData
UINTN                            R_Context
EFI_UDP4_COMPLETION_TOKEN        R_Token
EFI_UDP4_TRANSMIT_DATA           R_TxData
EFI_UDP4_FRAGMENT_DATA           R_FragmentTable
CHAR8                            R_FragmentBuffer(600)
EFI_UDP4_SESSION_DATA            R_SessionData

Udp4ServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
SetVar   [subst $ENTS_CUR_CHILD]  @R_Handle
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Udp4SBP.Transmit - Conf - Create Child"                       \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetVar R_Udp4ConfigData.AcceptBroadcast             TRUE
SetVar R_Udp4ConfigData.AcceptPromiscuous           FALSE
SetVar R_Udp4ConfigData.AcceptAnyPort               TRUE
SetVar R_Udp4ConfigData.AllowDuplicatePort          TRUE
SetVar R_Udp4ConfigData.TypeOfService               0
SetVar R_Udp4ConfigData.TimeToLive                  1
SetVar R_Udp4ConfigData.DoNotFragment               TRUE
SetVar R_Udp4ConfigData.ReceiveTimeout              0
SetVar R_Udp4ConfigData.TransmitTimeout             0
SetVar R_Udp4ConfigData.UseDefaultAddress           FALSE
SetIpv4Address R_Udp4ConfigData.StationAddress      $targetip
SetIpv4Address R_Udp4ConfigData.SubnetMask          $subnetmask
SetVar R_Udp4ConfigData.StationPort                 $targetport
SetIpv4Address R_Udp4ConfigData.RemoteAddress       $arg_destaddrss
SetVar R_Udp4ConfigData.RemotePort                  $hostport

#
#check point
#
Udp4->Configure {&@R_Udp4ConfigData, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Udp4.Transmit - Conf - Config Child"                          \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
                                
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                 &@R_Token.Event, &@R_Status"
GetAck

SetVar         R_TxData.DataLength              21
SetVar         R_TxData.FragmentCount           1
SetVar         R_FragmentBuffer                 "UdpConfigureTest" 
SetVar         R_FragmentTable.FragmentBuffer   &@R_FragmentBuffer
SetVar         R_FragmentTable.FragmentLength   21
SetVar         R_TxData.FragmentTable           @R_FragmentTable
SetVar         R_TxData.UdpSessionData          0 
SetVar         R_TxData.GatewayAddress          0
SetVar         R_Token.Packet                   &@R_TxData

Udp4->Transmit {&@R_Token, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_NOT_FOUND]
RecordAssertion $assert $Udp4TransmitConf4AssertionGuid001                     \
                "Udp4.Transmit - Conf - Invoke Transmit() when there is no route\
                 to the destination network or address."                       \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_NOT_FOUND"
                              

Udp4ServiceBinding->DestroyChild {@R_Handle, &@R_Status}
GetAck

BS->CloseEvent "@R_Token.Event, &@R_Status"
GetAck

VifDown 0
#
# EndScope
#
EndScope _UDP4_TRANSMIT_CONFORMANCE4_CASE1_

#
# End Log
#
EndLog
