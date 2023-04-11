function 	outSignal	=	FastInvDFnT( inSignal, num_Spl )
%	=======================================================================
%	Functions - FastInvDFnT:
%		Fast Inverse Discrete Fresnel Transform (DFnT) using fast Fourier transform (FFT) algorithm
%	-----------------------------------------------------------------------
%		Version:    1.00.01
%		Date:		26 Junuary, 2018
%		Author:		Xing Ouyang (XOyLAB)
%	=======================================================================
%	function [ output_Signal ] = FastInvDFnT( input_Signal, num_pnt )
%	-----------------------------------------------------------------------
%	Input Parameters:
%		input_Signal:
%			Input signal for Inverse DFnT.
%		num_pnt:
%			Number of points of Inverse DFnT.
%	-----------------------------------------------------------------------
%	Output Parameters:
%		output_Signal:
%			Output signal after Inverse DFnT.
%	=======================================================================

	num_Row		=	size( inSignal, 1 );
	num_Col		=	size( inSignal, 2 );
	
	if	nargin	<=	1
		num_Spl		=	num_Row;
	end
	
	if	num_Spl >= 1
		
		if	num_Spl == num_Row
			temp_Signal		=	inSignal;
		elseif	num_Spl > num_Row
			temp_Signal		=	zeros( num_Spl, num_Col );
			temp_Signal( 1 : num_Row, : )	=	inSignal;
		else
			str_Warning_Msg		=	strcat( mfilename, ': num_pnt is smaller than the number of rows of the input_signal' );
			warning( str_Warning_Msg );
			temp_Signal		=	inSignal( 1 : num_Spl, : );
		end
		
		chirp_Index	=	( 0 : num_Spl - 1 ).';
		if	mod( num_Spl, 2 ) == 0
			theta_Coeff	=	sqrt( num_Spl ) * exp( 1i * pi / 4 );
			theta_1		=	exp( -1i * pi * chirp_Index.^2 / num_Spl );
			theta_2		=	exp( -1i * pi * chirp_Index.^2 / num_Spl );
		else
			theta_Coeff	=	sqrt( num_Spl ) * exp( 1i * pi * ( 1 - 1 / num_Spl ) / 4 );
			theta_1		=	exp( -1i * pi * chirp_Index .* ( chirp_Index - 1 ) / num_Spl );
			theta_2		=	exp( -1i * pi * chirp_Index .* ( chirp_Index + 1 ) / num_Spl );
		end

		temp_Signal		=	repmat( theta_2, 1, num_Col ) .* temp_Signal;
		temp_Signal		=	ifft( temp_Signal );
		temp_Signal		=	repmat( theta_1, 1, num_Col ) .* temp_Signal;

		outSignal	=	theta_Coeff * temp_Signal;
		
	else
		error( 'Error: IDFnT length must be a positive integer scalar.' );
	end
	
end


%%	Notes:
%	=======================================================================
%	version 1.00.01
%	-----------------------------------------------------------------------
%	Change on number of input arguments similar to fft/ifft. If num_pnt is
%	omitted, it will be the number of rows of the input signal. 




