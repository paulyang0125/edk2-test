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
CaseGuid        04310b5b-df5c-40fa-84c1-e44dd8543278
CaseName        RenewRebind.Conf1.Case1
CaseCategory    DHCP4
CaseDescription {This case is to test the Conformance - EFI_NOT_STARTED        \
	              -- This driver instance is in the Dhcp4Stopped state.}

################################################################################

Include DHCP4/include/Dhcp4.inc.tcl

proc CleanUpEutEnvironment {} {
  Dhcp4ServiceBinding->DestroyChild "@R_Handle, &@R_Status"
  GetAck

  BS->CloseEvent "@R_Event, &@R_Status"
  GetAck

  EndScope _DHCP4_RENEWREBIND_CONF1
  EndLog
}

#
# Begin log ...
#
BeginLog
BeginScope  _DHCP4_RENEWREBIND_CONF1

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                            R_Status
UINTN                            R_Handle
UINTN                            R_Event
UINTN                            R_Context

#
# Call [DHCP4SBP] -> CreateChild to create child.
#
Dhcp4ServiceBinding->CreateChild {&@R_Handle, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Dhcp4SBP.CreateChild - Create Child 1"                        \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle

#
# Call [DHCP4] -> RenewRebind to extend lease time.
#
BS->CreateEvent "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_Context,        \
                &@R_Event, &@R_Status"
GetAck
set assert    [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "BS.CreateEvent."                                              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Check Point: Call Dhcp4.Start while the instance is in the Dhcp4Stopped state.
# o RebindRequest = TRUE
#
Dhcp4->RenewRebind  "TRUE, @R_Event, &@R_Status"
GetAck
set assert    [VerifyReturnStatus R_Status $EFI_NOT_STARTED]
RecordAssertion $assert $Dhcp4RenewRebindConf1AssertionGuid001                 \
                "Dhcp4.RenewRebind - Start DHCP4 RenewRebind process when in   \
                the Dhcp4Stopped state"                                        \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_NOT_STARTED"

#
# Check Point: Call Dhcp4.Start while the instance is in the Dhcp4Stopped state.
# o RebindRequest = FALSE
#
Dhcp4->RenewRebind  "FALSE, @R_Event, &@R_Status"
GetAck
set assert    [VerifyReturnStatus R_Status $EFI_NOT_STARTED]
RecordAssertion $assert $Dhcp4RenewRebindConf1AssertionGuid001                 \
                "Dhcp4.RenewRebind - Start DHCP4 RenewRebind process when in   \
                the Dhcp4Stopped state"                                        \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_NOT_STARTED"

#
# Call Dhcp4->Stop to stop the driver
#
Dhcp4->Stop "&@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Dhcp4.Stop - Stop Driver."                                    \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Clean up the environment on EUT side.
#
CleanUpEutEnvironment
