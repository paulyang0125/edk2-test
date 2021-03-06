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
CaseGuid          7C06E40F-6665-44ca-88D2-BE801B61F458
CaseName          CnntOpening.Func1.Case10
CaseCategory      TCP
CaseDescription   {This item is to test the [EUT] correctly times out when     \
                   waiting a TCP connection to be established in SYN_SENT      \
                   state.}
################################################################################

Include TCP4/include/Tcp4.inc.tcl

proc CleanUpEutEnvironmentBegin {} {
  global RST
 
  UpdateTcpSendBuffer TCB -c $RST
  SendTcpPacket TCB
 
  DestroyTcb
  DelEntryInArpCache

  Tcp4ServiceBinding->DestroyChild "@R_Tcp4Handle, &@R_Status"
  GetAck
}

proc CleanUpEutEnvironmentEnd {} {
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

BeginLogPacket CnntOpening.Func1.Case10 "host $DEF_EUT_IP_ADDR and host        \
                                             $DEF_ENTS_IP_ADDR"

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                            R_Status
UINTN                            R_Tcp4Handle
UINTN                            R_Context

EFI_TCP4_ACCESS_POINT            R_Configure_AccessPoint
EFI_TCP4_OPTION                  R_Configure_ControlOption
EFI_TCP4_CONFIG_DATA             R_Configure_Tcp4ConfigData

EFI_TCP4_COMPLETION_TOKEN        R_Connect_CompletionToken
EFI_TCP4_CONNECTION_TOKEN        R_Connect_ConnectionToken

#
# Initialization of TCB related on OS side.
#
CreateTcb TCB $DEF_ENTS_IP_ADDR $DEF_ENTS_PRT $DEF_EUT_IP_ADDR $DEF_EUT_PRT

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
SetVar R_Configure_AccessPoint.UseDefaultAddress        FALSE
SetIpv4Address R_Configure_AccessPoint.StationAddress   $DEF_EUT_IP_ADDR
SetIpv4Address R_Configure_AccessPoint.SubnetMask       $DEF_EUT_MASK
SetVar R_Configure_AccessPoint.StationPort              $DEF_EUT_PRT
SetIpv4Address R_Configure_AccessPoint.RemoteAddress    $DEF_ENTS_IP_ADDR
SetVar R_Configure_AccessPoint.RemotePort               $DEF_ENTS_PRT
SetVar R_Configure_AccessPoint.ActiveFlag               TRUE
 
SetVar R_Configure_ControlOption.ReceiveBufferSize      4096
SetVar R_Configure_ControlOption.SendBufferSize         4096
SetVar R_Configure_ControlOption.MaxSynBackLog          0
SetVar R_Configure_ControlOption.ConnectionTimeout      60
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
RecordAssertion $assert $Tcp4CnntOpeningFunc1AssertionGuid010                  \
                "Tcp4.Connect - Open an active connection."                    \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# During 60 seconds, EUT should timeout following the sequence: 3, 6, 12, 24 ...
#
ReceiveTcpPacket TCB 5

if { ${TCB.received} == 1 } {
  if { ${TCB.r_f_syn} != 1 } {
    set assert fail
    puts "EUT doesn't send out SYN segment correctly."
    RecordAssertion $assert $GenericAssertionGuid                              \
                    "EUT doesn't send out SYN segment correctly."

    CleanUpEutEnvironmentBegin
    BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
    GetAck
    CleanUpEutEnvironmentEnd
    return
  }
} else {
  set assert fail
  puts "EUT doesn't send out any segment."
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "EUT doesn't send out any segment."

  CleanUpEutEnvironmentBegin
  BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
  GetAck
  CleanUpEutEnvironmentEnd
  return
}

UpdateTcpSendBuffer TCB -c $SYN
SendTcpPacket TCB

for {set i 0} {$i < 5} {incr i} {
  ReceiveTcpPacket TCB 25
 
  if { ${TCB.received} == 1 } {
    if { ${TCB.r_f_syn} != 1 || ${TCB.r_f_ack} != 1 } {
      set assert fail
      puts "EUT doesn't send out SYN/ACK segment correctly."
      RecordAssertion $assert $GenericAssertionGuid                            \
                      "EUT doesn't send out SYN/ACK segment correctly."

      CleanUpEutEnvironmentBegin
      BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
      GetAck
      CleanUpEutEnvironmentEnd
      return
    }
  } else {
    set assert fail
    puts "EUT doesn't send out any segment."
    RecordAssertion $assert $GenericAssertionGuid                              \
                    "EUT doesn't send out any segment."

    CleanUpEutEnvironmentBegin
    BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
    GetAck
    CleanUpEutEnvironmentEnd
    return
  }
}

#
# EUT should send out RST segment and return to CLOSED state.
#
ReceiveTcpPacket TCB 20

if { ${TCB.received} == 1 } {
  if { ${TCB.r_f_rst} != 1 } {
    set assert fail
    puts "EUT doesn't send out RST segment correctly."
    RecordAssertion $assert $GenericAssertionGuid                              \
                    "EUT doesn't send out RST segment correctly."

    CleanUpEutEnvironmentBegin
    BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
    GetAck
    CleanUpEutEnvironmentEnd
    return
  }
} else {
  set assert fail
  puts "EUT should send out RST but no segment sent out."
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "EUT should send out RST but no segment sent out."

  CleanUpEutEnvironmentBegin
  BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
  GetAck
  CleanUpEutEnvironmentEnd
  return
}

#
# Check the Token.Status to verify the connection has been timeouted.
#
while {1 > 0} {
  Stall 1
  GetVar R_Connect_ConnectionToken.CompletionToken.Status
 
  if { ${R_Connect_ConnectionToken.CompletionToken.Status} != $EFI_INCOMPATIBLE_VERSION} {
    if { ${R_Connect_ConnectionToken.CompletionToken.Status} != $EFI_TIMEOUT} {
      set assert fail
      puts "R_Connect_ConnectionToken.CompletionToken.Status is not EFI_TIMEOUT"
      RecordAssertion $assert $GenericAssertionGuid                            \
                      "CompletionToken.Status"                                 \
                      "ReturnStatus - ${R_Connect_ConnectionToken.CompletionToken.Status},\
                       ExpectedStatus - $EFI_TIMEOUT"

      CleanUpEutEnvironmentBegin
      BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
      GetAck
      CleanUpEutEnvironmentEnd
      return
    } else {
      break
    }
  }
}

#
# Clean up the environment on EUT side.
#
CleanUpEutEnvironmentBegin
BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
GetAck
CleanUpEutEnvironmentEnd
