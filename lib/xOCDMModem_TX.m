function	t_OCDMSignal	=	xOCDMModem_TX( t_ModemSymbol, OCDMModem_PARAM )
%	=======================================================================
%	$xOCDMModem_TX: OCDM baseband modulator
%	-----------------------------------------------------------------------
%		$Version:	1.00.00.000
%		$Date:		2023-04-10
%		$Author(s):	Xing Ouyang (ChirpComm)
%	-----------------------------------------------------------------------
%	Description: 
%		This function is used for OCDM baseband modulation
%	Usage/Examples:
%	
%	=======================================================================
%	Input Argument(s): 
%	-	t_ModemSymbol: (Type)
% 			Symbols (PAM, QAM, etc.) that are used for modulation
%	-	OCDMModem_PARAM: (Type)
% 			OCDM modem parameters
%	-----------------------------------------------------------------------
%	Output Argument(s): 
%	-	t_OCDMSignal: (Type)
%			OCDM signals after modulation
%	=======================================================================
%	Usage & Examples:
%	
%	=======================================================================


	%	Initialize parameters
	num_GrdIntv		=	OCDMModem_PARAM.Num_GrdIntv;
	num_Symbol		=	OCDMModem_PARAM.Num_Symbol;
	num_Chirp		=	OCDMModem_PARAM.Num_Chirp;
	num_Block		=	OCDMModem_PARAM.Num_Block;
	
	%	Implement modulation
	t_OCDMSymbol	=	reshape( t_ModemSymbol, num_Symbol, num_Block );
	t_OCDMSignal	=	FastInvDFnT( t_OCDMSymbol, num_Chirp );
	t_OCDMSignal_GI	=	[
		t_OCDMSignal( num_Chirp - num_GrdIntv + 1 : num_Chirp, : )
		t_OCDMSignal
		];
	t_OCDMSignal		=	t_OCDMSignal_GI( : );


end

