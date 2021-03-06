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

#
# test case Name, category, description, GUID...
#
CaseGuid           6231D7C6-F61C-4d6b-94C4-C6FC7359B6E2
CaseName           Transmit.Conf7.Case1
CaseCategory       TCP6
CaseDescription    {This case is to test the conformance - EFI_ACCESS_DENIED.     \
                   -- Transmit must not succeed when event has already been queued     \
                      Two Points to make sure the circumstance occurs:     \
                      1. EUTS send chunk of data larger than MSS     \
                      2. ENTS provide NO ack back to data fragments     }
################################################################################

Include Tcp6/include/Tcp6.inc.tcl

proc CleanUpEUTEnvironmentBegin {} {
  #
  # Destroy TCP6 child
  #
  Tcp6ServiceBinding->DestroyChild "@R_Handle, &@R_Status"
  GetAck
  
  #
  # Close transmittion mechanism for EUT
  #
  EUTClose

}

proc CleanUpEUTEnvironmentEnd {} {

  DestroyPacket
  EndCapture
  EndScope _TCP6_TRANSMIT_CONF7_CASE1_
  EndLog
}

#
# Begin log ...
#
BeginLog

#
# BeginScope
#
BeginScope _TCP6_TRANSMIT_CONF7_CASE1_

#EUTSetup

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                            R_Status
UINTN                            R_Handle
UINTN                            R_Context

EFI_TCP6_ACCESS_POINT            R_Configure_AccessPoint
EFI_TCP6_CONFIG_DATA             R_Configure_Tcp6ConfigData

EFI_TCP6_COMPLETION_TOKEN        R_Connect_CompletionToken
EFI_TCP6_CONNECTION_TOKEN        R_Connect_ConnectionToken

EFI_TCP6_IO_TOKEN                R_Transmit_IOToken1
EFI_TCP6_IO_TOKEN                R_Transmit_IOToken2
EFI_TCP6_COMPLETION_TOKEN        R_Transmit_CompletionToken1
EFI_TCP6_COMPLETION_TOKEN        R_Transmit_CompletionToken2

set  L_FragmentLength1           4096
set  L_FragmentLength2           64
Packet                           R_Packet_Buffer1
Packet                           R_Packet_Buffer2

EFI_TCP6_TRANSMIT_DATA           R_TxData1
EFI_TCP6_TRANSMIT_DATA           R_TxData2
EFI_TCP6_FRAGMENT_DATA           R_FragmentTable1
EFI_TCP6_FRAGMENT_DATA           R_FragmentTable2
CHAR8                            R_FragmentBuffer1($L_FragmentLength1)
CHAR8                            R_FragmentBuffer2($L_FragmentLength2)

EUTSetup

#
# Create Child for TCP6 protocol
#
Tcp6ServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp6SBP.CreateChild - Create Child"                         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
               
#
# Configure Tcp6 Instance
#
SetIpv6Address  R_Configure_AccessPoint.StationAddress     $DEF_EUT_IP_ADDR
SetVar          R_Configure_AccessPoint.StationPort        $DEF_EUT_PRT
SetIpv6Address  R_Configure_AccessPoint.RemoteAddress      $DEF_ENTS_IP_ADDR
SetVar          R_Configure_AccessPoint.RemotePort         $DEF_ENTS_PRT
SetVar          R_Configure_AccessPoint.ActiveFlag         TRUE


SetVar R_Configure_Tcp6ConfigData.TrafficClass        0
SetVar R_Configure_Tcp6ConfigData.HopLimit            128
SetVar R_Configure_Tcp6ConfigData.AccessPoint         @R_Configure_AccessPoint
SetVar R_Configure_Tcp6ConfigData.ControlOption       0

