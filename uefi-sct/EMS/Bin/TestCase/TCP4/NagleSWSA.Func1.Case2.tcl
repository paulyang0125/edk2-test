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
CaseGuid          B7C1390A-A6B1-4127-8669-D10ECEFF1EDA
CaseName          NagleSWSA.Func1.Case2
CaseCategory      TCP
CaseDescription   {This item is to test the [EUT] correctly disables the Nagle \
                   Algorithm, when retransmission happens, the accumulated     \
                   small segments should be sent out together.                 \
                   Note: Currently re-packetization is not implemented.}
################################################################################

Include TCP4/include/Tcp4.inc.tcl

proc CleanUpEutEnvironment {} {
  global RST
 
  UpdateTcpSendBuffer TCB -c $RST
  SendTcpPacket TCB
 
  DestroyTcb
  DelEntryInArpCache

  Tcp4ServiceBinding->DestroyChild "@R_Tcp4Handle, &@R_Status"
  GetAck

  BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
  GetAck
  BS->CloseEvent "@R_Transmit_CompletionToken1.Event, &@R_Status"
  GetAck
  BS->CloseEvent "@R_Transmit_CompletionToken2.Event, &@R_Status"
  GetAck

  EndLogPacket
  EndScope _TCP4_RFC_COMPATIBILITY_
  EndLog
}

#
# Begin log ...
#
BeginLog

#
# BeginScope on OS.
#
BeginScope _TCP4_RFC_COMPATIBILITY_

BeginLogPacket NagleSWSA.Func1.Case2   "host $DEF_EUT_IP_ADDR and host         \
                                             $DEF_ENTS_IP_ADDR"

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
set    L_FragmentLength          1

UINTN                            R_Status
UINTN                            R_Tcp4Handle
UINTN                            R_Context

EFI_TCP4_ACCESS_POINT            R_Configure_AccessPoint
EFI_TCP4_OPTION                  R_Configure_ControlOption
EFI_TCP4_CONFIG_DATA             R_Configure_Tcp4ConfigData

EFI_TCP4_COMPLETION_TOKEN        R_Connect_CompletionToken
EFI_TCP4_CONNECTION_TOKEN        R_Connect_ConnectionToken

EFI_TCP4_IO_TOKEN                R_Transmit_IOToken1
EFI_TCP4_COMPLETION_TOKEN        R_Transmit_CompletionToken1
EFI_TCP4_IO_TOKEN                R_Transmit_IOToken2
EFI_TCP4_COMPLETION_TOKEN        R_Transmit_CompletionToken2

Packet                           R_Packet_Buffer
EFI_TCP4_TRANSMIT_DATA           R_TxData
EFI_TCP4_FRAGMENT_DATA           R_FragmentTable
CHAR8                            R_FragmentBuffer($L_FragmentLength)

#
# Initialization of TCB related on OS side.
#
CreateTcb TCB $DEF_ENTS_IP_ADDR $DEF_ENTS_PRT $DEF_EUT_IP_ADDR $DEF_EUT_PRT
BuildTcpOptions MssOption -m 256

LocalEther  $DEF_ENTS_MAC_ADDR
RemoteEther $DEF_EUT_MAC_ADDR
LocalIp     $DEF_ENTS_IP_ADDR
RemoteIp    $DEF_EUT_IP_ADDR

#
# Add an entry in ARP cache.
#
AddEntryInArpCache

#
# Create Tcp4 Child.
#
Tcp4ServiceBinding->CreateChild "&@R_Tcp4Handle, &@R_Status"
GetAck
SetVar     [subst $ENTS_CUR_CHILD]  @R_Tcp4Handle
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp4SBP.CreateChild - Create Child 1."                        \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Configure TCP instance.
#
SetVar R_Configure_AccessPoint.UseDefaultAddress      FALSE
SetIpv4Address R_Configure_AccessPoint.StationAddress $DEF_EUT_IP_ADDR
SetIpv4Address R_Configure_AccessPoint.SubnetMask     $DEF_EUT_MASK
SetVar R_Configure_AccessPoint.StationPort            $DEF_EUT_PRT
SetIpv4Address R_Configure_AccessPoint.RemoteAddress  $DEF_ENTS_IP_ADDR
SetVar R_Configure_AccessPoint.RemotePort             $DEF_ENTS_PRT
SetVar R_Configure_AccessPoint.ActiveFlag             TRUE

