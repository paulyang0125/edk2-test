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
CaseGuid        4988EFC5-6EE2-472e-B823-3B4AEA4DC16F
CaseName        Configure.Func1.Case2
CaseCategory    MNP
CaseDescription {Test the Configure function of MNP - Call MNP.Configure()     \
	               with Unicast Broadcast disabled.}
################################################################################

Include MNP/include/Mnp.inc.tcl

#
# Begin log ...
#
BeginLog
BeginScope _MNP_CONFIGURE_FUNCTION1_CASE2_

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                            R_Status
UINTN                            R_Handle
EFI_MANAGED_NETWORK_CONFIG_DATA  R_MnpConfData

MnpServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Mnp.Configure - Create Child 1"                               \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Modify Configure Data: Disable Unicast Broadcast
#
SetMnpConfigData R_MnpConfData 0 0 0 FALSE TRUE FALSE FALSE FALSE FALSE FALSE 
Mnp->Configure "&@R_MnpConfData, &@R_Status"
GetAck
set assert  [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $MnpConfigureFunc1AssertionGuid002                     \
                "Mnp.Configure - Call Configure() when                         \
                disable Unicast Broadcast."                                    \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Destroy Child
#
MnpServiceBinding->DestroyChild {@R_Handle, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid "Mnp.Configure - Create Child 1" \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

EndScope _MNP_CONFIGURE_FUNCTION1_CASE2_

#
# End Log
#
EndLog