Tcp6->Configure {&@R_Configure_Tcp6ConfigData, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                \
                "Tcp6.Configure - Call Configure() with valid config data"         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Tcp6.Connect() for an active TCP instance
#
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                 &@R_Connect_CompletionToken.Event, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.CreateEvent."                                              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetVar R_Connect_ConnectionToken.CompletionToken @R_Connect_CompletionToken

#
# Start Capture
#
set L_Filter "ether src $DEF_EUT_MAC_ADDR and tcp"
StartCapture CCB $L_Filter
#
# Setup the packet sending parameters
#
LocalIPv6           $DEF_ENTS_IP_ADDR
RemoteIPv6          $DEF_EUT_IP_ADDR
LocalEther          $DEF_ENTS_MAC_ADDR
RemoteEther         $DEF_EUT_MAC_ADDR

Tcp6->Connect {&@R_Connect_ConnectionToken, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp6.Connect - Open an active connection."      \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Handle Three-Way Shake
#

#
# EUT : SYN
#
ReceiveCcbPacket CCB L_Packet 5
if { ${CCB.received} == 0} {    
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                \
                  "TCP6.Connect - No SYN sent."
  BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
  GetAck
  CleanUpEUTEnvironmentBegin
  CleanUpEUTEnvironmentEnd
  return
}

ParsePacket L_Packet -t IPv6 -IPv6_payload L_Tcp6Packet
set L_Flag [lrange $L_Tcp6Packet 13 13]
set L_Flag [expr {$L_Flag & 0x37}]
set L_Flag [format "%#04x" $L_Flag]
if {[string compare $L_Flag $SYN] != 0} {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid  \
                  "Tcp6.Connect - No SYN sent."
  BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
  GetAck
  CleanUpEUTEnvironmentBegin
  CleanUpEUTEnvironmentEnd
  return
}
#
# ENTS : SYN | ACK
#
set L_PortDst [lrange $L_Tcp6Packet 0 1]
set L_PortDst [Hex2Dec $L_PortDst]
set L_PortSrc [lrange $L_Tcp6Packet 2 3]
set L_PortSrc [Hex2Dec $L_PortSrc]
set L_Seq     [lrange $L_Tcp6Packet 4 7]
set L_AckAck  [expr {[Hex2Dec $L_Seq]+1}]
set L_Ack     [lrange $L_Tcp6Packet 8 11]
set L_SeqAck  0 
set L_FlagAck [expr {$SYN | $ACK}]

CreatePayload L_TcpOption Data 8 0x02 0x04 0x05 0xa0 0x01 0x03 0x03 0x06
CreatePacket P_Tcp6PacketAck -t tcp -tcp_sp $L_PortSrc -tcp_dp $L_PortDst -tcp_control $L_FlagAck -tcp_seq $L_SeqAck -tcp_options L_TcpOption -IP_ver 0x06 -tcp_ack $L_AckAck
SendPacket P_Tcp6PacketAck -c 1

#
# EUT : ACK
#
ReceiveCcbPacket CCB L_Packet 5
if { ${CCB.received} == 0} {    
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                \
                  "TCP6.Connect - No ACK sent."
  BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
  GetAck
  CleanUpEUTEnvironmentBegin
  CleanUpEUTEnvironmentEnd
  return
}

ParsePacket L_Packet -t IPv6 -IPv6_payload L_Tcp6Packet
set L_Flag [lrange $L_Tcp6Packet 13 13]
set L_Flag [expr {$L_Flag & 0x37}]
set L_Flag [format "%#04x" $L_Flag]
if {[string compare $L_Flag $ACK] != 0} {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid  \
                  "Tcp6.Connect - No ACK sent."
  BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
  GetAck
  CleanUpEUTEnvironmentBegin
  CleanUpEUTEnvironmentEnd
  return
}

#
# Check Point: Call Tcp6.Transmit() to transmit a partial packet,
#              with valid parameter.
#
SetVar R_TxData1.Push                      FALSE
SetVar R_TxData1.Urgent                    FALSE
SetVar R_TxData1.DataLength                $L_FragmentLength1
SetVar R_TxData1.FragmentCount           1

SetVar R_FragmentTable1.FragmentLength     $L_FragmentLength1
SetVar R_FragmentTable1.FragmentBuffer     &@R_FragmentBuffer1
SetVar R_TxData1.FragmentTable(0)          @R_FragmentTable1

SetVar R_Packet_Buffer1.TxData             &@R_TxData1

BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                 &@R_Transmit_CompletionToken1.Event, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.CreateEvent."                                              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
SetVar R_Transmit_CompletionToken1.Status  $EFI_INCOMPATIBLE_VERSION
SetVar R_Transmit_IOToken1.CompletionToken @R_Transmit_CompletionToken1
SetVar R_Transmit_IOToken1.Packet_Buffer   @R_Packet_Buffer1

Tcp6->Transmit {&@R_Transmit_IOToken1, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                     \
                "Tcp6.Transmit - Call Transmit() to send a partial packet with valid parameter."     \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

ReceiveCcbPacket CCB L_Packet 5
if { ${CCB.received} == 0} {    
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                \
                  "TCP6.Transmit - No partial package sent."
  BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
  GetAck
  BS->CloseEvent {@R_Transmit_CompletionToken1.Event, &@R_Status}
  GetAck
  CleanUpEUTEnvironmentBegin
  CleanUpEUTEnvironmentEnd
  return
}
ParsePacket L_Packet -t tcp -tcp_control L_Flag
set L_Flag [format "%#04x" $L_Flag]
if {[string compare $L_Flag $ACK] != 0} {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid  \
                  "Tcp6.Transmit-Transmit a partial packet"  \
                  "No ACK back"
  BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
  GetAck
  BS->CloseEvent {@R_Transmit_CompletionToken1.Event, &@R_Status}
  GetAck
  CleanUpEUTEnvironmentBegin
  CleanUpEUTEnvironmentEnd
  return
}

#
# Check Point: Check whether the transmit event is signaled or not
#
GetVar R_Transmit_CompletionToken1.Status
if { ${R_Transmit_CompletionToken1.Status} != $EFI_INCOMPATIBLE_VERSION} {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                             \
                  "Data transmission should NOT be success.                \
                  ReturnStatus - ${R_Transmit_CompletionToken1.Status},\
                  ExpectedStatus - $EFI_INCOMPATIBLE_VERSION"

  BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
  GetAck
  BS->CloseEvent {@R_Transmit_CompletionToken1.Event, &@R_Status}
  GetAck
  CleanUpEutEnvironmentBegin
  CleanUpEutEnvironmentEnd
  return
}


#
# Check Point: Call Tcp6.Transmit() to transmit a packet,
#              with event has already been queued.
#
set L_TCPTransmitPayload2 "2222222222222222"
SetVar R_TxData2.Push                      FALSE
SetVar R_TxData2.Urgent                    FALSE
SetVar R_TxData2.DataLength                $L_FragmentLength2
SetVar R_TxData2.FragmentCount           1

SetVar R_FragmentBuffer2                   $L_TCPTransmitPayload2
SetVar R_FragmentTable2.FragmentLength     $L_FragmentLength2
SetVar R_FragmentTable2.FragmentBuffer     &@R_FragmentBuffer2
SetVar R_TxData2.FragmentTable(0)          @R_FragmentTable2

SetVar R_Packet_Buffer2.TxData             &@R_TxData2

SetVar R_Transmit_CompletionToken2.Event  @R_Transmit_CompletionToken1.Event
SetVar R_Transmit_IOToken2.CompletionToken @R_Transmit_CompletionToken2
SetVar R_Transmit_IOToken2.Packet_Buffer   @R_Packet_Buffer2

Tcp6->Transmit {&@R_Transmit_IOToken2, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_ACCESS_DENIED]
RecordAssertion $assert $Tcp6TransmitConf7AssertionGuid001                     \
                "Tcp6.Transmit - Call Transmit() with event has already been queued."     \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_ACCESS_DENIED"

#
# Clean Up
#
CleanUpEUTEnvironmentBegin
#
# Close Event for Pending Transmition in the Queue
#
BS->CloseEvent {@R_Transmit_CompletionToken1.Event, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.DestroyEvent. "                         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
#
# Close Event for Connection
#
BS->CloseEvent {@R_Connect_CompletionToken.Event, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.DestroyEvent. "                         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
#CleanUpEUTEnvironmentBegin
CleanUpEUTEnvironmentEnd
