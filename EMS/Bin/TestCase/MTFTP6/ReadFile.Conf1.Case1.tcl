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
CaseGuid        6AF17BE0-C8EE-4233-897A-A3B967314E72
CaseName        ReadFile.Conf1.Case1
CaseCategory    MTFTP6
CaseDescription {Test ReadFile conformance of MTFTP6,invoke ReadFile() when the \
                 instance hasn't been configured.EFI_NOT_STARTED should be returned.
                }
################################################################################

Include MTFTP6/include/Mtftp6.inc.tcl
#
# Begin log ...
#
BeginLog

BeginScope _MTFTP6_READFILE_CONFORMANCE1_CASE1_

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local ENTS Side Parameter"
#
UINTN                            R_Status
UINTN                            R_Handle

#
# Create child
#
Mtftp6ServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Mtftp6SB.CreateChild - Create Child 1"                       \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle

#
# Check Point: Call ReadFile when the instance hasn't been configured.\
#              EFI_NOT_STARTED should be returned.
# 
EFI_MTFTP6_TOKEN                  R_Token

SetVar R_Token.Status             $EFI_SUCCESS
SetVar R_Token.Event              0
SetVar R_Token.OverrideData       0
CHAR8                             R_NameOfFile(20)
SetVar R_NameOfFile               "Shell.efi"
SetVar R_Token.Filename           &@R_NameOfFile
SetVar R_Token.ModeStr            0
SetVar R_Token.OptionCount        0
SetVar R_Token.OptionList         0
SetVar R_Token.BufferSize         0
SetVar R_Token.Buffer             0
SetVar R_Token.Context            0

Mtftp6->ReadFile "&@R_Token, 1, 1, 1, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_NOT_STARTED]
RecordAssertion $assert $Mtftp6ReadFileConf1AssertionGuid001                 \
                "Mtftp6.ReadFile -Conf- Call ReadFile when the instance hasn't been configured"   \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_NOT_STARTED"

#
# Destroy Child
#
Mtftp6ServiceBinding->DestroyChild "@R_Handle, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                   \
                "Mtftp6SBP.DestroyChild - Destroy Child 1"                 \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

EndScope _MTFTP6_READFILE_CONFORMANCE1_CASE1_

#
# End Log
#
EndLog
