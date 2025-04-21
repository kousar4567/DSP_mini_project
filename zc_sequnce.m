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

%%
matlab_pss=pss_trasmission;
rtl_pss=readmatrix('/home/wisig/Desktop/FPGA_LAB/pss_transmission/test_folder/script/pss_sequence.dat','Delimiter','tab');
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
%% 
matlab_fft_shift=FFT_SHIFT;
rtl_fft_shift=readmatrix('/home/wisig/Desktop/FPGA_LAB/pss_transmission/test_folder/script/fft_shift.dat','Delimiter','tab');
sgtitle('dmrs matlab and rtl output symbols real values');
for i=1:1
    %subplot(3,3,i);
    plot(real((matlab_fft_shift(i,:))),'g');
    hold on;
    stem(real(rtl_fft_shift(1+(i-1)*(128):i*(128))));
    title(['Samples of Symbol ', num2str(i)]);
    legend("matlab output","rtl output");
    hold off;
end

%%
matlab_zc=ZC;
rtl_zc=readmatrix('/home/wisig/Desktop/FPGA_LAB/pss_transmission/test_folder/script/ZC.dat','Delimiter','tab');
sgtitle('dmrs matlab and rtl output symbols real values');
for i=1:1
    %subplot(3,3,i);
    plot(real((matlab_zc(i,:))),'g');
    hold on;
    stem(real(rtl_zc(1+(i-1)*(62):i*(62))));
    title(['Samples of Symbol ', num2str(i)]);
    legend("matlab output","rtl output");
    hold off;
end