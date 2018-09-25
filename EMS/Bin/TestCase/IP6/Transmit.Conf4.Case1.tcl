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
CaseLevel          CONFORMANCE
CaseAttribute      AUTO
CaseVerboseLevel   DEFAULT
set reportfile     report.csv

#
# Test Case Name, Category, Description, GUID ...
#
CaseGuid           E59F42F1-9A76-4c72-91D2-24D757B5E46F
CaseName           Transmit.Conf4.Case1
CaseCategory       IP6
CaseDescription    { Test the Transmit Function of IP6 - invoke Transmit()                      \
                     when Token->Packet.TxData is NULL.EFI_INVALID_PARAMETER should be returned.   
                   }
################################################################################

Include IP6/include/Ip6.inc.tcl

#
# Begin  log ...
#
BeginLog
#
# Begin Scope ...
#
BeginScope        _IP6_TRANSMIT_CONF4_CASE1_

# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                             R_Status
UINTN                             R_Handle 

#
# Create Child
#
Ip6ServiceBinding->CreateChild    "&@R_Handle, &@R_Status"
GetAck
set assert       [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion  $assert $GenericAssertionGuid               \
                 "Ip6SB->CreateChild - Conf - Create Child "             \
                 "ReturnStatus -$R_Status, ExpectedStatus -$EFI_SUCCESS"
SetVar  [subst $ENTS_CUR_CHILD]    @R_Handle

EFI_IP6_CONFIG_DATA                R_Ip6ConfigData
SetVar R_Ip6ConfigData.DefaultProtocol                0x11;        #Next Header: UDP
SetVar R_Ip6ConfigData.AcceptAnyProtocol              FALSE
SetVar R_Ip6ConfigData.AcceptIcmpErrors               TRUE
SetVar R_Ip6ConfigData.AcceptPromiscuous              FALSE
SetIpv6Address R_Ip6ConfigData.DestinationAddress     "::"
SetIpv6Address R_Ip6ConfigData.StationAddress         "::"
SetVar R_Ip6ConfigData.TrafficClass                   0
SetVar R_Ip6ConfigData.HopLimit                       64
SetVar R_Ip6ConfigData.FlowLabel                      0
SetVar R_Ip6ConfigData.ReceiveTimeout                 50000
SetVar R_Ip6ConfigData.TransmitTimeout                50000

#
# Configure Child with valid parameters
#
Ip6->Configure  "&@R_Ip6ConfigData, &@R_Status"
GetAck
set assert      [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                \
                "Ip6->Configure - Conf - Configure Child  "               \
                "ReturnStatus -$R_Status, ExpectedStatus -$EFI_SUCCESS"

EFI_IP6_COMPLETION_TOKEN                     R_Token
UINTN                                        R_NotifyContext
SetVar           R_NotifyContext             0

#
# Create an Event
#
BS->CreateEvent  "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_NotifyContext, &@R_Token.Event, &@R_Status"
GetAck
set assert       [VerifyReturnStatus  R_Status  $EFI_SUCCESS]
RecordAssertion  $assert          $GenericAssertionGuid           \
                 "BS->CreateEvent -Conf- Create an Event "                  \
                 "ReturnStatus -$R_Status, ExpectedStatus -$EFI_SUCCESS"

SetVar               R_Token.Status          "$EFI_SUCCESS"

EFI_IP6_TRANSMIT_DATA                        R_TxData
SetVar               R_TxData                0
SetVar               R_Token.Packet          &@R_TxData

#
# Check point:Call Transmit Function when Token->Packet.TxData is NULL.EFI_INVALID_PARAMETER should be returned.
#
Ip6->Transmit        " &@R_Token, &@R_Status"
GetAck
set assert           [VerifyReturnStatus  R_Status  $EFI_INVALID_PARAMETER]
RecordAssertion      $assert           $Ip6TransmitConf4AssertionGuid001            \
                     "Ip6->Transmit -Conf- Call the function Transmit  with Token->Packet.TxData is NULL " \
                     "ReturnStatus -$R_Status, ExpectedStatus -$EFI_INVALID_PARAMETER" 

#
# Destroy Child 
#
Ip6ServiceBinding->DestroyChild "@R_Handle, &@R_Status"
GetAck
set      assert   [VerifyReturnStatus  R_Status $EFI_SUCCESS]
RecordAssertion   $assert  $GenericAssertionGuid                 \
                  "Ip6SB->DestroyChild - Conf - Destroy Child"              \
                  "RetrunStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
#
# Close Event
#
BS->CloseEvent    "@R_Token.Event, &@R_Status"
GetAck
set assert         [VerifyReturnStatus   R_Status   $EFI_SUCCESS]
RecordAssertion    $assert     $GenericAssertionGuid             \
                   "BS->CloseEvent -Conf- Close the Event we created before"  \
                   "ReturnStatus -$R_Status, ExpectedStatus -$EFI_SUCCESS"

#
# End scope
#
EndScope          _IP6_TRANSMIT_CONF4_CASE1_
#
# End log
#
EndLog
