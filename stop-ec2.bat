@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0connect-ec2.ps1" -Action stop
