@echo off
REM EC2 Connect - Usage: connect-aws.bat [connect|stop|status]
powershell -ExecutionPolicy Bypass -File "%~dp0connect-aws.ps1" -Action "%~1"
