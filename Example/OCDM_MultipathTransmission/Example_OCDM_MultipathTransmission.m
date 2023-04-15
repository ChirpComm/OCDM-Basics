%%	OCDMModem
%	This example shows the performance OCDM signals under AWGN channel and
%	compares it with the theoretical BER performance. 

clear	all;

%% 	Simulation Parameters

%	Symbol Mapping 
num_ModemOrder		=	4;
symbolConstMapping	=	qammod( ( 0 : 2^num_ModemOrder - 1 ).', 2^num_ModemOrder, 'InputType', 'integer', 'UnitAveragePower', true );
%	OCDM Modulation 
num_OCDMGrdIntv	=	256;
num_OCDMSymbol	=	4096;
num_OCDMChirp	=	4096;
num_OCDMBlock	=	2^6;
OCDMParam		=	struct;
OCDMParam.Num_GrdIntv		=	num_OCDMGrdIntv;
OCDMParam.Num_Symbol		=	num_OCDMSymbol;
OCDMParam.Num_Chirp			=	num_OCDMChirp;
OCDMParam.Num_Block			=	num_OCDMBlock;
%	OCDM Channel Equalization
OCDMChEst_Param		=	struct;
OCDMChEst_Param.EQUMode		=	1;
OCDMChEst_Param.SNR			=	100;
OCDMChEst_Param.CFR			=	1;
%	Signal Frame 
num_InfoBit		=	num_ModemOrder * num_OCDMSymbol * num_OCDMBlock;
num_ModSignal	=	( num_OCDMChirp + num_OCDMGrdIntv ) * num_OCDMBlock;
%	Multipath Fading Channel
mode_Multipath	=	'LTE-EVA';
switch	mode_Multipath
	case	'AWGN'

	case	'EquiPath'
		Ch_MultiPath_PDP	=	[ 1, 1, 1, 1, 1, 1 ].';			%	Power delay profile
		Ch_MultiPath_DP		=	[ 0, 6, 8, 11, 17, 25 ].';		%	Delay profile
	case	'LTE-EVA'
		Ch_EVA_DelayProfile		=	[ 
			0		0.0
			30		-1.5
			150		-1.4
			310		-3.6
			370		-0.6
			710		-9.1
			1090	-7.0
			1730	-12.0
			2510	-16.9
			];
		Ch_MultiPath_PDP	=	10.^( Ch_EVA_DelayProfile( : , 2 ) ./ 10 );
		Ch_MultiPath_DP		=	round( Ch_EVA_DelayProfile( : , 1 ) ./ 1e9 .* 100e6 );
	otherwise

end


Ch_MultiPath_PDP	=	Ch_MultiPath_PDP ./ sum( Ch_MultiPath_PDP );
Ch_NumTap			=	size( Ch_MultiPath_DP, 1 );

%	Channel Setting
vec_EbN0_dB		=	( 00 : 5 : 50 ).';
vec_SNR_dB		=	vec_EbN0_dB + 10 * log10( num_ModemOrder );
vec_BER			=	zeros( size( vec_EbN0_dB ) );
vec_EVM			=	zeros( size( vec_EbN0_dB ) );

num_Loop	=	2^8;

for cnt_SNR = 1 : numel( vec_SNR_dB )
	
	num_SNR_dB		=	vec_SNR_dB( cnt_SNR );
	num_EbN0_dB		=	vec_EbN0_dB( cnt_SNR );
	num_BitError	=	0;
	num_EVM			=	0;
	num_SigVar		=	0;
	
	for cnt_Loop = 1 : num_Loop
		%% OCDM Transmitter
	
		t_InfoBit		=	double( rand( num_InfoBit, 1 ) > 0.5 );
		t_ModSymbol		=	qammod( t_InfoBit, 2^num_ModemOrder, 'InputType', 'bit', 'UnitAveragePower', true );
		t_ModSignal		=	xOCDMModem_TX( t_ModSymbol, OCDMParam );
	
	
		%%	Channel Transmission 
	
		ch_Signal	=	t_ModSignal;
		%	Multipath channel implementation
		Ch_MultiPath_Tap	=	sqrt( 0.5 ) * randn( size( Ch_MultiPath_PDP ) ) + 1i * randn( size( Ch_MultiPath_PDP ) );
		Ch_MultiPath_Tap	=	Ch_MultiPath_PDP .* Ch_MultiPath_Tap;
		Ch_MultiPath_CIR	=	zeros( num_OCDMChirp, 1 );
		Ch_MultiPath_CIR( 1 + Ch_MultiPath_DP, : )		=	Ch_MultiPath_Tap;
		Ch_MultiPath_CFR	=	fft( Ch_MultiPath_CIR );
	
		ch_MultiPath_Signal	=	zeros( size( t_ModSignal ), 'like', ch_Signal );
		for cnt_Path = 1 : Ch_NumTap
			ch_MultiPath_Signal		=	ch_MultiPath_Signal + ...
				Ch_MultiPath_Tap( cnt_Path ) .* circshift( ch_Signal, [ Ch_MultiPath_DP( cnt_Path ), 0 ] );
		end
	
		%	Received signal at RF front-end
		r_ModSignal		=	ch_MultiPath_Signal;
		r_ModSignal		=	awgn( r_ModSignal, num_SNR_dB );
	
	
		%%	OCDM Receiver
	
		OCDMChEst_Param.SNR		=	10.^( num_SNR_dB ./ 10 );
		OCDMChEst_Param.CFR		=	Ch_MultiPath_CFR;
	
		r_ModSymbol		=	xOCDMModem_RX( r_ModSignal, OCDMParam, OCDMChEst_Param );
		r_InfoBit		=	qamdemod( r_ModSymbol, 2^num_ModemOrder, 'OutputType', 'bit', 'UnitAveragePower', true );

		num_BitError	=	num_BitError + sum( r_InfoBit ~= t_InfoBit );
		num_EVM			=	num_EVM + mean( abs( r_ModSymbol - t_ModSymbol ) );
		num_SigVar		=	num_SigVar + mean( abs( r_ModSymbol - t_ModSymbol ).^2 );

	end
	

	%%	Performance Evaluation

	num_BER		=	num_BitError / num_InfoBit / num_Loop;
	num_EVM		=	num_EVM / num_Loop;
	num_SigVar	=	num_SigVar / num_Loop;
	
	vec_BER( cnt_SNR )	=	num_BER;
	vec_EVM( cnt_SNR )	=	num_EVM;
	
	str_PerfPrompt	=	'EbN0 = %.2f dB, EVM = %.2f%%, BER = %.3e (%d errors out of %d bits)\n';
	fprintf( str_PerfPrompt, num_EbN0_dB, num_EVM * 100, num_BER, num_BitError, num_InfoBit );
	
end


%%	Results Rendering
vec_TheorBER	=	berawgn( vec_EbN0_dB, 'qam', 2^num_ModemOrder );

figure;
box on;
semilogy( vec_EbN0_dB, vec_BER, 'o', 'MarkerSize', 6 );
hold on;
semilogy( vec_EbN0_dB, vec_TheorBER, '-' );
title( 'BER versus E_{b}/N_{0}' );
xlabel( 'E_{b}/N_{0}' );
xlim( [ 0, 20 ] );
ylabel( 'BER' );
ylim( [ 1e-6, 1e-1 ] );

