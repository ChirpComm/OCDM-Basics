function	r_ModemSymbol	=	xOCDMModem_RX(r_ModemSignal, OCDMModem_PARAM, OCDMChEst_PARAM )
%	=======================================================================
%	$xOCDMModem_RX: OCDM baseband demodulator
%	-----------------------------------------------------------------------
%		$Version:	1.00.00.000
%		$Date:		2023-04-10
%		$Author(s):	Xing Ouyang (ChirpComm)
%	-----------------------------------------------------------------------
%	Description: 
%		This function is used for OCDM baseband demodulation
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
	%	Channel Equalization
	if	nargin < 3
		mode_ChEQU	=	0;
		ChEQU_Tap	=	ones( num_Chirp, 1 );
	else
		ChFreqResp		=	OCDMChEst_PARAM.CFR;
		mode_ChEQU		=	OCDMChEst_PARAM.EQUMode;
		switch	mode_ChEQU

			case	0
				%	No EQU

			case	1
				%	Zero-forcing (ZF) Equalization
				ChEQU_Tap	=	1 ./ ChFreqResp;

			case	2
				%	Minumum Mean Square Error (MMSE/Wiener) Equalization
				num_SNR		=	OCDMChEst_PARAM.SNR;
				ChEQU_Tap	=	conj( ChFreqResp ) ./ ( abs( ChFreqResp ).^2 + num_SNR.^-1 );

			otherwise

				
		end


	end


	%	Implement demodulation
	r_OCDMSignal_GI	=	reshape( r_ModemSignal, num_Chirp + num_GrdIntv, num_Block );
	r_OCDMSignal	=	r_OCDMSignal_GI( num_GrdIntv + 1 : num_GrdIntv + num_Chirp, : );

	%	Equalization
	phaseSeq_Gamma		=	exp( -1i * pi * ( 0 : num_Chirp - 1 ).^2 ./ num_Chirp ).';
	r_OCDMSymbol		=	sqrt( 1 / num_Chirp ) .* fft( r_OCDMSignal, num_Chirp );
	r_OCDMSymbol		=	phaseSeq_Gamma .* r_OCDMSymbol;
	r_OCDMSymbol		=	ChEQU_Tap .* r_OCDMSymbol;
	r_OCDMSymbol_EQU	=	sqrt( num_Chirp ) .* ifft( r_OCDMSymbol, num_Chirp );

	r_ModemSymbol		=	r_OCDMSymbol_EQU( : );

	
end

