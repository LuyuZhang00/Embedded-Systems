1.直接运行流程：
>>MOUNT C C:\TASM5\exp7   （选择自己文件夹路径）

>> c:

>>exp7


2.若修改了代码，则需重新编译运行:
>>MOUNT C C:\TASM5\exp7    （选择自己文件夹路径）

>>c:

编译:
>>tasm exp2
>>tasm exp3
>>tasm exp4
>>tasm exp5
>>tasm exp6
>>tasm exp7

链接:
>> tlink/v/3 exp7.obj+exp6.obj+exp5.obj+exp4.obj+exp3.obj+exp2.obj

运行:
>>exp7


