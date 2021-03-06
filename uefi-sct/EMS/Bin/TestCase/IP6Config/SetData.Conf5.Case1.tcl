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
CaseGuid        1F1728C3-BB62-4f28-9D75-6E631F7A6833
CaseName        SetData.Conf5.Case1
CaseCategory    IP6Config
CaseDescription {SetData must not succeed when data size does not match the data type.}

################################################################################
Include IP6Config/Include/Ip6Config.inc.tcl


#
# Begin log ...
#
BeginLog

#
# BeginScope
#
BeginScope _IP6CONFIG_SETDATA_CONF5

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local ENTS Side Parameter"
#
UINTN                            R_Status
UINTN                            R_Context
UINTN                            R_DoneEvent
UINTN                            R_Ip6ConfigDataSize
UINT32                            R_Ip6ConfigDataType
EFI_IP6_CONFIG_INTERFACE_INFO    R_Ip6ConfigInterfaceInfo
EFI_IP6_CONFIG_INTERFACE_ID      R_Ip6ConfigInterfaceId
UINT32                            R_Ip6ConfigPolicy
EFI_IP6_CONFIG_DUP_ADDR_DETECT_TRANSMITS    R_Ip6ConfigDadTransmits

#
# Check Point: Call Ip6Config->SetData to set manual policy
#
SetVar R_Ip6ConfigDataType   $IP6CDT(Policy)
SetVar R_Ip6ConfigDataSize   [Sizeof UINT32]
SetVar R_Ip6ConfigPolicy     $IP6CP(Manual)

SetVar R_Context 0
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_NOTIFY, 1, &@R_Context,\
                &@R_DoneEvent, &@R_Status"
