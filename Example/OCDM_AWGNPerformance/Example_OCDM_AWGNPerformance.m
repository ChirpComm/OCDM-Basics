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
num_OCDMBlock	=	2^10;
OCDMParam		=	struct;
OCDMParam.Num_GrdIntv		=	num_OCDMGrdIntv;
OCDMParam.Num_Symbol		=	num_OCDMSymbol;
OCDMParam.Num_Chirp			=	num_OCDMChirp;
OCDMParam.Num_Block			=	num_OCDMBlock;
%	Signal Frame 
num_InfoBit		=	num_ModemOrder * num_OCDMSymbol * num_OCDMBlock;
num_ModSignal	=	( num_OCDMChirp + num_OCDMGrdIntv ) * num_OCDMBlock;
%	Channel Setting
vec_EbN0_dB		=	( 0 : 1 : 20 ).';
vec_SNR_dB		=	vec_EbN0_dB + 10 * log10( num_ModemOrder );
vec_BER			=	zeros( size( vec_EbN0_dB ) );
vec_EVM			=	zeros( size( vec_EbN0_dB ) );



for cnt_SNR = 1 : numel( vec_SNR_dB )
	
	num_SNR_dB		=	vec_SNR_dB( cnt_SNR );
	num_EbN0_dB		=	vec_EbN0_dB( cnt_SNR );
	
	%% OCDM Transmitter

	t_InfoBit		=	double( rand( num_InfoBit, 1 ) > 0.5 );
	t_ModSymbol		=	qammod( t_InfoBit, 2^num_ModemOrder, 'InputType', 'bit', 'UnitAveragePower', true );
	t_ModSignal		=	OCDMMod( t_ModSymbol, OCDMParam );


	%%	Channel Transmission 

	r_ModSignal		=	awgn( t_ModSignal, num_SNR_dB );


	%%	OCDM Receiver

	r_ModSymbol		=	OCDMDemod( r_ModSignal, OCDMParam );
	r_InfoBit		=	qamdemod( r_ModSymbol, 2^num_ModemOrder, 'OutputType', 'bit', 'UnitAveragePower', true );


	%%	Performance Evaluation

	num_BitError		=	sum( r_InfoBit ~= t_InfoBit );
	num_BER				=	num_BitError / num_InfoBit;
	num_EVM				=	mean( abs( r_ModSymbol - t_ModSymbol ) );
	num_SigVar			=	mean( abs( r_ModSymbol - t_ModSymbol ).^2 );
	
	vec_BER( cnt_SNR )	=	num_BER;
	vec_EVM( cnt_SNR )	=	num_EVM;
	
	str_PerfPrompt	=	'EbN0 = %.2f dB, EVM = %.2f%%, BER = %.3e (%d errors out of %d bits)\n';
	fprintf( str_PerfPrompt, num_EbN0_dB, num_EVM * 100, num_BER, num_BitError, num_InfoBit );
	
end


%%	Results Rendering
vec_TheorBER	=	berawgn( vec_EbN0_dB, 'qam', 2^num_ModemOrder );
vec_TheorEVM	=	1 ./ ( 10.^( vec_SNR_dB ./ 20 ) );

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


figure;
box on;
plot( vec_EbN0_dB, vec_EVM, 'o', 'MarkerSize', 6 );
hold on;
plot( vec_EbN0_dB, vec_TheorEVM, '-' );
title( 'EVM versus E_{b}/N_{0}' );
xlabel( 'E_{b}/N_{0}' );
xlim( [ 0, 20 ] );
ylabel( 'EVM' );
ylim( [ 0, 0.5 ] );



%%	

function	t_ModSignal		=	OCDMMod( t_ModSymbol, OCDMParam )

	num_GrdIntv		=	OCDMParam.Num_GrdIntv;
	num_Symbol		=	OCDMParam.Num_Symbol;
	num_Chirp		=	OCDMParam.Num_Chirp;
	num_Block		=	OCDMParam.Num_Block;
	
	t_OCDMSymbol	=	reshape( t_ModSymbol, num_Symbol, num_Block );
	t_OCDMSignal	=	FastInvDFnT( t_OCDMSymbol, num_Chirp );
	t_OCDMSignal_GI	=	[
		t_OCDMSignal( num_Chirp - num_GrdIntv + 1 : num_Chirp, : )
		t_OCDMSignal
		];
	t_ModSignal		=	t_OCDMSignal_GI( : );
	
end


function	r_ModSymbol	=	OCDMDemod( r_ModSignal, OCDMParam )

	num_GrdIntv		=	OCDMParam.Num_GrdIntv;
	num_Symbol		=	OCDMParam.Num_Symbol;
	num_Chirp		=	OCDMParam.Num_Chirp;
	num_Block		=	OCDMParam.Num_Block;
	
	r_OCDMSignal_GI		=	reshape( r_ModSignal, num_Chirp + num_GrdIntv, num_Block );
	r_OCDMSignal		=	r_OCDMSignal_GI( num_GrdIntv + 1 : num_GrdIntv + num_Chirp, : );
	r_OCDMSymbol		=	FastDFnT( r_OCDMSignal, num_Chirp );
	r_ModSymbol			=	r_OCDMSymbol( : );

end
