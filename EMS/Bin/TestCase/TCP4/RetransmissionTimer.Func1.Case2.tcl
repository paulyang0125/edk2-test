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
CaseGuid          7AAC41B4-3A6D-4895-97B8-B70224F8AB0B
CaseName          RetransmissionTimer.Func1.Case2
CaseCategory      TCP
CaseDescription   {This case is to test the [EUT] correctly close connection   \
                   when retransmission timer time out. }
################################################################################

Include TCP4/include/Tcp4.inc.tcl

proc CleanUpEutEnvironmentBegin {} {
#
# send RST segment to [EUT]
#
  global RST
  UpdateTcpSendBuffer TCB -c $RST
  SendTcpPacket  TCB
 
  DestroyTcb
  DestroyPacket R_Packet_Buffer
  DelEntryInArpCache
 
  Tcp4ServiceBinding->DestroyChild "@R_Handle, &@R_Status"
  GetAck
 
}

proc CleanUpEutEnvironmentEnd {} {
  EndLogPacket
  EndScope _TCP4_RFC_Timer_Retransmission
  EndLog
}

#
# Begin log...
#
BeginLog

#
# Begin Scope
#
BeginScope _TCP4_RFC_Timer_Retransmission
BeginLogPacket Timer.Retransmission.Func1.case2 "host $DEF_EUT_IP_ADDR and host\
                                               $DEF_ENTS_IP_ADDR"

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                            R_Status
UINTN                            R_Handle
UINTN                            R_Context
 
EFI_TCP4_CONFIG_DATA             R_Configure_Tcp4ConfigData
EFI_TCP4_ACCESS_POINT            R_Configure_AccessPoint
EFI_TCP4_OPTION                  R_Configure_ControlOption
 
EFI_TCP4_CONNECTION_TOKEN        R_Connect_ConnectionToken
EFI_TCP4_COMPLETION_TOKEN        R_Connect_CompletionToken

EFI_TCP4_COMPLETION_TOKEN        R_Transmit_CompletionToken
EFI_TCP4_IO_TOKEN                R_Transmit_IOToken

set    L_FragmentLength          16

Packet                           R_Packet_Buffer
EFI_TCP4_TRANSMIT_DATA           R_TxData
EFI_TCP4_FRAGMENT_DATA           R_FragmentTable
CHAR8                            R_FragmentBuffer($L_FragmentLength)

SetVar R_FragmentBuffer          "hahahahahahahah"

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
# Create TCP CHILD
#
Tcp4ServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp4SBP.CreateChild - Create Child 1"                         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Configure TCP instance
#
 
SetVar          R_Configure_AccessPoint.UseDefaultAddress  FALSE
SetIpv4Address  R_Configure_AccessPoint.StationAddress     $DEF_EUT_IP_ADDR
SetIpv4Address  R_Configure_AccessPoint.SubnetMask         $DEF_EUT_MASK
SetVar          R_Configure_AccessPoint.StationPort        $DEF_EUT_PRT
SetIpv4Address  R_Configure_AccessPoint.RemoteAddress      $DEF_ENTS_IP_ADDR
SetVar          R_Configure_AccessPoint.RemotePort         $DEF_ENTS_PRT
SetVar          R_Configure_AccessPoint.ActiveFlag         TRUE

SetVar R_Configure_ControlOption.ReceiveBufferSize      4096
SetVar R_Configure_ControlOption.SendBufferSize         4096
SetVar R_Configure_ControlOption.MaxSynBackLog          0
SetVar R_Configure_ControlOption.ConnectionTimeout      0
SetVar R_Configure_ControlOption.DataRetries            8
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
#  Control 3way handshake
#
ReceiveTcpPacket TCB  3
if { ${TCB.received} == 1 } {
   if { ${TCB.r_f_syn} !=1 }  {
     set assert fail
     puts "EUT doesn't send out SYN segment correctly."
     RecordAssertion $assert $GenericAssertionGuid                             \
                     "EUT doesn't send out SYN segment correctly."

     CleanUpEutEnvironmentBegin
     BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
     GetAck
     CleanUpEutEnvironmentEnd
     return
}
} else {
   set assert fail
   puts "EUT doesn't send out SYN segment ."
   RecordAssertion $assert $GenericAssertionGuid                               \
                   "EUT doesn't send out SYN segment . "

   CleanUpEutEnvironmentBegin
   BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
   GetAck
   CleanUpEutEnvironmentEnd
   return

}

