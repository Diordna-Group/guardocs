@echo off
echo user ftp> ftpcmd.dat
echo ftp>> ftpcmd.dat
echo cd office>> ftpcmd.dat
echo cd archivista>> ftpcmd.dat
echo bin>> ftpcmd.dat
echo put %1>> ftpcmd.dat
echo quit>> ftpcmd.dat
ftp -n -s:ftpcmd.dat 192.168.0.220
del ftpcmd.dat
del %1
cd C:\\Programme\\Mozilla Firefox
firefox.exe "http://192.168.0.220/perl/avclient/index.pl?host=localhost&db=archivista&uid=Admin&pwd=archivista&go_queryfile&fld_Dateiname=%1"

