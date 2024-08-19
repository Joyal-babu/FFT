 fs = 300e6;
 ts = 1/fs;
 t = 0:ts:(512*ts-ts);
 x = sin(2*pi*0.6e6*t);

 figure(1);
 plot(t,x)

 writematrix(x, "D:\JOYAL\matlab\lut.txt")

%h= hamming(400);

%figure(2);
%plot(h)

%out= h.*x;

%figure(3);
%plot(abs(out))