set L_TCPFlage [expr $SYN | $ACK]
UpdateTcpSendBuffer TCB -C $L_TCPFlage 
SendTcpPacket TCB


ReceiveTcpPacket TCB 3
if { ${TCB.received} == 1 } {
   if { ${TCB.r_f_ack}!=1 }  {
     set assert fail
     puts "EUT doesn't send out ACK segment correctly."
     RecordAssertion $assert $GenericAssertionGuid                             \
                     "EUT doesn't send out ACK segment correctly."

     CleanUpEutEnvironmentBegin
     BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
     GetAck
     CleanUpEutEnvironmentEnd
     return    
 }    
} else {
   set assert fail
   puts "EUT doesn't send out SYN segment correctly."
   RecordAssertion $assert $GenericAssertionGuid                               \
                   "EUT doesn't send out SYN segment correctly . "

   CleanUpEutEnvironmentBegin
   BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
   GetAck
   CleanUpEutEnvironmentEnd
   return
	
}
#
# Call Tcp4.Trasmit to make [EUT] send segment to [OS]
#

BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                &@R_Transmit_CompletionToken.Event, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.CreateEvent."                                              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetVar R_TxData.Push                       FALSE
SetVar R_TxData.Urgent                     FALSE
SetVar R_TxData.DataLength                 $L_FragmentLength  
SetVar R_TxData.FragmentCount              1

SetVar R_FragmentTable.FragmentBuffer      &@R_FragmentBuffer
SetVar R_FragmentTable.FragmentLength      $L_FragmentLength
SetVar R_TxData.FragmentTable(0)           @R_FragmentTable


SetVar R_Packet_Buffer.TxData              &@R_TxData

SetVar R_Transmit_IOToken.CompletionToken  @R_Transmit_CompletionToken
SetVar R_Transmit_IOToken.Packet_Buffer    @R_Packet_Buffer


Tcp4->Transmit {&@R_Transmit_IOToken, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Tcp4.Transmit - Transmit a packet."                           \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
#
# CheckPoint: does [EUT] correctly retransmit 
#
set i 1
set count 0                
while {$i > 0} {
ReceiveTcpPacket TCB 1
if {${TCB.received} == 1} {
     if { ${TCB.r_f_ack}!=1 || ${TCB.r_len} != 16 }  {
     } else {
      incr count
      if {$count == 8} {
      	set i 0 
        } 
  } 
 } 
}
Stall 10


set L_TCPFlage [expr $ACK]
UpdateTcpSendBuffer TCB -C $L_TCPFlage 
SendTcpPacket TCB


ReceiveTcpPacket TCB 20
if { ${TCB.received} == 1 } {
     if {${TCB.r_f_rst} != 1}  {
      set assert fail
      puts "[EUT] not correctly performs retransmission timer ."
      RecordAssertion $assert $Tcp4RetransmissionTimerFunc1AssertionGuid002    \
                      "[EUT] not correctly performs retransmission timer."

      CleanUpEutEnvironmentBegin
      BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
      GetAck
      BS->CloseEvent "@R_Transmit_CompletionToken.Event, &@R_Status"
      GetAck
      CleanUpEutEnvironmentEnd
      return 
   }
 }
 
#
# CleanUpEutEnvironmentEnd
#

CleanUpEutEnvironmentBegin
BS->CloseEvent "@R_Connect_CompletionToken.Event, &@R_Status"
GetAck
BS->CloseEvent "@R_Transmit_CompletionToken.Event, &@R_Status"
GetAck
CleanUpEutEnvironmentEnd
