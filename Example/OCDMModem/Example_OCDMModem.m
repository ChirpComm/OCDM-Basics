%%	OCDMModem
%	This example shows how OCDM is generated based on the Fresnel
%	transforms under AWGN channel. 

clear	all;

%% 	Simulation Parameters

%	Symbol Mapping 
num_ModemOrder		=	4;
symbolConstMapping	=	qammod( ( 0 : 2^num_ModemOrder - 1 ).', 2^num_ModemOrder, 'InputType', 'integer', 'UnitAveragePower', true );
%	OCDM Modulation 
num_OCDMGrdIntv	=	256;
num_OCDMSymbol	=	4096;
num_OCDMChirp	=	4096;
num_OCDMBlock	=	2^8;
%	Signal Frame 
num_InfoBit		=	num_ModemOrder * num_OCDMSymbol * num_OCDMBlock;
num_ModSignal	=	( num_OCDMChirp + num_OCDMGrdIntv ) * num_OCDMBlock;
%	Channel Setting
num_EbN0_dB		=	10;
num_SNR_dB		=	num_EbN0_dB + 10 * log10( num_ModemOrder );


%% OCDM Transmitter

t_InfoBit		=	double( rand( num_InfoBit, 1 ) > 0.5 );
t_ModSymbol		=	qammod( t_InfoBit, 2^num_ModemOrder, 'InputType', 'bit', 'UnitAveragePower', true );
t_OCDMSymbol	=	reshape( t_ModSymbol, num_OCDMChirp, num_OCDMBlock );
t_OCDMSignal	=	FastInvDFnT( t_OCDMSymbol, num_OCDMChirp );
t_OCDMSignal_GI	=	[
	t_OCDMSignal( num_OCDMChirp - num_OCDMGrdIntv + 1 : num_OCDMChirp, : )
	t_OCDMSignal
	];
t_ModSignal		=	t_OCDMSignal_GI( : );


%%	Channel Transmission 

r_ModSignal		=	awgn( t_ModSignal, num_SNR_dB );


%%	OCDM Receiver

r_OCDMSignal_GI		=	reshape( r_ModSignal, num_OCDMChirp + num_OCDMGrdIntv, num_OCDMBlock );
r_OCDMSignal		=	r_OCDMSignal_GI( num_OCDMGrdIntv + 1 : num_OCDMGrdIntv + num_OCDMChirp, : );
r_OCDMSymbol		=	FastDFnT( r_OCDMSignal, num_OCDMChirp );
r_ModSymbol			=	r_OCDMSymbol( : );
r_InfoBit			=	qamdemod( r_ModSymbol, 2^num_ModemOrder, 'OutputType', 'bit', 'UnitAveragePower', true );


%%	Performance Evaluation and Rendering

num_BitError		=	sum( r_InfoBit ~= t_InfoBit );
num_BER				=	num_BitError / num_InfoBit;
num_EVM				=	mean( abs( r_ModSymbol - t_ModSymbol ) );
num_SigVar			=	mean( abs( r_ModSymbol - t_ModSymbol ).^2 );


figure;
box on;
hold on;
plot( r_ModSymbol, '.', 'MarkerSize', 3 );
plot( symbolConstMapping, '.', 'MarkerSize', 16 );


str_PerfPrompt	=	'EbN0 = %.2f dB, EVM = %.2f%%, BER = %.3e (%d errors out of %d bits)\n';
fprintf( str_PerfPrompt, num_EbN0_dB, num_EVM * 100, num_BER, num_BitError, num_InfoBit );


