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
CaseGuid        03861C43-B98C-45ad-8160-2F25CEACE40D
CaseName        ReadFile.Conf7.Case1
CaseCategory    MTFTP6
CaseDescription {Test ReadFile conformance of MTFTP6,invoke ReadFile() when\
                 ServerIP in OverrideData is an invalid unicast address.\
                 EFI_INVALID_PARAMETER should be returned.
                }
################################################################################

Include MTFTP6/include/Mtftp6.inc.tcl
#
# Begin log ...
#
BeginLog

BeginScope _MTFTP6_READFILE_CONFORMANCE7_CASE1_

EUTSetup

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
# Check Point: Call Configure function with valid parameters. 
#              EFI_SUCCESS should be returned.
#
EFI_MTFTP6_CONFIG_DATA      R_Mtftp6ConfigData
SetIpv6Address    R_Mtftp6ConfigData.StationIp         "2002::4321" 
SetVar            R_Mtftp6ConfigData.LocalPort         1780
SetIpv6Address    R_Mtftp6ConfigData.ServerIp          "2002::2"
SetVar            R_Mtftp6ConfigData.InitialServerPort 0
SetVar            R_Mtftp6ConfigData.TryCount          3
SetVar            R_Mtftp6ConfigData.TimeoutValue      3

Mtftp6->Configure "&@R_Mtftp6ConfigData, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                 \
                "Mtftp6.Configure -conf- Call Configure with valid parameters"  \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Check Point: Call ReadFile when ServerIp in OverrideData is an invalid \
#              unicast address.EFI_INVALID_PARAMETER should be returned.
# 
EFI_MTFTP6_TOKEN                             R_Token

SetVar R_Token.Status                        $EFI_SUCCESS
SetVar R_Token.Event                         0

EFI_MTFTP6_OVERRIDE_DATA                     R_OverrideData
SetIpv6Address R_OverrideData.ServerIp       "ff02::1"
SetVar         R_OverrideData.ServerPort     1781
SetVar         R_OverrideData.TryCount       0
SetVar         R_OverrideData.TimeoutValue   0
SetVar         R_Token.OverrideData          &@R_OverrideData
CHAR8                                        R_NameOfFile
SetVar         R_NameOfFile                  "Shell.efi"
SetVar         R_Token.Filename              &@R_NameOfFile
SetVar         R_Token.ModeStr               0
SetVar         R_Token.OptionCount           1
EFI_MTFTP6_OPTION                            R_OptionList(3)
CHAR8                                        R_OptionStr(10)
CHAR8                                        R_OptionVal(10)
SetVar         R_OptionStr                   "blksize"
SetVar         R_OptionVal                   "1024"
SetVar         R_OptionList(0).OptionStr     &@R_OptionStr
SetVar         R_OptionList(0).ValueStr      &@R_OptionVal
SetVar         R_Token.OptionList            &@R_OptionList
SetVar         R_Token.BufferSize            0
SetVar         R_Token.Buffer                0
SetVar         R_Token.Context               0

Mtftp6->ReadFile "&@R_Token, 1, 1, 1, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_INVALID_PARAMETER]
RecordAssertion $assert $Mtftp6ReadFileConf7AssertionGuid001    \
                "Mtftp6.ReadFile -Conf- Call ReadFile when ServerIp in OverrideData is an invalid unicast address"\
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_INVALID_PARAMETER"

#
# Destroy Child
#
Mtftp6ServiceBinding->DestroyChild "@R_Handle, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                   \
                "Mtftp6SBP.DestroyChild - Destroy Child 1"                 \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

EUTClose
				
EndScope _MTFTP6_READFILE_CONFORMANCE7_CASE1_

#
# End Log
#
EndLog
