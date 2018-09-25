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
CaseGuid        ADCD0EC9-F53F-4938-A1FB-ED440F1EC7CB
CaseName        ReadDirectory.Func5.Case1
CaseCategory    MTFTP6
CaseDescription {Test ReadDirectory function of MTFTP6,invoke ReadDirectory() with a icmp6  \
                 port unreachable error packet received for asynchronous calling.   \
                 EFI_SUCCESS should be returned. 
                }
################################################################################

proc CleanUpEutEnvironment {} {

#
# Destroy Child 
#
Mtftp6ServiceBinding->DestroyChild "@R_Handle, &@R_Status"
GetAck

EUTClose

DestroyPacket
EndCapture
EndScope _MTFTP6_READDIRECTORY_FUNCTION5_CASE1_

#
# End Log
#
EndLog
}

Include MTFTP6/include/Mtftp6.inc.tcl
#
# Begin log ...
#
BeginLog

BeginScope _MTFTP6_READDIRECTORY_FUNCTION5_CASE1_

EUTSetup

UINTN                            R_Status
UINTN                            R_Handle

#
# Create child
#
Mtftp6ServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                      \
                "Mtftp6SB.CreateChild - Create Child 1"                       \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle

#
# Initialize the environment
#
set hostmac    [GetHostMac]
set targetmac  [GetTargetMac]
RemoteEther    $targetmac
LocalEther     $hostmac
set LocalIP    "2002::2"
set RemoteIp   "2002::4321"
LocalIPv6      $LocalIP
RemoteIPv6     $RemoteIp

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
# Check Point: Call ReadDirectory with valid parameters for asynchronous calling. \
#              EFI_SUCCESS should be returned.
# 
EFI_MTFTP6_TOKEN                             R_Token

SetVar R_Token.Status                        $EFI_SUCCESS
UINTN                                        R_NotifyContext
SetVar               R_NotifyContext         0
#
# Create an Event
#
BS->CreateEvent      "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_NotifyContext, &@R_Token.Event, &@R_Status"
GetAck
set assert           [VerifyReturnStatus  R_Status  $EFI_SUCCESS]
RecordAssertion      $assert          $GenericAssertionGuid           \
                     "BS->CreateEvent -Func- Create an Event "                  \
                     "ReturnStatus -$R_Status, ExpectedStatus -$EFI_SUCCESS"

SetVar         R_Token.OverrideData          0
CHAR8                                        R_NameOfFile(20)
SetVar         R_NameOfFile                  "Shell.efi"
SetVar         R_Token.Filename              &@R_NameOfFile
SetVar         R_Token.ModeStr               0
SetVar         R_Token.OptionCount           2
EFI_MTFTP6_OPTION                            R_OptionList(2)
CHAR8                                        R_OptionStr1(10)
CHAR8                                        R_OptionVal1(10)
SetVar         R_OptionStr1                  "blksize"
SetVar         R_OptionVal1                  "1024"
SetVar         R_OptionList(0).OptionStr     &@R_OptionStr1
SetVar         R_OptionList(0).ValueStr      &@R_OptionVal1
CHAR8                                        R_OptionStr2(10)
CHAR8                                        R_OptionVal2(10)
SetVar         R_OptionStr2                  "timeout"
SetVar         R_OptionVal2                  "2"
SetVar         R_OptionList(1).OptionStr     &@R_OptionStr2
SetVar         R_OptionList(1).ValueStr      &@R_OptionVal2
SetVar         R_Token.OptionList            &@R_OptionList
SetVar         R_Token.BufferSize            13
CHAR8          R_Buffer(30)
SetVar         R_Token.Buffer                &@R_Buffer
SetVar         R_Token.Context               NULL

#
# Start capture
#
set L_Filter "ether proto 0x86dd"
StartCapture CCB $L_Filter
Mtftp6->ReadDirectory "&@R_Token, 1, 4, 4, &@R_Status"

ReceiveCcbPacket CCB Mtftp6Packet 10
if { ${CCB.received} == 0} {
#
# If have not captured the packet. Fail
#
set assert fail
RecordAssertion $assert $GenericAssertionGuid    \
                  "Mtftp6.ReadDirectory -Func- No packet received."

CleanUpEutEnvironment
return
}

#
# If have captured the packet. Server response with a icmp6 error packet
#
ParsePacket Mtftp6Packet -t IPv6 -IPv6_src IPV6Src -IPv6_dst IPV6Dst
SendPacket [Icmp6DstPortUnreach $IPV6Src $IPV6Dst]
Stall 5

set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $Mtftp6ReadDirectoryFunc5AssertionGuid001    \
                "Mtftp6.ReadDirectory -Func- Call ReadDirectory with a icmp6 error packet received for asynchronous calling"\
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"


GetVar R_NotifyContext
set assert pass
if { $R_NotifyContext == 0} {
  set assert fail
} 
RecordAssertion $assert $$Mtftp6ReadDirectoryFunc5AssertionGuid002              \
                "If Token->Event be signaled,the value of R_NotifyContext should be changed."

GetVar R_Token.Status
set assert pass
if { ${R_Token.Status} != $EFI_PORT_UNREACHABLE } {
   set assert fail
}
RecordAssertion $assert $$Mtftp6ReadDirectoryFunc5AssertionGuid003              \
                "When returned the Token.Status should be EFI_PORT_UNREACHABLE."

CleanUpEutEnvironment