GetAck
set assert    [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                      \
                "BS.CreateEvent."                                      \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

Ip6Config->RegisterDataNotify "@R_Ip6ConfigDataType,@R_DoneEvent,&@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid     \
                "Ip6Config.RegisterDataNotify - Register notification event for configuration."    \
				"ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

Ip6Config->SetData "@R_Ip6ConfigDataType,@R_Ip6ConfigDataSize,&@R_Ip6ConfigPolicy,&@R_Status"
GetAck
GetVar R_Status
if { $R_Status == $EFI_SUCCESS } {
  set assert pass
  RecordAssertion $assert $GenericAssertionGuid                   \
                "Ip6Config.SetData - Call SetData to set manual policy."            \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
} elseif { $R_Status == $EFI_NOT_READY } {
  set i 0
  set L_TimeOut 30
  while { 1 > 0 } {
    GetVar R_Context
	if { $R_Context == 1 } {
		break
	} elseif { $i == $L_TimeOut } {
		set assert fail
		RecordAssertion $assert $GenericAssertionGuid         \
                      "SetData failed.(event hasn't been signaled before TIMEOUT)."      \
                      "TIMEOUT value is $L_TimeOut (sec), "
	       SetVar R_Ip6ConfigDataType   $IP6CDT(Policy)
		Ip6Config->UnregisterDataNotify "@R_Ip6ConfigDataType,@R_DoneEvent,&@R_Status"
		GetAck
		BS->CloseEvent {@R_DoneEvent,&@R_Status}
		GetAck
		EndScope _IP6CONFIG_SETDATA_CONF5
		EndLog
		return
	}
	incr i
	Stall 1
  }
} else {
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                   \
               "Ip6Config.SetData - Call SetData to set manual policy."            \
               "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

  SetVar R_Ip6ConfigDataType   $IP6CDT(Policy)
  Ip6Config->UnregisterDataNotify "@R_Ip6ConfigDataType,@R_DoneEvent,&@R_Status"
  GetAck
  BS->CloseEvent {@R_DoneEvent,&@R_Status}
  GetAck
  EndScope _IP6CONFIG_SETDATA_CONF5
  EndLog
  return
}

Ip6Config->GetData "@R_Ip6ConfigDataType,&@R_Ip6ConfigDataSize,&@R_Ip6ConfigPolicy,&@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid        \
                      "Ip6Config.GetData - Call GetData to get policy value."        \
                      "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
GetVar R_Ip6ConfigPolicy
if { $R_Ip6ConfigPolicy == $IP6CP(Manual) } {
  set assert pass
} else {
  set assert fail

  RecordAssertion $assert $GenericAssertionGuid        \
                      "Set manual policy succeeds(event is signaled correctly and data correct)."
  SetVar R_Ip6ConfigDataType   $IP6CDT(Policy)
  Ip6Config->UnregisterDataNotify "@R_Ip6ConfigDataType,@R_DoneEvent,&@R_Status"
  GetAck
  BS->CloseEvent {@R_DoneEvent,&@R_Status}
  GetAck
  EndScope _IP6CONFIG_SETDATA_CONF5
  EndLog
  return
}
RecordAssertion $assert $GenericAssertionGuid        \
                      "Set manual policy succeeds(event is signaled correctly and data correct)."

#
# Check Point : Set Manual Address with wrong data size
#
EFI_IP6_CONFIG_MANUAL_ADDRESS    R_Temp_Ip6ConfigManualAddress

set L_ManualListLen    1
EFI_IP6_CONFIG_MANUAL_ADDRESS    R_Ip6ConfigManualAddress
set L_UnitLen [Sizeof EFI_IP6_CONFIG_MANUAL_ADDRESS]
set L_ListLen [expr {$L_UnitLen * $L_ManualListLen}]
SetVar R_Ip6ConfigDataType   $IP6CDT(ManualAddress)
SetVar R_Ip6ConfigDataSize   16
SetVar R_Temp_Ip6ConfigManualAddress.IsAnycast FALSE
SetVar R_Temp_Ip6ConfigManualAddress.PrefixLength 64
SetIpv6Address R_Temp_Ip6ConfigManualAddress.Address "2002::5000"
SetVar R_Ip6ConfigManualAddress @R_Temp_Ip6ConfigManualAddress

Ip6Config->SetData "@R_Ip6ConfigDataType,@R_Ip6ConfigDataSize,&@R_Ip6ConfigManualAddress,&@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_BAD_BUFFER_SIZE]
RecordAssertion $assert $Ip6ConfigSetDataConf5AssertionGuid001                   \
                "Ip6Config.SetData - Call SetData to set manual address with wrong data size."            \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_BAD_BUFFER_SIZE"
DelVar R_Ip6ConfigManualAddress

#
# Check Points : Set Gateway with wrong data size
#
set L_GatewayListLen   1
EFI_IPv6_ADDRESS                 R_Temp_Ip6ConfigGateway
EFI_IPv6_ADDRESS                 R_Ip6ConfigGateway
set L_UnitLen [Sizeof EFI_IPv6_ADDRESS]
set L_ListLen [expr {$L_UnitLen * $L_GatewayListLen}]
SetVar R_Ip6ConfigDataType   $IP6CDT(Gateway)
SetVar R_Ip6ConfigDataSize   8

SetIpv6Address R_Temp_Ip6ConfigGateway "2002::5001"
SetVar R_Ip6ConfigGateway @R_Temp_Ip6ConfigGateway
Ip6Config->SetData "@R_Ip6ConfigDataType,@R_Ip6ConfigDataSize,&@R_Ip6ConfigGateway,&@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_BAD_BUFFER_SIZE]
RecordAssertion $assert $Ip6ConfigSetDataConf5AssertionGuid002                   \
                "Ip6Config.SetData - Call SetData to set gateway with wrong data size."            \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_BAD_BUFFER_SIZE"

DelVar R_Ip6ConfigGateway

#
# Check Point : Set Dns Server with wrong data size
#
set L_DnsServerListLen 1
EFI_IPv6_ADDRESS                 R_Temp_Ip6ConfigDnsServer
EFI_IPv6_ADDRESS                 R_Ip6ConfigDnsServer
set L_UnitLen [Sizeof EFI_IPv6_ADDRESS]
set L_ListLen [expr {$L_UnitLen * $L_DnsServerListLen}]
SetVar R_Ip6ConfigDataType   $IP6CDT(DnsServer)
SetVar R_Ip6ConfigDataSize   8

SetIpv6Address R_Temp_Ip6ConfigDnsServer "2002::5002"
SetVar R_Ip6ConfigDnsServer @R_Temp_Ip6ConfigDnsServer

Ip6Config->SetData "@R_Ip6ConfigDataType,@R_Ip6ConfigDataSize,&@R_Ip6ConfigDnsServer,&@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_BAD_BUFFER_SIZE]
RecordAssertion $assert $Ip6ConfigSetDataConf5AssertionGuid003                   \
                "Ip6Config.SetData - Call SetData to set dns server with wrong data size."            \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_BAD_BUFFER_SIZE"

DelVar R_Ip6ConfigDnsServer

#
# Check Point : Set Altlfld with wrong data size
#
SetVar R_Ip6ConfigDataType   $IP6CDT(AltInterfaceId)
SetVar R_Ip6ConfigDataSize   1

Ip6Config->SetData "@R_Ip6ConfigDataType,@R_Ip6ConfigDataSize,&@R_Ip6ConfigInterfaceId,&@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_BAD_BUFFER_SIZE]
RecordAssertion $assert $Ip6ConfigSetDataConf5AssertionGuid004                   \
                "Ip6Config.SetData - Call SetData to set Altlfld with wrong data size."            \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_BAD_BUFFER_SIZE"

#
# Check Point : Set DadXmits with wrong data size
#
SetVar R_Ip6ConfigDataType   $IP6CDT(DupAddrDetectTransmits)
SetVar R_Ip6ConfigDataSize   1
SetVar R_Ip6ConfigDadTransmits.DupAddrDetectTransmits   3

Ip6Config->SetData "@R_Ip6ConfigDataType,@R_Ip6ConfigDataSize,&@R_Ip6ConfigDadTransmits,&@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_BAD_BUFFER_SIZE]
RecordAssertion $assert $Ip6ConfigSetDataConf5AssertionGuid005                   \
                "Ip6Config.SetData - Call SetData to set DadXmits with wrong data size."            \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_BAD_BUFFER_SIZE"
				
#
# Check Point : Set Policy with wrong data size
#
SetVar R_Ip6ConfigDataType   $IP6CDT(Policy)
SetVar R_Ip6ConfigDataSize   1
SetVar R_Ip6ConfigPolicy     $IP6CP(Manual)

Ip6Config->SetData "@R_Ip6ConfigDataType,@R_Ip6ConfigDataSize,&@R_Ip6ConfigPolicy,&@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_BAD_BUFFER_SIZE]
RecordAssertion $assert $Ip6ConfigSetDataConf5AssertionGuid006                   \
                "Ip6Config.SetData - Call SetData to set Policy with wrong data size."            \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_BAD_BUFFER_SIZE"
				
#
# Clean up
#
SetVar R_Ip6ConfigDataType   $IP6CDT(Policy)
Ip6Config->UnregisterDataNotify "@R_Ip6ConfigDataType,@R_DoneEvent,&@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid     \
                "Ip6Config.UnregisterDataNotify - Unregister notification event for configuration."    \
				"ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
				
BS->CloseEvent {@R_DoneEvent,&@R_Status}
GetAck

EndScope _IP6CONFIG_SETDATA_CONF5

EndLog