SetVar R_Configure_ControlOption.ReceiveBufferSize      4096
SetVar R_Configure_ControlOption.SendBufferSize         4096
SetVar R_Configure_ControlOption.MaxSynBackLog          0
SetVar R_Configure_ControlOption.ConnectionTimeout      20
SetVar R_Configure_ControlOption.DataRetries            0
SetVar R_Configure_ControlOption.FinTimeout             0
SetVar R_Configure_ControlOption.KeepAliveProbes        0
SetVar R_Configure_ControlOption.KeepAliveTime          0
SetVar R_Configure_ControlOption.KeepAliveInterval      0
SetVar R_Configure_ControlOption.EnableNagle            FALSE
SetVar R_Configure_ControlOption.EnableTimeStamp        FALSE
SetVar R_Configure_ControlOption.EnableWindowScaling    FALSE
SetVar R_Configure_ControlOption.EnableSelectiveAck     FALSE
SetVar R_Configure_ControlOption.EnablePathMtuDiscovery FALSE

SetVar R_Configure_Tcp4ConfigData.TypeOfService      0
SetVar R_Configure_Tcp4ConfigData.TimeToLive         128
SetVar R_Configure_Tcp4ConfigData.AccessPoint        @R_Configure_AccessPoint
SetVar R_Configure_Tcp4ConfigData.ControlOption      &@R_Configure_ControlOption

