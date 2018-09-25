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
CaseGuid        338AD37B-3F60-4e45-A48D-9344CF47AD85
CaseName        Transmit.Conf1.Case5
CaseCategory    MNP
CaseDescription {Test Transmit conformance of MNP - Call MNP.Transmit() with   \
	               one or more of the Token.TxData.FragmentTable[].FragmentLength\
	               fields being zero. The return status should be                \
	               EFI_INVALID_PARAMETER.}
################################################################################

Include MNP/include/Mnp.inc.tcl

#
# Begin log ...
#
BeginLog
BeginScope _MNP_TRANSMIT_CONFORMANCE1_CASE5_

#
# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                                 R_Status
UINTN                                 R_Handle
EFI_MANAGED_NETWORK_CONFIG_DATA       R_MnpConfData
EFI_MAC_ADDRESS                       R_DstAddr
EFI_MAC_ADDRESS                       R_SrcAddr
EFI_MANAGED_NETWORK_TRANSMIT_DATA     R_TxData
TOKEN_PACKET                          R_TokenPacket
EFI_MANAGED_NETWORK_FRAGMENT_DATA     R_FragData
EFI_MANAGED_NETWORK_COMPLETION_TOKEN  R_Token
RAW_ETH_PACKET_BODY                   R_Body

MnpServiceBinding->CreateChild {&@R_Handle, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Mnp.Transmit - Conf - Create Child"                           \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"
SetVar          [subst $ENTS_CUR_CHILD]  @R_Handle
                
                
#
# configure this child
#
SetMnpConfigData R_MnpConfData 0 0 0 TRUE FALSE TRUE TRUE FALSE FALSE TRUE
Mnp->Configure {&@R_MnpConfData, &@R_Status}
GetAck

SetEthMacAddress  R_DstAddr "1:1:1:1:1:1" 
SetEthMacAddress  R_SrcAddr "2:2:2:2:2:2"
SetEtherTestPacket R_Body "1:1:1:1:1:1" "2:2:2:2:2:2"

SetVar R_TxData.DestinationAddress    &@R_DstAddr
SetVar R_TxData.SourceAddress         &@R_SrcAddr
SetVar R_TxData.ProtocolType          0x0800
SetVar R_TxData.FragmentCount         1
SetVar R_TxData.DataLength            [Sizeof R_Body]

SetVar R_FragData.FragmentBuffer      &@R_Body
SetVar R_FragData.FragmentLength      [Sizeof R_Body]
SetVar R_TxData.FragmentTable         @R_FragData
SetVar R_Token.Packet.TxData          &@R_TxData
#
# Token->TxData.FragmentTable[].Length = 0
#
SetVar R_FragData.FragmentLength      0
SetVar R_TxData.FragmentTable         @R_FragData
Mnp->Transmit "&@R_Token, &@R_Status"
GetAck
set assert [VerifyReturnStatus R_Status $EFI_INVALID_PARAMETER]
RecordAssertion $assert $MnpTransmitConf1AssertionGuid005                      \
                "Mnp.Transmit - Conf - Call Transmit with Invalid parameter -  \
                FragmentTable.Length=0"                                        \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_INVALID_PARAMETER"

#
# Destroy child R_Handle
#
MnpServiceBinding->DestroyChild {@R_Handle, &@R_Status}
GetAck
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Mnp.Transmit - Conf - Destroy Child"                          \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

EndScope _MNP_TRANSMIT_CONFORMANCE1_CASE5_

#
#EndLog
#
EndLog
