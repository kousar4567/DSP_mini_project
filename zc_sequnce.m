clc;
clear all;


q=25; % as a positive integer
N=63; % odd positive integer
%% step 1: generate zc sequence

for m=1:31
    theta(m)=(pi*q*(m-1)*m)/N;
    ZC(m)=exp(-j*theta(m));
end
for m=32:N-1
    theta(m)=(pi*q*(m+1)*m)/N;
    ZC(m)=exp(-j*theta(m));
end


%% Step 2: Map onto 128-point frequency-domain vector
X = zeros(1, 128);
X(34:95) = ZC(1:62);


FFT_SHIFT=fftshift(X);

%% Step 3: IFFT
pss_trasmission=ifft(FFT_SHIFT,128);

%% rtl and matlab verification
matlab_pss=pss_trasmission;
rtl_pss=readmatrix('pss_sequence.dat','Delimiter','tab');
sgtitle('dmrs matlab and rtl output symbols real values');
for i=1:1
    %subplot(3,3,i);
    plot(real((matlab_pss(1,:))),'g');
    hold on;
    stem(real(rtl_pss(1+(i-1)*(128):i*(128))));
    title(['Samples of Symbol ', num2str(i)]);
    legend("matlab output","rtl output");
    hold off;
end