Tcp4->Configure {&@R_Configure_Tcp4ConfigData, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp4.Configure - Configure Child 1."                          \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Call Tcp4.Connect for an active TCP instance.
#
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                 &@R_Connect_CompletionToken.Event, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.CreateEvent."                                              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetVar R_Connect_ConnectionToken.CompletionToken @R_Connect_CompletionToken
SetVar R_Connect_ConnectionToken.CompletionToken.Status $EFI_INCOMPATIBLE_VERSION

Tcp4->Connect {&@R_Connect_ConnectionToken, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp4.Connect - Open an active connection."                    \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Handles the three-way handshake.
#
ReceiveTcpPacket TCB 5

set L_TcpFlag [expr $SYN | $ACK]
UpdateTcpSendBuffer TCB -c $L_TcpFlag -o MssOption -w 257
SendTcpPacket TCB

ReceiveTcpPacket TCB 5

#
# Call Tcp4.Transmit to transmit a small segment.
#
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                 &@R_Transmit_CompletionToken1.Event, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.CreateEvent."                                              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                 &@R_Transmit_CompletionToken2.Event, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.CreateEvent."                                              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetVar R_TxData.Push                      FALSE
SetVar R_TxData.Urgent                    FALSE
SetVar R_TxData.DataLength                $L_FragmentLength
SetVar R_TxData.FragmentCount             1

SetVar R_FragmentTable.FragmentLength     $L_FragmentLength
SetVar R_FragmentTable.FragmentBuffer     &@R_FragmentBuffer
SetVar R_TxData.FragmentTable(0)          @R_FragmentTable

SetVar R_Packet_Buffer.TxData  &@R_TxData

SetVar R_Transmit_IOToken1.CompletionToken @R_Transmit_CompletionToken1
SetVar R_Transmit_IOToken1.Packet_Buffer   @R_Packet_Buffer

SetVar R_Transmit_IOToken2.CompletionToken @R_Transmit_CompletionToken2
SetVar R_Transmit_IOToken2.Packet_Buffer   @R_Packet_Buffer

Tcp4->Transmit {&@R_Transmit_IOToken1, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp4.Transmit - Transmit a packet."                           \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Call Tcp4.Transmit to transmit another small packet.
#
Tcp4->Transmit {&@R_Transmit_IOToken2, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $Tcp4NagleSWSAFunc1AssertionGuid002                    \
                "Tcp4.Transmit - Transmit a packet."                           \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# OS get the transmitted data packet.
# Nagle is disabled, so the two "small" segments should be sent out immediately.
#
set expected_r_seq 0
set expected_r_len 1
for { set i 0} { $i < 2 } { incr i } {
  ReceiveTcpPacket TCB 2
  if { ${TCB.received} == 1 } {
    if { ${TCB.r_f_ack} != 1 } {
      set assert fail
      RecordAssertion $assert $GenericAssertionGuid                            \
                      "EUT doesn't send out the data segment correctly."
      CleanUpEutEnvironment
      return
    } else {
        set expected_r_seq [expr $expected_r_seq + 1]
        if { ${TCB.r_seq} != $expected_r_seq || ${TCB.r_ack} != 1} {
          set assert fail
          RecordAssertion $assert $GenericAssertionGuid                        \
                          "The sequence number or acknowledge number of the data\
                           segment is not correct."
          CleanUpEutEnvironment
          return
        }
        if { ${TCB.r_len} != $expected_r_len } {
         	set assert fail
          RecordAssertion $assert $GenericAssertionGuid                        \
                          "The data length of the data segment is not correct."
          CleanUpEutEnvironment
          return
        }
      }
    set assert pass
    RecordAssertion $assert $GenericAssertionGuid                              \
                    "The EUT send out the data segment correctly."
  } else {
    set assert fail
    RecordAssertion $assert $GenericAssertionGuid                              \
                    "EUT doesn't send out any segment."
    CleanUpEutEnvironment
    return
  }
}

#
# Wait for the data retransmission, the two small data segments should be sent
# out seperately during retransmission.
#
ReceiveTcpPacket TCB 5
if { ${TCB.received} == 1 } {
  if { ${TCB.r_f_ack} != 1 } {
    set assert fail
    RecordAssertion $assert $GenericAssertionGuid                              \
                    "EUT doesn't retransmit the data segment correctly."
    CleanUpEutEnvironment
    return
  } else {
      if { ${TCB.r_seq} != 1 || ${TCB.r_ack} != 1} {
        set assert fail
        RecordAssertion $assert $GenericAssertionGuid                          \
                        "The sequence number or acknowledge number of          \
                         the retransmitted data segment is incorrect."
        CleanUpEutEnvironment
        return
      }
      if { ${TCB.r_len} != 1 } {
       	set assert fail
        RecordAssertion $assert $GenericAssertionGuid                          \
                        "The data length of the retransmitted data segment is  \
                         not correct."
        CleanUpEutEnvironment
        return
      }
    }
  set assert pass
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "The EUT retransmit the data segment correctly."
} else {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "EUT doesn't send out any segment."
  CleanUpEutEnvironment
  return
}

UpdateTcpSendBuffer TCB -c $ACK
SendTcpPacket TCB

ReceiveTcpPacket TCB 5
if { ${TCB.received} == 1 } {
  if { ${TCB.r_f_ack} != 1 } {
    set assert fail
    RecordAssertion $assert $GenericAssertionGuid                              \
                    "EUT doesn't retransmit the data segment correctly."
    CleanUpEutEnvironment
    return
  } else {
      if { ${TCB.r_seq} != 2 || ${TCB.r_ack} != 1} {
        set assert fail
        RecordAssertion $assert $GenericAssertionGuid                          \
                        "The sequence number or acknowledge number of the      \
                         retransmitted data segment is incorrect."
        CleanUpEutEnvironment
        return
      }
      if { ${TCB.r_len} != 1 } {
       	set assert fail
        RecordAssertion $assert $GenericAssertionGuid                          \
                        "The data length of the retransmitted data segment is not\
                         correct."
        CleanUpEutEnvironment
        return
      }
    }
  set assert pass
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "The EUT retransmit the data segment correctly."
} else {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "EUT doesn't send out any segment."
  CleanUpEutEnvironment
  return
}

UpdateTcpSendBuffer TCB -c $ACK
SendTcpPacket TCB

#
# Clean up the environment on EUT side.
#
CleanUpEutEnvironment
