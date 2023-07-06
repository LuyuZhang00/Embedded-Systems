clc,clear,close all
f=importdata("D:\Wechat文件\WeChat Files\wxid_h0k3cbael6qw22\FileStorage\File\2023-06\dec_file2.txt");

ecg=rot90(f); 
len=size(ecg,2);
X=ecg(1:len);
Y=zeros(1,len);
Y1=zeros(1,len);
Y2=zeros(1,len);
Y3=zeros(1,len);
Y4=zeros(1,len);
Y5=zeros(1,len);
fs=360;
T=1/fs;
N=1:1:len;
 for i=3:len   
    Y(i)=(X(i)+X(i-1)+X(i-2))/3; %三点平均 filter处理
 end 
 for i=3:len   
    Y1(i)=(Y(i)+2*Y(i-1)+Y(i-2))/4; %一次hanning filter处理
 end 
 for i=3:len   
    Y2(i)=(Y1(i)+2*Y1(i-1)+Y1(i-2))/4; %二次hanning filter处理
 end 
 for i=3:len   
    Y3(i)=(Y2(i)+2*Y2(i-1)+Y2(i-2))/4; %三次hanning filter处理
 end 
  for i=2:len  
    Y4(i)=(Y3(i)-Y3(i-1))/T; %两点差分求导
  end

 subplot(2,1,1)
 plot(Y3);title('综合处理后的ECG信号');
 subplot(2,1,2)
 plot(Y4);title('综合处理并两点差分后的ECG信号');
 figure
plot(Y3);title('三次hanning filter处理');
 figure
plot(Y2);title('2次hanning filter处理');

% for i=0:len
Ymax=0;
for i=1:len
   if(Y4(i)<Ymax)
       Ymax=Ymax;
   else
       Ymax=Y4(i);
   end
end
%%%%%%%找到最大值%%%%%%%
Th=0.07*Ymax;%设置阈值
for i=1:len-1
    if((Y4(i)>Th)&&(Y3(i)>Y3(i-1))&&(Y3(i)>Y3(i+1)))
          Y5(i)=1;
    else
        Y5(i)=0;
    end
end
figure
plot(Y5);title('阈值检测');
%%%%%%%阈值判断%%%%%%%     
 K=zeros(1,len);
j=1;
figure
for i=1:len
    if(Y5(i)==1)
        K(j)=i;
       plot(N,Y3,i,Y3(i),'r.');hold on;
        j=j+1;
   
    end
end
title('R波定位');
%%%%%%%定位%%%%%%%
p=0;
for i=1:j-2
    p=p+(K(i+1)-K(i));
end
T1=p/(j-2)/180;
ncg1=60/T1


